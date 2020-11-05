#!/bin/bash

clusterId=$1

if [ -z $clusterId ]; then
  exit 99
fi

terraform destroy -auto-approve &

sleep 10 
workers=$(aws ec2 describe-instances --filters Name="tag:kubernetes.io/cluster/${clusterId}",Values="owned"  --query 'Reservations[].Instances[].[InstanceId, Tags[?Key==`Name`] | [0].Value]' --output text | grep worker | cut -d$'\t' -f1)

aws ec2 terminate-instances --instance-ids ${workers} 

vpcid=$(grep vpc terraform.tfstate | grep vpc_id | grep vpc- | head -1 | cut -d"\"" -f4)
elbname=$(aws elb describe-load-balancers --query  'LoadBalancerDescriptions[].[LoadBalancerName,VPCId]' --output text | cut -d$'\t' -f1)
aws elb delete-load-balancer --load-balancer-name ${elbname}

sleep 300

sg=$(aws ec2 describe-security-groups --filters Name="tag:kubernetes.io/cluster/${clusterId}",Values="owned" --query 'SecurityGroups[].[GroupId,GroupName]' --output text | grep "k8s-elb" | cut -d$'\t' -f1)

aws ec2 delete-security-group --group-id ${sg}

sleep 60

aws s3 ls | grep ${clusterId} | awk '{print "aws s3 rb —force s3://"$3}' | bash

aws iam list-users --query 'Users[].[UserName,UserId]' --output text | grep ${clusterId} 

aws iam list-users --query 'Users[].[UserName,UserId]' --output text | grep ${clusterId} | awk '{print "aws iam delete-user-policy --user-name "$1" --policy-name "$1"-policy"}' | bash

aws iam list-users --query 'Users[].[UserName,UserId]' --output text | grep ${clusterId} | awk '{print "aws iam delete-access-key --user-name "$1" --access-key-id $(aws iam list-access-keys --user-name "$1" --query 'AccessKeyMetadata[].AccessKeyId' --output text)"}' | bash

aws iam list-users --query 'Users[].[UserName,UserId]' --output text | grep ${clusterId} | awk '{print "aws iam delete-user --user-name "$1}' | bash

exit 0
