# firehose
firehose practice

3.17.2025

My exercise to implement a basice AWS Data FireHose and Splunk Cloud.

Lastk week, I mistakenly installed Splunk Enterprise to my local laptop then realized there was now way AWS Firehose was going to connect to my laptop.
Also, the splunk enterprise quickly made me run out of disk space.

I transitioned to a 14-day Splunk Cloud account, but have had errors about dropped or failed connections.

Troubleshooting.

=====================
UPDATE - Mon 2025-03-17 @ 16:14

When I try to send data from AWS Data Firehose to Splunk Cloud, the AWS error is "Could not connect to the HEC endpoint. Make sure that the certificate and the host are valid."

I have verified with curl tests that Splunk Cloud HEC Endpoint does successfully ingest data.

According to this article https://docs.splunk.com/Documentation/SplunkCloud/9.3.2408/Data/UsetheHTTPEventCollector?ref=hk#HEC_and_Splunk_Cloud_Platform,

"You must file a ticket with Splunk Support to enable HEC for use with Amazon Web Services (AWS) Kinesis Firehose. Standard HEC is enabled by default on all Splunk Cloud Platform deployments and does not require a Splunk Support ticket."

I've sent an email to splunk support requesting that feature.

