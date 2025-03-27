# Amazon Web Services

Refer to [Magic Castle Documentation](https://github.com/ComputeCanada/magic_castle/tree/main/docs) for a complete step-by-step guide.

TL;DR:
1. Export the following environment variables : `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
2. Download the [latest release of Magic Castle for AWS](https://github.com/ComputeCanada/magic_castle/releases/latest).
3. Unpack the release.
4. Adapt the [parameters](https://github.com/ComputeCanada/magic_castle/tree/main/docs#4-configuration) in `main.tf` file.
5. In a terminal, change your current directory to the directory containing `main.tf`.
6. Initiate the Terraform state : `terraform init`.
7. Verify the Terraform plan : `terraform plan`.
8. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.

### AWS Minimal IAM Policy

This policy grants Terraform the necessary permissions to create, update, and destroy EC2 resources. It includes permissions for managing EC2 instances, security groups, key pairs, and other related resources. This policy should be applied to the IAM role or user that Terraform will use to manage the EC2 infrastructure for Magic Castle.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeleteSubnet",
                "ec2:DescribeInstances",
                "ec2:AttachInternetGateway",
                "ec2:DescribePlacementGroups",
                "ec2:DescribeInternetGateways",
                "ec2:DeleteVolume",
                "ec2:CreatePlacementGroup",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:CreateRoute",
                "ec2:CreateInternetGateway",
                "ec2:DescribeVolumes",
                "ec2:DeleteInternetGateway",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeRouteTables",
                "ec2:ImportKeyPair",
                "ec2:CreateTags",
                "ec2:DeleteNetworkInterface",
                "ec2:RunInstances",
                "ec2:DetachInternetGateway",
                "ec2:DescribeInstanceCreditSpecifications",
                "ec2:CreateVolume",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeInstanceTypes",
                "ec2:DeleteVpc",
                "ec2:AssociateAddress",
                "ec2:CreateSubnet",
                "ec2:DescribeSubnets",
                "ec2:DeleteKeyPair",
                "ec2:AttachVolume",
                "ec2:DisassociateAddress",
                "ec2:DescribeAddresses",
                "ec2:DeleteTags",
                "ec2:DescribeInstanceAttribute",
                "ec2:CreateVpc",
                "ec2:DescribeVpcAttribute",
                "ec2:ModifySubnetAttribute",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeAvailabilityZones",
                "ec2:CreateSecurityGroup",
                "ec2:ModifyVpcAttribute",
                "ec2:ReleaseAddress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:TerminateInstances",
                "ec2:DetachNetworkInterface",
                "ec2:DeletePlacementGroup",
                "ec2:DescribeTags",
                "ec2:DeleteRoute",
                "ec2:AllocateAddress",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeImages",
                "ec2:DescribeVpcs",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*"
        }
    ]
}
```
