# --- ROLES BASE ---
resource "aws_iam_role" "upload_role" {
  name = "upload-lambda-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role" "crop_role" {
  name = "crop-lambda-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

# --- POLÍTICAS ADMINISTRADAS (Logs y VPC) ---
resource "aws_iam_role_policy_attachment" "upload_vpc_basic" {
  role       = aws_iam_role.upload_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc_basic" {
  role       = aws_iam_role.crop_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# --- POLÍTICAS ESPECÍFICAS (S3 y SQS) ---
resource "aws_iam_policy" "upload_s3_policy" {
  name        = "upload-s3-policy-${var.environment}"
  description = "Permite a Upload Lambda escribir SOLO en uploads/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = ["${aws_s3_bucket.images.arn}/uploads/*"]
    }]
  })
}
resource "aws_iam_role_policy_attachment" "upload_s3_attach" {
  role       = aws_iam_role.upload_role.name
  policy_arn = aws_iam_policy.upload_s3_policy.arn
}

resource "aws_iam_policy" "crop_s3_sqs_policy" {
  name        = "crop-s3-sqs-policy-${var.environment}"
  description = "Permite a Crop Lambda leer de uploads, escribir en processed y manejar SQS"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.images.arn}/uploads/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.images.arn}/processed/*"]
      },
      {
        Effect   = "Allow"
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [aws_sqs_queue.image_queue.arn]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "crop_s3_sqs_attach" {
  role       = aws_iam_role.crop_role.name
  policy_arn = aws_iam_policy.crop_s3_sqs_policy.arn
}