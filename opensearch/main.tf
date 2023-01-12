terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "maidsafe-org-infra-tfstate"
    key    = "terraform-testnet-infra-opensearch.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_cloudwatch_log_group" "testnet_elasticsearch" {
  name = "${var.domain_name}-${terraform.workspace}"
}

resource "aws_cloudwatch_log_resource_policy" "testnet_elasticsearch" {
  policy_name = "${var.domain_name}-${terraform.workspace}"

  policy_document = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ],
      "Resource": "arn:aws:logs:*"
    }
  ]
}
CONFIG
}

resource "aws_opensearch_domain" "testnet_dev" {
  domain_name = "${var.domain_name}-${terraform.workspace}"

  engine_version = var.opensearch_version

  advanced_security_options {
    enabled = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name = var.master_user_name
      master_user_password = var.master_user_password
    }
  }

  cluster_config {
    instance_type = var.instance_type
    instance_count = var.instance_count
  }

  domain_endpoint_options {
    enforce_https = true
    tls_security_policy = "Policy-Min-TLS-1-0-2019-07"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }
}

resource "aws_elasticsearch_domain_policy" "access_kibana_and_put_data" {
  domain_name   = aws_opensearch_domain.testnet_dev.domain_name
  access_policies        = <<POLICIES
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "${aws_opensearch_domain.testnet_dev.arn}/*"
    }
  ]
}
POLICIES
}
