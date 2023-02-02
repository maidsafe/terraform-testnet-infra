variable "vpc_name" {
  default = "elastic"
  description = "The name for the VPC for hosting the APM server"
}

variable "availability_zones" {
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  description = "The availability zones to use"
}

variable "master_user_name" {
  default = "elastic"
  description = "The username for the master elastic user"
}

variable "master_user_password" {
  description = "The password for the master elastic user"
}

variable "instance_type" {
  default = "m6g.2xlarge.search"
  description = "The type of instance to be used to run the OpenSearch nodes"
}

variable "instance_count" {
  default = 2
  description = "The number of OpenSearch nodes"
}

variable "domain_name" {
  default = "testnet-infra"
  description = "The name for the testnet_dev domain"
}

variable "opensearch_version" {
  default = "OpenSearch_2.3"
  description = "The OpenSearch version"
}
