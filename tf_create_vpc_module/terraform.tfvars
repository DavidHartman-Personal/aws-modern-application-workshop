region = "us-east-1"
aws_account_id = "612530344502"
azs = ["us-east-1a", "us-east-1b"]
aws_profile = "challengetaker"
s3_website_bucket = "mysfitsdjh"

mysfits_vpc = {
  name = "mysfits_vpc_tf"
  cidr = "10.0.0.0/16"
}
public_subnet_1 = {
  name = "public_subnet_1"
  cidr = "10.0.0.0/24"
}
public_subnet_2 = {
  name = "public_subnet_2"
  cidr = "10.0.1.0/24"
}
private_subnet_1 = {
  name = "public_subnet_1"
  cidr = "10.0.2.0/24"
}
private_subnet_2 = {
  name = "public_subnet_2"
  cidr = "10.0.3.0/24"
}