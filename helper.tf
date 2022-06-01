locals {
  major_version   = join(".", slice(split(".", var.openshift_version), 0, 2))
  minor_version    = split(".", local.major_version)[1]
  aws_azs         = (var.aws_azs != null) ? var.aws_azs : tolist([join("",[var.aws_region,"a"]),join("",[var.aws_region,"b"]),join("",[var.aws_region,"c"])])
  rhcos_image     = local.minor_version < 10 ? lookup(lookup(lookup(jsondecode(data.http.images.body), "amis"), "${var.aws_region}"),"hvm") : lookup(lookup(lookup(lookup(lookup(lookup(lookup(jsondecode(data.http.images.body), "architectures"), "x86_64"), "images"), "aws"), "regions"), "${var.aws_region}"),"image")
}

data "http" "images" {
  url = local.minor_version < 10 ? "https://raw.githubusercontent.com/openshift/installer/release-${local.major_version}/data/data/rhcos.json" : "https://raw.githubusercontent.com/openshift/installer/release-${local.major_version}/data/data/coreos/rhcos.json"
  request_headers = {
    Accept = "application/json"
  }
}
