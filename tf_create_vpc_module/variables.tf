variable "region" {
  default = "us-east-1"
}
variable "aws_account_id" {
  default = "612530344502"
  description = "The AWS Account ID.  Enhancement would involve looking this up"
}
variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
variable "aws_profile" {
  type = string
  default = "challengetaker"
  description = "Local AWS config entry for connecting to AWS"
}
variable "s3_website_bucket" {
  type = string
  default = "mysfitsdjh"
  description = "S3 bucket containing static content for Mysfits Website"
}

variable "mysfits_vpc" {
  type = object({
    name = string
    cidr = string
  })
  description = "VPC for Mysfits Lab"
}

variable "public_subnet_1" {
  type = object({
    name = string
    cidr = string
  })
  description = "Public VPC for Mysfits Lab"
}

variable "public_subnet_2" {
  type = object({
    name = string
    cidr = string
  })
  description = "Public Subnet for Mysfits Lab"
}
variable "private_subnet_1" {
  type = object({
    name = string
    cidr = string
  })
  description = "Private Subnet for Mysfits Lab"
}

variable "private_subnet_2" {
  type = object({
    name = string
    cidr = string
  })
  description = "Private VPC for Mysfits Lab"
}

//
//variable "availability_zone_names" {
//  type    = list(string)
//  default = ["us-east-1a", "us-east-1b"]
//}
//
//variable "docker_ports" {
//  type = list(object({
//    internal = number
//    external = number
//    protocol = string
//  }))
//  default = [
//    {
//      internal = 8300
//      external = 8300
//      protocol = "tcp"
//    }
//  ]
//}