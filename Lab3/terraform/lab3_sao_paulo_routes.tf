# Explanation: Liberdade knows the way to Shinjuku—Tokyo CIDR routes go through the TGW corridor.
resource "aws_route" "liberdade_to_tokyo_route01" {
  provider               = aws.saopaulo
  route_table_id         = aws_route_table.liberdade_private_rt01.id
  destination_cidr_block = "10.x.x.x/xx" # Tokyo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id
}
