
resource "random_id" "bucketid" {
 byte_length = "8"
}

resource "aws_s3_bucket" "ocp_ignition" {
  bucket        = "${local.infrastructure_id}-infra-${random_id.bucketid.hex}"
  acl           = "private"

  tags = "${merge(
      var.default_tags,
      map(
        "Name", "${local.infrastructure_id}-infra-${random_id.bucketid.hex}"
      )
  )}"
}

resource "aws_s3_bucket_object" "bootstrap_ign" {
  depends_on = [
    "null_resource.generate_ignition_config"
  ]

  bucket = "${aws_s3_bucket.ocp_ignition.id}"
  key = "bootstrap.ign"
  content = "${data.local_file.bootstrap_ign.content}"
}