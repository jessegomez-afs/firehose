variable "splunk_hec_endpoint" {
  description = "Splunk HEC endpoint URL"
  type        = string
  default     = "https://your-splunk-instance:8088/services/collector" # Replace
}

variable "splunk_hec_token" {
  description = "Splunk HEC token"
  type        = string
  sensitive   = true
  default     = "your-hec-token-here" # Replace
}

variable "cloudwatch_log_group" {
  description = "CloudWatch Log Group name"
  type        = string
  default     = "/aws/lambda/my-function" # Replace
}

variable "s3_backup_bucket" {
  description = "S3 bucket for failed log backup"
  type        = string
  default     = "splunk-cw-logs-backup"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1" # Adjust to your region
}
