output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "data_prepper_config_efs_id" {
  value = aws_efs_file_system.data_prepper_config.id
}

output "data_prepper_security_group_id" {
  value = aws_security_group.data_prepper.id
}

output "telemetry_collector_target_group_arn" {
  value = aws_lb_target_group.telemetry_collector.arn
}

output "telemetry_collector_config_efs_id" {
  value = aws_efs_file_system.telemetry_collector_config.id
}

output "telemetry_collector_security_group_id" {
  value = aws_security_group.telemetry_collector.id
}

output "data_prepper_service_registry_arn" {
  value = aws_service_discovery_service.data_prepper.arn
}
