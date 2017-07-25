import ConfigParser
import os
import socket
import time

CONTRAILCTL_DIR = "/etc/contrailctl/"
TOKEN_FILE = "/tmp/serviceaccount/token"

AGENT_SECTION = ("global", "agent", "kubemanager")
KUBEMANAGER_SECTION = ("global", "kubemanager")

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

        get_filename = lambda section: self.tmp_conf_dir + section + ".conf"

        if self.component == "agent":
            self.component_section = AGENT_SECTION
            self.file_list = map(get_filename,self.component_section)
        elif self.component == "kubemanager":
            self.component_section = KUBEMANAGER_SECTION
            self.file_list = map(get_filename,self.component_section)

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

    def merge_update_sections(self):
        """ Merges the section and updates is with right values """
        component_config = self._get_config_from_files(self.file_list)
        if "kubemanager" in self.component_section:
            token = self._get_k8s_token()
            component_config.set("KUBERNETES", "token",value=token)

        if "agent" in self.component_section:
            if not component_config.has_option("AGENT", "ctrl_data_network"):
                pod_ip = self._get_pod_ip()
                component_config.set("AGENT", "ctrl_data_ip",value=pod_ip)

            token = self._get_k8s_token()
            if component_config.has_option("KUBERNETES", "api_server"):
                k8s_api_server = component_config.get("KUBERNETES",
                                                      "api_server")
            else:
                k8s_api_server = False

            # removing unwanted kubernetes section
            # and adding kubernetes section with only required option
            component_config.remove_section("KUBERNETES")
            component_config.add_section("KUBERNETES")

            component_config.set("KUBERNETES", "token",value=token)
            if k8s_api_server:
                component_config.set("KUBERNETES", "api_server",
                                     value=k8s_api_server)

        component_config.write(self.contrailctl_conf)
        self.contrailctl_conf.close()

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

    def _get_pod_ip(self):
        """ With simple test, gets the default ip address """
        s_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s_socket.connect((DUMMY_IP, DUMMY_PORT))
        return s_socket.getsockname()[0]
