## REQUIRED
variable "origin_domain_name" {
  type        = string
  description = "The domain name CloudFront should pull from."
}

variable "origin_id" {
  type        = string
  description = "A unique identifier for the origin."
}

variable "alias" {
  type        = string
  description = "The alternate domain name for the distribution."
}

variable "acm_certificate_arn" {
  type        = string
  description = "The ARN for the ACM cert to use in this distribution."
}

variable "origin_access_identity" {
  type        = string
  description = "The identity path used to limit S3 access to Cloudfront."
}

## OPTIONAL
variable "origin_path" {
  type        = string
  description = "The folder on the origin to request content from. Must begin with '/' with no trailing '/'."
  default     = ""
}

variable "distribution_enabled" {
  type        = bool
  description = "Whether the CloudFront Distribution is enabled."
  default     = true
}

variable "comment" {
  type        = string
  description = "A comment to add to the distribution."
  default     = ""
}

variable "default_root_object" {
  type        = string
  description = "The object to return when a user requests the root URL."
  default     = "index.html"
}

variable "compression" {
  type        = bool
  description = "Enable CloudFront to compress some files with gzip (and forward the Accept-Encoding header to the origin)."
  default     = false
}

variable "headers" {
  type        = map(bool)
  description = "A map of HTTP response headers that can be conditionally enabled."
  default = {
    enabled                  = false
    hsts-enabled             = false
    x-content-type-enabled   = false
    x-frame-options-enabled  = false
    x-xss-protection-enabled = false
  }
}
