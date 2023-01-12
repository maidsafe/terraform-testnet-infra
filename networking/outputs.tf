output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "data_prepper_target_group_arn" {
  value = aws_lb_target_group.data_prepper.arn
}

output "data_prepper_config_efs_id" {
  value = aws_efs_file_system.data_prepper_config.id
}

output "testnet_infra_security_group_id" {
  value = aws_security_group.testnet_infra.id
}
