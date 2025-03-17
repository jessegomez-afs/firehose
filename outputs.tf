output "firehose_stream_arn" {
  value = aws_kinesis_firehose_delivery_stream.splunk_stream.arn
}

output "s3_backup_bucket" {
  value = aws_s3_bucket.backup.bucket
}
