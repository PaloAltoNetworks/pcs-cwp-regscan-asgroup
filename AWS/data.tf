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

  depends_on = [null_resource.create_ami]
}