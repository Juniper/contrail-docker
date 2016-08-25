from contrail_provisioning.database.setup import *
from os import environ

IPADDRESS = environ.get('IPADDRESS', '127.0.0.1')
CFGM_IP = environ.get("CFGM_IP", IPADDRESS)
CASSANDRA_DIRECTORY = environ.get("CASSANDRA_DIRECTORY")
INITIAL_TOKEN = environ.get("INITIAL_TOKEN", 0)
SEED_LIST = environ.get("SEED_LIST")
DATA_DIR = environ.get("DATA_DIR")
ANALYTICS_DATA_DIR = environ.get("ANALYTICS_DATA_DIR")
SSD_DATA_DIR = environ.get("SSD_DATA_DIR")
ZOOKEEPER_IP_LIST = environ.get("ZOOKEEPER_IP_LIST")
#  The index of this databse node
DATABASE_INDEX = environ.get("DATABASE_INDEX")
# Required minimum disk space for contrail database
MINIMUM_DISKGB = environ.get("MINIMUM_DISKGB")
#The broker id of the database node
KAFKA_BROKER_ID = environ.get("KAFKA_BROKER_ID")
# The DB node to remove from the cluster
NODE_TO_DELETE = environ.get("NODE_TO_DELETE")
CASSANDRA_USER = environ.get("CASSANDRA_USER")
CASSANDRA_PASSWORD = environ.get("CASSANDRA_PASSWORD")

args = "--self_ip %s --initial_token %s " % (IPADDRESS, INITIAL_TOKEN)


def update_args(args, param, value):
    if value:
        args += " %s %s " % (param, value)
    return args

args = update_args(args, "--dir", CASSANDRA_DIRECTORY)
args = update_args(args, "--cfgm_ip", CFGM_IP)
args = update_args(args, "--seed_list", SEED_LIST)
args = update_args(args, "--data_dir", DATA_DIR)
args = update_args(args, "--analytics_data_dir", ANALYTICS_DATA_DIR)
args = update_args(args, "--ssd_data_dir", SSD_DATA_DIR)
args = update_args(args, "--zookeeper_ip_list", ZOOKEEPER_IP_LIST)
args = update_args(args, "--database_index", DATABASE_INDEX)
args = update_args(args, "--minimum_diskGB", MINIMUM_DISKGB)
args = update_args(args, "--kafka_broker_id", KAFKA_BROKER_ID)
args = update_args(args, "--node_to_delete", NODE_TO_DELETE)
args = update_args(args, "--cassandra_user", CASSANDRA_USER)
args = update_args(args, "--cassandra_password", CASSANDRA_PASSWORD)

database = DatabaseSetup(args)
database.fixup_config_files()
