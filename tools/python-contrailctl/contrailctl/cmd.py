import argparse
import yaml
import sys
import os
import fcntl
import time
from .config import Configurator
from .map import *
from .runner import Runner
from .k8s_modify_config import K8sModifyConfig
from jsonschema import validate,FormatChecker, exceptions, RefResolver
import json

from ansible.executor.stats import AggregateStats


LOCK_PATH = "/var/lock/contrailctl"
PLAYBOOK_DIR = "/contrail-ansible-internal"
TMP_K8S_CONTRAILCTL = "/tmp/contrailctl"


class SingleInstance(object):
    def __init__(self):
        self.fh = None
        self.is_running = False
        try:
            self.fh = open(LOCK_PATH, 'w')
            fcntl.lockf(self.fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except EnvironmentError as err:
            if self.fh is not None:
                self.is_running = True
            else:
                raise

    def clean_up(self):
        try:
            if self.fh is not None:
                fcntl.lockf(self.fh, fcntl.LOCK_UN)
                self.fh.close()
                os.unlink(LOCK_PATH)
        except Exception as err:
            raise


class ConfigManager(object):
    # This name (component_map) may not make sense here, in any time we wanted
    # to handle individual services within the container with contrailctl.
    # Here the assumption is that contrailctl always handle high level configs,
    # but it may ended up managing individual components later.
    COMPONENT_PARAM_MAP = {
        "controller": CONTROLLER_PARAM_MAP,
        "analyticsdb": ANALYTICSDB_PARAM_MAP,
        "analytics": ANALYTICS_PARAM_MAP,
        "lb": LB_PARAM_MAP,
        "agent": AGENT_PARAM_MAP,
        "kubemanager": KUBEMANAGER_PARAM_MAP,
        "kubernetesagent": KUBERNETESAGENT_PARAM_MAP,
        "mesosmanager": MESOSMANAGER_PARAM_MAP,
        "cephcontroller": CEPHCONTROLLER_PARAM_MAP,
        "contrailissu": CONTRAIL_ISSU_MAP,
    }

    PLAYBOOKS = dict(
        controller="contrail_controller.yml",
        analytics="contrail_analytics.yml",
        analyticsdb="contrail_analyticsdb.yml",
        lb="contrail_lb.yml",
        agent="contrail_agent.yml",
        kubemanager="contrail_kube_manager.yml",
        mesosmanager="contrail_mesos_manager.yml",
        cephcontroller="storage_ceph_controller.yml",
        contrailissu="contrail_issu.yml",
        kubernetesagent="contrail_kubernetes_agent.yml"
    )

    def __init__(self, config_file, component):
        self.component = component
        self.config_file = config_file
        self.param_map = self.COMPONENT_PARAM_MAP[component]
        configurator = Configurator(self.config_file, self.param_map, self.component)
        self.config_dict = configurator.get_config_dict()
        self.mapped_dict = configurator.map({})
        if os.environ.get('PLAYBOOK_DIRECTORY', None):
            playbook_dir = os.environ['PLAYBOOK_DIRECTORY']
        else:
            playbook_dir = PLAYBOOK_DIR

        if os.path.isdir(playbook_dir):
            if os.path.isdir(os.path.join(playbook_dir,"playbooks")):
                self.playbook_dir = os.path.join(playbook_dir, "playbooks")
            else:
                self.playbook_dir = playbook_dir
        else:
            raise OSError(2, 'No such file or directory', playbook_dir)

    def _update_yml(self, yml, new_vars):
        """ Update vars yaml file
        :param yml: yaml file to update
        :param new_vars: data to be updated
        :return: True in case the file is changed, False in case the file is
                 not changed
        """
        with open(yml, "r+") as f:
            current_vars = yaml.load(f) or {}
            if current_vars == new_vars:
                return False
            else:
                f.seek(0)
                f.write("## CAUTION! CAUTION! CAUTION! ##\n"
                        "# This file is managed by contrailctl. ##\n"
                        "# All manual configurations will be wiped off\n##\n")
                f.write(yaml.dump(new_vars, default_flow_style=False))
                f.truncate()
                return True

    def validate(self, data=None):
        if not data:
            data = self.config_dict
        schema_dir = "/usr/share/contrailctl/schema/"
        schema_path="{}/{}.json".format(schema_dir, self.component)
        resolver = RefResolver("file://{}/".format(schema_dir), None)
        try:
            schema=open(schema_path,'r').read()
        except IOError as error:
            print("Schema file is missing - {}".format(schema_path))
            return True
        try:
            validate(data, json.loads(schema), format_checker=FormatChecker(), resolver=resolver)
            return True
        except exceptions.ValidationError as error:
            print(error.message)
            return False

    def sync(self, force=False, tags=None, verbose=False, extra_vars=None):
        """Sync configuration from container master config to internal service
        configs
        :param force: Forcefully run the sync even if there is no difference in
                      configurations
        :param tags: specific ansible tags to run
        :param verbose: Verbose output
        :param extra_vars: extra vars to be passed to ansible
        """
        extra_vars = extra_vars or {}
        extra_vars_dict = dict(x.split('=') for x in extra_vars)
        if not tags:
            tags = ['configure', 'service', 'provision']

        valid = self.validate()
        if not valid:
            return None
        var_file = "{}/vars/{}".format(
            self.playbook_dir, self.PLAYBOOKS[self.component])
        playbook = "{}/{}".format(
            self.playbook_dir, self.PLAYBOOKS[self.component])
        need_ansible_run = self._update_yml(var_file, self.mapped_dict)
        if need_ansible_run or force:
            # NOTE: it may make sense to have some of these params to be get
            # from user in later point.  But currently they are constants
            runner_params = dict(
                inventory="{}/inventory/all-in-one".format(self.playbook_dir),
                playbook=playbook,
                tags=tags,
                verbosity=0,
                run_data=extra_vars_dict
            )
            ansible_runner = Runner(**runner_params)
            stats = ansible_runner.run(verbose)
            return stats
        else:
            print("All configs are in sync")
            return AggregateStats()

    def node_config(self, action, type, servers, config_servers=None, seed_list=None):
        """add/remove node from cluster configuration
        action: add/remove
        type: Type of the node
        servers: comma separated node list
        config_servers: Optional comma separated config_server list, only required
                        if newly added servers have config disabled.
        """
        config_dict = self.config_dict
        if 'GLOBAL' not in config_dict:
            config_dict['GLOBAL'] = {}
        if type == 'controller':
            if config_servers:
                config_server_list = config_servers
            else:
                servers.extend(config_dict['GLOBAL'].get('config_server_list', []))
                config_server_list = list(set(servers))
            if not seed_list:
                seed_list = config_dict['GLOBAL'].get('config_seed_list', [])
            servers.extend(config_dict['GLOBAL'].get('controller_list', []))
            server_list = list(set(servers))
            config_dict['GLOBAL'].update({'controller_list': server_list})
            config_dict['GLOBAL'].update({'config_server_list': config_server_list})
            config_dict['GLOBAL'].update({'config_seed_list': seed_list})
        elif type == 'analytics':
            servers.extend(config_dict['GLOBAL'].get('analytics_list', []))
            server_list = list(set(servers))
            config_dict['GLOBAL'].update({'analytics_list': server_list})
        elif type == 'analyticsdb':
            if not seed_list:
                seed_list = config_dict['GLOBAL'].get('analyticsdb_seed_list', [])
            servers.extend(config_dict['GLOBAL'].get('analyticsdb_list', []))
            server_list = list(set(servers))
            config_dict['GLOBAL'].update({'analyticsdb_list': server_list})
            config_dict['GLOBAL'].update({'analyticsdb_seed_list': seed_list})
        playbook = "{}/contrailctl_config.yml".format(self.playbook_dir)
        runner_params = dict(
            inventory='{}/inventory/all-in-one'.format(self.playbook_dir),
            playbook=playbook,
            run_data={'contrailctl_config_file': self.config_file, 'contrailctl_config_data': config_dict},
            verbosity=0
        )
        ansible_runner = Runner(**runner_params)
        stats = ansible_runner.run()
        return stats


def main(args=sys.argv[1:]):

    components = ["controller", "analyticsdb", "analytics", "agent",
                      "lb","kubemanager", "mesosmanager", "cephcontroller", "contrailissu", "kubernetesagent"]
    types = ["controller", "analyticsdb", "analytics", "cephcontroller"]
    ap_node_common = argparse.ArgumentParser(add_help=False)
    ap_node_common.add_argument('-t', '--type', type=str, required=True,
                                choices=types,
                                help='Type of node')
    ap_node_common.add_argument('-n', '--node-addresses', required=True,
                                type=lambda x: x.split(','),
                                help='Comma separated list of node addresses')
    ap_node_common.add_argument('-s', '--seed-list',
                                type=lambda x: x.split(','),
                                help='Comma separated list of seed nodes to be used')
    ap_common = argparse.ArgumentParser(add_help=False)
    ap_common.add_argument("-f", "--config-file", type=str,
                           help="contrailctl config file path for the component")
    ap_common.add_argument("-c", "--component", type=str, choices=components,
                           help="contrail role to be configured")

    ap = argparse.ArgumentParser(description="Contrailctl")

    sp = ap.add_subparsers(dest="resource", help="Resource to manage")
    p_config = sp.add_parser("config", help="manage configuration")
    sp_config = p_config.add_subparsers(dest="action")
    p_config_sync = sp_config.add_parser("sync", help="Sync the config",
                                         parents=[ap_common])
    p_config_sync.add_argument("-F", "--force", action='store_true',
                               help="Whether to apply config forcibly")
    p_config_sync.add_argument("-t", "--tags", type=lambda x: x.split(','),
                               help="comma separated list of tags to run" +
                                    "specific set of ansible code")
    p_config_sync.add_argument("-v", "--verbose", action='store_true',
                               help="Verbose")
    p_config_sync.add_argument('-e', '--extra-vars', nargs='*',
                    help="Extra variables to be passed to ansible")
    sp_config.add_parser("validate", help="Validate the config",
                                             parents=[ap_common])

    p_config_node = sp_config.add_parser(
        "node", help="add/remove/swap nodes in the cluster configuration")
    sp_config_node = p_config_node.add_subparsers(dest="subaction")
    p_config_node_add = sp_config_node.add_parser(
        "add", help="add nodes in the cluster configuration",
        parents=[ap_node_common, ap_common])
    p_config_node_add.add_argument(
        "--config-list", type=lambda x: x.split(','),
        help="comma separated list of config nodes. Optional it is needed only"
             " when the new controller nodes added are config service disabled")
    sp_config_node.add_parser(
        "remove", help="remove nodes from the cluster configuration",
        parents=[ap_node_common, ap_common])


    args = ap.parse_args()
    if not args.component:
        if os.path.isfile('/etc/contrail-role'):
            component = open('/etc/contrail-role', 'r').read().strip()
            if component in components:
                args.component = component
            else:
                print("Wrong role in /etc/contrail-role, valid roles are: %s" % components)
                return 1
        else:
            print ("Unable to detect component name from either --component or /etc/contrail-role")
            return 1
    if not args.config_file:
        args.config_file = "/etc/contrailctl/%s.conf" % args.component

    timeout = 1800
    poll = 10
    total_wait_time = 0

    if args.tags and 'configure' in args.tags:
        if args.component in ["kubemanager", "agent", "kubernetesagent"]:
            if os.path.exists(TMP_K8S_CONTRAILCTL):
                k8s_modify = K8sModifyConfig(args.component,TMP_K8S_CONTRAILCTL,args.config_file)
                merged = False
                if args.component == "agent":
                    merged = k8s_modify.merge_update_sections_agent()
                elif args.component == "kubemanager":
                    merged = k8s_modify.merge_update_sections_kubemanager()
                elif args.component == "kubernetesagent":
                    merged = k8s_modify.merge_update_sections_kubernetesagent()
                if not merged:
                    return 1

    while True:
        si = SingleInstance()
        if si.is_running:
            if total_wait_time > timeout:
                print("Wait timeout after %s seconds" % timeout)
                return 1
            if total_wait_time < poll:
                print("Waiting for already running process to finish")

            time.sleep(poll)
            total_wait_time += poll
        else:
            return_value = 0
            if args.resource == 'config':
                if args.action == 'sync':
                    cm = ConfigManager(args.config_file, args.component)
                    stats = cm.sync(args.force, args.tags, args.verbose, args.extra_vars)
                    if stats:
                        if stats.failures:
                            return_value = 1
                        else:
                            return_value = 0
                    else:
                        return_value = 1
                elif args.action == 'validate':
                    cm = ConfigManager(args.config_file, args.component)
                    valid = cm.validate()
                    if valid:
                        print("All configurations are valid")
                    else:
                        return_value = 1
                elif args.action == 'node':
                    if args.subaction == 'add':
                            cm = ConfigManager(args.config_file, args.component)
                            stats = cm.node_config('add', args.type, args.node_addresses, args.config_list, args.seed_list)
                            if stats:
                                if stats.failures:
                                    print("contrailctl configuration failed")
                                    return_value = 2
                                else:
                                    return_value = config_sync(args.config_file, args.component)
            si.clean_up()
            return return_value

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
