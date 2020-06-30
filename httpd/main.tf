variable "main_port" {
  description = "Server port for HTTP requests."
  default = 8080
}

provider "aws" {
  region = "eu-west-1"
}

data "template_file" "start_script" {
  template = "${file("server_run.sh")}"
  vars = {
    port = "${var.main_port}"
  }
}

resource "aws_security_group" "instance" {
  name = "server-security-group"

  # first server
  ingress {
    from_port = "${var.main_port}"
    to_port = "${var.main_port}"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "source" {
  image_id = "ami-f90a4880"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = "${data.template_file.start_script.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "source" {
  launch_configuration = "${aws_launch_configuration.source.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  load_balancers = ["${aws_elb.source.name}"]
  health_check_type = "ELB"
  max_size = 2
  min_size = 2

  tag {
    key = "Name"
    value = "asg-source"
    propagate_at_launch = true
  }
}

resource "aws_elb" "source" {
  name = "elb-source"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.main_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 15
    target = "HTTP:${var.main_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-source-elb-security"

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

output "public_ip" { 
  value = "${aws_elb.source.dns_name}" 
}
