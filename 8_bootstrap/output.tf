
output "clustername" {
    value = "${var.clustername}"
}

output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

output "master_ign_64" {
    value = "${base64encode(data.local_file.master_ign.content)}"
}

output "worker_ign_64" {
    value = "${base64encode(data.local_file.worker_ign.content)}"
}

output "private_ssh_key" {
    value = "${tls_private_key.installkey.private_key_pem}"
}

output "public_ssh_key" {
    value = "${tls_private_key.installkey.public_key_openssh}"
}

output "worker_machineset_yaml" {
    value = "${local_file.worker_machineset.*.content}"
}

output "cluster_ingress_service_yaml" {
    value = "${local_file.cluster_ingress_service.content}"
}

output "worker_user_data_yaml" {
    value = "${local_file.worker-user-data.content}"
}
