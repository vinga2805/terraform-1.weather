resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags {
        Name = "terraform-aws-vpc"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
}

/*
  NAT Instance
*/
resource "aws_security_group" "nat" {
    name = "vpc_nat"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "NATSG"
    }
}

resource "aws_instance" "nat" {
    ami = "ami-30913f47" # this is a special ami preconfigured to do NAT
    availability_zone = "eu-west-1a"
    instance_type = "m1.small"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.nat.id}"]
    subnet_id = "${aws_subnet.eu-west-1a-public.id}"
    associate_public_ip_address = true
    source_dest_check = false

    tags {
        Name = "VPC NAT"
    }
}

resource "aws_eip" "nat" {
    instance = "${aws_instance.nat.id}"
    vpc = true
}

/*
  Public Subnet
*/
resource "aws_subnet" "eu-west-1a-public" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "eu-west-1a"

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_route_table" "eu-west-1a-public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_route_table_association" "eu-west-1a-public" {
    subnet_id = "${aws_subnet.eu-west-1a-public.id}"
    route_table_id = "${aws_route_table.eu-west-1a-public.id}"
}

/*
  Private Subnet
*/
resource "aws_subnet" "eu-west-1a-private" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.private_subnet_cidr}"
    availability_zone = "eu-west-1a"

    tags {
        Name = "Private Subnet"
    }
}

resource "aws_route_table" "eu-west-1a-private" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }

    tags {
        Name = "Private Subnet"
    }
}

resource "aws_route_table_association" "eu-west-1a-private" {
    subnet_id = "${aws_subnet.eu-west-1a-private.id}"
    route_table_id = "${aws_route_table.eu-west-1a-private.id}"
}

#  1.weather Util ASG 
# ------------------------------------------------------

### Creating Security Group for EC2
data "aws_availability_zones" "all" {}
resource "aws_security_group" "instance" {
  name = "weather-SG"
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.default.id}"
}

#  1.weather Util ASG
# ------------------------------------------------------
resource "aws_launch_configuration" "1-weather_util_lc" {
  name = "${var.env}-${var.platform}-1-weather-util-20180605"

  image_id             = "ami-ca0135b3"
  instance_type        = "t2.micro"
#  iam_instance_profile = "${aws_iam_instance_profile.cassandra_profile.name}"
  key_name             = "${var.aws_key_name}"
  security_groups = ["${aws_security_group.instance.id}"]
  root_block_device = [
    {
      volume_size = "8"
      volume_type = "gp2"
    },
  ]
}

resource "aws_autoscaling_group" "1-weather_util_asg" {
  name                = "${var.env}-${var.platform}-1-weather-util"
#  vpc_zone_identifier = ["${var.public_subnet_cidr}"]
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  suspended_processes  = ["AZRebalance"]
  termination_policies = ["OldestLaunchConfiguration", "OldestInstance"]

  min_size                  = 1
  max_size                  = 1
  wait_for_capacity_timeout = 0

  launch_configuration = "${aws_launch_configuration.1-weather_util_lc.name}"
  enabled_metrics      = ["GroupInServiceInstances", "GroupTerminatingInstances", "GroupPendingInstances", "GroupDesiredCapacity", "GroupStandbyInstances", "GroupMinSize", "GroupMaxSize", "GroupTotalInstances"]
  health_check_type    = "EC2"

}
