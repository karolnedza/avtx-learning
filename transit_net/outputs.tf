output "tvpc_id" {
  value = aviatrix_vpc.aws_transit.vpc_id
}

output "avtx_gw_name" {
  value = aviatrix_transit_gateway.transit_gateway_tvpc.gw_name
}
