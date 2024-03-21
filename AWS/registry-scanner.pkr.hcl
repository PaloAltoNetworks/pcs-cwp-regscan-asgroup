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

variable "new_hostname" {
  type = string
  default = registry-scanner 
}

variable "ec2_role" {
  type = string
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "amazon_linux_2023" {
  ami_name      = "${var.ami_name}-${local.timestamp}"
  instance_type = "t2.small"
  region        = "us-east-2"
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  ssh_username         = "ec2-user"
  iam_instance_profile = "${var.ec2_role}"
}

build {
  name = "registry-scanner"
  sources = [
    "source.amazon-ebs.amazon_linux_2023"
  ]

  provisioner "shell" {
    script           = "defender-install.sh"
    environment_vars = ["NEW_HOSTNAME=${var.new_hostname}"]
  }
}