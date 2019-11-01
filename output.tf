
output "clustername" {
    value = "${var.clustername}"
}

output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

output "ingress_yaml" {
    value = "You should remove the default ingress controller and ingress service using \n oc delete ingresscontroller default -n openshift-ingress-operator\n oc delete service router-default -n openshift-ingress \n oc create -f ${path.root}/ingress_controller.yml \n oc create -f ${path.root}/ingress_service.yml"
}

