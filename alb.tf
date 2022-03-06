// ALB
resource "aws_lb" "alb-web" {
  name               = "alb-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  tags = {
    Environment = "production"
  }
}

//Add listener
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.alb-web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target.arn
  }
}

//Create target group
resource "aws_lb_target_group" "alb-target" {
  name        = "alb-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc-test.id
  health_check {
    port                = 80
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 60
    interval            = 70
    matcher             = "200,301,302"
  }
}


# ALB security group
resource "aws_security_group" "lb-sg" {
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.vpc-test.id

  ingress {
    description = "allow TCP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
