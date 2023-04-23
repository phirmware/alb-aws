#! /bin/sh

# we need to create the auto scaling group so
# it can create the instances we want to add to
# a target group for out ALB
terraform apply -target=module.my_vpc_asg -auto-approve

terraform apply -auto-approve

