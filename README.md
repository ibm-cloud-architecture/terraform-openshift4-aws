# Automated OpenShift v4 installation on AWS

This project automates the Red Hat Openshift Container Platform 4.2 installation on Amazon AWS platform. It focuses on the Openshift User-provided infrastructure installation (UPI) where end users provide pre-existing infrastructure including VMs, networking, load balancers, DNS configuration etc.

* [Infrastructure Architecture](#infrastructure-architecture)
* [Terraform Automation](#terraform-automation)
* [Installation Procedure](#installation-procedure)
* [Cluster access](#cluster-access)
* [AWS Cloud Provider](#aws-cloud-provider)


## Infrastructure Architecture

For detail on OpenShift UPI, please reference the following:


* [https://docs.openshift.com/container-platform/4.1/installing/installing_aws_user_infra/installing-aws-user-infra.html](https://docs.openshift.com/container-platform/4.1/installing/installing_aws_user_infra/installing-aws-user-infra.html)
* [https://github.com/openshift/installer/blob/master/docs/user/aws/install_upi.md](https://github.com/openshift/installer/blob/master/docs/user/aws/install_upi.md)


The following diagram outlines the infrastructure architecture.
![OpenShift 4 on AWS](img/openshift_aws_network.png)

## Terraform Automation

This project uses mainly Terraform as infrastructure management and installation automation driver. All the user provisioned resource are created via the terraform scripts in this project.

### Prerequisites

1. To use Terraform automation, download the Terraform binaries [here](https://www.terraform.io/). The code here supports Terraform 0.12 - 0.12.13; there are warning messages to run this on 0.12.14 and later.

   On MacOS, you can acquire it using [homebrew](brew.sh) using this command:

   ```bash
   brew install terraform
   ```

   We recommend to run Terraform automation from an AWS bastion host because the installation will place the entire OpenShift cluster in a private network where you might not have easy access to validate the cluster installation from your laptop.

   Provision an EC2 bastion instance (with public and private subnets).
   Install Terraform binary.
   Install git

   ```bash
   sudo yum intall git-all
   git --version
   ```

   Install OpenShift command line `oc` cli:

   ```bash
   wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.x.xx.tar.gz
   tar -xvf openshift-client-linux-4.x.xx.tar.gz
   chmod u+x oc kubectl
   sudo mv oc /usr/local/bin
   sudo mv kubectl /usr/local/bin
   oc version
   ```

   You'll also need the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html) to do this.

2. Get the Terraform code

   ```bash
   git clone https://github.com/ibm-cloud-architecture/terraform-openshift4-aws.git
   ```

3. Prepare the DNS

   OpenShift requires a valid DNS domain, you can get one from AWS Route53 or using existing domain and registrar. The DNS must be registered as a Public Hosted Zone in Route53.


4. Prepare AWS Account Access

   Please reference the [Required AWS Infrastructure components](https://docs.openshift.com/container-platform/4.1/installing/installing_aws_user_infra/installing-aws-user-infra.html#installation-aws-user-infra-requirements_installing-aws-user-infra) to setup your AWS account before installing OpenShift 4.

   We suggest to create an AWS IAM user dedicated for OpenShift installation with permissions documented above.
   On the bastion host, configure your AWS user credential as environment variables:

    ```bash
    export AWS_ACCESS_KEY_ID=RKXXXXXXXXXXXXXXX
    export AWS_SECRET_ACCESS_KEY=LXXXXXXXXXXXXXXXXXX/ng
    export AWS_DEFAULT_REGION=us-east-2

    aws s3 ls
   ```

## Installation Procedure

This project installs the OpenShift 4 in several stages where each stage automates the provisioning of different components from infrastructure to OpenShift installation. The design is to provide the flexibility of different topology and infrastructure requirement.

1. The deployment assumes that you run the terraform deployment from a Linux based environment. This can be performed on an AWS-linux EC2 instance. The deployment machine has the following requirements:

    - git cli
    - terraform 0.12 or later
    - aws client
    - jq command
    - wget command

2. Deploy the private network and OpenShift 4 cluster through the connection using transit gateway to the public environment.
   You can use all the automation in a single deployment or you can use the individual folder in the git repository sequentially. The folders are:

 	- 1_private_network: Create the VPC and subnets for the OpenShift cluster
	- 2_load_balancer: Create the system loadbalancer for the API and machine config operator
	- 3_dns: generate a private hosted zone using route 53
	- 4_security_group: defines network access rules for masters and workers
	- 5_iam: define AWS authorities for the masters and workers
	- 6_bootstrap: main module to provision the bootstrap node and generates OpenShift installation files and resources
	- 7_control_plane: create master nodes manually (UPI)
	- 8_postinstall: defines public DNS for application load balancer (optional)

	You can also provision all the components in a single terraform main module, to do that, you need to use a terraform.tfvars, that is copied from the terraform.tfvars.example file. The variables related to that are:

	Create a `terraform.tfvars` file with following content:

  ```
  aws_region = "us-east-2"
  aws_azs = ["a", "b", "c"]
  default_tags = { "owner" = "ocp42" }
  infrastructure_id = "ocp42-abcde"
  clustername = "ocp42"
  domain = "example.com"
  ami = "ami-0bc59aaa7363b805d"
  aws_access_key_id = ""
  aws_secret_access_key = ""
  bootstrap = { type = "i3.xlarge" }
  control_plane = { count = "3" , type = "m4.xlarge", disk = "120" }
  use_worker_machinesets = true
  # worker = {        count = "3" , type = "m4.large" , disk = "120" }
  openshift_pull_secret = "./openshift_pull_secret.json"
  openshift_installer_url = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest"
  ```

|name | required                        | description and value        |
|----------------|------------|--------------|
| `aws_region`   | no           | AWS region that the VPC will be created in.  By default, uses `us-east-2`.  Note that for an HA installation, the AWS selected region should have at least 3 availability zones. |
| `aws_azs`          | no           | AWS Availability Zones that the VPC will be created in, e.g. `[ "a", "b", "c"]` to install in three availability zones.  By default, uses `["a", "b", "c"]`.  Note that the AWS selected region should have at least 3 availability zones for high availability.  Setting to a single availability zone will disable high availability and not provision EFS, in this case, reduce the number of master and proxy nodes to 1. |
| `default_tags`     | no          | AWS tag to identify a resource for example owner:gchen     |
| `infrastructure_id` | yes | This id will be prefixed to all the AWS infrastructure resources provisioned with the script - typically using the clustername as its prefix.  |
| `clustername`     | yes          | The name of the OpenShift cluster you will install     |
| `domain` | yes | The domain that has been created in Route53 public hosted zone |
| `ami` | no | Red Hat CoreOS ami for your region (see [here](https://docs.openshift.com/container-platform/4.2/installing/installing_aws_user_infra/installing-aws-user-infra.html#installation-aws-user-infra-rhcos-ami_installing-aws-user-infra)). Other platforms images information can be found [here](https://github.com/openshift/installer/blob/master/data/data/rhcos.json) |
| `aws_secret_access_key` | yes | adding aws_secret_access_key to the cluster |
| `aws_access_key_id` | yes | adding aws_access_key_id to the cluster |
| `bootstrap` | no | |
| `control_plane` | no | |
| `use_worker_machinesets` | no | if set to true, then workers are created using machinesets otherwise use the worker variable |
| `worker` | no | if not using the machinesets, this variable is used to size the worker machines |
| `openshift_pull_secret` | no | The value refers to a file name that contain downloaded pull secret from https://cloud.redhat.com/openshift/install; the default name is `openshift_pull_secret.json` |
| `openshift_installer_url` | no | The URL to the download site for Red Hat OpenShift installation and client codes.  |
| `private_vpc_cidr`     | no          | VPC private netwrok CIDR range default 10.10.0.0/16  |
| `vpc_private_subnet_cidrs`     | no          | CIDR range for the VPC private subnets default ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24" ]   |
| `vpc_public_subnet_cidrs` | no | default to ["10.10.20.0/24","10.10.21.0/24","10.10.22.0/24"] |
| `cluster_network_cidr` | no | The pod network CIDR, default to "192.168.0.0/17" |
| `cluster_network_host_prefix` | no | The prefix for the pod network, default to "23" |
| `service_network_cidr` | no | The service network CIDR, default to "192.168.128.0/24" |



See [Terraform documentation](https://www.terraform.io/intro/getting-started/variables.html) for the format of this file.


Initialize the Terraform:

```bash
terraform init
```

Run the terraform provisioning:

```bash
terraform plan
terraform apply
```
