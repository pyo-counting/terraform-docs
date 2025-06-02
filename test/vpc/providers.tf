provider "aws" {
  region  = local.region
  profile = local.profile

  default_tags {
    tags = {
      CreatedBy = "pyo_counting@kakao.com"
    }
  }
}
