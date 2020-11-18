variable "aws_access_key" {
  type        = string
  description = "Access Key of AWS Account"
}

variable "aws_secret_key" {
  type        = string
  description = "Secret Key of AWS Account"
}

variable "region" {
  type        = string
  description = "Region of the new VPC in AWS Cloud"
}

variable "availability_zone" {
  type        = string
  description = "Availablility zone in VPC for the EC2 App Instance"
}

variable "vpc_prefix" {
  type        = string
  description = "Prefix VPC IP range: like 10.0.0.0/16"
}

variable "subnet_prefix" {
  type        = string
  description = "Prefix subnet IP range: like 10.0.1.0/20"
}

variable "installation_method" {
  type        = string
  description = "Installation method (Must be 'package' or 'git')"
  # default = "package"

  validation {
    condition     = can(regex("^(package|git)$", var.installation_method))
    error_message = "Must be package or git."
  }
}


variable "key_public_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}


variable "key_private_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}


variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}
