resource "aws_iam_role" "kubernetes" {
    name = "kubernetes"
    assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com",
            "AWS": "arn:aws:iam::740380980326:user/Terraform"
          },
          "Action": "sts:AssumeRole"
        }
      ]
}
EOF
}

resource "aws_iam_instance_profile" "kubernetes" {
    name = "kubernetes"
    roles = ["${aws_iam_role.kubernetes.name}"]
}

resource "aws_iam_role_policy" "kubernetes" {
    name = "kubernetes"
    role = "${aws_iam_role.kubernetes.id}"
    policy = <<EOF
{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "ec2:*",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "elasticloadbalancing:*",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "cloudwatch:*",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "autoscaling:*",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "iam:*",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "ecr:*",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "s3:*",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "kms:*",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "route53:*",
                "Resource": "*"
            }
        ]
}
EOF
}
