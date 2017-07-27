import ConfigParser
import os
import socket
import time

CONTRAILCTL_DIR = "/etc/contrailctl/"
TOKEN_FILE = "/tmp/serviceaccount/token"

AGENT_DATA = ("global", "agent")
KUBEMANAGER_DATA = ("global", "kubemanager")
KUBERNETESAGENT_DATA = ("global", "kubernetesagent")


DUMMY_IP = "1.1.1.1"
DUMMY_PORT = 80

class K8sModifyConfig(object):

    def __init__(self, contrail_role, tmp_conf_dir, config_file):
        """ Modifies the temporary config given through the single yaml file
            to add options like token and pod_ip for the necessary sections
        """
        self.component = contrail_role
        self.tmp_conf_dir = tmp_conf_dir

        if not self.tmp_conf_dir.endswith("/"):
            self.tmp_conf_dir += "/"

        self._get_filename = lambda file_name: self.tmp_conf_dir + file_name + ".conf"

        if not os.path.exists(CONTRAILCTL_DIR):
            os.makedirs(CONTRAILCTL_DIR)

        self.contrailctl_conf = open(config_file, 'w')

    def _get_config_from_files(self, file_list):
        """ Reads ini config from the input file list provided and
            returns ConfigParser object
        """
        config_object = ConfigParser.ConfigParser()
        for count in range(180):
            try:
                if config_object.read(file_list):
                    break
            except ConfigParser.Error as e:
                print("Error while reading the config file: %s\n%s"
                      %(filename,e))
                break
            time.sleep(1)

        return config_object

    def merge_update_sections_agent(self):
        """ Merges the section and update for agent role """
        self.config_files = map(self._get_filename, AGENT_DATA)
        agent_config = self._get_config_from_files(self.config_files)
        if not agent_config.has_option("AGENT", "ctrl_data_network"):
            pod_ip = self._get_pod_ip()
            agent_config.set("AGENT", "ctrl_data_ip",value=pod_ip)

        # Adding kubernetes section to agent config
        agent_config.add_section("KUBERNETES")
        k8s_api_server = self._get_k8s_api_server()
        agent_config.set("KUBERNETES", "api_server",value=k8s_api_server)
        agent_config = self._update_k8s_token(agent_config, "KUBERNETES")
        self._write_contrailctl_file(agent_config)

    def merge_update_sections_kubemanager(self):
        """ Merges the section and update for kubemanager role """
        self.config_files = map(self._get_filename,KUBEMANAGER_DATA)
        kubemanager_config = self._get_config_from_files(self.config_files)
        kubemanager_config = self._update_k8s_token(kubemanager_config, "KUBERNETES")
        self._write_contrailctl_file(kubemanager_config)

    def merge_update_sections_kubernetesagent(self):
        """ Merges the section and update for kubernetesagent role """
        self.config_files = map(self._get_filename,KUBERNETESAGENT_DATA)
        kubernetesagent_config = self._get_config_from_files(self.config_files)
        self._write_contrailctl_file(kubernetesagent_config)

    def _write_contrailctl_file(self, role_config):
        """ Write role config to the contrailcltl file """
        role_config.write(self.contrailctl_conf)
        self.contrailctl_conf.close()

    def _update_k8s_token(self, role_config, section):
        """ Update config_obj with token value in the given section """
        token = self._get_k8s_token()
        role_config.set(section, "token",value=token)
        return role_config

    def _get_k8s_token(self):
        """ Reads token file and returns token value """
        try:
            tf = open(TOKEN_FILE)
            token = tf.read()
            tf.close()
            return  token
        except Exception as e:
            print("Error while getting token from file: %s, error: %s"%(TOKEN_FILE, e))
            return None

    def _get_k8s_api_server(self):
        """ Reads kubemanager.conf to get the k8s_api_server"""
        kubemanager_file = self.tmp_conf_dir + "kubemanager.conf"
        kubemanager_config = self._get_config_from_files(kubemanager_file)
        if kubemanager_config.has_option("KUBERNETES", "api_server"):
            k8s_api_server = kubemanager_config.get("KUBERNETES", "api_server")
        else:
            k8s_api_server = ""
        return k8s_api_server

    def _get_pod_ip(self):
        """ With simple test, gets the default ip address """
        s_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s_socket.connect((DUMMY_IP, DUMMY_PORT))
        return s_socket.getsockname()[0]
