packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_name" {
  type    = string
  default = "registry-scanner"
}

variable "hostname" {
  type    = string
  default = "registry-scanner"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "console_version" {
  type = string
}

variable "token" {
  type    = string
}

variable "pcc_url" {
  type    = string
}

variable "pcc_san" {
  type    = string
}

variable "subnet_id" {
  type    = string
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "amazon_linux_2023" {
  ami_name        = "${var.ami_name}-${var.console_version}-${local.timestamp}"
  ami_description = "AMI with Prisma Cloud Defender version ${var.console_version}"
  instance_type   = "t2.small"
  region          = "${var.region}"
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  subnet_id = "${var.subnet_id}"

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  ssh_username         = "ec2-user"

  tags = {
    use = "registryScanning"
  }
}

build {
  name = "registry-scanner"
  sources = [
    "source.amazon-ebs.amazon_linux_2023"
  ]
  
  provisioner "shell" {
    script = "defender-install.sh"
    environment_vars = [
      "NEW_HOSTNAME=${var.hostname}",
      "TOKEN=${var.token}",
      "PCC_URL=${var.pcc_url}",
      "PCC_SAN=${var.pcc_san}"
    ]
  }
}