locals {
  infrastructure_id = "${var.clustername}-vbd01"
}

module "private_network" {
  source = "./1_private_network"
  aws_region = "${var.aws_region}"
  aws_azs = "${var.aws_azs}"
  default_tags = "${var.default_tags}"
  infrastructure_id = "${local.infrastructure_id}"
  clustername = "${var.clustername}"
  vpc_cidr = "${var.private_vpc_cidr}"
  vpc_private_subnet_cidrs = "${var.vpc_private_subnet_cidrs}"
}
# ---------------------------
#     "${module.private_network.infrastructure_id}"
#     "${module.private_network.clustername}"
#     "${module.private_network.private_vpc_id}"
#     "${module.private_network.private_vpc_private_subnet_ids}"
# ---------------------------
module "load_balancer" {
  source = "./2_load_balancer"
  aws_region = "${var.aws_region}"
  default_tags = "${var.default_tags}"
  infrastructure_id = "${local.infrastructure_id}"
  clustername = "${var.clustername}"
  private_vpc_id = "${module.private_network.private_vpc_id}"
  private_vpc_private_subnet_ids = "${module.private_network.private_vpc_private_subnet_ids}"
}
# ---------------------------
#     "${module.load_balancer.private_vpc_id}"
#     "${module.load_balancer.infrastructure_id}"
#     "${module.load_balancer.clustername}"
#     "${module.load_balancer.ocp_control_plane_lb_int_arn}"
#     "${module.load_balancer.ocp_control_plane_lb_int_6443_tg_arn}"
#     "${module.load_balancer.ocp_control_plane_lb_int_22623_tg_arn}"
# ---------------------------
module "dns" {
  source = "./3_dns"
  aws_region = "${var.aws_region}"
  default_tags = "${var.default_tags}"
  infrastructure_id = "${local.infrastructure_id}"
  private_vpc_id = "${module.private_network.private_vpc_id}"
  ocp_control_plane_lb_int_arn = "${module.load_balancer.ocp_control_plane_lb_int_arn}"
  clustername = "${var.clustername}"
  domain = "${var.domain}"
}
# ---------------------------
#     "${module.dns.ocp_route53_private_zone_id}"
#     "${module.dns.private_vpc_id}"
#     "${module.dns.infrastructure_id}"
#     "${module.dns.clustername}"
#     "${module.dns.ocp_control_plane_lb_int_arn}"
# ---------------------------
module "security_group" {
  source = "./4_security_group"
  aws_region = "${var.aws_region}"
  default_tags = "${var.default_tags}"
  clustername = "${var.clustername}"
  infrastructure_id = "${local.infrastructure_id}"
  private_vpc_id = "${module.private_network.private_vpc_id}"
}
# ---------------------------
#     "${module.security_group.infrastructure_id}"
#     "${module.security_group.clustername}"
#     "${module.security_group.ocp_control_plane_security_group_id}"
#     "${module.security_group.ocp_worker_security_group_id}"
# ---------------------------
module "iam" {
  source = "./5_iam"
  aws_region = "${var.aws_region}"
  default_tags = "${var.default_tags}"
  infrastructure_id = "${local.infrastructure_id}"
  clustername = "${var.clustername}"
}
# ---------------------------
#     "${module.iam.infrastructure_id}"
#     "${module.iam.clustername}"
#     "${module.iam.ocp_master_instance_profile_id}"
#     "${module.iam.ocp_worker_instance_profile_id}"
# ---------------------------
module "public_network" {
  source = "./6_public_network"
  aws_region = "${var.aws_region}"
  aws_azs = "${var.aws_azs}"
  default_tags = "${var.default_tags}"
  infrastructure_id = "${local.infrastructure_id}"
  clustername = "${var.clustername}"
  public_vpc_id = "${var.public_vpc_id}"
  ocp_route53_private_zone_id = "${module.dns.ocp_route53_private_zone_id}"
  public_vpc_private_subnet_cidrs = "${var.public_vpc_private_subnet_cidrs}"
  public_vpc_public_subnet_cidrs = "${var.public_vpc_public_subnet_cidrs}"
  domain = "${var.domain}"
}
# ---------------------------
#     "${module.public_network.clustername}"
#     "${module.public_network.infrastructure_id}"
#     "${module.public_network.public_vpc_id}"
#     "${module.public_network.public_vpc_public_subnet_ids}"
#     "${module.public_network.public_vpc_private_subnet_ids}"
# ---------------------------
module "transit_gw" {
  source = "./7_transit_gw"
  aws_region = "${var.aws_region}"
  default_tags = "${var.default_tags}"
  clustername = "${var.clustername}"
  infrastructure_id = "${local.infrastructure_id}"
  private_vpc_id = "${module.private_network.private_vpc_id}"
  public_vpc_id = "${module.public_network.public_vpc_id}"
  private_vpc_private_subnet_ids = "${module.private_network.private_vpc_private_subnet_ids}"
  public_vpc_private_subnet_ids = "${module.public_network.public_vpc_private_subnet_ids}"
  public_vpc_public_subnet_ids = "${module.public_network.public_vpc_public_subnet_ids}"
}

