terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws" # AWS를 조작하는 플러그인
      version = "~> 6.0"        # 6.x 버전대 사용
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # 서울 리전

  default_tags { # 만드는 모든 자원에 자동으로 붙는 꼬리표
    tags = {
      Project   = "reaction-ranking"
      ManagedBy = "terraform"
    }
  }
}
