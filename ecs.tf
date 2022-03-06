resource "aws_ecs_cluster" "my-cluster" {
  name = "my-cluster"

}

//ecs service
resource "aws_ecs_service" "my-service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my-cluster.id
  task_definition = aws_ecs_task_definition.my-task.arn
  desired_count   = 2
  iam_role        = aws_iam_role.ecs-instance-role.arn
  depends_on      = [aws_iam_role_policy.test_policy]



  load_balancer {
    target_group_arn = aws_lb_target_group.alb-target.arn
    container_name   = "hello-world"
    container_port   = 8080
  }
}

//ecs task definition
resource "aws_ecs_task_definition" "my-task" {
  family                = "service"
  container_definitions = file("container-definitions/container-def.json")

}

//iam role ecs
resource "aws_iam_role" "ecs-instance-role" {
  name = "ecs-instance-role-test-web"


  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = aws_iam_role.ecs-instance-role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ecs_service_role" {
  role = aws_iam_role.ecs-instance-role.name
}
