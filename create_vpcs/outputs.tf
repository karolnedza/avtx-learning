output "vpc_ids" {
  value = "${aviatrix_vpc.aws_vpc.*.vpc_id}"
}


output "ec2_instance_public_ip" {
  value = "${aws_instance.test_instance.*.public_ip}"
}
