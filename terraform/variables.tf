variable "project" {
  type    = string
  default = "sap2"
}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region to deploy resources (default Frankfurt)."
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type = list(string)
  # Need at least two subnets in different AZs for RDS subnet group coverage
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "allowed_ip" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Lock this to your IP in real usage"
}

variable "public_key_path" {
  type        = string
  description = "Path to SSH public key"
}

variable "web_app_revision" {
  type        = string
  description = "Change this to force a new launch template version & instance recycle when user_data logic changes"
  default     = "v1"
}

variable "alert_email" {
  type        = string
  default     = ""
  description = "Email address to subscribe to infrastructure alerts (leave blank to skip subscription)"
}
