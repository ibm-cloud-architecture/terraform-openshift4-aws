data "local_file" "kubeadmin-password" {
  depends_on = [ module.installer ]
  filename = "kubeadmin-password"
}

output "infraID" {
    value =  module.installer.infraID
}

output "kubeadmin" {
    value = data.local_file.kubeadmin-password.content
}

output "consoleURL" {
    value = "https://console-openshift-console.apps.${var.cluster_name}.${var.base_domain}"
}

output "apiURL" {
    value = "api.${var.cluster_name}.${var.base_domain}:6443"
}