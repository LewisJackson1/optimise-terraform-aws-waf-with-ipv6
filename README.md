# aws_wafv2_ip_set performance with IPv6 addresses

`aws_wafv2_ip_set` is extremely slow to compare a large set of IPv6 addresses to the desired state. IPv4 addresses don't have this problem _(results roughly in line with the proposed config)_.

Versions:

```shell
terraform version
Terraform v1.5.7
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v5.19.0
+ provider registry.terraform.io/hashicorp/github v5.39.0
+ provider registry.terraform.io/hashicorp/random v3.5.1
```

This repository shows an example of how to work around this by ignoring changes to the addresses.

## Setup

Initialise the Terraform state, then create the the two WAF IP sets.

```shell
terraform init
terraform apply
```

Note that this will use your current AWS CLI profile.

## Benchmarking

Run the benchmark script:

```shell
chmod +x ./benchmark.sh
./benchmark.sh
```

This will loop over two test cases three times:

- one where no changes have been made to the IPv6 address list from GitHub
- one where a dummy IP address that we add to the address list changes

Each test case will run for the base config and the proposed config.

**Note**:

- The test will redirect stdout output from `terraform` to `/dev/null` to reduce noise. I've added some `echo` statements to log the process as this test can be quite slow.
- You may wish to edit the loop counters to reduce the total duration.
- The test case where no change is effectively just a `terraform plan`, so this issue can slow down PR workflows too.

## Tear Down

Destroy the two WAF IP sets:

```shell
terraform destroy
```

## Results

It is expected that the proposed config will be much faster in both test cases:

|              | Base config mean (s) | Proposed config mean (s) |
| ------------ | -------------------- | ------------------------ |
| No changes   | 275                  | 7.7                      |
| 1 IP changed | 198.3                | 15.3                     |

This data was taken from the `user` values in [`sample-results.md`](./sample-results.txt), dividing each value by the number of test cases (three).
