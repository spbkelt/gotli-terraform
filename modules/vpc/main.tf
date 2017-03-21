data "aws_route_table" "kube_public" {
  subnet_id = "${aws_subnet.kube_public.id}"
}

data "aws_route_table" "kube_private" {
  subnet_id = "${aws_subnet.kube_private.id}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "kubernetes" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags {
    Name = "kubernetes"
    KubernetesCluster = "${var.aws_region}"
  }
}

# Create a public subnet to launch our bastion ssh instance, and IpSec VPN
resource "aws_subnet" "kube_public" {
  vpc_id                  = "${aws_vpc.kubernetes.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "kube_public"
    KubernetesCluster = "${var.aws_region}"
  }
}

# Create a private  subnet to launch all our backend instances
resource "aws_subnet" "kube_private"{
  vpc_id                  = "${aws_vpc.kubernetes.id}"
  cidr_block              = "10.0.1.0/24"

  tags {
    Name = "kube_private"
    KubernetesCluster = "${var.aws_region}"
  }
}

# Create an internet gateway to give our public subnet access to the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.kubernetes.id}"

  tags {
    Name = "kubernetes"
    KubernetesCluster = "${var.aws_region}"
  }
}

#Create Elatic IP for NAT gateway allocation
resource "aws_eip" "nat" {
  vpc      = true
}

#Create NAT gateway to give our private subnet access to the outside world. Allocate EIP with NAT gateway
resource "aws_nat_gateway" "nat_gw" {
    allocation_id = "${aws_eip.nat.id}"
    subnet_id = "${aws_subnet.kube_public.id}"
}

resource "aws_route_table" "kube_public" {
  vpc_id = "${aws_vpc.kubernetes.id}"

  tags {
       Name = "kube_public"
       Role = "Main"
       KubernetesCluster = "${var.aws_region}"
   }
}

resource "aws_route_table" "kube_private" {
  vpc_id = "${aws_vpc.kubernetes.id}"

  tags {
       Name = "kube_private"
       KubernetesCluster = "${var.aws_region}"
   }
}

resource "aws_route_table_association" "kube_public" {
    subnet_id = "${aws_subnet.kube_public.id}"
    route_table_id = "${aws_route_table.kube_public.id}"
}

resource "aws_route_table_association" "kube_private" {
    subnet_id = "${aws_subnet.kube_private.id}"
    route_table_id = "${aws_route_table.kube_private.id}"

}



# Grant the VPC internet access on its main route table
resource "aws_route" "kube_public" {
  route_table_id         = "${data.aws_route_table.kube_public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.gw.id}"

}

# Grant the VPC internet access on its main route table
resource "aws_route" "kube_private" {
  route_table_id         = "${data.aws_route_table.kube_private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat_gw.id}"
}


# Our kubernetes security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "kubernetes" {
  name        = "kubernetes"
  description = "Allow VPC internal traffic. Used for all EC2 instances"
  vpc_id      = "${aws_vpc.kubernetes.id}"

  #Access from the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "kubernetes"
    KubernetesCluster = "${var.aws_region}"
  }
}

resource "aws_security_group" "ssh_public" {
  name        = "ssh_public"
  description = "Used for ssh access from public subnet to private"
  vpc_id      = "${aws_vpc.kubernetes.id}"

  #Access from the VPC only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ssh_public"
    KubernetesCluster = "${var.aws_region}"
  }

}

resource "aws_security_group" "ssh_private" {
  name        = "ssh_private"
  description = "Used for ssh access from public subnet to private"
  vpc_id      = "${aws_vpc.kubernetes.id}"

  #Access from the VPC only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ssh_private"
    KubernetesCluster = "${var.aws_region}"
  }
}

resource "aws_security_group" "etcd" {
  name        = "etcd access security group"
  description = "Used for etcd access from VPC"
  vpc_id      = "${aws_vpc.kubernetes.id}"

  #Access from the VPC only
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 4001
    to_port     = 4001
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }


  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "etcd"
    KubernetesCluster = "${var.aws_region}"
  }
}
