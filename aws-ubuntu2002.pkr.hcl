packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
    cnspec = {
      version = ">= 9.0.0"
      source  = "github.com/mondoohq/cnspec"
    }
  }
}


variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "image_prefix" {
  type        = string
  description = "Prefix to be applied to image name"
  default     = "mondoo-ubuntu-20.04-secure-base"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "ubuntu2004" {
  ami_name      = "${var.image_prefix}-${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.aws_region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  tags = {
    Base_AMI_Name = "{{ .SourceAMIName }}"
    Name          = "${var.image_prefix}-${local.timestamp}"
    Source_AMI    = "{{ .SourceAMI }}"
    Creation_Date = "{{ .SourceAMICreationDate }}"
    GitRepo       = "https://github.com/scottford-io/aws-mondoo-secure-ami-packer"
  }
}

build {
  name = "mondoo-ubuntu-2004-secure-base"

  sources = [
    "source.amazon-ebs.ubuntu2004"
  ]

  provisioner "shell" {
    inline = [
      "sudo hostnamectl set-hostname ${var.image_prefix}-${local.timestamp}",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt purge telnet -y",
      "sudo apt purge rsync -y",
      "sudo sysctl -w net.ipv4.conf.all.accept_redirects=0",
      "sudo sysctl -w net.ipv4.conf.default.accept_redirects=0",
      "sudo sysctl -w net.ipv4.conf.all.accept_source_route=0",
      "sudo sysctl -w net.ipv4.conf.default.accept_source_route=0",
      "sudo sysctl -w net.ipv4.conf.all.send_redirects=0",
      "sudo sysctl -w net.ipv4.conf.default.send_redirects=0",
      "sudo sysctl -w net.ipv4.conf.all.secure_redirects=0",
      "sudo sysctl -w net.ipv4.conf.default.secure_redirects=0",
      "sudo sysctl -w net.ipv4.conf.all.log_martians=1",
      "sudo sysctl -w net.ipv4.conf.default.log_martians=1",
      "sudo sysctl -w net.ipv4.conf.all.rp_filter=1",
      "sudo sysctl -w net.ipv4.conf.default.rp_filter=1",
      "sudo sysctl -w net.ipv6.conf.all.accept_ra=0",
      "sudo sysctl -w net.ipv6.conf.default.accept_ra=0",
      "sudo sysctl -w net.ipv4.route.flush=1",
      "sudo chmod u-x,g-wx,o-rwx /etc/shadow",
      "sudo chmod u-x,g-wx,o-rwx /etc/shadow-",
      "sudo chown root:root /etc/gshadow-",
      "sudo chown root:root /etc/shadow",
      "sudo chown root:root /etc/shadow-",
    ]
  }

  provisioner "cnspec" {
    on_failure = "continue"
    asset_name = "${var.image_prefix}-${local.timestamp}"
    sudo {
      active = true
    }
    annotations = {
      Name          = "${var.image_prefix}-${local.timestamp}"
      GitRepo       = "https://github.com/scottford-io/aws-mondoo-secure-ami-packer"
      Creation_Date = "{{ .SourceAMICreationDate }}"
    }
  }
}
