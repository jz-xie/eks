terraform {

}

locals {
  types   = ["public", "private"]
  subnets = { for i in var.subnets : i["subnet_type"] => i["cidr_block_subnet"] }
  common_tags = {
    project     = var.project
    environment = var.environment
  }
  subnet_tags = {
    public = {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = 1
    },
    private = merge(
      var.private_subnet_tags,
      {
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb"           = 1
      }
    )
  }
}

resource "aws_subnet" "subnets" {
  for_each          = local.subnets
  vpc_id            = var.vpc_id
  availability_zone = var.availability_zone
  cidr_block        = each.value

  tags = merge({
    Name = "${var.cluster_name}/subnet-${each.key}-${var.availability_zone}"
    type = each.key
    },
    local.subnet_tags[each.key],
    local.common_tags
  )
}

resource "aws_eip" "nat_eip" {
  vpc                  = true
  network_border_group = var.aws_region
  public_ipv4_pool     = "amazon"

  tags = merge(
    local.common_tags,
    { Name = "${var.cluster_name}/nat-ip-${var.availability_zone}" }
  )
}

resource "aws_nat_gateway" "nat" {
  connectivity_type = "public"
  subnet_id         = aws_subnet.subnets["public"].id
  allocation_id     = aws_eip.nat_eip.id

  tags = merge(
    local.common_tags,
    { Name = "${var.cluster_name}/nat-gateway-${var.availability_zone}" }
  )
}

resource "aws_route_table" "private_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(
    local.common_tags,
    { Name = "${var.cluster_name}/private-route-table" }
  )
}


resource "aws_route_table" "public_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = merge(
    local.common_tags,
    { Name = "${var.cluster_name}/public-route-table" }
  )
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.subnets["public"].id
  route_table_id = aws_route_table.public_table.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.subnets["private"].id
  route_table_id = aws_route_table.private_table.id
}
