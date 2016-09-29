import logging
import pprint
import datetime
import os
from ansible.inventory import Inventory
from ansible.vars import VariableManager
from ansible.parsing.dataloader import DataLoader
from ansible.executor import playbook_executor
from ansible.utils.display import Display
from ansible.plugins.callback import CallbackBase


class LoggingCallback(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    CALLBACK_NAME = 'log'
    CALLBACK_NEEDS_WHITELIST = False

    def __init__(self):
        super(LoggingCallback, self).__init__()
        self.start_time = datetime.now()

    def log(self, level, msg, *args, **kwargs):
        logging.log(level, msg, *args, **kwargs)

    def _on_any(self, level, label, host, orig_result):
        result = orig_result.copy()
        result.pop('invocation', None)
        result.pop('verbose_always', True)
        item = result.pop('item', None)
        if not result:
            msg = ''
        elif len(result) == 1:
            msg = ' | {0}'.format(result.values().pop())
        else:
            msg = '\n' + pprint.pformat(result)
        if item:
            self.log(level, '{0} (item={1}): {2}{3}'.format(host, item, label, msg))
        else:
            self.log(level, '{0}: {1}{2}'.format(host, label, msg))

    def v2_runner_on_failed(self, result, ignore_errors=False):
        delegated_vars = result._result.get('_ansible_delegated_vars', None)

        if ignore_errors:
            level = logging.INFO
            label = 'FAILED (ignored)'
        else:
            level = logging.ERROR
            label = 'FAILED'

        if delegated_vars:
            host = "{1} -> {2}".format(result._host.get_name(), delegated_vars['ansible_host'])
        else:
            host = result._host.get_name()

        self._on_any(level, label, host, result)

    def v2_runner_on_ok(self, result):
        self._clean_results(result._result, result._task.action)
        delegated_vars = result._result.get('_ansible_delegated_vars', None)
        msg = ""

        if delegated_vars:
            host = "{1} -> {2}".format(result._host.get_name(), delegated_vars['ansible_host'])
        else:
            host = result._host.get_name()

        self._on_any(logging.INFO, 'SUCCESS', host, result)


class Options(object):
    """
    Options class to replace Ansible OptParser
    """
    def __init__(self, verbosity=None, inventory=None, listhosts=None, subset=None, module_paths=None, extra_vars=None,
                 forks=None, ask_vault_pass=None, vault_password_files=None, new_vault_password_file=None,
                 output_file=None, tags=None, skip_tags=None, one_line=None, tree=None, ask_sudo_pass=None, ask_su_pass=None,
                 sudo=None, sudo_user=None, become=None, become_method=None, become_user=None, become_ask_pass=None,
                 ask_pass=None, private_key_file=None, remote_user=None, connection=None, timeout=None, ssh_common_args=None,
                 sftp_extra_args=None, scp_extra_args=None, ssh_extra_args=None, poll_interval=None, seconds=None, check=None,
                 syntax=None, diff=None, force_handlers=None, flush_cache=None, listtasks=None, listtags=None, module_path=None):
        self.verbosity = verbosity
        self.inventory = inventory
        self.listhosts = listhosts
        self.subset = subset
        self.module_paths = module_paths
        self.extra_vars = extra_vars
        self.forks = forks
        self.ask_vault_pass = ask_vault_pass
        self.vault_password_files = vault_password_files
        self.new_vault_password_file = new_vault_password_file
        self.output_file = output_file
        self.tags = tags
        self.skip_tags = skip_tags
        self.one_line = one_line
        self.tree = tree
        self.ask_sudo_pass = ask_sudo_pass
        self.ask_su_pass = ask_su_pass
        self.sudo = sudo
        self.sudo_user = sudo_user
        self.become = become
        self.become_method = become_method
        self.become_user = become_user
        self.become_ask_pass = become_ask_pass
        self.ask_pass = ask_pass
        self.private_key_file = private_key_file
        self.remote_user = remote_user
        self.connection = connection
        self.timeout = timeout
        self.ssh_common_args = ssh_common_args
        self.sftp_extra_args = sftp_extra_args
        self.scp_extra_args = scp_extra_args
        self.ssh_extra_args = ssh_extra_args
        self.poll_interval = poll_interval
        self.seconds = seconds
        self.check = check
        self.syntax = syntax
        self.diff = diff
        self.force_handlers = force_handlers
        self.flush_cache = flush_cache
        self.listtasks = listtasks
        self.listtags = listtags
        self.module_path = module_path


class Runner(object):

    def __init__(self, playbook, inventory, run_data=None, verbosity=0, tags=None, skip_tags=None):
        self.run_data = run_data or {}
        self.options = Options()

        self.options.verbosity = verbosity
        self.options.connection = 'local'  # Need a connection type "smart" or "ssh"
        self.options.become = True
        self.options.become_method = 'sudo'
        self.options.become_user = 'root'
        self.options.tags = tags
        self.options.skip_tags = skip_tags
        # Set global verbosity
        self.display = Display()
        self.display.verbosity = self.options.verbosity
        # Executor appears to have it's own
        # verbosity object/setting as well
        playbook_executor.verbosity = self.options.verbosity

        # Become Pass Needed if not logging in as user root
        passwords = {}

        # Gets data from YAML/JSON files
        self.loader = DataLoader()
        self.loader.set_vault_password(os.environ.get('VAULT_PASS',''))

        # All the variables from all the various places
        self.variable_manager = VariableManager()
        self.variable_manager.extra_vars = self.run_data

        self.inventory = Inventory(loader=self.loader, variable_manager=self.variable_manager, host_list=inventory)
        self.variable_manager.set_inventory(self.inventory)

        # Setup playbook executor, but don't run until run() called
        self.pbex = playbook_executor.PlaybookExecutor(
            playbooks=[playbook],
            inventory=self.inventory,
            variable_manager=self.variable_manager,
            loader=self.loader,
            options=self.options,
            passwords=passwords)

    def run(self):
        # Results of PlaybookExecutor
        self.pbex.run()
        stats = self.pbex._tqm._stats

        # Test if success for record_logs
        run_success = True
        hosts = sorted(stats.processed.keys())
        for h in hosts:
            t = stats.summarize(h)
            if t['unreachable'] > 0 or t['failures'] > 0:
                run_success = False

        return stats


def main():
    # You may want this to run as user root instead
    # or make this an environmental variable, or
    # a CLI prompt. Whatever you want!
    runner = Runner(
        inventory='/ansible-code/playbooks/inventory/all-in-one',
        playbook='/ansible-code/playbooks/site.yml',
        tags=['provision'],
        verbosity=0
    )

    stats = runner.run()

    # Maybe do something with stats here? If you want!

    return stats

if __name__ == '__main__':
    main()
