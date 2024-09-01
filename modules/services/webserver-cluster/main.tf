locals {
  http_port = 80
  https_port = 443
  ssh_port = 22
  db_port = 3306
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket
    key    = var.vpc_remote_state_key
    region = "us-west-2"
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-west-2"
  }
}

resource "aws_security_group" "asg" {
  name = "${var.cluster_name}-asg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.asg.id

  from_port = var.server_port
  to_port   = var.server_port
  protocol  = local.tcp_protocol
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "allow_https_outbound" {
  type = "egress"
  security_group_id = aws_security_group.asg.id

  from_port   = local.https_port
  to_port     = local.https_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "db_allow_inbound_mysql" {
  type = "ingress"
  security_group_id = data.terraform_remote_state.db.outputs.sg_id

  from_port   = local.db_port
  to_port     = local.db_port
  protocol    = local.tcp_protocol
  source_security_group_id = aws_security_group.asg.id
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_launch_template" "north" {
  name_prefix   = "north-"
  image_id      = var.ami
  instance_type = var.instance_type
  update_default_version = true


  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.asg.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
    server_text = var.server_text
  }))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name = var.cluster_name

  launch_template {
    id      = aws_launch_template.north.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.app_subnet_ids

  target_group_arns = [aws_lb_target_group.alb.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key  = "Name"
    value = "north"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

resource "aws_lb" "alb" {
  name = "${var.cluster_name}-lb"
  load_balancer_type = "application"
  subnets = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = local.http_port
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "alb_allow_inbound_http" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "alb_allow_outbound_all" {
  type = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_lb_target_group" "alb" {
  name = "alb"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business-hours" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name = "${var.cluster_name}-scale-out-during-business-hours"
  min_size = 1
  max_size = 2
  desired_capacity = 1
  recurrence = "0 9 * * *"

  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name = "${var.cluster_name}-scale-in-at-night"
  min_size = 0
  max_size = 2
  desired_capacity = 0
  recurrence = "0 17 * * *"

  autoscaling_group_name = aws_autoscaling_group.asg.name
}