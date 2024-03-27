module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs                     = slice(data.aws_availability_zones.azs.names, 0, length(var.public_subnets))
  public_subnets          = var.public_subnets
  map_public_ip_on_launch = true
}

resource "aws_security_group" "registry-scanner-sg" {
  name        = var.security_group_name
  description = "Allow Outbound communication to Prisma Cloud Console"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.egress_cidr
  }

  tags = {
    Name = var.security_group_name
  }
}

