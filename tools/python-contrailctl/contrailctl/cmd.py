import argparse
import yaml
import sys
import os
import fcntl
import time
from .config import Configurator, read_config
from .map import *
from .runner import Runner

LOCK_PATH = "/var/lock/contrailctl"


class SingleInstance:
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
        "mesosmanager": MESOSMANAGER_PARAM_MAP,
    }

    PLAYBOOKS = dict(
        controller="contrail_controller.yml",
        analytics="contrail_analytics.yml",
        analyticsdb="contrail_analyticsdb.yml",
        lb="contrail_lb.yml",
        agent="contrail_agent.yml",
        kubemanager="contrail_kube_manager.yml",
        mesosmanager="contrail_mesos_manager.yml"
    )

    def __init__(self, config_file, component):
        self.component = component
        self.config_file = config_file
        self.param_map = self.COMPONENT_PARAM_MAP[component]

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

    def sync(self, force=False, tags=None):
        """Sync configuration from container master config to internal service
        configs
        :param force: Forcefully run the sync even if there is no difference in
                      configurations
        :param tags: specific ansible tags to run
        """
        if not tags:
            tags = ['configure', 'service', 'provision']

        component_config = Configurator(self.config_file, self.param_map)
        config_dict = component_config.map({})
        var_file = "/contrail-ansible/playbooks/vars/%s" % (
                self.PLAYBOOKS[self.component])
        playbook = "/contrail-ansible/playbooks/%s" % (
                self.PLAYBOOKS[self.component])
        need_ansible_run = self._update_yml(var_file, config_dict)
        if need_ansible_run or force:
            print("CONFIGS: ", config_dict)
            # NOTE: it may make sense to have some of these params to be get
            # from user in later point.  But currently they are constants
            runner_params = dict(
                inventory='/contrail-ansible/playbooks/inventory/all-in-one',
                playbook=playbook,
                tags=tags,
                verbosity=0
            )
            ansible_runner = Runner(**runner_params)
            stats = ansible_runner.run()
            return stats
        else:
            print("All configs are in sync")
            return None

    def node_config(self, action, type, servers, config_servers=None, seed_list=None):
        """add/remove node from cluster configuration
        action: add/remove
        type: Type of the node
        servers: comma separated node list
        config_servers: Optional comma separated config_server list, only required
                        if newly added servers have config disabled.
        """
        config = read_config(self.config_file)
        config_dict = {}
        for section in config.sections():
            config_dict[section] = {}
            for option in config.options(section):
                config_dict[section][option] = Configurator.eval(config.get(section, option))

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
        playbook = "/contrail-ansible/playbooks/contrailctl_config.yml"
        runner_params = dict(
            inventory='/contrail-ansible/playbooks/inventory/all-in-one',
            playbook=playbook,
            run_data={'contrailctl_config_file': self.config_file, 'contrailctl_config_data': config_dict},
            verbosity=0
        )
        ansible_runner = Runner(**runner_params)
        stats = ansible_runner.run()
        return stats


def config_sync(config_file, component, force=False, tags=None):
    cm = ConfigManager(config_file, component)
    stats = cm.sync(force, tags)
    if stats:
        if stats.failures:
            return 1
        else:
            return 0


def main(args=sys.argv[1:]):

    components = ["controller", "analyticsdb", "analytics", "agent",
                      "lb","kubemanager", "mesosmanager"]
    types = ["controller", "analyticsdb", "analytics"]
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
                           help="Master config file path")
    ap_common.add_argument("-c", "--component", type=str, required=True,
                           choices=components,
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
    if not args.config_file:
        if hasattr(args, 'component'):
            args.config_file = "/etc/contrailctl/%s.conf" % args.component
        elif os.path.isfile('/etc/contrail-role'):
            component = open('/etc/contrail-role', 'r').read().strip()
            if component in components:
                args.config_file = "/etc/contrailctl/%s.conf" % component
            else:
                print("Wrong role in /etc/contrail-role, valid roles are: %s" % components)
                return 1
        else:
            print ("Unable to detect component name from either --component or /etc/contrail-role")
            return 1

    timeout = 1800
    poll = 10
    total_wait_time = 0

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
                    return_value = config_sync(args.config_file, args.component, args.force, args.tags)
                elif args.action == 'node':
                    if args.subaction == 'add':
                            cm = ConfigManager(args.config_file, args.component)
                            stats = cm.node_config('add', args.type, args.node_addresses, args.config_list, args.seed_list)
                            if stats:
                                if stats.failures:
                                    print("contrailctl configuration failed")
                                    return 2
                                else:
                                    return_value = config_sync(args.config_file, args.component)
            si.clean_up()
            return return_value

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
