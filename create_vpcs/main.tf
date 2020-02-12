resource "random_integer" "subnet" {
  min     = 1
  max     = 250
}

resource "aviatrix_vpc" "aws_vpc" {
  count                = var.vpc_count
  cloud_type           = 1
  account_name         = var.account_name
  region               = var.region
  name                 = "${var.region}-lab-vpc-${count.index + 1}"
  cidr                 = cidrsubnet("10.0.0.0/8", 8, random_integer.subnet.result + count.index)
  aviatrix_transit_vpc = true
  aviatrix_firenet_vpc = false
}

resource "aws_instance" "test_instance" {
  count         = 2
  key_name      = aws_key_pair.comp_generated_key.key_name
  ami           = "${data.aws_ami.ubuntu_server.id}"
  instance_type = "t2.micro"
  subnet_id               = "${aviatrix_vpc.aws_vpc[count.index].subnets[4].subnet_id}"
  vpc_security_group_ids  = ["${aws_security_group.allow_ssh_icmp_spoke[count.index].id}"]
  associate_public_ip_address = true

  connection {
    type     = "ssh"
    user     = "ubuntu"
    host     = "${self.public_ip}"
    private_key = var.private_key
#    private_key = file("avtx_priv_key.pem")
  }

  tags = {
    Name = "test_instance_${aviatrix_vpc.aws_vpc[count.index].vpc_id}"
  }
}

data "aws_ami" "ubuntu_server" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["*ubuntu-xenial-16.04-amd64-server-20181114*"]
  }
  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "allow_ssh_icmp_spoke" {
  count       = var.vpc_count
  name        = "allow_ssh_icmp"
  description = "Allow SSH & ICMP inbound traffic"
  vpc_id      = "${aviatrix_vpc.aws_vpc[count.index].vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "comp_generated_key" {
  key_name   = "${var.key_name}_${var.region}"
  public_key = var.public_key
}
