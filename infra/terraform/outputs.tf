output "web_server_public_ip" {
  description = "Elastic IP of the web server"
  value       = aws_eip.web_server.public_ip
}

output "cloudtrail_s3_bucket" {
  description = "S3 bucket ARN storing CloudTrail logs"
  value       = module.cloudtrail.s3_bucket_arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.guardduty.detector_id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group ARN for Docker logs"
  value       = module.cloudwatch.log_group_arn
}
