# ランダム文字列を生成するリソース(S3バケット名をユニークするため、受講者同士で重複しないように)
resource "random_string" "s3_unique_key" {
  length  = 6     #生成する文字数
  upper   = false #大文字を使うか
  lower   = true  #小文字を使うか
  number  = true  #数字を使うか
  special = false #特殊文字を使うか

}

# ---------------------------------------------------
# S3 static bucket 静的コンテンツ(Sorryページ)保管用バケット
# ---------------------------------------------------
resource "aws_s3_bucket" "s3_static_bucket" {
  #random文字列の値を返す時は、result
  bucket = "${var.project}-${var.environment}-${random_string.s3_unique_key.result}"

  versioning {
    enabled = false
  }
}

#ブロックパブリックアクセスを別リソースとして設定
resource "aws_s3_bucket_public_access_block" "s3_static_bucket" {
  #バケットの関連付け
  bucket                  = aws_s3_bucket.s3_static_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false

  #パブリックアクセスとバケットポリシーの依存関係を記述
  #子要素であるバケットポリシーを先に作ってから、パブリックアクセスで制限する。
  depends_on = [
    aws_s3_bucket_policy.s3_static_bucket
  ]
}


#バケットポリシーの設定
resource "aws_s3_bucket_policy" "s3_static_bucket" {
  #バケットの関連付け
  bucket = aws_s3_bucket.s3_static_bucket.id
  #別途データブロックで定義したバケットポリシーを関連付け。dataブロックを参照する場合は、「data」から記述(resourceを参照する場合、ブロック名は省略している)。dataブロック=>ポリシードキュメントリソース=>論理名s3_static_bucket => 属性json
  policy = data.aws_iam_policy_document.s3_static_bucket.json
}

#バケットポリシーの内容をJSONで定義
data "aws_iam_policy_document" "s3_static_bucket" {
  statement {
    effect = "Allow"
    #actionのvalueはCloudFormationと同じく、[リソース名：アクション名, x:x, y:y...]の様に配列で定義
    actions = ["s3:GetObject"]
    #制作したバケット名以下の全てのオブジェクトを*で対象に指定。
    resources = ["${aws_s3_bucket.s3_static_bucket.arn}/*"]
    #アクセスしてきたクライアント全てを許可
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cf_s3_origin_access_identity.iam_arn] #value　は　set of string
    }
  }
}

# ---------------------------------------------------
# S3 deploy bucket 
# AutoScaling時に新たに起動したEC2が取得する動的コンテンツを保管するバケット
# ---------------------------------------------------
resource "aws_s3_bucket" "s3_deploy_bucket" {
  #random文字列の値を返す時は、result
  bucket = "${var.project}-${var.environment}-${random_string.s3_unique_key.result}"

  versioning {
    enabled = false
  }
}

#ブロックパブリックアクセスを別リソースとして設定
resource "aws_s3_bucket_public_access_block" "s3_deploy_bucket" {
  #バケットの関連付け プライベートなので全て有効
  bucket                  = aws_s3_bucket.s3_deploy_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  #パブリックアクセスとバケットポリシーの依存関係を記述
  #子要素であるバケットポリシーを先に作ってから、パブリックアクセスで制限する。
  depends_on = [
    aws_s3_bucket_policy.s3_deploy_bucket
  ]
}


#バケットポリシーの設定
resource "aws_s3_bucket_policy" "s3_deploy_bucket" {
  #バケットの関連付け
  bucket = aws_s3_bucket.s3_deploy_bucket.id
  #別途データブロックで定義したバケットポリシーを関連付け。dataブロックを参照する場合は、「data」から記述(resourceを参照する場合、ブロック名は省略している)。dataブロック=>ポリシードキュメントリソース=>論理名s3_static_bucket => 属性json
  policy = data.aws_iam_policy_document.s3_deploy_bucket.json
}

#バケットポリシーの内容をJSONで定義
data "aws_iam_policy_document" "s3_deploy_bucket" {
  statement {
    effect = "Allow"
    #actionのvalueはCloudFormationと同じく、[リソース名：アクション名, x:x, y:y...]の様に配列で定義
    actions = ["s3:GetObject"]
    #制作したバケット名以下の全てのオブジェクトを*で対象に指定。
    resources = ["${aws_s3_bucket.s3_deploy_bucket.arn}/*"]
    # appサーバであるEC2からのアクセスのみ許可　＝＞　appサーバのIAMロール
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.app_iam_role.arn] #value　は　set of string
    }
  }
}

