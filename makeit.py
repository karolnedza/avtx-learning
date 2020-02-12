
#!/usr/bin/env python3

import os
from python_terraform import Terraform, IsFlagged
import logging
import hashlib
import errno, sys
import json


### Setting OS variables

workdir_ctrl = str(os.getcwd())+"/controller" # controller main.tf
workdir_ctrl_main = str(os.getcwd())+"/controller/main.tf"
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
    ctrl_main  = open(workdir_ctrl_main, "rt")
    data = ctrl_main.read()
    data = data.replace('aws_access_key', access_key )
    data = data.replace('aws_secret_key', secret_key)
    ctrl_main.close()

    ctrl_main = open(workdir_ctrl_main, "wt")
    ctrl_main.write(data)
    ctrl_main.close()


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

    #variables_main = open("variables.tf", "r")
    variables_remote = open(remotevariables, "r")
    #
    # if "avtx_controller_bucket" in variables_main.read():
    #     variables_main.close()
    #     pass
    # else:
    #     variables_main = open("variables.tf", "+a")
    #     variables_main.write('\n')
    #     variables_main.write('variable "avtx_controller_bucket" { \n')
    #     variables_main.write('    default = "' + hash + '"\n')
    #     variables_main.write('}\n')
    #     variables_main.write('variable "avtx_dynamodb_table" { \n')
    #     variables_main.write('    default = "' + hash + '"\n')
    #     variables_main.write('}\n')
    #     variables_main.close()

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



############## Need link to S3 bucket with EC2 ssh key  #####
adding_keys = add_keys()
s3_bucket = s3_bucket()
remote_state = remotestate()


################################################################################
# Build controller and return controller public IP and admin password
controller_outputs = build_controller()


ctrl_ip = controller_outputs['controller_public_ip']['value']
ctrl_passwd = controller_outputs['controller_admin_password']['value']
