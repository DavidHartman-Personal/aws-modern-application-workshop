terraform {
  required_version = "0.12.18"
}
provider "aws" {
  profile = "challengetaker"
  region = "us-east-1"
  version = "~> 2.42"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = var.mysfits_vpc.name
  cidr = var.mysfits_vpc.cidr

  azs = var.azs
  private_subnets = [
    var.private_subnet_1.cidr,
    var.private_subnet_2.cidr]
  public_subnets = [
    var.public_subnet_1.cidr,
    var.public_subnet_2.cidr]

  # VPC Endpoint for DynamoDB
  enable_dynamodb_endpoint = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "prototype"
  }
  public_subnet_tags = {
    Name = "public_mysfits_subnet"
  }
  vpc_tags = {
    Name = "mysfits_vpc_tf_module"
  }
}
resource "aws_security_group" "fargate_security_group" {
  name = "fargate_security_group"
  description = "Access to the fargate containers from the Internet"
  vpc_id = module.vpc.vpc_id
  ingress {
    cidr_blocks = [
      var.mysfits_vpc.cidr]
    protocol = "-1"
    from_port = 0
    to_port = 0
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"]
    protocol = "-1"
    from_port = 0
    to_port = 0
  }
}

//Service Policies to attach to created roles
data "aws_iam_policy_document" "ecs_service_policy_document" {
  statement {
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:Describe*",
      "ec2:DetachNetworkInterface",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "iam:PassRole",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:DescribeLogStreams",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
    ]
    resources = [
      "*",
    ]
  }
}
resource "aws_iam_policy" "ecs_service_policy" {
  name = "ecs-service"
  path = "/"
  policy = data.aws_iam_policy_document.ecs_service_policy_document.json
}
//ECS Service Role
data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "ecs_service_role" {
  name = "ecs-service-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_role_policy_attach" {
  role = aws_iam_role.ecs_service_role.name
  policy_arn = aws_iam_policy.ecs_service_policy.arn
}


//ECS Task Policy Document
data "aws_iam_policy_document" "ecs_task_policy_document" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/MysfitsTable*",
    ]
  }
}
resource "aws_iam_policy" "ecs_task_policy" {
  name = "ecs-task"
  path = "/"
  policy = data.aws_iam_policy_document.ecs_task_policy_document.json
}
data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"]
    }
  }
}
//ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attach" {
  role = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

//CodeBuild Service Role
data "aws_iam_policy_document" "codebuildservice_task_policy_document" {
  statement {
    actions = [
      "codecommit:ListBranches",
      "codecommit:ListRepositories",
      "codecommit:BatchGetRepositories",
      "codecommit:Get*",
      "codecommit:GitPull",
    ]
    resources = [
      "arn:aws:codecommit:${var.region}:${var.aws_account_id}:MythicalMysfitsServiceRepository",
    ]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "ecr:InitiateLayerUpload",
      "ecr:GetAuthorizationToken",
    ]
    resources = [
      "*",
    ]
  }
}
resource "aws_iam_policy" "codebuild_service_policy" {
  name = "mythicalmysfits-codebuild-service-role"
  path = "/"
  policy = data.aws_iam_policy_document.codebuildservice_task_policy_document.json
}
data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "codebuild_service_role" {
  name = "mythicalmysfits-codebuild-service-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
}
resource "aws_iam_role_policy_attachment" "codebuild_service_role_policy_attach" {
  role = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_service_policy.arn
}

//CodePipeline Service Role
data "aws_iam_policy_document" "codepipelineservice_policy_document" {
  statement {
    actions = [
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::*",
    ]
  }
  statement {
    actions = [
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "ecs:*",
      "codebuild:*",
      "iam:PassRole",
    ]
    resources = [
      "*",
    ]
  }
}
resource "aws_iam_policy" "codepipeline_service_policy" {
  name = "mythicalmysfits-codepipeline-service-role"
  path = "/"
  policy = data.aws_iam_policy_document.codepipelineservice_policy_document.json
}
data "aws_iam_policy_document" "codepipeline_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "codepipeline.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "codepipeline_service_role" {
  name = "mythicalmysfits-codepipeline-service-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
}
resource "aws_iam_role_policy_attachment" "codepipeline_service_role_policy_attach" {
  role = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_service_policy.arn
}

