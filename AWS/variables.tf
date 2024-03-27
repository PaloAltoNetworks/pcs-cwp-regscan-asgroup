variable "secret_id" {
  type        = string
  default     = "PrismaCloudCompute"
  description = "Name or ARN of the secret"
  sensitive   = true
}

variable "secret_region" {
  type        = string
  default     = "us-east-1"
  description = "Region where the Secret is stored"
  sensitive   = true
}

variable "ec2_role" {
  type        = string
  default     = "PrismaCloudComputeAccess"
  description = "Name of the Role to be attached to the EC2 instance"
  sensitive   = true
}

variable "ami_name" {
  type        = string
  default     = "registry-scanner"
  description = "Name of the AMI to be built"
}

variable "hostname" {
  type        = string
  default     = "registry-scanner"
  description = "Hostname of the EC2 instances to be used for Registry Scanning"
}

variable "launch_template_name" {
  type        = string
  description = "Name of the launch template to be created"
  default     = "registry-scanner-lt"
}

variable "asgroup_name" {
  type        = string
  description = "Name of the EC2 Auto Scaling Group to be created"
  default     = "registry-scanner-ag"
}

variable "asgroup_max_instances" {
  type        = number
  description = "Max ammount of instances to be used in the AS Group"
  default     = 10
}

variable "asgroup_instance_type" {
  type        = string
  description = "Instance Type to be used for AS Group"
  default     = "t3.small"
}

variable "vpc_name" {
  type        = string
  description = "Name of the launch template to be created"
  default     = "registry-scanner-vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "Name of the launch template to be created"
  default     = "10.120.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "Name of the launch template to be created"
  default     = ["10.120.0.0/24", "10.120.1.0/24", "10.120.2.0/24"]
}

variable "security_group_name" {
  type        = string
  description = "Name of the Security Group to be launched"
  default     = "registry-scanner-sg"
}

variable "egress_cidr" {
  type        = list(string)
  description = "Egress CIDR Blocks for Security Group"
  default     = ["0.0.0.0/0"]
}