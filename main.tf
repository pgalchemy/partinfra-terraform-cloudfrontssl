variable "origin_domain_name" {}
variable "origin_id" {}
variable "alias" {}
variable "acm_certificate_arn" {}
variable "origin_path" {
  default     = ""
}
variable "origin_access_identity" {
  default     = ""
}
variable "distribution_enabled" {
  default     = true
}
variable "comment" {
  default     = ""
}
variable "default_root_object" {
  default     = "index.html"
}
variable "compression" {
  default     = false
}


resource "aws_cloudfront_distribution" "ssl_distribution" {
  origin {
    domain_name = "${var.origin_domain_name}"
    origin_id   = "${var.origin_id}"
    origin_path = "${var.origin_path}"

    s3_origin_config {
      origin_access_identity = "${var.origin_access_identity}"
    }
  }

  enabled             = "${var.distribution_enabled}"
  comment             = "${var.comment}"
  default_root_object = "${var.default_root_object}"
  aliases = ["${var.alias}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.origin_id}"
    compress         = "${var.compression}"

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
      target_origin_id = "${var.origin_id}"
      compress         = "${var.compression}"
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
          event_type = "${var.headers["enabled"] ? "viewer-response" : ""}"
          // this currently does not work in Terraform
          //lambda_arn = "${var.headers["enabled"] ? aws_lambda_function.headers.arn : ""}"
          lambda_arn = "${aws_lambda_function.headers.arn}:${aws_lambda_function.headers.version}"

        }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "DE", "CN", "GB"]
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${var.acm_certificate_arn}"
    ssl_support_method = "sni-only"
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
