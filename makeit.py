
#!/usr/bin/env python3

import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
import os
from python_terraform import Terraform, IsFlagged
import logging
from urllib3.exceptions import InsecureRequestWarning
import hashlib
import errno, sys



### To silence all HTTP/HTTPs logs on screen. For UI this can be removed
logging.getLogger('urllib3.connectionpool').setLevel(logging.CRITICAL)
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
requests_log = logging.getLogger("requests")
requests_log.setLevel(logging.ERROR)
requests_log.propagate = True

### Setting OS variables

workdir_ctrl = str(os.getcwd())+"/controller" # controller main.tf
workdir_ctrl_main = str(os.getcwd())+"/controller/main.tf"
workdir_net = str(os.getcwd()) # network main.tf
tfvars = str(os.getcwd())+"/terraform.tfvars.json"


remotestate_dic = str(os.getcwd())+"/remotestate"
remotevariables = str(os.getcwd())+"/remotestate/variables.tf"







############ Preparing remote-state credentials


def add_keys():

    def load_keys():
        with open("terraform.tfvars.json") as file:
            return json.load(file)

    keys = load_keys()
    aws_access_key=keys['awsaccesskey']
    aws_secret_access=keys['awssecretkey']

    access_key = '\"' + str(aws_access_key) + '\"'
    secret_key = '\"' + str(aws_secret_access) + '\"'
    print(access_key)
    print(secret_key)
    ctrl_main  = open(workdir_ctrl_main, "rt")
    data = ctrl_main.read()
    data = data.replace('aws_access_key', access_key )
    data = data.replace('aws_secret_key', secret_key)
    ctrl_main.close()

    ctrl_main = open(workdir_ctrl_main, "wt")
    ctrl_main.write(data)
    ctrl_main.close()


add_keys()


########Function to create a unique name for S3 bucket ######



def remotestate():
    tf_state = Terraform(remotestate_dic)
    tf_state.init()
    #tf_state.plan(capture_output=False, var_file=tfvars)
    tf_state.apply(skip_plan=True, capture_output=False, var_file=tfvars)
    state_output = tf_state.output(capture_output=True)


def s3_bucket():
    with open("terraform.tfvars.json","rb") as vars:
        bytes = vars.read() # read file as bytes
        hash = hashlib.md5(bytes).hexdigest();
        vars.close()

    variables_main = open("variables.tf", "r")
    variables_remote = open(remotevariables, "r")

    if "avtx_controller_bucket" in variables_main.read():
        variables_main.close()
        pass
    else:
        variables_main = open("variables.tf", "+a")
        variables_main.write('\n')
        variables_main.write('variable "avtx_controller_bucket" { \n')
        variables_main.write('    default = "' + hash + '"\n')
        variables_main.write('}\n')
        variables_main.write('variable "avtx_dynamodb_table" { \n')
        variables_main.write('    default = "' + hash + '"\n')
        variables_main.write('}\n')
        variables_main.close()

    if "avtx_controller_bucket" in variables_remote.read():
        variables_remote.close()
        pass
    else:
        variables_remote = open(remotevariables, "+a")
        variables_remote.write('\n')
        variables_remote.write('variable "avtx_controller_bucket" { \n')
        variables_remote.write('    default = "' + hash + '"\n')
        variables_remote.write('}\n')
        variables_remote.write('variable "avtx_dynamodb_table" { \n')
        variables_remote.write('    default = "' + hash + '"\n')
        variables_remote.write('}\n')
        variables_remote.close()

    return hash

#### Function to build controller


def build_controller():
    bucket_backend = 'bucket='+str(s3_bucket)
    table_backend = 'dynamodb_table='+str(s3_bucket)

    backend_configs = [bucket_backend, table_backend]

    tf_base = Terraform(workdir_ctrl)
    #tf_base.init()
    tf_base.init(backend_config=backend_configs)
    #tf_base.plan(capture_output=False, var_file=tfvars)
    return_code = tf_base.apply(skip_plan=True, capture_output=False, var_file=tfvars)
    controller_outputs = tf_base.output(capture_output=True)
    if return_code[0] == 1:
         print("Something went wrong!")
         sys.exit(1)
    else:
        print("All good!")
        pass
    return controller_outputs

#### Function to build network
def build_net():
    tf_net = Terraform(workdir_net)
    tf_net.init()
#    tf_net.plan(capture_output=False)
    return_code = tf_net.apply(skip_plan=True, capture_output=False)
    net_outputs = tf_net.output(capture_output=True)
    if return_code[0] == 1:
        print("Something went wrong!")
        sys.exit(1)
    else:
        print("All good!")
        pass
    return net_outputs


#### Function to wait until controller is up and running
## This must be enhanced and log in on controller using admin/pass!

def requests_retry_session(
    retries=6,
    backoff_factor=1,
    status_forcelist=(500, 502, 504, 404),
    session=None,
):
    session = session or requests.Session()
    retry = Retry(
        total=retries,
        read=retries,
        connect=retries,
        backoff_factor=backoff_factor,
        status_forcelist=status_forcelist,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session


############## Need link to S3 bucket with EC2 ssh key  #####

s3_bucket = s3_bucket()
remote_state = remotestate()

link_to_s3 = 'https://' + s3_bucket + ".s3.amazonaws.com/avtx_priv_key.pem"

################################################################################
# Build controller and return controller public IP and admin password
controller_outputs = build_controller()


ctrl_ip = controller_outputs['controller_public_ip']['value']
ctrl_passwd = controller_outputs['controller_admin_password']['value']

# ################################################################################
# # Wait until controller is up and running. I need to improve it! It should use user/pass!
# #
# # sleep = {backoff factor} * (2 ^ ({number of total retries} - 1)
# # back_off= 1sec returns  sleep() for [0, 2, 4, 8, 16, 32, 64, 128...] sec
#
# try:
#     response = requests_retry_session().get('https://'+str(ctrl_ip), verify=False)
# except Exception as x:
#     print('Unable to connect to AVTX Controller', x.__class__.__name__)
#     exit()
# else:
#     print("Connected to Aviatrix Controller")
#
#
# ###############################################################################
# # Build Network
#
#
# net_outputs = build_net()
#
#
# ###############################################################################
# # I need to check with Jacob and others what output should be returned
# #
#
# file = open("lab.txt", "w+")
# file.write("********************         EC2 Test Instances        *************************************"  + '\n''\n''\n')
# file.write("Region US-East-1 EC2 public IPs:   "  +   str(net_outputs['ec2_public_ip_us_east1']['value']) + '\n' )
# file.write("Region US-East-2 EC2 public IPs:   "  +   str(net_outputs['ec2_public_ip_us_east2']['value']) + '\n' )
# file.write("Region US-West-2 EC2 public IPs:   "  +   str(net_outputs['ec2_public_ip_us_west2']['value']) + '\n' '\n' '\n' )
# file.write("********************         Aviatrix Controller       *************************************"  + '\n''\n''\n')
# file.write("Aviatrix Controller public IP:   "  +   str(controller_outputs['controller_public_ip']['value']) + '\n' '\n' '\n' )
# file.write("*******************************************************************************************"  + '\n''\n' '\n')
# file.write("EC2 public key: " + link_to_s3 + '\n' '\n' '\n')
# file.write("*******************************************************************************************"  + '\n''\n' '\n')
# file.close()
