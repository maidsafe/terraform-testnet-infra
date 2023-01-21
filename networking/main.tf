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

resource "aws_service_discovery_private_dns_namespace" "testnet_infra" {
  name        = "${terraform.workspace}-testnet-infra.local"
  description = "Service discovery for the Telemetry Collector and Data Prepper services"
  vpc         = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "data_prepper" {
  name = "data-prepper"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.testnet_infra.id
    dns_records {
      ttl = 10
      type = "A"
    }
  }
}

#
# Security group and network ACLs for debugging and working with the EFS mounts
#
resource "aws_security_group" "debugging" {
  name        = "${terraform.workspace}-testnet-infra-debugging"
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
  security_group_id = aws_security_group.debugging.id
}

resource "aws_security_group_rule" "testnet_infra_nfs_ingress" {
  type              = "ingress"
  description       = "Permits inbound NFS traffic for the EFS volume attachment"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.debugging.id
}

resource "aws_security_group_rule" "testnet_infra_nfs_egress" {
  type              = "egress"
  description       = "Permits outbound NFS traffic for the EFS volume attachment"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.debugging.id
}

resource "aws_security_group_rule" "testnet_infra_https_egress" {
  type              = "egress"
  description       = "Permits HTTPS internet access for debugging and testing"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.debugging.id
}

resource "aws_security_group_rule" "testnet_infra_http_egress" {
  type              = "egress"
  description       = "Permits HTTP internet access for debugging and testing"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.debugging.id
}

resource "aws_security_group_rule" "testnet_infra_data_prepper_http_egress" {
  type              = "egress"
  description       = "Permits TCP access to the Data Prepper"
  from_port         = 4900
  to_port           = 4900
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.debugging.id
}

resource "aws_security_group_rule" "testnet_infra_data_prepper_egress" {
  type              = "egress"
  description       = "Permits TCP access to the Data Prepper"
  from_port         = 21890
  to_port           = 21890
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.debugging.id
}

