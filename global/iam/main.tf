terraform {
    backend "s3" {
        bucket = "north-tf-state-usw2"
        key = "global/iam/terraform.tfstate"
        region = "us-west-2"
        dynamodb_table = "north-tf-locks"
        encrypt = true
    }
}

provider "aws" {
    region = "us-west-2"

    default_tags {
        tags = {
            Project = "north"
            Module = "iam"
            ManagedBy = "terraform"
            Environment = "global"            
        }
    }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = [ "sts.amazonaws.com" ]
    thumbprint_list = [ data.tls_certificate.github.certificates[0].sha1_fingerprint ]
}

resource "aws_iam_role" "terraform" {
    name_prefix = "terraform"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "admin_permissions" {
    statement {
        effect = "Allow"
        actions = [ "ec2:*", "rds:*", "s3:*", "dynamodb:*" ]
        resources = [ "*" ]
    }
}
resource "aws_iam_role_policy" "north_admin" {
    role = aws_iam_role.terraform.id
    policy = data.aws_iam_policy_document.admin_permissions.json
}

data "tls_certificate" "github" {
    url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "assume_role" {
    statement {
        actions = [ "sts:AssumeRoleWithWebIdentity" ]
        effect = "Allow"
        principals {
            identifiers = [ aws_iam_openid_connect_provider.github_actions.arn ]
            type = "Federated"
        }

        condition {
            test = "StringEquals"
            variable = "token.actions.githubusercontent.com:sub"
            values = [
                for a in var.allowed_repos_branches : "repo:${a["org"]}/${a["repo"]}:ref:refs/heads/${a["branch"]}"
            ]
        }
    }
}

variable "allowed_repos_branches" {
    description = "GitHub repos/branches allowed to assume the IAM role."
    type = list(object({
        org = string
        repo = string
        branch = string
    }))
    default = [
        {
            org = "sberts"
            repo = "north"
            branch = "main"
        }
    ]
}

output "role_arn" {
    value = aws_iam_role.terraform.arn
    description = "role for github actions"
}
