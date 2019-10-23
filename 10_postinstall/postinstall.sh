#!/bin/bash
# Assumptions
# - IP addr of bootstrap $bootIP
# - SSH key for bootstrap $sshkey
# - the oc command
# - the kubeconfig
# - 

echo "Bootstrap complete"

export KUBECONFIG=$(find / -name kubeconfig 2>/dev/null | tail -1)

curmco=$(oc get machineconfig | grep "rendered-master" | tail -1 | awk '{print $1}')
curuid=$(oc get machineconfig ${curmco} -o yaml | grep "   uid:" | awk '{print $2}')

cd opt/openshift/openshift

sed "s/uid: \"\"/uid: \"$curuid\"/g" -i rendered-master-*.yaml

oc apply -f 99_openshift-cluster-api_worker-user-data-secret.yaml
oc apply -f 99_openshift-cluster-api_worker-machineset-0.yaml
oc apply -f 99_openshift-cluster-api_worker-machineset-1.yaml
oc apply -f 99_openshift-cluster-api_worker-machineset-2.yaml

oc apply -f 99_kubeadmin-password-secret.yaml

