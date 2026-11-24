variable "aws_region" {
  description = "AWS region for the project (default: Mumbai)."
  type        = string
  default     = "ap-south-1"
}

variable "admin_ip_cidr" {
  description = "Your current public IPv4 address as /32, e.g. 203.0.113.10/32. Never use 0.0.0.0/0."
  type        = string
  validation {
    condition     = can(cidrhost(var.admin_ip_cidr, 0)) && endswith(var.admin_ip_cidr, "/32")
    error_message = "Supply one valid IPv4 /32 address, such as 203.0.113.10/32."
  }
}

variable "key_name" {
  description = "Name of an EC2 key pair ALREADY created in this AWS region."
  type        = string
}

variable "web_instance_type" {
  description = "4GB RAM is recommended for React npm build; adjust for your budget."
  type        = string
  default     = "t3.medium"
}

variable "db_instance_type" {
  description = "MongoDB lab instance, not a production sizing recommendation."
  type        = string
  default     = "t3.small"
}
