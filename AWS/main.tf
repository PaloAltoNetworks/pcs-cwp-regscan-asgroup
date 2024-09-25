resource "terraform_data" "create_ami" {
  triggers_replace = [
    "${timestamp()}"
  ]

  provisioner "local-exec" {
    #Create Secret if not exists
    command = "bash generate-ami.sh -s ${var.secret_id} -R ${var.secret_region} -r ${data.aws_region.current.id} -a ${var.ami_name} -h ${var.hostname} -S ${module.vpc.public_subnets[0]}"
  }

  depends_on = [ module.vpc ]
}

resource "aws_launch_template" "registry-scanner-lt" {
  name                   = var.launch_template_name
  image_id               = data.aws_ami.registry-scanner-ami.id
  vpc_security_group_ids = [aws_security_group.registry-scanner-sg.id]
  update_default_version = true

  monitoring {
    enabled = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = var.launch_template_name
    use  = "registryScanning"
  }

}

resource "aws_autoscaling_group" "registry-scanner-ag" {
  name                      = var.asgroup_name
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = var.asgroup_max_instances
  vpc_zone_identifier       = module.vpc.public_subnets
  default_cooldown          = 120
  health_check_grace_period = 120

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.registry-scanner-lt.id
      }

      override {
        instance_type     = var.asgroup_instance_type
        weighted_capacity = "1"
      }
    }
  }

  tag {
    key                 = "use"
    value               = "registryScanning"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "registry-scanner-aspolicy" {
  name                      = "registry-scanner-aspolicy"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 60
  autoscaling_group_name    = var.asgroup_name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 40.0
  }

  depends_on = [aws_autoscaling_group.registry-scanner-ag]
}