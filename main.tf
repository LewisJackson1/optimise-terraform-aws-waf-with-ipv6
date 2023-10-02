provider "aws" {
  region = "us-east-1"
}

data "github_ip_ranges" "github" {}

locals {
  newbits             = 16
  random_ip_addresses = [cidrsubnet("fd00:fd12:3456:7890::/56", local.newbits, random_integer.ipv6_netnum.result)]
  ip_ranges           = concat(data.github_ip_ranges.github.actions_ipv6, local.random_ip_addresses)
}

resource "random_integer" "ipv6_netnum" {
  min = 0
  max = pow(2, local.newbits)
}

resource "random_id" "ipv6" {
  keepers = {
    ipv6_addresses = md5(join("", local.ip_ranges))
  }

  byte_length = 8
}

resource "aws_wafv2_ip_set" "ipv6_ignore_changes" {
  name  = "ignored-changes-${random_id.ipv6.hex}"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV6"
  addresses          = [for ip in local.ip_ranges : cidrsubnet(ip, 0, 0)]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [addresses]
  }
}

resource "aws_wafv2_ip_set" "ipv6" {
  name  = "github-actions-ipv6"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV6"
  addresses          = [for ip in local.ip_ranges : cidrsubnet(ip, 0, 0)]
}
