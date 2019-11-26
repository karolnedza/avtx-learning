resource "aws_security_group" "AviatrixSecurityGroup" {
  count       = (var.vpc == "new" ? 1 : 0)
  name        = "${local.name_prefix}AviatrixSecurityGroup"
  description = "Aviatrix - Controller Security Group"
  vpc_id       = (var.vpc == "new" ? "${aws_vpc.avtx_ctrl_vpc[count.index].id}" : var.vpc)

  tags = {
    Name      = "${local.name_prefix}AviatrixSecurityGroup"
    Createdby = "Terraform+Aviatrix"
  }
}

resource "aws_security_group_rule" "ingress_rule" {
  count       = (var.vpc == "new" ? 1 : 0)
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.incoming_ssl_cidr
  security_group_id = "${aws_security_group.AviatrixSecurityGroup[count.index].id}"
}

resource "aws_security_group_rule" "egress_rule" {
  count       = (var.vpc == "new" ? 1 : 0)
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.AviatrixSecurityGroup[count.index].id}"
}
