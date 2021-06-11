# resource "null_resource" "aws_credentials" {
#   provisioner "local-exec" {
#     command = "mkdir -p ~/.aws"
#   }

#   provisioner "local-exec" {
#     command = "echo '${data.template_file.aws_credentials.rendered}' > ~/.aws/credentials"
#   }
# }

# data "template_file" "aws_credentials" {
#   template = <<-EOF
# [default]
# aws_access_key_id = ${var.aws_access_key_id}
# aws_secret_access_key = ${var.aws_secret_access_key}
# EOF
# }

locals {
  zone_infra_replicas = [for idx in range(length(var.aws_worker_availability_zones)) : floor(var.infra_count / length(var.aws_worker_availability_zones)) + (idx + 1 > (var.infra_count % length(var.aws_worker_availability_zones)) ? 0 : 1)]
}

data "local_file" "cabundle" {
  count = var.openshift_additional_trust_bundle == "" ? 0 : 1
  filename = "${var.openshift_additional_trust_bundle}"
}


data "template_file" "install_config_yaml" {
  template = <<-EOF
apiVersion: v1
baseDomain: ${var.domain}
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 3
  platform:
    aws:
      rootVolume:
        iops: ${var.aws_worker_root_volume_iops}
        size: ${var.aws_worker_root_volume_size}
        type: ${var.aws_worker_root_volume_type}
      type: ${var.aws_worker_instance_type}
      zones:
      %{ for zone in var.aws_worker_availability_zones}
      - ${zone}%{ endfor }
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: ${var.master_count}
metadata:
  name: ${var.clustername}
networking:
  clusterNetworks:
  - cidr: ${var.cluster_network_cidr}
    hostPrefix: ${var.cluster_network_host_prefix}
  machineCIDR:  ${var.vpc_cidr_block}
  networkType: OpenShiftSDN
  serviceNetwork:
  - ${var.service_network_cidr}
platform:
  aws:
    region: ${var.aws_region}
pullSecret: '${file(var.openshift_pull_secret)}'
sshKey: '${local.public_ssh_key}'
%{if var.airgapped["enabled"]}imageContentSources:
- mirrors:
  - ${var.airgapped["repository"]}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${var.airgapped["repository"]}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev%{endif}
%{if var.proxy_config["enabled"]}proxy:
  httpProxy: ${var.proxy_config["httpProxy"]}
  httpsProxy: ${var.proxy_config["httpsProxy"]}
  noProxy: ${var.proxy_config["noProxy"]}%{endif}
%{if var.openshift_additional_trust_bundle != ""}additionalTrustBundle: | 
  ${indent(2,data.local_file.cabundle[0].content)}%{endif}
EOF
}


resource "local_file" "install_config" {
  content  =  data.template_file.install_config_yaml.rendered
  filename =  "${path.root}/installer-files/install-config.yaml"
}

# when the subnets are provided, modify the worker machinesets 
resource "null_resource" "manifest_cleanup_worker_machineset" {
  depends_on = [
    null_resource.generate_manifests
  ]
  count  = var.aws_private_subnets != null ? length(var.aws_private_subnets) : 0
  provisioner "local-exec" {
    command = "rm -f ${path.root}/installer-files/temp/openshift/99_openshift-cluster-api_worker-machineset-${count.index}.yaml"
  }
}

