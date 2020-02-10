#!/bin.bash
# Invoked woth the implementation ID
# Collect AWS ids and insert into terraform
clusterid=$1 # "ocp42ss-gse01"
clustername=$2 #"ocp42ss"
domain=$3 # "vbudi.cf"

if [ -z $domain ]; then
  echo "Arguments are clusterID clusterName Domain airgapped"
  exit 999
fi

MY_PATH=$(dirname "$0")              # relative
cp $MY_PATH/worker_config.tftemplate $MY_PATH/worker_config.tf

instList=$(aws ec2 describe-instances --filters "Name=instance.group-name,Values=${clusterid}-worker"  --query "Reservations[*].Instances[*].{Instance:InstanceId}" | grep Instance | cut -d\" -f4)
i=0
echo $instList
for instName in $instList
do
  terraform import "module.postinstall.aws_instance.workermachines[$i]" $instName
  i=$((i+1))
done

lb_list=$(aws elb describe-load-balancers | jq '."LoadBalancerDescriptions" | .[]."LoadBalancerName"')
for lbname in $lb_list; do
    lbname=$(echo $lbname | tr -d '"')
    jqargs=".\"TagDescriptions\" | .[].Tags | .[] | select(.Key == \"kubernetes.io/cluster/${clusterid}\") | .Value"
    klval=$(aws elb describe-tags --load-balancer-names ${lbname} | jq "$jqargs" )
    if [ $klval = '"owned"' ]; then
      found=1
      created_lb=$lbname
    fi
done
terraform import module.postinstall.aws_elb.ocp_compute_elb ${created_lb}

sg_elb=$(aws ec2 describe-security-groups --query "SecurityGroups[*].GroupName" | grep "k8s-elb" | cut -d\" -f2)
sg_name=$(aws ec2 describe-security-groups --query "SecurityGroups[*].GroupId" --filter "Name=group-name,Values=$sg_elb" | grep sg | cut -d\" -f2)
terraform import module.postinstall.aws_security_group.compute_elb ${sg_name}

if [ $airgapped -ne "true" ]; then
  rte53pubargs=".HostedZones | .[] |  select(.Name == \"${domain}.\") | .Id"
  rte53pubzone=$(aws route53 list-hosted-zones | jq "$rte53pubargs" | tr -d '"')
  terraform import module.postinstall.aws_route53_record.compute_apps_public[0] ${rte53pubzone}_*.apps.${clustername}.${domain}_A
fi

rte53priargs=".HostedZones | .[] |  select(.Name == \"${clustername}.${domain}.\") | .Id"
rte53prizone=$(aws route53 list-hosted-zones | jq "$rte53priargs" | tr -d '"')
terraform import module.postinstall.aws_route53_record.compute_apps ${rte53prizone}_*.apps.${clustername}.${domain}_A


# must decouple Security group  $sg_name from $clusterid-master and $clusterid-worker

aws ec2 revoke-security-group-ingress --group-name $clusterid-master --source_group $sg_name
aws ec2 revoke-security-group-ingress --group-name $clusterid-worker --source_group $sg_name
