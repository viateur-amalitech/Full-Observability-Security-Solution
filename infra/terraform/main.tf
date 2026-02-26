# ============================================
# Root Module – Orchestrates all sub-modules
# ============================================

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# -------------------------
# 1. CloudWatch (must come first – produces the IAM profile for EC2)
# -------------------------
module "cloudwatch" {
  source = "./modules/cloudwatch"
}

# -------------------------
# 2. Compute – EC2 Web Server
# -------------------------
module "web_server" {
  source                    = "./modules/ec2"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  iam_instance_profile_name = module.cloudwatch.instance_profile_name
}

resource "aws_eip" "web_server" {
  instance = module.web_server.instance_id
  domain   = "vpc"
}

# -------------------------
# 3. CloudTrail + Encrypted S3
# -------------------------
module "cloudtrail" {
  source      = "./modules/cloudtrail"
  bucket_name = var.cloudtrail_bucket_name
  account_id  = data.aws_caller_identity.current.account_id
}

# -------------------------
# 4. GuardDuty – Threat Detection
# -------------------------
module "guardduty" {
  source = "./modules/guardduty"
}
