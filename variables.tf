variable "my_vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_names" {
  default = ["my_vpc_subnet_a", "my_vpc_subnet_b", "my_vpc_subnet_c"]
}

variable "my_vpc_azs" {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
