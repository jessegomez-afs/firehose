variable "splunk_hec_endpoint" {
  description = "Splunk HEC endpoint URL"
  type        = string
  # default     = "https://your-splunk-instance:8088/services/collector" # Replace
  default     = "https://localhost:8000/services/collector" # Replace
}

variable "splunk_hec_token" {
  description = "Splunk HEC token"
  type        = string
  sensitive   = true
  # default     = "your-hec-token-here" # Replace
  default     = "c44dd184-0d31-41d8-84d4-3c4b8008727a" # Replace
}

variable "cloudwatch_log_group" {
  description = "CloudWatch Log Group name"
  type        = string
  # default     = "/aws/lambda/my-function" # Replace
  default     = "/aws/kinesisfirehose/kinesis-test-stream" # Replace
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
