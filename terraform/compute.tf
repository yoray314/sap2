resource "aws_key_pair" "deployer" {
  key_name   = "${var.project}-key"
  public_key = file(var.public_key_path)
}

# IAM role and instance profile to allow future retrieval of secrets/parameters (e.g., SSM)
resource "aws_iam_role" "web_role" {
  name = "${var.project}-web-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "web_ssm_policy" {
  name = "${var.project}-web-ssm-read"
  role = aws_iam_role.web_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory"
        ]
        Resource = [aws_ssm_parameter.db_password.arn]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "web_profile" {
  name = "${var.project}-web-instance-profile"
  role = aws_iam_role.web_role.name
}

# Web server autoscaling group (simplified: single instance via ASG of size 1)
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project}-web-"
  image_id      = data.aws_ami.amzn2.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.web_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/templates/web_user_data.sh.tpl", {
    db_address       = aws_db_instance.postgres.address
    db_name          = var.db_name
    db_user          = var.db_username
    web_app_revision = var.web_app_revision
  }))

  network_interfaces {
    security_groups = [aws_security_group.web.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project}-web" }
  }
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_autoscaling_group" "web" {
  name                      = "${var.project}-web-asg"
  max_size                  = 3
  min_size                  = 2
  desired_capacity          = 2
  health_check_type         = "ELB"
  health_check_grace_period = 60
  vpc_zone_identifier       = [for s in aws_subnet.public : s.id]
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  termination_policies = ["OldestInstance"]
  tag {
    key                 = "Name"
    value               = "${var.project}-web"
    propagate_at_launch = true
  }
}

resource "aws_lb" "app" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for s in aws_subnet.public : s.id]
}

resource "aws_lb_target_group" "web" {
  name                 = "${var.project}-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 30
  health_check {
    path                = "/health"
    matcher             = "200-399"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
}

resource "aws_autoscaling_attachment" "asg_tg" {
  autoscaling_group_name = aws_autoscaling_group.web.name
  lb_target_group_arn    = aws_lb_target_group.web.arn
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
