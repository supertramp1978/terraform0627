# ---------------------------------------------------
# Terraform config
# ---------------------------------------------------

terraform {
  # Terraformのバージョン指定 => 0.13以上で指定
  required_version = ">=0.13"
  #providerのバージョン指定 =>3.0以上で指定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">3.0"
    }
  }

  #共有tfstateファイルの記述箇所を定義。＝＞s3に保存する。
  #backend属性に共有バケットの定義が可能。
  backend "s3" {
    bucket = "tastylog-tfstate-bucket-monge"
    # keyのvalueは変数を代入するとエラーになるので注意
    key     = "tastylog-dev.tfstate"
    region  = "ap-northeast-1"
    profile = "terraform"

  }

}


# ---------------------------------------------------
# Provider
# ---------------------------------------------------
#どのCloud Plattformを使うか/ IAMユーザー名/ リージョン
provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}

#CloudFrontのSSL証明書発行のためヴァージニアリージョンを追加
provider "aws" {
  alias   = "virginia" #デフォルトと別のリージョンを指定
  profile = "terraform"
  region  = "us-east-1"
}

# ---------------------------------------------------
# Variables　変数として扱うものは、変数名、データ型をこのセクションで宣言する。
# ---------------------------------------------------

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain" {
  type = string

}
