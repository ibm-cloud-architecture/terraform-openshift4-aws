data "aws_ami" "rhcos" {
    most_recent = true

    owners = ["531415883065"]

    name_regex = "^rhcos-410\\.\\d{1}\\..*-hvm"
    filter {
        name = "name"
        values = ["rhcos-4*-hvm"]
    }

    filter {
        name = "image-id"
        values = ["${var.ami}"]
    }

    filter {
        name   = "architecture"
        values = ["x86_64"]
    }

    filter {
        name   = "image-type"
        values = ["machine"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

}