module "bootstrap" {
  source = "./8_bootstrap"
  aws_region = "${var.aws_region}"
  aws_azs = "${var.aws_azs}"
  default_tags = "${var.default_tags}"
  ami = "${var.ami}"
  aws_access_key_id = "${var.aws_access_key_id}"
  aws_secret_access_key = "${var.aws_secret_access_key}"
  infrastructure_id = "${local.infrastructure_id}"
  clustername = "${var.clustername}"
  private_vpc_id = "${module.private_network.private_vpc_id}"
  private_vpc_private_subnet_ids = "${module.private_network.private_vpc_private_subnet_ids}"
  domain = "${var.domain}"
  cluster_network_cidr = "${var.cluster_network_cidr}"
  cluster_network_host_prefix = "${var.cluster_network_host_prefix}"
  service_network_cidr = "${var.service_network_cidr}"
  bootstrap = "${var.bootstrap}"
  control_plane = "${var.control_plane}"
  worker = "${var.worker}"
  openshift_pull_secret = "${var.openshift_pull_secret}"
  use_worker_machinesets = "${var.use_worker_machinesets}"
  openshift_installer_url = "${var.openshift_installer_url}"
  ocp_control_plane_security_group_id = "${module.security_group.ocp_control_plane_security_group_id}"
  ocp_worker_security_group_id = "${module.security_group.ocp_worker_security_group_id}"
  ocp_master_instance_profile_id = "${module.iam.ocp_master_instance_profile_id}"
  ocp_worker_instance_profile_id = "${module.iam.ocp_worker_instance_profile_id}"
  ocp_control_plane_lb_int_arn = "${module.load_balancer.ocp_control_plane_lb_int_arn}"
  ocp_control_plane_lb_int_22623_tg_arn = "${module.load_balancer.ocp_control_plane_lb_int_22623_tg_arn}"
  ocp_control_plane_lb_int_6443_tg_arn = "${module.load_balancer.ocp_control_plane_lb_int_6443_tg_arn}"
  ocp_route53_private_zone_id = "${module.dns.ocp_route53_private_zone_id}"
}
# ---------------------------
#     "${module.bootstrap.clustername}"
#     "${module.bootstrap.infrastructure_id}"
#     "${module.bootstrap.master_ign_64}"
#     "${module.bootstrap.worker_ign_64}"
#     "${module.bootstrap.private_ssh_key}"
#     "${module.bootstrap.public_ssh_key}"
# ---------------------------
module "control_plane" {
  source = "./9_control_plane"
  aws_region = "${var.aws_region}"
  aws_azs = "${var.aws_azs}"
  default_tags = "${var.default_tags}"
  ami = "${var.ami}"
  infrastructure_id = "${local.infrastructure_id}"
  clustername = "${var.clustername}"
  private_vpc_id = "${module.private_network.private_vpc_id}"
  private_vpc_private_subnet_ids = "${module.private_network.private_vpc_private_subnet_ids}"
  domain = "${var.domain}"
  control_plane = "${var.control_plane}"
  worker = "${var.worker}"
  openshift_pull_secret = "${var.openshift_pull_secret}"
  use_worker_machinesets = "${var.use_worker_machinesets}"
  ocp_control_plane_security_group_id = "${module.security_group.ocp_control_plane_security_group_id}"
  ocp_worker_security_group_id = "${module.security_group.ocp_worker_security_group_id}"
  ocp_master_instance_profile_id = "${module.iam.ocp_master_instance_profile_id}"
  ocp_worker_instance_profile_id = "${module.iam.ocp_worker_instance_profile_id}"
  ocp_control_plane_lb_int_arn = "${module.load_balancer.ocp_control_plane_lb_int_arn}"
  ocp_control_plane_lb_int_22623_tg_arn = "${module.load_balancer.ocp_control_plane_lb_int_22623_tg_arn}"
  ocp_control_plane_lb_int_6443_tg_arn = "${module.load_balancer.ocp_control_plane_lb_int_6443_tg_arn}"
  ocp_route53_private_zone_id = "${module.dns.ocp_route53_private_zone_id}"
  master_ign_64 = "${module.bootstrap.master_ign_64}"
  worker_ign_64 = "${module.bootstrap.worker_ign_64}"
}
# ---------------------------
#     "${module.control_plane.int_lb_url}"
# ---------------------------
