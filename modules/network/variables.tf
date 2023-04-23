variable "my_vpc_cidr" {
  description = "cidr block for vpc"
  default = ""
}

variable "my_vpc_azs" {
  description = "availability zones for vpc"
  default = []
}

variable "public_subnet_names" {
  description = "names of public subnets"
  default = []
}
