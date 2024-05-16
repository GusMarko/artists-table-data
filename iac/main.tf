# uvesti postojece resurse koji ce biti potrebni 
# postojeca dynamodb iz koje citamo
# neophodni network resursi
# napraviti lambda resurs



data "aws_dynamodb_table" "artists" {
  name = "project1-artists-${var.env}"
}

data "aws_ssm_parameter" "priv_sub_id" {
  name = "/vpc/${var.env}/private_subnet/id"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/vpc/${var.env}/id"
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



resource "aws_iam_role" "main" {

  name               = "project1-artists-table-data-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json

}

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:*"

    ]
    resources = [data.aws_dynamodb_table.artists.arn, data.aws_dynamodb_table.artists.stream_arn]
    effect    = "Allow"
  }
}


resource "aws_iam_policy" "dynamodb_access" {
  name   = "project1-artists-table-data-dynamodb-access-${var.env}"
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
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
      ARTISTS_TABLE = data.aws_dynamodb_table.artists.id
    }
  }

  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.priv_sub_id.value]
    security_group_ids = [aws_security_group.main.id]
  }

}


# podesavanje trigera

resource "aws_lambda_event_source_mapping" "allow_dynamodb_table_to_trigger_lambda" {
  event_source_arn  = data.aws_dynamodb_table.artists.stream_arn
  function_name     = aws_lambda_function.main.arn
  starting_position = "LATEST"
}

