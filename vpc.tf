resource "aws_vpc" "vpc-test" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }

}


# public subnet 1
resource "aws_subnet" "public_subnet_1" {
  depends_on = [
    aws_vpc.vpc-test,
  ]

  vpc_id     = aws_vpc.vpc-test.id
  cidr_block = "192.168.0.0/24"

  availability_zone_id = "euc1-az2"

  tags = {
    Name = "public-subnet_1"
  }

  map_public_ip_on_launch = true
}


# public subnet 2
resource "aws_subnet" "public_subnet_2" {
  depends_on = [
    aws_vpc.vpc-test,
  ]

  vpc_id     = aws_vpc.vpc-test.id
  cidr_block = "192.168.1.0/24"

  availability_zone_id = "euc1-az3"

  tags = {
    Name = "public-subnet_2"
  }

  map_public_ip_on_launch = true
}

# private subnet 1
resource "aws_subnet" "private_subnet_1" {
  depends_on = [
    aws_vpc.vpc-test,
  ]

  vpc_id     = aws_vpc.vpc-test.id
  cidr_block = "192.168.2.0/24"

  availability_zone_id = "euc1-az2"

  tags = {
    Name = "private-subnet_1"
  }
}

# private subnet 1
resource "aws_subnet" "private_subnet_2" {
  depends_on = [
    aws_vpc.vpc-test,
  ]

  vpc_id     = aws_vpc.vpc-test.id
  cidr_block = "192.168.3.0/24"


  availability_zone_id = "euc1-az3"

  tags = {
    Name = "private-subnet_2"
  }
}


# internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  depends_on = [
    aws_vpc.vpc-test,
  ]

  vpc_id = aws_vpc.vpc-test.id

  tags = {
    Name = "internet-gateway"
  }
}


# route table with target as internet gateway
resource "aws_route_table" "IG_route_table" {
  depends_on = [
    aws_vpc.vpc-test,
    aws_internet_gateway.internet_gateway,
  ]

  vpc_id = aws_vpc.vpc-test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "IG-route-table"
  }
}

# associate route table to public subnet 1
resource "aws_route_table_association" "associate_routetable_to_public_subnet_1" {
  depends_on = [
    aws_subnet.public_subnet_1,
    aws_route_table.IG_route_table,
  ]
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.IG_route_table.id
}


# associate route table to public subnet 2
resource "aws_route_table_association" "associate_routetable_to_public_subnet_2" {
  depends_on = [
    aws_subnet.public_subnet_2,
    aws_route_table.IG_route_table,
  ]
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.IG_route_table.id
}


# elastic ip
resource "aws_eip" "elastic_ip" {
  vpc = true
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [
    aws_subnet.public_subnet_1,
    aws_eip.elastic_ip,
  ]
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "nat-gateway"
  }
}

# route table with target as NAT gateway
resource "aws_route_table" "NAT_route_table" {
  depends_on = [
    aws_vpc.vpc-test,
    aws_nat_gateway.nat_gateway,
  ]

  vpc_id = aws_vpc.vpc-test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "NAT-route-table"
  }
}

# associate route table to private subnet_1
resource "aws_route_table_association" "associate_routetable_to_private_subnet_1" {
  depends_on = [
    aws_subnet.private_subnet_1,
    aws_route_table.NAT_route_table,
  ]
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.NAT_route_table.id
}

# associate route table to private subnet_2
resource "aws_route_table_association" "associate_routetable_to_private_subnet_2" {
  depends_on = [
    aws_subnet.private_subnet_2,
    aws_route_table.NAT_route_table,
  ]
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.NAT_route_table.id
}


# dynamic web security_group


resource "aws_security_group" "web-sg" {
  name   = "Dynamic Security Group"
  vpc_id = aws_vpc.vpc-test.id


  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    Name  = "Dynamic Security Group"
    Owner = "Gevorg Arabyan"
  }
}
