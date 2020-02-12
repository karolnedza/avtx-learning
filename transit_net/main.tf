resource "random_integer" "tvpc_subnet" {
  min     = 1
  max     = 250
}

resource "aviatrix_vpc" "aws_transit" {
  cloud_type           = 1
  account_name         = var.account_name
  region               = var.region
  name                 = "transit-vpc-${var.region}"
  cidr                 = cidrsubnet("10.0.0.0/8", 8, random_integer.tvpc_subnet.result)
  aviatrix_transit_vpc = true
  aviatrix_firenet_vpc = false
}

resource "aviatrix_transit_gateway" "transit_gateway_tvpc" {
  cloud_type               = 1
  vpc_reg                  = var.region
  vpc_id                   = aviatrix_vpc.aws_transit.vpc_id
  account_name             = aviatrix_vpc.aws_transit.account_name
  gw_name                  = "tvpc-gw-${var.region}"
  insane_mode              = var.hpe
  ha_gw_size               = var.hpe ? "c5.xlarge" : var.avtx_gw_size
  gw_size                  = var.hpe ? "c5.xlarge" : var.avtx_gw_size
  subnet                   = var.hpe ? cidrsubnet(aviatrix_vpc.aws_transit.cidr,10,4) : aviatrix_vpc.aws_transit.subnets[5].cidr
  ha_subnet                = var.hpe ? cidrsubnet(aviatrix_vpc.aws_transit.cidr,10,8) : aviatrix_vpc.aws_transit.subnets[7].cidr
  insane_mode_az           = var.hpe ? data.aws_subnet.gw_az.availability_zone : null
  ha_insane_mode_az        = var.hpe ? data.aws_subnet.hagw_az.availability_zone : null
  enable_active_mesh       = true
  enable_hybrid_connection = true
  connected_transit        = false
  enable_advertise_transit_cidr = false
#  bgp_manual_spoke_advertise_cidrs = ""
}
/*
resource "aviatrix_aws_tgw_vpc_attachment" "transit_vpc_attachment" {
  tgw_name             = var.aws_transit_gw
  region               = var.region
  security_domain_name = "Aviatrix_Edge_Domain"
  vpc_account_name     = var.account_name
  vpc_id               = aviatrix_vpc.aws_transit.vpc_id
}
*/
data "aws_subnet" "gw_az" {
  id = aviatrix_vpc.aws_transit.subnets[5].subnet_id
}

data "aws_subnet" "hagw_az" {
  id = aviatrix_vpc.aws_transit.subnets[7].subnet_id
}
