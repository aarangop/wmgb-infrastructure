# Add to your infrastructure/main.tf or create a new iam.tf file

resource "aws_iam_group" "whos_my_good_boy_developers" {
    name = "WhosMyGoodBoyDeveloper"
}

# Create policy for S3 access
resource "aws_iam_policy" "model_access_policy" {
  name        = "model-developer-access-policy"
  description = "Policy to access ML models in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
        # Account level permissions
        Effect = "Allow",
        Action = [
            "s3:ListAllMyBuckets"
        ],
        Resource = "*"
        },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:HeadObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::whos-my-good-boy-models",
          "arn:aws:s3:::whos-my-good-boy-models/*"
        ]
      }
    ]
  })
}

# Attach this policy to the group
resource "aws_iam_group_policy_attachment" "developer_s3_access" {
    group = aws_iam_group.whos_my_good_boy_developers.name
    policy_arn = aws_iam_policy.model_access_policy.arn
}