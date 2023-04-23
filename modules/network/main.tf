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
