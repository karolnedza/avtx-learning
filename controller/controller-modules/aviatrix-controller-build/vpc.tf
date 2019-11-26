resource "aws_vpc" "avtx_ctrl_vpc" {
  count = (var.vpc == "new" ? 1 : 0)
  cidr_block       = "172.64.0.0/20"
#  instance_tenancy = "dedicated"

  tags = {
    Name = "CTRL_VPC"
  }
}
 
resource "aws_internet_gateway" "gw" {
  count = (var.vpc == "new" ? 1 : 0)
  vpc_id = "${aws_vpc.avtx_ctrl_vpc[count.index].id}"
}

resource "aws_subnet" "avtx_ctrl_subnet" {
  count = (var.subnet == "new" ? 1 : 0)
  vpc_id     = "${aws_vpc.avtx_ctrl_vpc[count.index].id}"
  cidr_block = "172.64.0.0/28"

  tags = {
    Name = "CTRL_SUBNET"
  }
}
 
resource "aws_default_route_table" "default" {
  count = (var.vpc == "new" ? 1 : 0)
  default_route_table_id = "${aws_vpc.avtx_ctrl_vpc[count.index].default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw[count.index].id}"
  }
}

resource "aws_key_pair" "avtx_ctrl_key" {
  count = (var.keypair == "" ? 1 : 0)
  key_name   = "avtx-ctrl-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/2BtoNIerbk/4tWJHa7z28xhc8Ls/HAKuaatrUaBZbun0G6AvqYkOMD4uqqp8ZOjtqjtjU+UOZHGcODmZIyJP1EXYA8Ii5Y/J7xNorHU7tZjAu1+FWJ3lxxXI5onpd56XzfU2UldvQkqlSf7zRD2PiGx9bmedPC/ky8kFriZ4u1WtL/bFqPP7VqHFdME342wUoFW+ItjhTsl+P3kwhdOUIxVTo5C+NuPs+vvxCvKTHDWHHrg7uvizAcqhusfERR/jbdnnP3YFRCR2symCWsjl7oUom8sFX/9GVYGocLFF5EIkbIDjWgjkkLdkQ5CXJpM4+OGHh1EjgcyYFzRsdYE1 abhishek@Abhisheks-MacBook-Pro.local"
}
