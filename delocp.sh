#!/bin/bash

terraform destroy -auto-approve &

sleep 10 

workers=$(aws ec2 describe-instances --filters Name="tag:kubernetes.io/cluster/ocp46-mcm",Values="owned"  --query 'Reservations[].Instances[].[InstanceId, Tags[?Key==`Name`] | [0].Value]' --output text | grep worker | cut -d$'\t' -f1)

aws ec2 terminate-instances --instance-ids ${workers} 

vpcid=$(grep vpc terraform.tfstate | grep vpc_id | grep vpc- | head -1 | cut -d"\"" -f4)
elbname=$(aws elb describe-load-balancers --query  'LoadBalancerDescriptions[].[LoadBalancerName,VPCId]' --output text | cut -d$'\t' -f1)
aws elb delete-load-balancer --load-balancer-name ${elbname}

sleep 180

sg=$(aws ec2 describe-security-groups --filters Name="tag:kubernetes.io/cluster/ocp46-mcm",Values="owned" --query 'SecurityGroups[].[GroupId,GroupName]' --output text | grep "k8s-elb" | cut -d$'\t' -f1)

aws ec2 delete-security-group --group-id ${sg}
