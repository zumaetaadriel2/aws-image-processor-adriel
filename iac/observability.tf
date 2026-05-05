# --- LOG GROUPS (Retención de 14 días) ---
resource "aws_cloudwatch_log_group" "upload_logs" {
  name              = "/aws/lambda/${aws_lambda_function.upload.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "crop_logs" {
  name              = "/aws/lambda/${aws_lambda_function.crop.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "apigw_logs" {
  name              = "/aws/apigateway/${var.project_name}-api-${var.environment}"
  retention_in_days = 14
}

# --- ALARMA PARA LA DEAD-LETTER QUEUE (DLQ) ---
# Creamos un tema SNS para enviar la notificación
resource "aws_sns_topic" "dlq_alerts" {
  name = "${var.project_name}-dlq-alerts-${var.environment}"
}

# La métrica y alarma propiamente dichas
resource "aws_cloudwatch_metric_alarm" "dlq_messages_alarm" {
  alarm_name          = "${var.project_name}-dlq-messages-alarm-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alerta si un mensaje falla 3 veces y cae en la DLQ."
  alarm_actions       = [aws_sns_topic.dlq_alerts.arn]
  
  dimensions = {
    QueueName = aws_sqs_queue.image_dlq.name
  }
}