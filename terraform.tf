    ## main.tf

provider "aws" {
    region = var.region
}

resource "aws_instance" "ec2" {
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = "tws-volumes-key"
    user_data = <<-EOF
        #!/bin/bash
        apt update -y
        apt install nginx -y
        systemctl start nginx
        systemctl enable nginx
    EOF
    vpc_security_group_ids = [aws_security_group.my-sg1.id]
    tags = {
        Name = "my-ec2"
    }
}

resource "aws_security_group" "my-sg1" {
    name = "my-sg1"
    description = "SSH and HTTP are allowed"
    vpc_id = "vpc-0df645a043bb0465e"

    ingress {
        from_port = 22
        to_port = 22 
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "region" {
      default = "us-east-1"
}
variable "ami_id" {
      default = "ami-0b6d9d3d33ba97d99"
}
variable "instance_type" {
      default = "t3.micro"
}


