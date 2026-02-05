# Explanation: Shinjuku returns traffic to Liberdade—because doctors need answers, not one-way tunnels.
resource "aws_route" "shinjuku_to_sp_route01" {
  route_table_id         = aws_route_table.chewbacca_private_rt01.id
  destination_cidr_block = "10.x.x.x/xx" # Sao Paulo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgw01.id
}
