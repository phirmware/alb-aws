# ALB with terraform

This creates a VPC with subnets in 3 availability zones
The aim is to have at least one instance in each subnet at every
point in time, and have an application load balancer route traffic
to the instances based on some rules.

# Zone Mapping
The ALB should forward all requests to `us-west-2a` and `us-west-2b`
the only exception is when there is a query string with key value
`?region=another` then we forward the traffic to the instance in `us-west-2c`

# How to acheive
We are using a launch template and an autoscaling
group to make sure there is an instance in each availability zone at
all times, then we are going to create the target groups for the zones
and have the application load balancer forward traffic to the instances
based on the rules specified.

# How to test
The instance template has user data that fetches a script from s3
which creates a HTML file which tells the region of the instance that
served the request. To set this up, check the readme in `./s3-setup`

# How to run
- Clone the repo and navigate inside the directory
- ```terraform init```
- ```./setup.sh```

No remote state configured.