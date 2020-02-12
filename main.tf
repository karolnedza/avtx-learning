data "terraform_remote_state" "controller" {
  backend = "s3"
  config = {
      bucket = "${var.avtx_controller_bucket}"
      key    = "controller.tfstate"
      region = "us-east-1"
    }
}

# data "terraform_remote_state" "controller" {
#   backend = "local"
#
#   config = {
#     path = "controller/controller.tfstate"
#   }
# }

data "aws_caller_identity" "current" {
  provider = aws.east1

}


provider "aviatrix" {
  username      = "admin"
  password      = data.terraform_remote_state.controller.outputs.controller_admin_password
  controller_ip = data.terraform_remote_state.controller.outputs.controller_public_ip

  version = "~> 2.7"
}


 provider "aws" {
   access_key = var.awsaccesskey
   secret_key = var.awssecretkey
   region     = "us-east-1"
 }
provider "aws" {
  access_key = var.awsaccesskey
  secret_key = var.awssecretkey
  region     = "us-east-1"
  alias      = "east1"
}

provider "aws" {
  access_key = var.awsaccesskey
  secret_key = var.awssecretkey
  region     = "us-east-2"
  alias      = "east2"
}

provider "aws" {
  access_key = var.awsaccesskey
  secret_key = var.awssecretkey
  region     = "us-west-2"
  alias      = "west2"
}



module "aviatrix-create-vpcs-area1" {
  source    = "./create_vpcs"
  region    = var.region
  account_name = var.account_name
  public_key = "${tls_private_key.avtx_key.public_key_openssh}"
  private_key= "${tls_private_key.avtx_key.private_key_pem}"
  vpc_count = 3

  providers = {
    aws = aws.east1
  }
}


module "aviatrix-create-aws-tgw-area1" {
  source = "./aws_tgw"
  region = var.region
  account_name = var.account_name
#  tvpc_id = module.aviatrix-transit-net-area1.tvpc_id
#  sec_vpc_id = module.aviatrix-firenet-east1.sec_vpc_id
}

module "aviatrix-create-transit-net-area1" {
  source = "./transit_net"
  region = var.region
  account_name = var.account_name
  aws_transit_gw = module.aviatrix-create-aws-tgw-area1.tgw_id
  hpe = true

  providers = {
    aws = aws.east1
  }
}


module "aviatrix-create-vpcs-area2" {
  source    = "./create_vpcs"
  account_name = var.account_name
  region    = var.region2
  public_key = "${tls_private_key.avtx_key.public_key_openssh}"
  private_key= "${tls_private_key.avtx_key.private_key_pem}"
  vpc_count = 4

  providers = {
    aws = aws.east2
  }
}

module "aviatrix-create-vpcs-area3" {
  source    = "./create_vpcs"
  region    = "us-west-2"
  account_name = var.account_name
  public_key = "${tls_private_key.avtx_key.public_key_openssh}"
  private_key= "${tls_private_key.avtx_key.private_key_pem}"
  vpc_count = 2

  providers = {
    aws = aws.west2
  }
}


resource "aws_s3_bucket_object" "object" {
  provider = aws.east1
  acl = "public-read"
  bucket = "${var.avtx_controller_bucket}"
  key    = "avtx_priv_key.pem"
  source = "avtx_priv_key.pem"
}


resource "tls_private_key" "avtx_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "avtx_priv_key" {
  content  = "${tls_private_key.avtx_key.private_key_pem}"
  filename = "avtx_priv_key.pem"
  file_permission = "0400"
}



output "ec2_public_ip_us_east1" {
  value = module.aviatrix-create-vpcs-area1.ec2_instance_public_ip
}

output "ec2_public_ip_us_east2" {
  value = module.aviatrix-create-vpcs-area2.ec2_instance_public_ip
}

output "ec2_public_ip_us_west2" {
  value = module.aviatrix-create-vpcs-area3.ec2_instance_public_ip
}
