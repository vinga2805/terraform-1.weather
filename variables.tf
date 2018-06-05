variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}

variable "aws_region" {
    description = "EC2 Region for the VPC"
    default = "eu-west-1"
}

variable "amis" {
    description = "AMIs by region"
    default = {
        eu-west-1 = "ami-f1810f86" # ubuntu 14.04 LTS
    }
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "10.0.1.0/24"
}
variable "count" {
    default = 1
}

variable "amis-ec2" {
    description = "Base AMI to launch EC2"
    default = {
        eu-west-1 = "ami-ca0135b3" #AML
    }
}
variable "env" {
  type        = "string"
  description = "Environment such as pro, sta, fit, tst"
}

variable "tag_environment" {
  type        = "string"
  description = "Environment such as Production or Staging"
}

variable "platform" {
  type        = "string"
  description = "the platform being built"
}

variable "tag_platform" {
  type        = "string"
  description = "the platform being built, for the tags"
}

variable "tag_business_unit" {
  type        = "string"
  description = "the business unit this platform belongs to"
}

 
