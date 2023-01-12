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
  load_balancer {
    target_group_arn = var.data_prepper_target_group_arn
    container_port   = 4900
    container_name   = "${terraform.workspace}-opensearch-data-prepper"
  }
  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.testnet_infra_security_group_id]
    assign_public_ip = true
  }
}
