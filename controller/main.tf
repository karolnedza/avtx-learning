terraform {
  backend "local" {
    path = "controller.tfstate"
  }
}

provider "aws" {
  region     = "us-east-1"
}

data "aws_caller_identity" "current" {}

module "aviatrix-iam-roles" {
  source = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-iam-roles?ref=terraform_0.12"
}

module "aviatrix-controller-build" {
  source  = "./controller-modules/aviatrix-controller-build"
  vpc     = "new"
  subnet  = "new"
  keypair = ""
  ec2role = module.aviatrix-iam-roles.aviatrix-role-ec2-name
  termination_protection = false
}

module "aviatrix-controller-initialize" {
  source              = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-initialize?ref=terraform_0.12"
  admin_password      = var.ctrl_password
  admin_email         = var.account_email
  private_ip          = module.aviatrix-controller-build.private_ip
  public_ip           = module.aviatrix-controller-build.public_ip
  access_account_name = var.account_name
  aws_account_id      = data.aws_caller_identity.current.account_id
  customer_license_id = "carmelodev-1393702544.64"
}

output "result" {
  value = module.aviatrix-controller-initialize.result
}

output "controller_private_ip" {
  value = module.aviatrix-controller-build.private_ip
}

output "controller_public_ip" {
  value = module.aviatrix-controller-build.public_ip
}

output "controller_admin_password" {
  value = var.ctrl_password
  sensitive = true
}
