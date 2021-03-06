# terraform-aws-cloudfront

## Introduction
A Terraform module to easily create an SSL-enabled CloudFront distribution for a custom domain, with optional security headers.

## Examples
An example which specifies only the required variables:
```
module "example" {
  source              = "github.com/pgalchemy/terraform-aws-cloudfront"

  origin_domain_name  = "discourse.mozilla-community.org"
  origin_id           = "discoursecdn"
  alias               = "cdn.discourse.mozilla-community.org"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/00e371ce-a96e-435b-9e76-687ad6sa8231"
}

```

An example that enables some headers:
```

module "example" {
  source              = "github.com/pgalchemy/terraform-aws-cloudfront"

  origin_domain_name  = "discourse.mozilla-community.org"
  origin_id           = "discoursecdn"
  alias               = "cdn.discourse.mozilla-community.org"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/00e371ce-a96e-435b-9e76-687ad6sa8231"

  headers = {
    enabled = true
    hsts-enabled = true
    x-content-type-enabled = true
    x-frame-options-enabled = true
    x-xss-protection-enabled = true
  }
}
```
## Reference

| Variable              | Description                                                                                | Required     | Default  |
| -------------          |-------------                                                                               |----------    | ----- |
| `origin_domain_name`     | The domain name CloudFront should pull from.                                                | yes          |  |
| `alias`     | The alternate domain name for the distribution.                                                | yes          |  |
| `origin_id`              | A unique identifier for the origin.                                                        | yes          |  |
| `acm_certificate_arn`              | The ARN for the ACM cert to use in this distribution.                                                        | yes          |  |
| `origin_access_identity` | The identity path used to limit S3 access to Cloudfront | yes |  |
| `origin_path`            | The folder on the origin to request content from. Must begin with `/` with no tailing `/`.  | no           |    |
| `distribution_enabled`           | Whether the CloudFront Distribution is enabled.  | no           |    `true` |
| `comment`           | A comment to add to the distribution.  | no           |    |
| `default_root_object`           | The object to return when a user requests the root URL.  | no           |  `index.html`  |
| `compression` | Enable CloudFront to compress some files with gzip (and forward the `Accept-Encoding` header to the origin) | no | `false`
| `headers` | A map of HTTP response headers that can be conditionally enabled (see below) | no | | |

### Headers
Add secure headers to every response, using Lambda@Edge (very basic, to be changed to allow any headers with any value to be added in the future)

| Variable              | Description                                                                                | Required     | Default  |
| -------------          |-------------                                                                               |----------    | ----- |
| `enabled`     | Deploy a Lambda@Edge function to add headers to all responses                                                 | no          | `false` |
| `hsts_enabled`     |`Strict-Transport-Security: max-age=63072000`                                                | no          | `false` |
| `x-content-type-enabled`              | `X-Content-Type-Options: nosniff`                                                        | no          | `false` |
| `x-frame-options-enabled`              | `X-Frame-Options: DENY`                                                        | no          | `false` |
| `x-xss-protection-enabled`              | `X-XSS-Protection: 1; mode=block`                                                        | no          | `false` | |
