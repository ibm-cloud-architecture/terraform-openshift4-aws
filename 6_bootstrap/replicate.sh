#!/bin/bash

repoName=$1
pullSecretFile=$2
# arguments:
# - repoName
# - Pull secret file

# requirements
# jq
# aws CLI
# AWS env variable

pullDir=$(dirname $pullSecretFile)
email=$(cat $pullSecretFile | jq -r -M '."auths"."quay.io"'."email")
#loginString=$(cat /tmp/dkrout.txt)
loginString=$(aws ecr get-login)
# regex magic loginString " -p " passworf " -e none https://" $repoHost
password=$(echo $loginString |  awk -F"-p " '{print $2}' | awk -F" -e none" '{print $1}')
repoHost=$(echo $loginString |  awk -F"https://" '{print $2}' )
# regex repoHost "https://" repoURL
authdata="{\"$repoHost\":{\"auth\":\"AWS:$password\",\"email\":\"$email\"}}"
newSecret=$(cat $pullSecretFile | jq -r -M --argjson c $authdata '."auths" + $c')
echo -n "{\"auths\":$newSecret}" > $pullDir/newPullSecret.json

OCP_RELEASE=$(oc version --client | cut -d- -f3)

oc adm -a newPullSecret.json release mirror --from=quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE} \
       --to=${repoHost}/${repoName} --to-release-image=${repoHost}/${repoName}:${OCP_RELEASE}
