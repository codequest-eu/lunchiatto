locals {
  src_dir = "${path.module}/src"
  src_hash = base64sha256(join("", [
    filesha256("${local.src_dir}/create.js"),
    filesha256("${local.src_dir}/drop.js"),
    filesha256("${local.src_dir}/package.json"),
    filesha256("${local.src_dir}/package-lock.json"),
  ]))
  src_archive = "${path.module}/tmp/src.${local.src_hash}.zip"
}

data "archive_file" "package" {
  count = var.create ? 1 : 0

  type        = "zip"
  source_dir  = local.src_dir
  output_path = local.src_archive
}

data "aws_iam_policy_document" "assume_lambda" {
  count = var.create ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  count = var.create ? 1 : 0

  name               = "${var.project.prefix}-db-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda[0].json
  tags               = var.project.tags
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.create ? 1 : 0

  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "lambda" {
  count = var.create ? 1 : 0

  name = "${var.project.prefix}-create-db-lambda"
  tags = var.project.tags

  vpc_id = var.cluster.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deleting security groups attached to lambdas can take 45+ minutes,
# because AWS creates network interfaces for lambdas which are not
# deleted when the lambda is deleted, instead it's cleaned up later on.
# So as a workaround, creating a second security group.
resource "aws_security_group" "lambda_2" {
  count = var.create ? 1 : 0

  name = "${var.project.prefix}-db-lambda"
  tags = var.project.tags

  vpc_id = var.cluster.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "create" {
  count = var.create ? 1 : 0

  name = "/aws/lambda/${var.project.prefix}-create-db"
  tags = var.project.tags
}

resource "aws_lambda_function" "create" {
  count = var.create ? 1 : 0
  depends_on = [
    data.archive_file.package,
    aws_cloudwatch_log_group.create,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]

  function_name = "${var.project.prefix}-create-db"
  filename      = local.src_archive
  handler       = "create.handler"
  runtime       = "nodejs12.x"
  publish       = true
  timeout       = 10
  role          = aws_iam_role.lambda[0].arn
  vpc_config {
    subnet_ids         = var.cluster.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_2[0].id]
  }

  tags = var.project.tags
}

resource "aws_cloudwatch_log_group" "drop" {
  count = var.create ? 1 : 0

  name = "/aws/lambda/${var.project.prefix}-drop-db"
  tags = var.project.tags
}

resource "aws_lambda_function" "drop" {
  count = var.create ? 1 : 0
  depends_on = [
    data.archive_file.package,
    aws_cloudwatch_log_group.drop,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]

  function_name = "${var.project.prefix}-drop-db"
  filename      = local.src_archive
  handler       = "drop.handler"
  runtime       = "nodejs12.x"
  publish       = true
  timeout       = 10
  role          = aws_iam_role.lambda[0].arn
  vpc_config {
    subnet_ids         = var.cluster.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_2[0].id]
  }

  tags = var.project.tags
}
