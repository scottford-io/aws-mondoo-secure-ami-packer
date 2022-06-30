data "aws_ami" "ubuntu-2004" {
  most_recent = true

  filter {
    name   = "name"
    values = ["mondoo-ubuntu-20.04-secure-base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["177043759486"]
}
