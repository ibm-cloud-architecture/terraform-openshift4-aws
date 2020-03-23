## private ec2 endpoint
data "aws_vpc_endpoint_service" "ec2" {
  service = "ec2"
}

resource "aws_vpc_endpoint" "private_ec2" {
  count = var.airgapped.enabled ? 1 : 0

  vpc_id       =  aws_vpc.new_vpc[0].id
  service_name =  data.aws_vpc_endpoint_service.ec2.service_name
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [
     aws_security_group.private_ec2_api.id
  ]

  subnet_ids =  aws_subnet.private_subnet.*.id
  tags =  merge(
    var.tags,
    map(
      "Name",  "${var.cluster_id}-ec2-vpce"
    )
  )

}

data "aws_vpc_endpoint_service" "ecr" {
  service = "ecr.dkr"
}

resource "aws_vpc_endpoint" "private_ecr" {
  count = var.airgapped.enabled ? 1 : 0

  vpc_id       =  aws_vpc.new_vpc[0].id
  service_name =  data.aws_vpc_endpoint_service.ecr.service_name
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [
     aws_security_group.private_ecr_api.id
  ]

  subnet_ids =  aws_subnet.private_subnet.*.id
  tags =  merge(
    var.tags,
    map(
      "Name",  "${var.cluster_id}-ecr-vpce"
    )
  )

}
