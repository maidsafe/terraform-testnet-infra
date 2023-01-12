terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "maidsafe-org-infra-tfstate"
    key    = "terraform-testnet-infra-networking.tfstate"
    region = "eu-west-2"
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

resource "aws_security_group" "testnet_infra" {
  name        = "${terraform.workspace}-${var.testnet_infra_security_group_name}"
  description = "Connectivity for Elastic-related services."
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "testnet_infra_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet_infra.id
}

resource "aws_security_group_rule" "testnet_infra_nfs_ingress" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet_infra.id
}

resource "aws_security_group_rule" "testnet_infra_nfs_egress" {
  type              = "egress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet_infra.id
}

resource "aws_security_group_rule" "testnet_infra_data_prepper_ingress" {
  type              = "ingress"
  from_port         = 4900
  to_port           = 4900
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet_infra.id
}

resource "aws_security_group_rule" "testnet_infra_https_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet_infra.id
}

resource "aws_security_group_rule" "testnet_infra_http_egress" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testnet_infra.id
}

resource "aws_lb" "testnet_infra" {
  name               = "${terraform.workspace}-${var.testnet_infra_lb_name}"
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "data_prepper" {
  name        = "${terraform.workspace}-data-prepper"
  target_type = "ip"
  port        = 4900
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_lb_listener" "data_prepper" {
  load_balancer_arn = aws_lb.testnet_infra.arn
  port              = "4900"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.data_prepper.arn
  }
}

resource "aws_efs_file_system" "data_prepper_config" {
  encrypted = true
  tags = {
    Name = "${terraform.workspace}-data_prepper_config"
  }
}

resource "aws_efs_mount_target" "data_prepper_config_public_subnet" {
  file_system_id  = aws_efs_file_system.data_prepper_config.id
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.testnet_infra.id]
}

resource "aws_efs_mount_target" "data_prepper_config_public_subnet2" {
  file_system_id  = aws_efs_file_system.data_prepper_config.id
  subnet_id       = module.vpc.public_subnets[1]
  security_groups = [aws_security_group.testnet_infra.id]
}

resource "aws_cloudwatch_log_group" "data_prepper" {
  name = "/ecs/${terraform.workspace}-opensearch-data-prepper"
}
