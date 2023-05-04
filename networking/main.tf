terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    key    = "terraform-testnet-infra-networking.tfstate"
  }
}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.18.0"
  name                 = "${terraform.workspace}-${var.testnet_infra_vpc_name}"
  cidr                 = "10.0.0.0/16"
  azs                  = var.availability_zones
  public_subnets       = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets      = ["10.0.2.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

#
# Security group and network ACLs for debugging and working with the EFS mounts
#
resource "aws_security_group" "testnet" {
  name        = "${terraform.workspace}-testnet-infra"
  description = "Use for launching EC2 instances for populating EFS mounts and testing"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "testnet_infra_ssh_ingress" {
  type              = "ingress"
  description       = "Permits inbound SSH access"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_infra_nfs_ingress" {
  type              = "ingress"
  description       = "Permits inbound NFS traffic for the EFS volume attachment"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_infra_nfs_egress" {
  type              = "egress"
  description       = "Permits outbound NFS traffic for the EFS volume attachment"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_infra_https_egress" {
  type              = "egress"
  description       = "Permits HTTPS internet access for debugging and testing"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_data_prepper_egress" {
  type              = "egress"
  description       = "Permits access to the Data Prepper service"
  from_port         = 4317
  to_port           = 4317
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_sn_node_egress" {
  type              = "egress"
  description       = "Permits outbound access for Safe Node"
  from_port         = 12000
  to_port           = 12000
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_infra_http_egress" {
  type              = "egress"
  description       = "Permits HTTP internet access for debugging and testing"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_infra_data_prepper_http_egress" {
  type              = "egress"
  description       = "Permits TCP access to the Data Prepper"
  from_port         = 4900
  to_port           = 4900
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_infra_data_prepper_egress" {
  type              = "egress"
  description       = "Permits TCP access to the Data Prepper"
  from_port         = 21890
  to_port           = 21890
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_sn_node_ingress" {
  type              = "ingress"
  description       = "Permits inbound access for Safe Node"
  from_port         = 12000
  to_port           = 12000
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}

resource "aws_security_group_rule" "testnet_sn_node_rpc_admin_ingress" {
  type              = "ingress"
  description       = "Permits inbound access for Safe Node RCP admin"
  from_port         = 12001
  to_port           = 12001
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet.id
}
