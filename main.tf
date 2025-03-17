terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }
}

# Data block for account ID
data "aws_caller_identity" "current" {}

# S3 Bucket for Backup
resource "aws_s3_bucket" "backup" {
  bucket = var.s3_backup_bucket
  force_destroy = true
}

# S3 Bucket Policy (Replaces ACL)
resource "aws_s3_bucket_policy" "backup_policy" {
  bucket = aws_s3_bucket.backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.firehose_role.arn
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.backup.arn}/*"
      }
    ]
  })
}

# Optional: Enforce Bucket Owner Control
resource "aws_s3_bucket_ownership_controls" "backup_ownership" {
  bucket = aws_s3_bucket.backup.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# IAM Role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "firehose_to_splunk_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  role = aws_iam_role.firehose_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.backup.arn}",
          "${aws_s3_bucket.backup.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:InvokeAsync"
        ]
        Resource = "${aws_lambda_function.transformer.arn}*"
      },
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch",
          "firehose:DescribeDeliveryStream",
          "firehose:UpdateDestination",
          "firehose:CreateDeliveryStream"
        ]
        Resource = "arn:aws:firehose:${var.aws_region}:${data.aws_caller_identity.current.account_id}:delivery-stream/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/CWLogsToSplunkStream:*"
      }
    ]
  })
}

# Lambda Function for Transformation
resource "aws_lambda_function" "transformer" {
  filename      = "lambda.zip"
  function_name = "CWLogsToSplunkTransformer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  source_code_hash = filebase64sha256("lambda.zip")
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_transformer_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Firehose Delivery Stream
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name = var.cloudwatch_log_group
  retention_in_days = 7
}

# Firehose Delivery Stream (without Lambda processing for now)
resource "aws_cloudwatch_log_group" "firehose_debug_log_group" {
  name = "/aws/kinesisfirehose/CWLogsToSplunkStream"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "firehose_debug_log_stream" {
  name           = "SplunkDelivery"
  log_group_name = aws_cloudwatch_log_group.firehose_debug_log_group.name
}

resource "aws_kinesis_firehose_delivery_stream" "splunk_stream" {
  name        = "CWLogsToSplunkStream"
  destination = "splunk"

  splunk_configuration {
    hec_endpoint           = var.splunk_hec_endpoint
    hec_token              = var.splunk_hec_token
    hec_endpoint_type      = "Event"
    hec_acknowledgment_timeout = 300
    retry_duration         = 300
    buffering_size         = 1
    buffering_interval     = 60
    s3_backup_mode         = "FailedEventsOnly"
    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = aws_s3_bucket.backup.arn
      prefix             = "failed-logs/"
    }
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_debug_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_debug_log_stream.name
    }
  }
}

# IAM Role for CloudWatch Logs Subscription
resource "aws_iam_role" "cw_logs_role" {
  name = "cw_logs_to_firehose_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cw_logs_policy" {
  role = aws_iam_role.cw_logs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = aws_kinesis_firehose_delivery_stream.splunk_stream.arn
      }
    ]
  })
}

# CloudWatch Logs Subscription Filter
resource "aws_cloudwatch_log_subscription_filter" "firehose_subscription" {
  name            = "CWLogsToFirehoseFilter"
  log_group_name  = var.cloudwatch_log_group
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.splunk_stream.arn
  role_arn        = aws_iam_role.cw_logs_role.arn
  depends_on      = [aws_cloudwatch_log_group.firehose_log_group]
}
