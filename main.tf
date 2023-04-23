data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.2023*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}


module "network" {
  source = "./modules/network"

  my_vpc_cidr         = var.my_vpc_cidr
  my_vpc_azs          = var.my_vpc_azs
  public_subnet_names = var.public_subnet_names
}

resource "aws_security_group" "public_instance_sg" {
  name   = "my_vpc_public_sg"
  vpc_id = module.network.vpc_id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all incoming public communication"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outgoing public communication"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_launch_template" "my_vpc_launch_template" {
  name = "my_vpc_launch_template"
  iam_instance_profile {
    arn = "arn:aws:iam::863801874088:instance-profile/s3ReadOnly"
  }
  image_id               = data.aws_ami.amazon_linux.id
  key_name               = "triggr-test"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.public_instance_sg.id]
  user_data              = "IyEvYmluL2Jhc2gKc3VkbyB5dW0gdXBkYXRlIC15CnN1ZG8geXVtIGluc3RhbGwgaHR0cGQgLXkKc3VkbyBzeXN0ZW1jdGwgc3RhcnQgaHR0cGQKc3VkbyBzeXN0ZW1jdGwgZW5hYmxlIGh0dHBkCmNkIC92YXIvd3d3L2h0bWwKc3VkbyBhd3MgczMgY3AgczM6Ly92cGMtZW5kcG9pbnQtYnVja2V0LTEyMmVlajMzaS9pbmRleC50eHQgLi8KRUMyQVo9JChUT0tFTj1gY3VybCAtWCBQVVQgImh0dHA6Ly8xNjkuMjU0LjE2OS4yNTQvbGF0ZXN0L2FwaS90b2tlbiIgLUggIlgtYXdzLWVjMi1tZXRhZGF0YS10b2tlbi10dGwtc2Vjb25kczogMjE2MDAiYCAmJiBjdXJsIC1IICJYLWF3cy1lYzItbWV0YWRhdGEtdG9rZW46ICRUT0tFTiIgLXYgaHR0cDovLzE2OS4yNTQuMTY5LjI1NC9sYXRlc3QvbWV0YS1kYXRhL3BsYWNlbWVudC9hdmFpbGFiaWxpdHktem9uZSkKc3VkbyB0b3VjaCBpbmRleC5odG1sCnN1ZG8gY2htb2QgNzc3IGluZGV4Lmh0bWwKc2VkICJzL0lOU1RBTkNFSUQvJEVDMkFaLyIgaW5kZXgudHh0ID4gaW5kZXguaHRtbA=="
}

module "my_vpc_asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name                   = "my_vpc_asg"
  min_size               = 4
  max_size               = 4
  desired_capacity       = 4
  create_launch_template = false
  launch_template        = aws_launch_template.my_vpc_launch_template.name
  update_default_version = true
  vpc_zone_identifier    = module.network.public_subnets

  depends_on = [
    module.network
  ]
}

data "aws_instances" "first_group_instances" {
  filter {
    name   = "availability-zone"
    values = ["us-west-2a", "us-west-2b"]
  }

  instance_state_names = ["running"]
  depends_on = [
    module.my_vpc_asg
  ]
}

data "aws_instances" "second_group_instances" {
  filter {
    name   = "availability-zone"
    values = ["us-west-2c"]
  }

  instance_state_names = ["running"]
  depends_on = [
    module.my_vpc_asg
  ]
}

resource "aws_lb_target_group" "first_target_group" {
  name     = "my-vpc-first-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id
}

resource "aws_lb_target_group" "second_target_group" {
  name     = "my-vpc-second-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id
}

resource "aws_lb_target_group_attachment" "first_group_attachment" {
  count = length(data.aws_instances.first_group_instances.ids)

  target_group_arn = aws_lb_target_group.first_target_group.arn
  target_id        = data.aws_instances.first_group_instances.ids[count.index]
  port             = 80
}

resource "aws_lb_target_group_attachment" "second_group_attachment" {
  count = length(data.aws_instances.second_group_instances.ids)

  target_group_arn = aws_lb_target_group.second_target_group.arn
  target_id        = data.aws_instances.second_group_instances.ids[count.index]
  port             = 80

  depends_on = [
    module.my_vpc_asg
  ]
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name               = "my-vpc-alb"
  load_balancer_type = "application"

  vpc_id = module.network.vpc_id

  subnets         = module.network.public_subnets
  security_groups = [aws_security_group.public_instance_sg.id]
}

resource "aws_lb_listener" "my_vpc_alb_listener" {
  load_balancer_arn = module.alb.lb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.first_target_group.arn
  }
}

resource "aws_lb_listener_rule" "second_group_listner_rule" {
  listener_arn = aws_lb_listener.my_vpc_alb_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.second_target_group.arn
  }

  condition {
    query_string {
      key   = "region"
      value = "another"
    }
  }
}
