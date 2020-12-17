resource "aws_vpc" "AppVpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "AppScalaVpc"
  }
}

resource "aws_subnet" "AppSubnet" {
  vpc_id = aws_vpc.AppVpc.id
  cidr_block = "10.0.0.0/16"
   tags = {
    Name = "AppSubnet"
  }
}

resource "aws_internet_gateway" "AppGateway" {
  vpc_id = aws_vpc.AppVpc.id

  tags = {
    Name = "AppGateway"
  }
}
resource "aws_route_table" "AppRouting" {
  vpc_id = aws_vpc.AppVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.AppGateway.id
  }

  tags = {
    Name = "AppRoutingTable"
  }
}
resource "aws_security_group" "securityAppScala" {
  name        = "securityAppScala"
  description = "policies to autorize the traffic on port 22, 8080 and 80"
  vpc_id      = aws_vpc.AppVpc.id

  ingress {
    description = "policies to autorize port22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "policies to autorize port8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "policies to autorize  port80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "SecurityGroupAppScala"
  }
}

data "aws_ami" "AppScala" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }

  owners = ["amazon"]
}
resource "aws_instance" "AppScala" {
  instance_type = "t2.micro"
  key_name = "cles"
  ami           = data.aws_ami.AppScala.id
  user_data = <<-EOF
		#! /bin/bash
    sudo apt-get update
    sudo yum install httpd
    sudo service httpd start
	
	EOF

  tags = {
		Name = "TwitterAuthorScala"	
		Batch = "5AM"
	
  }
}

resource "aws_kinesis_stream" "AppStreamData" {
  name             = "AppStreamData"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = {
    Environment = "test"
  }
}

resource "aws_s3_bucket" "ApiScalabucket" {
  bucket = "apiscalabucket"
  acl    = "private"
}
resource "aws_s3_bucket" "result" {
  bucket = "apiauthorsresult"
  acl    = "private"
}

resource "aws_iam_role" "firehose_role" {
  name = "AppScalafirehose"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [ {
  "Action": "sts:AssumeRole",
  "Principal": { "Service": "firehose.amazonaws.com" },
  "Effect": "Allow",
  "Sid": "" } ]
}
EOF
}

resource "aws_iam_role_policy" "inline-policy" {
  name   = "tppolicy"
  role   = aws_iam_role.firehose_role.id
  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
        
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:PutRecord",
        "kinesis:PutRecords",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:ListShards",
        "kinesis:DescribeStreamSummary",
        "kinesis:RegisterStreamConsumer"
      
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "AppDataFirehose" {
  name        = "AppFirehose"
  destination = "s3"

kinesis_source_configuration{
    kinesis_stream_arn = aws_kinesis_stream.AppStreamData.arn
    role_arn = aws_iam_role.firehose_role.arn
}
  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.ApiScalabucket.arn
  }
}

resource "aws_iam_role" "crawler_role" {
  name = "analyserrole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [ {
  "Action": "sts:AssumeRole",
  "Principal": { "Service": "glue.amazonaws.com" },
  "Effect": "Allow",
  "Sid": "" } ]
}
EOF
}
resource "aws_glue_crawler" "tpcrawler" {
  database_name = aws_athena_database.tpdatabase.name
  name          = "tpanalyser"
  role          = aws_iam_role.crawler_role.arn

  s3_target {
    path = "s3://apiscalabucket"
  }
}
resource "aws_athena_database" "tpdatabase" {
  name   = "authorsdata"
  bucket = aws_s3_bucket.result.bucket
}