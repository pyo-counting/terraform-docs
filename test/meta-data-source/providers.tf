provider "aws" {
  region  = local.region
  profile = local.profile

  default_tags {
    tags = {
      CreatedBy = "seyeol.pyo@kurlycorp.com"
    }
  }
}
