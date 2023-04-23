# CODE UPDATED SO IT WORKS WITH AMAZON LINUX 2 AMI AND AMAZON LINUX 2023
*** COPY CODE FROM LINES 4-12 ***

#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
cd /var/www/html
sudo aws s3 cp s3://${BUCKET_NAME}/index.txt ./
EC2AZ=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/placement/availability-zone)
sudo touch index.html
sudo chmod 777 index.html
sed "s/INSTANCEID/$EC2AZ/" index.txt > index.html