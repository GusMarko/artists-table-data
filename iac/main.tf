# uvesti postojece resurse koji ce biti potrebni 
# postojeca dynamodb iz koje citamo
# neophodni network resursi
# napraviti lambda resurs



data "aws_s3_bucket" "artists" {
  bucket = "project1-artists-${var.env}"
}

data "aws_ssm_parameter" "priv_sub_id" {
  name = "/vpc/dev/private_subnet/id"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/vpc/dev/id"
}



resource "aws_security_group" "main" {

  name        = "project1-artists-table-data_api-${var.env}"
  description = "Security groupd for table data lambda"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      description      = "Allow all egress"
      self             = false
    }
  ]
}


data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_second_lambda" {
  bucket = data.aws_s3_bucket.artists.id
  policy = data.aws_iam_policy_document.allow_access_from_second_lambda.json
}

data "aws_iam_policy_document" "allow_access_from_second_lambda" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::381492201388:role/project1-artists-table-data-dev"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]
  }
}


resource "aws_iam_role" "main" {

  name               = "project1-artists-table-data-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json

}

resource "aws_iam_role_policy_attachment" "vpc_policy_for_lambda" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" #AWS predefined policy
}


#### LAMBDA

# podesavanja lambde
resource "aws_lambda_function" "main" {
  function_name = "project1-artists-table-data-${var.env}"
  role          = aws_iam_role.main.arn
  memory_size   = 128
  timeout       = 10
  package_type  = "Image"
  image_uri     = var.image_uri

  environment {
    variables = {
      ARTISTS_BUCKET = "project1-artists-${env.var}"
    }
  }

  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.priv_sub_id.value]
    security_group_ids = [aws_security_group.main.id]
  }

}


# podesavanje trigera
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.artists.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = data.aws_s3_bucket.artists.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.main.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".txt"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
