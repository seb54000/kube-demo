#!/bin/bash

aws --region eu-west-1 cloud9 create-environment-ec2 --name eksworkshop --instance-type t2.micro --owner-arn arn:aws:iam::$(aws iam list-users | jq -r .[][0].Arn | awk -F ":" {'print $5'}):root

sleep 20
INSTANCE_CLOUD9=$(aws --region eu-west-1 ec2 describe-instances --filters 'Name=tag:Name,Values=*eksworkshop*' --output text --query 'Reservations[*].Instances[*].InstanceId')

cat <<EOF > policy.json
{
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ],
  "Version": "2012-10-17"
}
EOF

aws iam create-role --role-name eksworkshop --assume-role-policy-document file://policy.json
aws iam attach-role-policy --role-name eksworkshop --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-instance-profile --instance-profile-name eksworkshop
aws iam add-role-to-instance-profile --instance-profile-name eksworkshop --role-name eksworkshop
aws --region eu-west-1 ec2 associate-iam-instance-profile --instance-id $INSTANCE_CLOUD9 --iam-instance-profile Name="eksworkshop"
rm policy.json

