# ---------------------------------------------------
# Certificate
# ---------------------------------------------------
# 東京リージョン向け　ACM証明書(ELBのHTTPS通信用)
resource "aws_acm_certificate" "tokyo_cert" {
  domain_name       = "*.${var.domain}" #設定したドメイン名
  validation_method = "DNS"             #証明書リクエストにあたり、申請したドメインの所有者確認の方法をどうするか？DNS or EMAIL or NONE

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true #ELBで証明書を利用している場合true設定が推奨(削除前に生成するか)
  }

  # terraformで認知されない依存関係があるリソースを記述。
  #　Route53のホストゾーンを生成したあとに生成することを指示
  depends_on = [
    aws_route53_zone.route53_zone
  ]
}


#レコード設定 -------------------------------------

#　ACMリソース作成時に生成される検証CNAMEレコードを参照させる(以下がCNAMEレコード情報)=> 元の記述場所は？
# valueは配列の中にオブジェクトが入っている状態。取得方法に注意。
# -------------------------------------------------------------------------
# "domain_validation_options" : {
#     "domain_name" = "*.tastylog.work"
#     "resource_record_name" : "_0123...cdef.tastylog.work",
#     "resource_record_type" : "CNAME",
#     "resource_record_value" : "_0123...cdef.xxxxxxx.acm-validations.aws"
#}
# -------------------------------------------------------------------------
resource "aws_route53_record" "route53_acm_dns_resolve" {
  for_each = {
    # dvo = domain validation options とする。
    # リソース"aws_acm_certificate"で論理名"tokyo_cert"にあるdomain_validation_options属性の値(配列)を取得
    for dvo in aws_acm_certificate.tokyo_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  zone_id         = aws_route53_zone.route53_zone.id #route53.tfで定義したホストゾーン 
  name            = each.value.name
  type            = each.value.type
  ttl             = 600
  records         = [each.value.record]
}

#ACM検証の設定 -------------------------------------
resource "aws_acm_certificate_validation" "cert_valid" {
  certificate_arn         = aws_acm_certificate.tokyo_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.route53_acm_dns_resolve : record.fqdn]
}


# ヴァージニアリージョン向け　ACM証明書(CloudFrontのHTTPS通信用)
resource "aws_acm_certificate" "virginia_cert" {
  provider = aws.virginia #providerを上書き

  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_route53_zone.route53_zone
  ]

}
