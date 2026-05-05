data "archive_file" "upload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/function-upload"
  output_path = "${path.module}/upload.zip"
}

resource "aws_lambda_function" "upload" {
  function_name    = "upload-lambda-${var.environment}"
  role             = aws_iam_role.upload_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  memory_size      = 256
  timeout          = 30
  filename         = data.archive_file.upload_zip.output_path
  source_code_hash = data.archive_file.upload_zip.output_base64sha256
  vpc_config {
    subnet_ids         = [aws_subnet.priv_a.id, aws_subnet.priv_b.id]
    security_group_ids = [aws_security_group.sg_upload.id]
  }
  environment {
    variables = { S3_BUCKET = aws_s3_bucket.images.id, UPLOAD_PREFIX = "uploads/" }
  }
}

data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/function-crop"
  output_path = "${path.module}/crop.zip"
}

resource "aws_lambda_function" "crop" {
  function_name    = "crop-lambda-${var.environment}"
  role             = aws_iam_role.crop_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  memory_size      = 512
  timeout          = 60
  filename         = data.archive_file.crop_zip.output_path
  source_code_hash = data.archive_file.crop_zip.output_base64sha256
  vpc_config {
    subnet_ids         = [aws_subnet.priv_a.id, aws_subnet.priv_b.id]
    security_group_ids = [aws_security_group.sg_crop.id]
  }
  environment {
    variables = { S3_BUCKET = aws_s3_bucket.images.id, PROCESSED_PREFIX = "processed/" }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.image_queue.arn
  function_name    = aws_lambda_function.crop.arn
  batch_size       = 5
}