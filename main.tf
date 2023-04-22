terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }
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


module "my_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  cidr                         = var.my_vpc_cidr
  create_igw                   = true
  create_redshift_subnet_group = false
  create_vpc                   = true

  map_public_ip_on_launch = true
  name                    = "my_vpc"

  azs                 = var.my_vpc_azs
  public_subnets      = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  public_subnet_names = var.public_subnet_names
}

resource "aws_security_group" "public_instance_sg" {
  name   = "my_vpc_public_sg"
  vpc_id = module.my_vpc.vpc_id

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
  vpc_zone_identifier    = module.my_vpc.public_subnets

  depends_on = [
    module.my_vpc
  ]
}
