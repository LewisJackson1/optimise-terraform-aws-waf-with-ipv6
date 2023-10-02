provider "aws" {
  region = "us-east-1"
}

data "github_ip_ranges" "github" {}

locals {
  newbits             = 16
  random_ip_addresses = [cidrsubnet("fd00:fd12:3456:7890::/56", local.newbits, random_integer.ipv6_netnum.result)]
  ip_ranges           = concat(data.github_ip_ranges.github.actions_ipv6, local.random_ip_addresses)
}

# randomly create a new IPv6 address when this is recreated
resource "random_integer" "ipv6_netnum" {
  min = 0
  max = pow(2, local.newbits)
}

# randomly create a new suffix for the IP set if a hash of the IPs changes
resource "random_id" "ipv6" {
  keepers = {
    ipv6_addresses = md5(join("", local.ip_ranges))
  }

  byte_length = 8
}

# example of the conventional way to try this
resource "aws_wafv2_ip_set" "ipv6" {
  name  = "github-actions-ipv6"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV6"
  addresses          = [for ip in local.ip_ranges : cidrsubnet(ip, 0, 0)]
}

# proposed config:
#   - doesn't compare the state to AWS
#   - creates a new IP set before destroying the old one
resource "aws_wafv2_ip_set" "ipv6_ignore_changes" {
  name  = "ignored-changes-${random_id.ipv6.hex}" # the name controls the recreation of the resource
  scope = "CLOUDFRONT"

  ip_address_version = "IPV6"
  addresses          = [for ip in local.ip_ranges : cidrsubnet(ip, 0, 0)] # calling this function on every IP fixes bad data from the GitHub where they don't give us the network part of the CIDR

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [addresses]
  }
}

# IPv4 sets aren't affected
resource "aws_wafv2_ip_set" "ipv4" {
  name  = "github-actions-ipv4"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV4"
  addresses          = [for ip in data.github_ip_ranges.github.actions_ipv4 : cidrsubnet(ip, 0, 0)]
}
