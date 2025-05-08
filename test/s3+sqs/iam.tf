module "iam_role_s3_replication" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.52.2"

  role_name         = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "s3-replication")
  create_role       = true
  role_description  = "iam role for eks ec2 node"
  role_requires_mfa = false
  tags              = { Name = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "s3-replication") }
  # ec2 instance profile
  create_instance_profile = false
  # permission policy
  inline_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      resources = ["arn:aws:s3:::${format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "source")}"]
    },
    {
      effect = "Allow"
      actions = [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ],
      resources = ["arn:aws:s3:::${format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "source")}/*"]
    },
    {
      effect = "Allow"
      actions = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      resources = ["arn:aws:s3:::${format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "destination")}/*"]
    }
  ]
  custom_role_policy_arns = []
  # trust policy
  create_custom_role_trust_policy = false
  custom_role_trust_policy        = ""
  trusted_role_services           = ["s3.amazonaws.com"]
  trust_policy_conditions         = []
  trusted_role_actions            = []
  trusted_role_arns               = []
}