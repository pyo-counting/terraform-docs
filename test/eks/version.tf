terraform {
  required_version = "1.3.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.87.0"
    }
  }
}

provider "aws" {
  alias   = "playground"
  profile = "playground"

  default_tags {
    tags = {
      CreatedBy = "seyeol.pyo@kurlycorp.com"
    }
  }
}
