locals {
  major_version   = join(".", slice(split(".", var.openshift_version), 0, 2))
  aws_azs         = (var.aws_azs != null) ? var.aws_azs : tolist([join("",[var.aws_region,"a"]),join("",[var.aws_region,"b"]),join("",[var.aws_region,"c"])])
 rhcos_image     = lookup(lookup(lookup(lookup(lookup(lookup(lookup(jsondecode(data.http.images.body), "architectures"),"x86_64"),"images"),"aws"), "regions"),"${var.aws_region}"),"image")
}

data "http" "images" {
  url = "https://raw.githubusercontent.com/openshift/installer/release-${local.major_version}/data/data/coreos/rhcos.json"
  request_headers = {
    Accept = "application/json"
  }
}