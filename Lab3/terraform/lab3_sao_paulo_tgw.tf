# Explanation: Liberdade is São Paulo’s Japanese town—local doctors, local compute, remote data.
resource "aws_ec2_transit_gateway" "liberdade_tgw01" {
  provider    = aws.saopaulo
  description = "liberdade-tgw01 (Sao Paulo spoke)"
  tags = { Name = "liberdade-tgw01" }
}

# Explanation: Liberdade accepts the corridor from Shinjuku—permissions are explicit, not assumed.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_peer01" {
  provider                      = aws.saopaulo
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
  tags = { Name = "liberdade-accept-peer01" }
}

# Explanation: Liberdade attaches to its VPC—compute can now reach Tokyo legally, through the controlled corridor.
resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_attach_sp_vpc01" {
  provider           = aws.saopaulo
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw01.id
  vpc_id             = aws_vpc.liberdade_vpc01.id
  subnet_ids         = [aws_subnet.liberdade_private_subnet01.id, aws_subnet.liberdade_private_subnet02.id]
  tags = { Name = "liberdade-attach-sp-vpc01" }
}
