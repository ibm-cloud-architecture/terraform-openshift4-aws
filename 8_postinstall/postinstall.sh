#!/bin/bash
# Assumptions
# aws, jq are installed
# checking aws
echo "Checking Classic load balancers for Kubernetes created elb"
clusterid=$1 # "ocp42ss-gse01"
clustername=$2 #"ocp42ss"
domain=$3 # "vbudi.cf"

if [ -z $domain ]; then
  echo "Arguments are clusterID clusterName Domain"
  exit 999
fi

found=0
created_lb=""
count=100

while [ $found -eq 0 ]; do
  lb_list=$(aws elb describe-load-balancers | jq '."LoadBalancerDescriptions" | .[]."LoadBalancerName"')

  if [ -z $lb_list ]; then
    echo "Empty - $count retries left"
    sleep 60
  else
    for lbname in $lb_list; do
      lbname=$(echo $lbname | tr -d '"')
      jqargs=".\"TagDescriptions\" | .[].Tags | .[] | select(.Key == \"kubernetes.io/cluster/${clusterid}\") | .Value"
      klval=$(aws elb describe-tags --load-balancer-names ${lbname} | jq "$jqargs" )
      if [ $klval = '"owned"' ]; then
        found=1
        created_lb=$lbname
      else
        echo "Empty - $count retries left"
        sleep 60
      fi
    done
  fi
  count=$((count-1))
  if [ $count -eq 0 ]; then
    echo "Giving up after 100 minutes"
    exit 999
  fi
done

lbzone=$(aws elb describe-load-balancers --load-balancer-names $created_lb | jq '."LoadBalancerDescriptions" | .[]."CanonicalHostedZoneNameID"' | tr -d '"')
lbhost=$(aws elb describe-load-balancers --load-balancer-names $created_lb | jq '."LoadBalancerDescriptions" | .[]."CanonicalHostedZoneName"' | tr -d '"')

echo $lbzone $lbhost

rte53args=".HostedZones | .[] |  select(.Name == \"${domain}.\") | .Id"
rte53zone=$(aws route53 list-hosted-zones | jq "$rte53args" | tr -d '"')
cat <<EOF >createRS.json
{
     "Comment": "Creating Alias resource record sets in Route 53",
     "Changes": [{
                "Action": "CREATE",
                "ResourceRecordSet": {
                            "Name": "*.apps.${clustername}.${domain}",
                            "Type": "A",
                            "AliasTarget":{
                                    "HostedZoneId": "$lbzone",
                                    "DNSName": "$lbhost",
                                    "EvaluateTargetHealth": false
                              }}
                          }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $rte53zone --change-batch file://createRS.json

exit 0
