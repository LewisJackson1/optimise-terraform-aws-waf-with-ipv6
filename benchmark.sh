#!/bin/bash

set -x

# echo "# Set up with a full apply"

# time terraform apply -auto-approve >/dev/null

echo "# Measure applying without changes"
echo "## Target: base config"

time for i in $(seq 1 3);
do
  echo "### Trial $i"
  terraform apply -target=aws_wafv2_ip_set.ipv6 -auto-approve >/dev/null
done

echo "## Target: proposed config"

time for i in $(seq 1 3);
do
  echo "### Trial $i"
  terraform apply -target=aws_wafv2_ip_set.ipv6_ignore_changes -auto-approve >/dev/null
done

echo "# Measure applying with a new IP appended"
echo "## Target: base config"

time for i in $(seq 1 3);
do
  echo "### Trial $i"
  terraform apply -target=aws_wafv2_ip_set.ipv6 -auto-approve -replace=random_integer.ipv6_netnum >/dev/null
done

echo "## Target: proposed config"

time for i in $(seq 1 3);
do
  echo "### Trial $i"
  terraform apply -target=aws_wafv2_ip_set.ipv6_ignore_changes -auto-approve -replace=random_integer.ipv6_netnum >/dev/null
done
