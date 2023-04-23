# Setup s3 bucket for testing

- Create an s3 bucket on aws and upload the `index.txt` file
- Update the `instance-user-data.md` file and replace `$BUCKET_NAME` with your bucket name
- Base64 encode the string, and use it as your user data in your launch template (check `aws_launch_template` resource in code)
- Create an IAM role for your EC2 instances and give it readonly access to s3
- Replace the `iam_instance_profile` arn with the arn of the role

Could as well just add a shell script to do all these using awscli
