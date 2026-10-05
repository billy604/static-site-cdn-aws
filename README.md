# Static Website Hosting with a Global CDN

[![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20CloudFront%20%7C%20ACM-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4)](https://www.terraform.io/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20(OIDC)-blue)](https://github.com/features/actions)

> **Project 1 of 7 in my Cloud & DevOps portfolio — Beginner tier.**
> This was my first real "infrastructure as code" project, and it's where I actually learned Terraform, not just read about it. [See the full series →](#the-rest-of-the-series)

## What this actually is

A personal static website — HTML/CSS, nothing fancy — hosted on S3, served through CloudFront so it's fast anywhere in the world, and secured over HTTPS by default. The whole thing is defined in Terraform, so I can tear it down completely when I'm not using it and bring it back with one command whenever I need it again.

I built this specifically to *not* do the thing every S3-hosting tutorial does, which is make the bucket public. Instead, the bucket stays completely private, and CloudFront is the only thing allowed to read from it, using something called an Origin Access Control. More on that below.

## Why this setup, and not something simpler

The honest answer is: this is the pattern real companies actually use for static sites — landing pages, marketing sites, docs sites. A public S3 bucket "works," but it means anyone can hit your bucket directly, bypass your CDN, and rack up S3 request costs you didn't expect. Locking the bucket down and only letting CloudFront in is a small amount of extra setup for a meaningfully better security posture, and it's the kind of decision I wanted to practice making early, not skip past.

## How it's wired together

```
GitHub push → GitHub Actions → S3 (private) → CloudFront (CDN) → Route 53 / your browser
                                     ▲
                          Origin Access Control
                          (only CloudFront can read the bucket)
```

1. I push a change to `main`.
2. GitHub Actions authenticates to AWS — no stored access keys, more on that below — and syncs my `src/` folder to S3.
3. CloudFront serves the site from its edge locations worldwide, pulling from S3 only when it needs a fresh copy.
4. The pipeline invalidates CloudFront's cache on every deploy, so changes show up immediately instead of waiting for the old cached version to expire.

## The part I'm actually proud of: no stored AWS credentials, anywhere

Instead of generating an AWS access key and pasting it into GitHub as a secret (which is what most tutorials tell you to do), this pipeline uses **OpenID Connect (OIDC)**. GitHub and AWS have a trust relationship set up ahead of time, and every time the workflow runs, GitHub hands AWS a short-lived, signed token proving "this really is a run of my repo, on my main branch, right now." AWS checks that token, and if it matches, issues temporary credentials that expire in about an hour. There's nothing sitting in GitHub Secrets that could leak.

## Repo layout

```
static-site-cdn-aws/
├── .github/workflows/deploy.yml   → the CI/CD pipeline
├── main.tf                        → S3 bucket, CloudFront, bucket policy
├── iam-oidc.tf                    → the OIDC trust relationship + deploy role
├── src/
│   ├── index.html
│   └── styles/main.css
└── docs/architecture-diagram.png
```

## Getting it running yourself

```bash
terraform init
terraform apply
```

That's genuinely it for the infrastructure. Terraform prints out a `cloudfront_domain_name` output when it's done — paste that into a browser and the site's live. Push to `main` after that and GitHub Actions takes care of every future deploy on its own.

## What's actually working right now, and what isn't (yet)

I'd rather be upfront about this than pretend it's flawless:

- ✅ The S3 + CloudFront infrastructure deploys cleanly and the site loads over HTTPS.
- ✅ The bucket is genuinely private — I confirmed this by trying to open the S3 object URL directly and getting Access Denied, which is exactly what should happen.
- ⚠️ The GitHub Actions OIDC pipeline is built and wired up correctly on the GitHub side, but I hit a trust-policy mismatch on the AWS side (`Not authorized to perform sts:AssumeRoleWithWebIdentity`) that I haven't finished debugging yet — it needs a console check I couldn't do at the time. Deploys currently still work fine via `terraform apply` locally; the automated pipeline is the one piece still mid-fix.

I'm leaving this note in instead of quietly fixing it and pretending it was never broken, because debugging IAM trust policies is a real, common part of this job, and I'd rather show that honestly than hide it.

## What I'd do differently in a real production setup

| What I simplified | What a production team would do instead |
|---|---|
| No custom domain — using the default `*.cloudfront.net` address | Route 53 + ACM for a real domain and a proper TLS cert |
| Terraform state stored locally on my laptop | Remote state in S3 with DynamoDB locking, so a team can collaborate safely |
| `terraform apply` run by hand | Terraform applied through a CI/CD pipeline with `plan` posted for review before merge |
| No automated policy scanning | Checkov or tfsec scanning every pull request for misconfigurations |

(I go deeper on remote state, CI/CD-driven Terraform, and policy scanning in Project 6 — this table is really a preview of what that project fixes.)

## Skills this one actually taught me

Terraform fundamentals (providers, resources, state, outputs), S3 + CloudFront + ACM, IAM roles and OIDC trust policies, GitHub Actions basics, and — unglamorously — a lot of real debugging: WSL clock drift breaking AWS request signing mid-`destroy`, and reading IAM trust policy errors closely enough to actually fix them instead of guessing.

## The rest of the series

| # | Project | Tier |
|---|---|---|
| 1 | **Static Website + CDN** (this one) | Beginner |
| 2 | [Three-Tier VPC App](../three-tier-vpc-architecture-aws) | Beginner |
| 3 | [Automated Backup & Monitoring](../automated-backup-monitoring-aws) | Beginner |
| 4 | Serverless REST API + CI/CD | Intermediate |
| 5 | Event-Driven Data Pipeline | Intermediate |
| 6 | Multi-Environment IaC Platform | Pro |
| 7 | Microservices on Kubernetes | Pro |