resource "local_file" "create_worker_machineset" {
  depends_on = [
    null_resource.manifest_cleanup_worker_machineset
  ]
  count  = var.aws_private_subnets != null ? length(var.aws_private_subnets) : 0
  file_permission = "0644"
  filename        = "${path.root}/installer-files/temp/openshift/99_openshift-cluster-api_worker-machineset-${count.index}.yaml"
  content         = <<EOF
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  creationTimestamp: null
  labels:
    machine.openshift.io/cluster-api-machine-role: worker
    machine.openshift.io/cluster-api-machine-type: worker
    machine.openshift.io/cluster-api-cluster: ${data.local_file.infrastructureID.content}
  name: ${data.local_file.infrastructureID.content}-worker-${var.aws_worker_availability_zones[count.index]}
  namespace: openshift-machine-api
spec:
  replicas: 1
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: ${data.local_file.infrastructureID.content}
      machine.openshift.io/cluster-api-machineset: ${data.local_file.infrastructureID.content}-worker-${var.aws_worker_availability_zones[count.index]}
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: ${data.local_file.infrastructureID.content}
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: ${data.local_file.infrastructureID.content}-worker-${var.aws_worker_availability_zones[count.index]}
    spec:
      metadata:
        creationTimestamp: null
      providerSpec:
        value:
          ami:
            id: ${var.ami}
          apiVersion: awsproviderconfig.openshift.io/v1beta1
          blockDevices:
          - ebs:
              encrypted: true
              iops: ${var.aws_worker_root_volume_iops}
              volumeSize: ${var.aws_worker_root_volume_size}
              volumeType: ${var.aws_worker_root_volume_type}
              kmsKey:
                arn: ""
          credentialsSecret:
            name: aws-cloud-credentials
          deviceIndex: 0
          iamInstanceProfile:
            id: ${data.local_file.infrastructureID.content}-worker-profile
          instanceType: ${var.aws_worker_instance_type}
          kind: AWSMachineProviderConfig
          metadata:
            creationTimestamp: null
          placement:
            availabilityZone: ${var.aws_worker_availability_zones[count.index]}
            region: ${var.aws_region}
          securityGroups:
          - filters:
            - name: tag:Name
              values:
              - ${data.local_file.infrastructureID.content}-worker-sg
          subnet:
            filters:
            - name: subnet-id
              values:
              - ${var.aws_private_subnets[count.index]}
          tags:
          - name: kubernetes.io/cluster/${data.local_file.infrastructureID.content}
            value: owned
          userDataSecret:
            name: worker-user-data
EOF
}

resource "null_resource" "extractInfrastructureID" {
  depends_on = [
    null_resource.generate_manifests
  ]

  provisioner "local-exec" {
    when    = create
    command = "cat ${path.root}/installer-files/temp/.openshift_install_state.json | jq -r '.\"*installconfig.ClusterID\".InfraID' | tr -d '\n' > ${path.root}/installer-files/infraID"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${path.root}/installer-files/infraID"
  }
}


data "local_file" "infrastructureID" {
  depends_on = [
    null_resource.extractInfrastructureID
  ]
  filename        =  "${path.root}/installer-files/infraID"

}

resource "local_file" "airgapped_registry_upgrades" {
  count    = var.airgapped["enabled"] ? 1 : 0
  filename = "${path.root}/installer-files/temp/openshift/99_airgapped_registry_upgrades.yaml"
  depends_on = [
    null_resource.generate_manifests,
  ]
  content  = <<EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: airgapped
spec:
  repositoryDigestMirrors:
  - mirrors:
    - ${var.airgapped["repository"]}
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - ${var.airgapped["repository"]}
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF
}

data "template_file" "cluster-dns-02-config" {
  template = <<EOF
apiVersion: config.openshift.io/v1
kind: DNS
metadata:
  creationTimestamp: null
  name: cluster
spec:
  baseDomain: ${var.clustername}.${var.domain}
status: {}
EOF
}

