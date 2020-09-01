## CLOUDFRONT CONFIG

resource aws_cloudfront_distribution ssl_distribution {
  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id
    origin_path = var.origin_path

    s3_origin_config {
      origin_access_identity = var.origin_access_identity
    }
  }

  enabled             = var.distribution_enabled
  comment             = var.comment
  default_root_object = var.default_root_object
  aliases             = [var.alias]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.origin_id
    compress         = var.compression

    forwarded_values {
      query_string = false

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  ordered_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.origin_id
    compress         = var.compression
    path_pattern     = "/*"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    lambda_function_association {
      event_type = var.headers["enabled"] ? "viewer-response" : ""
      lambda_arn = aws_lambda_function.headers[0].qualified_arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "DE", "CN", "GB"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}


# LAMBDA CONFIG

data template_file function {
  count    = var.headers["enabled"] ? 1 : 0
  template = file("${path.module}/headers_function.js")

  vars = {
    hsts             = var.headers["hsts-enabled"]
    x-content-type   = var.headers["x-content-type-enabled"]
    x-frame-options  = var.headers["x-frame-options-enabled"]
    x-xss-protection = var.headers["x-xss-protection-enabled"]
  }
}

data archive_file headers_function {
  count       = var.headers["enabled"] ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/.zip/headers_function.zip"
  source {
    filename = "index.js"
    content  = data.template_file.function[0].rendered
  }
}

resource aws_iam_role headers_function {
  count              = var.headers["enabled"] ? 1 : 0
  name               = "${replace(var.alias, ".", "-")}-lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource aws_iam_role_policy_attachment headers_function_role_policy {
  count      = var.headers["enabled"] ? 1 : 0
  role       = aws_iam_role.headers_function[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda@Edge requires that the function exist in the US East Region. See:
# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-requirements-limits.html#lambda-requirements-cloudfront-triggers
provider "aws" {
  alias  = "lambda_at_edge_region"
  region = "us-east-1"
}

resource aws_lambda_function headers {
  count            = var.headers["enabled"] ? 1 : 0
  function_name    = "${replace(var.alias, ".", "-")}-headers"
  filename         = data.archive_file.headers_function[0].output_path
  source_code_hash = data.archive_file.headers_function[0].output_base64sha256
  role             = aws_iam_role.headers_function[0].arn
  runtime          = "nodejs12.x"
  handler          = "index.handler"
  memory_size      = 128
  timeout          = 3
  publish          = true
  provider         = aws.lambda_at_edge_region
}
