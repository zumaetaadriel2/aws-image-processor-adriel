variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno (dev, qa, prod)"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "adriel-img-proc"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
}