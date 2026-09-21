data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_deploy_role" {
  name = "github-actions-static-site-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:billy604/static-site-cdn-aws:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_deploy_policy" {
  name = "github-actions-static-site-deploy-policy"
  role = aws_iam_role.github_actions_deploy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.site_bucket.arn,
          "${aws_s3_bucket.site_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = aws_cloudfront_distribution.site_distribution.arn
      }
    ]
  })
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy_role.arn
}