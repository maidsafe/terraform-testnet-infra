output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "testnet_infra_security_group_id" {
  value = aws_security_group.testnet.id
}
