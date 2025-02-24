data "aws_iam_policy_document" "vpc-cni" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
  }
}

resource "aws_iam_role" "vpc-cni" {
  name               = "psy-playground-test-role"
  assume_role_policy = data.aws_iam_policy_document.vpc-cni.json
}

resource "aws_iam_role_policy_attachment" "vpc-cni" {
  role       = aws_iam_role.vpc-cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

module "iam_policy" {
  source  = "terraform-aws-modules/eks/aws"
  version = "5.52.2"
}