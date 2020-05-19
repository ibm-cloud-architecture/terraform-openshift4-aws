locals {
  tags = merge(
    {
      "kubernetes.io/cluster/${var.cluster_id}" = "owned"
    },
    var.aws_extra_tags,
  )
}

provider "aws" {
  region = var.aws_region

  # Validation of AWS Bahrain region was added in AWS TF provider v2.22
  # so we skip when installing in me-south-1.
  skip_region_validation = var.aws_region == "me-south-1"
}

module "iam" {
  source = "./iam"

  cluster_id = var.cluster_id

  tags = local.tags
}

module "installer" {
  source = "./install"

  ami = aws_ami_copy.main.id
  dns_public_id = module.dns.public_dns_id
  infrastructure_id = var.cluster_id
  clustername = var.clustername
  domain = var.base_domain
  aws_region = var.aws_region
  aws_access_key_id = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  vpc_cidr_block = var.machine_cidr
  master_count = length(var.aws_azs)
  openshift_pull_secret = var.openshift_pull_secret
  openshift_installer_url = var.openshift_installer_url
  aws_worker_root_volume_iops = var.aws_worker_root_volume_iops
  aws_worker_root_volume_size = var.aws_worker_root_volume_size
  aws_worker_root_volume_type = var.aws_worker_root_volume_type
  aws_worker_availability_zones = var.aws_azs
  aws_worker_instance_type = var.aws_worker_instance_type
  airgapped = var.airgapped
}

module "vpc" {
  source = "./vpc"

  cidr_block       = var.machine_cidr
  cluster_id       = var.cluster_id
  region           = var.aws_region
  vpc              = var.aws_vpc
  public_subnets   = var.aws_public_subnets
  private_subnets  = var.aws_private_subnets
  publish_strategy = var.aws_publish_strategy
  airgapped = var.airgapped
  availability_zones = var.aws_azs

  tags = local.tags
}

module "dns" {
  source = "./route53"

  api_external_lb_dns_name = module.vpc.aws_lb_api_external_dns_name
  api_external_lb_zone_id  = module.vpc.aws_lb_api_external_zone_id
  api_internal_lb_dns_name = module.vpc.aws_lb_api_internal_dns_name
  api_internal_lb_zone_id  = module.vpc.aws_lb_api_internal_zone_id
  base_domain              = var.base_domain
  cluster_domain           = "${var.clustername}.${var.base_domain}"
  cluster_id               = var.cluster_id
  etcd_count               = length(var.aws_azs)
  etcd_ip_addresses        = flatten(module.masters.ip_addresses)
  tags                     = local.tags
  vpc_id                   = module.vpc.vpc_id
  publish_strategy         = var.aws_publish_strategy
}

resource "aws_ami_copy" "main" {
  name              = "${var.cluster_id}-master"
  source_ami_id     = var.aws_ami
  source_ami_region = var.aws_region
  encrypted         = true

  tags = merge(
    {
      "Name"         = "${var.cluster_id}-master"
      "sourceAMI"    = var.aws_ami
      "sourceRegion" = var.aws_region
    },
    local.tags,
  )
}

module "bootstrap" {
  source = "./bootstrap"

  ami                      = aws_ami_copy.main.id
  instance_type            = var.aws_bootstrap_instance_type
  cluster_id               = var.cluster_id
  ignition                 = module.installer.bootstrap_ign
  subnet_id                = var.aws_publish_strategy == "External" ? module.vpc.az_to_public_subnet_id[var.aws_azs[0]] : module.vpc.az_to_private_subnet_id[var.aws_azs[0]]
  target_group_arns        = module.vpc.aws_lb_target_group_arns
  target_group_arns_length = module.vpc.aws_lb_target_group_arns_length
  vpc_id                   = module.vpc.vpc_id
  vpc_cidrs                = module.vpc.vpc_cidrs
  vpc_security_group_ids   = [module.vpc.master_sg_id]
  publish_strategy         = var.aws_publish_strategy

  tags = local.tags
}

module "masters" {
  source = "./master"

  cluster_id    = var.cluster_id
  instance_type = var.aws_master_instance_type

  tags = local.tags

  availability_zones       = var.aws_azs
  az_to_subnet_id          = module.vpc.az_to_private_subnet_id
  instance_count           = length(var.aws_azs)
  master_sg_ids            = [module.vpc.master_sg_id]
  root_volume_iops         = var.aws_master_root_volume_iops
  root_volume_size         = var.aws_master_root_volume_size
  root_volume_type         = var.aws_master_root_volume_type
  target_group_arns        = module.vpc.aws_lb_target_group_arns
  target_group_arns_length = module.vpc.aws_lb_target_group_arns_length
  ec2_ami                  = aws_ami_copy.main.id
  user_data_ign            = module.installer.master_ign
  publish_strategy         = var.aws_publish_strategy
}
