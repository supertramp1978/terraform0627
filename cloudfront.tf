# ---------------------------------------------------
# CloudFront Cache Distribution
# ---------------------------------------------------
# Distributionの基本設定
resource "aws_cloudfront_distribution" "cf" {
  enabled         = true #CloudFrontの有効化
  is_ipv6_enabled = true #ipv6有効化
  comment         = "cache distribution"
  price_class     = "PriceClass_All" #マネコンでは下記がデフォルト =>何の設定？


  #ELB向けのオリジン設定 ------------------------------------
  # - origin_idはcloudfront内で一意であること(behaviorで参照する時に重複しないため)
  # - オリジンがELBの場合、cutom_origin_configで設定する
  origin {
    domain_name = aws_route53_record.route53_record.fqdn #DNSドメイン名
    origin_id   = aws_lb.alb.name                        #オリジンを識別する一意の名前

    custom_origin_config {
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      http_port              = 80
      https_port             = 443
    }
  }



  #S3をオリジンに設定 ------------------------------------
  #s3.tfで定義したs3_static_bucket。S3のドメインは「bucket_regional_domain_name」という属性に格納されている。
  origin {
    domain_name = aws_s3_bucket.s3_static_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.s3_static_bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf_s3_origin_access_identity.cloudfront_access_identity_path
    }
  }

  #ELBオリジンのBehavior ------------------------------------
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    target_origin_id       = aws_lb.alb.name #転送先のオリジンID
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }


  #S3オリジンのBehavior ------------------------------------
  ordered_cache_behavior {
    path_pattern     = "/public/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.s3_static_bucket.id

    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 86400
    max_ttl                = 31536000
    compress               = true #圧縮を行う

  }


  #アクセス制限 ------------------------------------
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["dev.${var.domain}"]

  #証明書
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.virginia_cert.arn #独自の証明書を利用する場合
    minimum_protocol_version = "TLSv1.2_2019"                        #推奨値
    ssl_support_method       = "sni-only"                            #Server Name Indication(1台のサーバで複数の証明書が利用できる)
  }
}

#s3へアクセスするためのアイデンティティを設定
resource "aws_cloudfront_origin_access_identity" "cf_s3_origin_access_identity" {
  comment = "s3 static bucket accesss identity"
}



#ドメイン名とCloudFrontを紐付けるAレコードの設定
resource "aws_route53_record" "route53_cloudfront" {
  # ホストゾーンのID
  zone_id = aws_route53_zone.route53_zone.id
  name    = "dev.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = true
  }
}
