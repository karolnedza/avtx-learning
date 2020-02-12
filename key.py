import os
import json


workdir_ctrl_main = str(os.getcwd())+"/controller/main.tf"



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