#
# Security group and network ACLs for the Data Prepper service
#
resource "aws_security_group" "data_prepper" {
  name        = "${terraform.workspace}-${var.data_prepper_security_group_name}"
  description = "Connectivity for the Data Prepper services."
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "telemetry_collector_data_prepper_http_ingress" {
  type                     = "ingress"
  description              = "Permits inbound Telemetry Collector traffic access to the Data Prepper"
  from_port                = 4900
  to_port                  = 4900
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.telemetry_collector.id
  security_group_id        = aws_security_group.data_prepper.id
}

resource "aws_security_group_rule" "telemetry_collector_data_prepper_ingress" {
  type                     = "ingress"
  description              = "Permits inbound debugging traffic access to the Data Prepper"
  from_port                = 21890
  to_port                  = 21890
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.telemetry_collector.id
  security_group_id        = aws_security_group.data_prepper.id
}

resource "aws_security_group_rule" "debugging_data_prepper_http_ingress" {
  type                     = "ingress"
  description              = "Permits inbound debugging traffic access to the Data Prepper"
  from_port                = 4900
  to_port                  = 4900
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.debugging.id
  security_group_id        = aws_security_group.data_prepper.id
}

resource "aws_security_group_rule" "debugging_data_prepper_ingress" {
  type                     = "ingress"
  description              = "Permits inbound debugging traffic access to the Data Prepper"
  from_port                = 21890
  to_port                  = 21890
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.debugging.id
  security_group_id        = aws_security_group.data_prepper.id
}

resource "aws_security_group_rule" "data_prepper_nfs_ingress" {
  type              = "ingress"
  description       = "Permits inbound NFS traffic for the EFS volume attachment"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.data_prepper.id
}

resource "aws_security_group_rule" "data_prepper_nfs_egress" {
  type              = "egress"
  description       = "Permits outbound NFS traffic for the EFS volume attachment"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.data_prepper.id
}

resource "aws_security_group_rule" "data_prepper_https_egress" {
  type              = "egress"
  description       = "Permits HTTPS internet access for pulling the container"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.data_prepper.id
}

resource "aws_security_group_rule" "data_prepper_http_egress" {
  type              = "egress"
  description       = "Permits HTTP internet access for pulling the container"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.data_prepper.id
}

#
# Security group and network ACLs for the Telemetry Collector service
#
resource "aws_security_group" "telemetry_collector" {
  name        = "${terraform.workspace}-${var.telemetry_collector_security_group_name}"
  description = "Connectivity for the Telemetry Collector services."
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "telemetry_collector_nfs_ingress" {
  type              = "ingress"
  description       = "Permits inbound NFS traffic for the EFS volume attachment"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.telemetry_collector.id
}

resource "aws_security_group_rule" "telemetry_collector_nfs_egress" {
  type              = "egress"
  description       = "Permits outbound NFS traffic for the EFS volume attachment"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.telemetry_collector.id
}

resource "aws_security_group_rule" "telemetry_collector_data_prepper_http_egress" {
  type                     = "egress"
  description              = "Permits outbound Telemetry Collector traffic access to the Data Prepper"
  from_port                = 4900
  to_port                  = 4900
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.data_prepper.id
  security_group_id        = aws_security_group.telemetry_collector.id
}

resource "aws_security_group_rule" "telemetry_collector_data_prepper_egress" {
  type                     = "egress"
  description              = "Permits outbound Telemetry Collector traffic access to the Data Prepper"
  from_port                = 21890
  to_port                  = 21890
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.data_prepper.id
  security_group_id        = aws_security_group.telemetry_collector.id
}

resource "aws_security_group_rule" "telemetry_collector_grpc" {
  type              = "ingress"
  description       = "Permits inbound public access to the Telemetry Collector"
  from_port         = 4317
  to_port           = 4317
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.telemetry_collector.id
}

resource "aws_security_group_rule" "telemetry_collector_https_egress" {
  type              = "egress"
  description       = "Permits HTTPS internet access for pulling the container"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.telemetry_collector.id
}

resource "aws_security_group_rule" "telemetry_collector_http_egress" {
  type              = "egress"
  description       = "Permits HTTP internet access for pulling the container"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.telemetry_collector.id
}

resource "aws_lb" "testnet_infra" {
  name               = "${terraform.workspace}-${var.testnet_infra_lb_name}"
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "telemetry_collector" {
  name        = "${terraform.workspace}-telemetry-collector"
  target_type = "ip"
  port        = 4317
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_lb_listener" "telemetry_collector" {
  load_balancer_arn = aws_lb.testnet_infra.arn
  port              = "4317"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.telemetry_collector.arn
  }
}

#
# The EFS file system for the Data Prepper service
#
resource "aws_efs_file_system" "data_prepper_config" {
  encrypted = true
  tags = {
    Name = "${terraform.workspace}-data_prepper_config"
  }
}

resource "aws_efs_mount_target" "data_prepper_config_public_subnet" {
  file_system_id  = aws_efs_file_system.data_prepper_config.id
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.data_prepper.id, aws_security_group.debugging.id]
}

resource "aws_efs_mount_target" "data_prepper_config_public_subnet2" {
  file_system_id  = aws_efs_file_system.data_prepper_config.id
  subnet_id       = module.vpc.public_subnets[1]
  security_groups = [aws_security_group.data_prepper.id, aws_security_group.debugging.id]
}

resource "aws_cloudwatch_log_group" "data_prepper" {
  name = "/ecs/${terraform.workspace}-opensearch-data-prepper"
}

#
# The EFS file system for the Telemetry Collector service
#
resource "aws_efs_file_system" "telemetry_collector_config" {
  encrypted = true
  tags = {
    Name = "${terraform.workspace}-telemetry_collector_config"
  }
}

resource "aws_efs_mount_target" "telemetry_collector_config_public_subnet" {
  file_system_id  = aws_efs_file_system.telemetry_collector_config.id
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.telemetry_collector.id, aws_security_group.debugging.id]
}

resource "aws_efs_mount_target" "telemetry_collector_config_public_subnet2" {
  file_system_id  = aws_efs_file_system.telemetry_collector_config.id
  subnet_id       = module.vpc.public_subnets[1]
  security_groups = [aws_security_group.telemetry_collector.id, aws_security_group.debugging.id]
}

resource "aws_cloudwatch_log_group" "telemetry_collector" {
  name = "/ecs/${terraform.workspace}-opensearch-telemetry-collector"
}
