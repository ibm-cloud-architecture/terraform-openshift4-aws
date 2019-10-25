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

1. To use Terraform automation, download the Terraform binaries [here](https://www.terraform.io/).

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

   OpenShift requires a valid DNS doamin, you can get one from AWS Route53 or using existing domain and registrar.


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

1. Provision the public DMZ that includes the bastion host on which you will run the subsequent deployment of OpenShift 4 in AWS. This can be performed manually and then you can use the instruction in the above section to set it up or you can use the 0_bastion code to deploy this environment in AWS.

2. Deploy the private network and OpenShift 4 cluster through the connection using transit gateway to the public environment.
   You can use all the automation in a single deployment or you can use the individual folder in the git repository sequentially. The folders are:

	- 1_private_network: Create the VPC and subnets for the OpenShift cluster
	- 2_load_balancer: Create the system loadbalancer for the API and machine config operator
	- 3_dns: generate a private hosted zone using route 53
	- 4_security_group: defines network access rules for masters and workers
	- 5_iam: define AWS authorities for the masters and workers
	- 6_public_network: define hosted zone to the related public DMZ zone
	- 7_transit_gw: creates and links transit gateway to connect the private VPC to the public DMZ
	- 8_bootstrap: main module to provision the bootstrap node and generates OpenShift installation files and resources
	- 9_control_plane: create master nodes manually (UPI) 
	- 10_postinstall: creates and initiates worker nodes, fixes machine-config operator and creates kubeadmin user

	You can also provision all the components in a single terraform main module, to do that, you need to use a terraform.tfvars, that is copied from the terraform.tfvars.example file. The variables related to that are:

	Create a `terraform.tfvars` file with following content:

	```
	aws_region = "us-east-2"
	aws_azs = ["a", "b", "c"]
	default_tags = { "owner" = "aws-user01" }
	infrastructure_id = "ocp4-abcde"
	clustername = "ocp4"
	private_vpc_cidr = "10.10.0.0/16"
	vpc_private_subnet_cidrs = ["10.10.10.0/24","10.10.11.0/24","10.10.12.0/24"]
	domain = "example.com"
	# public_vpc_cidr = "172.16.0.0/16"
	public_vpc_id = "vpc-0123456789"
	public_vpc_private_subnet_cidrs = ["172.16.10.0/24","172.16.11.0/24","172.16.12.0/24"]
	public_vpc_public_subnet_cidrs = ["172.16.20.0/24","172.16.21.0/24","172.16.22.0/24"]
	ami = "ami-0bc59aaa7363b805d"
	aws_access_key_id = "Aaccessid"
	aws_secret_access_key = "accesssecret"
	cluster_network_cidr = "192.168.0.0/17"
	cluster_network_host_prefix = "23"
	service_network_cidr = "192.168.128.0/24"
	bootstrap = { type = "i3.xlarge" }
	control_plane = { count = "3" , type = "m4.xlarge", disk = "120" }
	use_worker_machinesets = true
	# worker = {        count = "3" , type = "m4.large" , disk = "120" }
	openshift_pull_secret = "./openshift_pull_secret.json"
	openshift_installer_url = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest"
	```

|name | required                        | value        |
|----------------|------------|--------------|
| `aws_region`   | no           | AWS region that the VPC will be created in.  By default, uses `us-east-2`.  Note that for an HA installation, the AWS selected region should have at least 3 availability zones. |
| `aws_azs`          | no           | AWS Availability Zones that the VPC will be created in, e.g. `[ "a", "b", "c"]` to install in three availability zones.  By default, uses `["a", "b", "c"]`.  Note that the AWS selected region should have at least 3 availability zones for high availability.  Setting to a single availability zone will disable high availability and not provision EFS, in this case, reduce the number of master and proxy nodes to 1. |
| `default_tags`     | no          | AWS tag to identify a resource for example owner:gchen     |
| `infrastructure_id` | yes | This id will be prefixed to all the AWS infrastructure resources provisioned with the script |
| `clustername`     | yes          | The name of the OpenShift cluster you will install     |
| `vpc_cidr`     | yes          | VPC private netwrok CIDR range default 10.10.0.0/16  |
| `vpc_private_subnet_cidrs`     | yes          | CIDR range for the VPC private subnets default ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24" ]   |


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
