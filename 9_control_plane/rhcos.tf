data "aws_ami" "rhcos" {
    most_recent = true

    owners = ["531415883065"]


    filter {
        name = "image-id"
        values = ["${var.ami}"]
    }

}
