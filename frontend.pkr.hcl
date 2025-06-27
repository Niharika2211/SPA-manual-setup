packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "amz3_gp3" {
  ami_name      = "minifrntd-{{timestamp}}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023*"
      architecture        = "x86_64"
      root-device-type    = "ebs"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  
  ssh_username  = "ec2-user"
  # Adding tags to the AMI
  tags = {
    Name        = "frontmini-packer-image"
    Environment = "Development"
    Owner       = "niha"
    CreatedBy   = "Packer"
    Monitor     = "true"
  }
}

build {
  name    = "frontend"
  sources = ["source.amazon-ebs.amz3_gp3"]

  provisioner "file" {
    source      = "frontend.sh"
    destination = "/tmp/frontend.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/frontend.sh",
      "sudo /tmp/frontend.sh"
    ]
  }
}
