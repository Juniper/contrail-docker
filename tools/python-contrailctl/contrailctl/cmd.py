import argparse
import yaml
import sys
from contrailctl.config import Configurator
from contrailctl.map import CONTROLLER_PARAM_MAP
from contrailctl.runner import Runner


class ConfigManager(object):
    # This name (component_map) may not make sense here, in any time we wanted to handle individual services within
    # the container with contrailctl. Here the assumption is that contrailctl always handle high level configs, but
    # it may ended up managing individual components later.
    COMPONENT_PARAM_MAP = {
        "controller": CONTROLLER_PARAM_MAP,
    }

    PLAYBOOKS = dict(
        controller="contrail_controller.yml",
        analytics="contrail_analytics.yml",
        analyticsdb="contrail_analyticsdb.yml"
    )

    def __init__(self, config_file, component):
        self.component = component
        self.config_file = config_file
        self.param_map = self.COMPONENT_PARAM_MAP[component]

    def _update_yml(self, yml, data):
        """ Update vars yaml file
        :param yml: yaml file to update
        :param data: data to be updated
        :return: True in case the file is changed, False in case the file is not changed
        """
        with open(yml, "r+") as f:
            yml_data = yaml.load(f) or {}
            yml_data_new = yml_data.copy()
            yml_data_new.update(data)
            if yml_data == yml_data_new:
                return False
            else:
                f.seek(0)
                f.write(yaml.dump(yml_data_new, default_flow_style=False))
                f.truncate()
                return True

    def sync(self):
        component_config = Configurator(self.config_file, self.param_map)
        config_dict = component_config.map({})
        var_file = "/contrail-ansible/playbooks/vars/" + self.PLAYBOOKS[self.component]
        playbook = "/contrail-ansible/playbooks/" + self.PLAYBOOKS[self.component]
        need_ansible_run = self._update_yml(var_file, config_dict)
        if need_ansible_run:
            print("CONFIGS: ", config_dict)
            # NOTE: it may make sense to have some of these params to be get from user in later point.
            # But currently they are constants
            runner_params = dict(
                inventory='/contrail-ansible/playbooks/inventory/all-in-one',
                playbook=playbook,
                tags=['provision', 'configure'],
                verbosity=0
            )
            ansible_runner = Runner(**runner_params)
            stats = ansible_runner.run()
            return stats
        else:
            print("All configs are in sync")
            return None


def main(args=sys.argv[1:]):
    ap = argparse.ArgumentParser(description="Contrailctl")
    sp = ap.add_subparsers(dest="resource", help="Resource to manage")
    p_config = sp.add_parser("config", help="manage configuration")
    sp_config = p_config.add_subparsers(dest="action")
    p_config_sync = sp_config.add_parser("sync", help="Sync the config")
    p_config_cfg = p_config_sync.add_argument("-f", "--config-file", type=str,
                                         help="Master config file path")
    p_config_comp = p_config_sync.add_argument("-c", "--component", type=str,
                                         choices=["controller"],
                                         default="controller",
                                         help="Component[s] to be configured")
    args = ap.parse_args()

    if not args.config_file:
        args.config_file = "/etc/contrailctl/%s.conf" % args.component

    cm = ConfigManager(args.config_file, args.component)
    stats = cm.sync()

if __name__ == '__main__':
    main(sys.argv[1:])
