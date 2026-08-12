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

## PROJECT 

provider "aws" {
    region = "us-east-1"

}
resource "aws_launch_template" "home-temp" {
    name   = "home-temp"
    image_id      = "ami-0b6d9d3d33ba97d99"
    instance_type = "t3.micro"
    key_name      = "tws-volumes-key"
    vpc_security_group_ids = ["sg-0e76dde5b18c51600"]
    user_data     = base64encode(<<-EOF
        #!/bin/bash
        apt update -y
        apt install nginx -y
        systemctl start nginx
        systemctl enable nginx
        echo "<h1>HELLOW FROM WELCOME PAGE</h1>" | tee /var/www/html/index.html
    EOF
    )

    tags = {
        Name = "home-temp"
    }
  
}

resource "aws_launch_template" "cloth-temp" {
    name   = "cloth-temp"
    image_id      = "ami-0b6d9d3d33ba97d99"
    instance_type = "t3.micro"
    key_name      = "tws-volumes-key"
    vpc_security_group_ids = ["sg-0e76dde5b18c51600"]
    user_data     = base64encode(<<-EOF
        #!/bin/bash
        apt update -y
        apt install nginx -y
        systemctl start nginx
        systemctl enable nginx
        echo "<h1>SALE! SALE!! SALE!!!</h1>" | tee /var/www/html/index.html
    EOF
    )

    tags = {
        Name = "cloth-temp"
    }
  
}

 resource "aws_autoscaling_group" "home-asg" {
        name                      = "home-asg"
        availability_zones       = ["us-east-1a", "us-east-1b"]
        max_size                  = 1
        min_size                  = 1
        desired_capacity          = 1
        health_check_type = "EC2"
        launch_template {
            id      = aws_launch_template.home-temp.id
            version = "$Latest"
        }
    }

 resource "aws_autoscaling_group" "cloth-asg" {
        name                      = "cloth-asg"
        availability_zones       = ["us-east-1a", "us-east-1b"]
        max_size                  = 1
        min_size                  = 1
        desired_capacity          = 1
        health_check_type = "EC2"
    
        launch_template {
            id      = aws_launch_template.cloth-temp.id
            version = "$Latest"
        }
    }


resource "aws_autoscaling_policy" "home-scale-down" {
        name                   = "home-scale-down"
        autoscaling_group_name = aws_autoscaling_group.home-asg.name
        adjustment_type        = "ChangeInCapacity"
        scaling_adjustment     = -1 
        cooldown               = 120

      
    }

resource "aws_cloudwatch_metric_alarm" "home-alarms" {
        alarm_description          = "Alarm when CPU exceeds"
        alarm_actions              = [aws_autoscaling_policy.home-scale-down.arn]
        alarm_name                 = "home-alarms"
        comparison_operator        = "LessThanOrEqualToThreshold"
        namespace                  = "AWS/EC2"
        metric_name                = "CPUUtilization"
        threshold                  = "25"
        evaluation_periods          = "5"
        period                     = "30"
        statistic                  = "Average"

        dimensions = {
            AutoScalingGroupName = aws_autoscaling_group.home-asg.name
        }       

      
    }

resource "aws_autoscaling_policy" "cloth-scale-down" {
        name                   = "cloth-scale-down"
        autoscaling_group_name = aws_autoscaling_group.cloth-asg.name
        adjustment_type        = "ChangeInCapacity"
        scaling_adjustment     = -1 
        cooldown               = 120

      
    }

resource "aws_cloudwatch_metric_alarm" "cloth-alarms" {
        alarm_description          = "Alarm when CPU exceeds"
        alarm_actions              = [aws_autoscaling_policy.cloth-scale-down.arn]
        alarm_name                 = "cloth-alarms"
        comparison_operator        = "LessThanOrEqualToThreshold"
        namespace                  = "AWS/EC2"
        metric_name                = "CPUUtilization"
        threshold                  = "25"
        evaluation_periods          = "5"
        period                     = "30"
        statistic                  = "Average"

        dimensions = {
            AutoScalingGroupName = aws_autoscaling_group.cloth-asg.name
        }       

      
    }

resource "aws_lb_target_group" "home-tg" {
        name     = "home-tg"
        port     = 80
        protocol = "HTTP"
        vpc_id   = "vpc-0df645a043bb0465e"
    }

resource "aws_lb_target_group" "cloth-tg" {
        name     = "cloth-tg"
        port     = 80
        protocol = "HTTP"
        vpc_id   = "vpc-0df645a043bb0465e"
    }

resource "aws_autoscaling_attachment" "home-attach" {
        autoscaling_group_name = aws_autoscaling_group.home-asg.id
        lb_target_group_arn   = aws_lb_target_group.home-tg.arn
      
    }

resource "aws_autoscaling_attachment" "cloth-attach" {
        autoscaling_group_name = aws_autoscaling_group.cloth-asg.id
        lb_target_group_arn   = aws_lb_target_group.cloth-tg.arn
      
    }

resource "aws_lb" "alb" {
      name = "alb"
        internal = false
        load_balancer_type = "application"
        security_groups = ["sg-0e76dde5b18c51600"]
        subnets = ["subnet-05cdbff013b50d835", "subnet-0c162191b5a2c9111"]  
        tags = {
          Environment = "prod"
        }

    }
resource "aws_lb_listener" "my-listener" {
      load_balancer_arn = aws_lb.alb.arn
      port              = "80"
      protocol          = "HTTP"

      default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.home-tg.arn
      }
    } 


resource "aws_lb_listener_rule" "cloth-rule" {
    listener_arn = aws_lb_listener.my-listener.arn
    priority     = 10

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.cloth-tg.arn
      }
    

    condition {
        path_pattern {
          values = ["/cloth/*"]
       }
    }

}

