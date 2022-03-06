data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon", "self"]
}


resource "aws_autoscaling_group" "web" {
  name                 = "ASG-${aws_launch_configuration.web.name}"
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  #vpc_id               = aws_vpc.vpc-test.id
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  health_check_type   = "EC2"
  target_group_arns   = [aws_lb_target_group.alb-target.arn]
  #availability_zones  = data.aws_availability_zones.available.names

  dynamic "tag" {
    for_each = {
      Name   = "WebServer in ASG"
      Owner  = "Gevorg Arabyan"
      TAGKEY = "TAGVALUE"
    }
    content {

      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  #protect_from_scale_in = true
  lifecycle {
    create_before_destroy = true
  }

}

//autosaling group attach to ALB
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.web.id
  alb_target_group_arn   = aws_lb_target_group.alb-target.arn
}

# aws launch configuration
resource "aws_launch_configuration" "web" {
  name_prefix     = "WebServer-Highly-Available-"
  image_id        = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web-sg.id]

  iam_instance_profile        = aws_iam_instance_profile.ecs_service_role.name
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = <<EOF
#! /bin/bash
sudo apt-get update
sudo echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
EOF

  lifecycle {
    create_before_destroy = true
  }
}


data "aws_availability_zones" "available" {
  state = "available"
}
