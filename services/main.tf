terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "maidsafe-org-infra-tfstate"
    key    = "terraform-testnet-infra-services.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_ecs_cluster" "testnet_infra" {
  name = "${terraform.workspace}-${var.testnet_infra_ecs_cluster_name}"
  service_connect_defaults {
    namespace = var.service_registry_arn
  }
}

resource "aws_ecs_task_definition" "data_prepper" {
  family                   = "${terraform.workspace}-opensearch-data-prepper"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = var.ecs_testnet_infra_iam_role_arn
  task_role_arn            = var.ecs_testnet_infra_iam_role_arn
  container_definitions    = <<TASK_DEFINITION
[
    {
        "name": "${terraform.workspace}-opensearch-data-prepper",
        "image": "opensearchproject/data-prepper:latest",
        "cpu": 0,
        "memoryReservation": 2048,
        "portMappings": [
            {
                "name": "data-prepper",
                "containerPort": 4900,
                "hostPort": 4900,
                "protocol": "tcp"
            }
        ],
        "essential": true,
        "entryPoint": [],
        "command": [],
        "environment": [],
        "mountPoints": [
            {
                "sourceVolume": "opensearch-data-prepper-config",
                "containerPath": "/usr/share/data-prepper/pipelines"
            }
        ],
        "volumesFrom": [],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/${terraform.workspace}-opensearch-data-prepper",
                "awslogs-region": "eu-west-2",
                "awslogs-stream-prefix": "ecs"
            }
        }
    }
]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  volume {
    name = "opensearch-data-prepper-config"
    efs_volume_configuration {
      file_system_id          = var.data_prepper_config_efs_id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      authorization_config {
        iam                   = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "data_prepper" {
  name            = "${terraform.workspace}-opensearch-data-prepper"
  cluster         = aws_ecs_cluster.testnet_infra.id
  task_definition = aws_ecs_task_definition.data_prepper.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.data_prepper_security_group_id]
    assign_public_ip = true
  }
  service_connect_configuration {
    enabled   = true
    namespace = var.service_registry_arn
    service {
      port_name      = "data-prepper"
      discovery_name = "${terraform.workspace}-opensearch-data-prepper"
      client_alias {
        dns_name     = "${terraform.workspace}-opensearch-data-prepper"
        port         = 4900
      }
    }
  }
}

resource "aws_ecs_task_definition" "telemetry_collector" {
  family                   = "${terraform.workspace}-opensearch-telemetry-collector"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = var.ecs_testnet_infra_iam_role_arn
  task_role_arn            = var.ecs_testnet_infra_iam_role_arn
  container_definitions    = <<TASK_DEFINITION
[
    {
        "name": "${terraform.workspace}-opensearch-telemetry-collector",
        "image": "otel/opentelemetry-collector:0.69.0",
        "cpu": 0,
        "memoryReservation": 2048,
        "portMappings": [
            {
                "name": "telemetry-collector",
                "containerPort": 4317,
                "hostPort": 4317,
                "protocol": "tcp"
            }
        ],
        "essential": true,
        "entryPoint": [],
        "command": [],
        "environment": [],
        "mountPoints": [
            {
                "sourceVolume": "opensearch-telemetry-collector-config",
                "containerPath": "/etc/otelcol"
            }
        ],
        "volumesFrom": [],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/${terraform.workspace}-opensearch-telemetry-collector",
                "awslogs-region": "eu-west-2",
                "awslogs-stream-prefix": "ecs"
            }
        }
    }
]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  volume {
    name = "opensearch-telemetry-collector-config"
    efs_volume_configuration {
      file_system_id          = var.telemetry_collector_config_efs_id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      authorization_config {
        iam                   = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "telemetry_collector" {
  name            = "${terraform.workspace}-opensearch-telemetry-collector"
  cluster         = aws_ecs_cluster.testnet_infra.id
  task_definition = aws_ecs_task_definition.telemetry_collector.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = var.telemetry_collector_target_group_arn
    container_port   = 4317
    container_name   = "${terraform.workspace}-opensearch-telemetry-collector"
  }
  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.telemetry_collector_security_group_id]
    assign_public_ip = true
  }
  service_connect_configuration {
    enabled   = true
    namespace = var.service_registry_arn
    service {
      port_name      = "telemetry-collector"
      discovery_name = "${terraform.workspace}-opensearch-telemetry-collector"
      client_alias {
        dns_name     = "${terraform.workspace}-opensearch-telemetry-collector"
        port         = 4317
      }
    }
  }
}
