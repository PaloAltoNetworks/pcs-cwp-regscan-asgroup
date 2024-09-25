data "aws_region" "current" {}

data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_ami" "registry-scanner-ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${var.ami_name}*"]
  }

  depends_on = [terraform_data.create_ami]
}