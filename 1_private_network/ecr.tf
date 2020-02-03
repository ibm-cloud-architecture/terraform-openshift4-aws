resource "aws_ecr_repository" "ocp4" {
  count = var.airgapped ? 1 : 0
  name                 = local.infrastructure_id
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