resource "local_file" "cluster-dns-02-config" {
  count = var.byo_dns ? 1 : 0
  content  = data.template_file.cluster-dns-02-config.rendered
  filename = "${path.root}/installer-files/temp/manifests/cluster-dns-02-config.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}


##
## The rest of this file is for infrastructure node designation without taints
##

resource "local_file" "create_infra_machineset" {
  depends_on = [
    null_resource.generate_manifests
  ]

  count  = var.infra_count > 0 ? length(var.aws_worker_availability_zones) : 0
  file_permission = "0644"
  filename        = "${path.root}/installer-files/temp/openshift/99_openshift-cluster-api_infra-machineset-${count.index}.yaml"
  content         = <<EOF
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  creationTimestamp: null
  labels:
    machine.openshift.io/cluster-api-machine-role: infra
    machine.openshift.io/cluster-api-machine-type: infra
    machine.openshift.io/cluster-api-cluster: ${data.local_file.infrastructureID.content}
  name: ${data.local_file.infrastructureID.content}-infra-${var.aws_worker_availability_zones[count.index]}
  namespace: openshift-machine-api
spec:
  replicas: ${local.zone_infra_replicas[count.index]}
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: ${data.local_file.infrastructureID.content}
      machine.openshift.io/cluster-api-machineset: ${data.local_file.infrastructureID.content}-infra-${var.aws_worker_availability_zones[count.index]}
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: ${data.local_file.infrastructureID.content}
        machine.openshift.io/cluster-api-machine-role: infra
        machine.openshift.io/cluster-api-machine-type: infra
        machine.openshift.io/cluster-api-machineset: ${data.local_file.infrastructureID.content}-infra-${var.aws_worker_availability_zones[count.index]}
    spec:
      metadata:
        creationTimestamp: null
        labels:
          node-role.kubernetes.io/infra: ""
      providerSpec:
        value:
          ami:
            id: ${var.ami}
          apiVersion: awsproviderconfig.openshift.io/v1beta1
          blockDevices:
          - ebs:
              encrypted: true
              iops: ${var.aws_infra_root_volume_iops}
              volumeSize: ${var.aws_infra_root_volume_size}
              volumeType: ${var.aws_infra_root_volume_type}
              kmsKey:
                arn: ""
          credentialsSecret:
            name: aws-cloud-credentials
          deviceIndex: 0
          iamInstanceProfile:
            id: ${data.local_file.infrastructureID.content}-worker-profile
          instanceType: ${var.aws_infra_instance_type}
          kind: AWSMachineProviderConfig
          metadata:
            creationTimestamp: null
          placement:
            availabilityZone: ${var.aws_worker_availability_zones[count.index]}
            region: ${var.aws_region}
          securityGroups:
          - filters:
            - name: tag:Name
              values:
              - ${data.local_file.infrastructureID.content}-worker-sg
          subnet:
            filters:
            %{if var.aws_private_subnets != null}- name: subnet-id
              values:
              - ${var.aws_private_subnets[count.index]}%{endif}
            %{if var.aws_private_subnets == null}- name: tag:Name
              values:
              - ${data.local_file.infrastructureID.content}-private-${var.aws_worker_availability_zones[count.index]}%{endif}
          tags:
          - name: kubernetes.io/cluster/${data.local_file.infrastructureID.content}
            value: owned
          userDataSecret:
            name: worker-user-data
EOF
}

data "template_file" "cluster-monitoring-configmap" {
  template = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |+
    alertmanagerMain:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusK8s:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusOperator:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    grafana:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    k8sPrometheusAdapter:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    kubeStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    telemeterClient:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    openshiftStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    thanosQuerier:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
EOF
}

resource "local_file" "cluster-monitoring-configmap" {
  count    = var.infra_count > 0 ? 1 : 0
  content  = data.template_file.cluster-monitoring-configmap.rendered
  filename = "${path.root}/installer-files/temp/openshift/99_cluster-monitoring-configmap.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}


data "template_file" "configure-image-registry-job-serviceaccount" {
  template = <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: infra
  namespace: openshift-image-registry
EOF
}

resource "local_file" "configure-image-registry-job-serviceaccount" {
  count    = var.infra_count > 0 ? 1 : 0
  content  = data.template_file.configure-image-registry-job-serviceaccount.rendered
  filename = "${path.root}/installer-files/openshift/99_configure-image-registry-job-serviceaccount.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

data "template_file" "configure-image-registry-job-clusterrole" {
  template = <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:ibm-patch-cluster-storage
rules:
- apiGroups: ['imageregistry.operator.openshift.io']
  resources: ['configs']
  verbs:     ['get','patch']
  resourceNames: ['cluster']
EOF
}

resource "local_file" "configure-image-registry-job-clusterrole" {
  count    = var.infra_count > 0 ? 1 : 0
  content  = data.template_file.configure-image-registry-job-clusterrole.rendered
  filename = "${path.root}/installer-files/temp/openshift/99_configure-image-registry-job-clusterrole.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

data "template_file" "configure-image-registry-job-clusterrolebinding" {
  template = <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:ibm-patch-cluster-storage
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:ibm-patch-cluster-storage
subjects:
  - kind: ServiceAccount
    name: default
    namespace: openshift-image-registry
EOF
}

resource "local_file" "configure-image-registry-job-clusterrolebinding" {
  count    = var.infra_count > 0 ? 1 : 0
  content  = data.template_file.configure-image-registry-job-clusterrolebinding.rendered
  filename = "${path.root}/installer-files/temp/openshift/99_configure-image-registry-job-clusterrolebinding.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

data "template_file" "configure-image-registry-job" {
  template = <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ibm-configure-image-registry
  namespace: openshift-image-registry
spec:
  parallelism: 1
  completions: 1
  template:
    metadata:
      name: configure-image-registry
      labels:
        app: configure-image-registry
    serviceAccountName: infra
    spec:
      containers:
      - name:  client
        image: quay.io/openshift/origin-cli:latest
        command: ["/bin/sh","-c"]
        args: ["while ! /usr/bin/oc get configs.imageregistry.operator.openshift.io cluster >/dev/null 2>&1; do sleep 1;done;/usr/bin/oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{\"spec\": {\"nodeSelector\": {\"node-role.kubernetes.io/infra\": \"\"}}}'"]
      restartPolicy: Never
EOF
}

resource "local_file" "configure-image-registry-job" {
  count    = var.infra_count > 0 ? 1 : 0
  content  = data.template_file.configure-image-registry-job.rendered
  filename = "${path.root}/installer-files/temp/openshift/99_configure-image-registry-job.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

data "template_file" "configure-ingress-job-serviceaccount" {
  template = <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: infra
  namespace: openshift-ingress-operator
EOF
}

resource "local_file" "configure-ingress-job-serviceaccount" {
  count    = var.infra_count > 0 ? 1 : 0
  content  = data.template_file.configure-ingress-job-serviceaccount.rendered
  filename = "${path.root}/installer-files/temp/openshift/99_configure-ingress-job-serviceaccount.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

data "template_file" "configure-ingress-job-clusterrole" {
  template = <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:ibm-patch-ingress
rules:
- apiGroups:     ['operator.openshift.io']
  resources:     ['ingresscontrollers']
  verbs:         ['get','patch']
  resourceNames: ['default']
EOF
}

resource "local_file" "configure-ingress-job-clusterrole" {
  count    = var.infra_count > 0 ? 1 : 0
  content  = data.template_file.configure-ingress-job-clusterrole.rendered
  filename = "${path.root}/installer-files/temp/openshift/99_configure-ingress-job-clusterrole.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

data "template_file" "configure-ingress-job-clusterrolebinding" {
  template = <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:ibm-patch-ingress
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:ibm-patch-ingress
subjects:
  - kind: ServiceAccount
    name: default
    namespace: openshift-ingress-operator
EOF
}

resource "local_file" "configure-ingress-job-clusterrolebinding" {
  count    = var.infra_count > 0 ? 1 : 0
  content  = data.template_file.configure-ingress-job-clusterrolebinding.rendered
  filename = "${path.root}/installer-files/temp/openshift/99_configure-ingress-job-clusterrolebinding.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

data "template_file" "configure-ingress-job" {
  template = <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ibm-configure-ingress
  namespace: openshift-ingress-operator
spec:
  parallelism: 1
  completions: 1
  template:
    metadata:
      name: configure-ingress
      labels:
        app: configure-ingress
    serviceAccountName: infra
    spec:
      containers:
      - name:  client
        image: quay.io/openshift/origin-cli:latest
        command: ["/bin/sh","-c"]
        args: ["while ! /usr/bin/oc get ingresscontrollers.operator.openshift.io default -n openshift-ingress-operator >/dev/null 2>&1; do sleep 1;done;/usr/bin/oc patch ingresscontrollers.operator.openshift.io default -n openshift-ingress-operator --type merge --patch '{\"spec\": {\"nodePlacement\": {\"nodeSelector\": {\"matchLabels\": {\"node-role.kubernetes.io/infra\": \"\"}}}}}'"]
      restartPolicy: Never
EOF
}

resource "local_file" "configure-ingress-job" {
  count    = var.infra_count > 0 ? 1 : 0
  content  = data.template_file.configure-ingress-job.rendered
  filename = "${path.root}/installer-files/temp/openshift/99_configure-ingress-job.yml"
  depends_on = [
    null_resource.generate_manifests,
  ]
}

