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

1. Provision Prviate Network.
The script will create an AWS VPC and private subnets.
Navigate to the git repository folder `1_private_network`

```bash
cd 1_private_network
```

Create a `terraform.tfvars` file with following content:

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
terrafrm apply
```

2. Provision Load Balancers

This stage provisions the OpenShift control plane load balancer and the target groups. It will take the vpc_id and subnets ids from the previous step.

```bash
cd 2_load_balancer

cat > terraform.tfvars <<EOF
aws_region = "us-east-2"
default_tags = { owner = "gchen" }
infrastructure_id = "ocp4chen-aws"
clustername = "ocp4chen"
private_vpc_id = "vpc-0eec91d36e66950f3"
private_vpc_private_subnet_ids = [
  "subnet-08fa6e0ab331804ee",
  "subnet-0569eca464249d117",
  "subnet-0d5e8d8a9fc6f6187",
]
EOF

terraform init
terraform plan
terraform apply
```


3. Setup Route53 DNS Zones
OpenShift requires the private zone setup in Route53. This zone maps to the internal control plane ELB.

```bash
cd 3_dns

cat > terraform.tfvars <<EOF
aws_region = "us-east-2"
default_tags = { owner = "gchen" }
infrastructure_id = "ocp4chen-aws"
clustername = "ocp4chen"
domain = "kpak.tk"
private_vpc_id = "vpc-0eec91d36e66950f3"
ocp_control_plane_lb_int_arn = "arn:aws:elasticloadbalancing:us-east-2:353456611220:loadbalancer/net/ocp4chen-aws-int/0272df577ba9a2c3"
EOF

terraform init
terraform plan
terraform apply
```

4. Add security groups

```bash
cd 4_security_group

cat > terraform.tfvars <<EOF
aws_region = "us-east-2"
default_tags = { owner = "gchen" }
infrastructure_id = "ocp4chen-aws"
clustername = "ocp4chen"
domain = "kpak.tk"
private_vpc_id = "vpc-0eec91d36e66950f3"
EOF

terraform init
terraform plan
terraform apply
```