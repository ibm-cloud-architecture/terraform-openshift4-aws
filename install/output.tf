output master_ign {
    value = data.local_file.master_ign.content
}

output bootstrap_ign {
    value = data.local_file.bootstrap_ign.content
}

output "master_ign_64" {
    value =  base64encode(data.local_file.master_ign.content)
}

output "worker_ign_64" {
    value =  base64encode(data.local_file.worker_ign.content)
}

output "private_ssh_key" {
    value =  tls_private_key.installkey.private_key_pem
}

output "public_ssh_key" {
    value =  tls_private_key.installkey.public_key_openssh
}

