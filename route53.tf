# ---------------------------------------------------
# Route 53
# ---------------------------------------------------

#ホストゾーンの設定 
resource "aws_route53_zone" "route53_zone" {
  name          = var.domain #ドメイン名は変数化して、variables.tfvarに記述(外だし)
  force_destroy = false      #Terraform 以外で管理されたレコードを強制削除するかどうか

  tags = {
    Name    = "${var.project}-${var.environment}-domain"
    Project = var.project
    Env     = var.environment
  }
}

#ロードバランサーとドメインを紐付けるaliasレコードを定義 
resource "aws_route53_record" "route53_record" {
  zone_id = aws_route53_zone.route53_zone.zone_id #上記で定義したホストゾーンのID
  name    = "dev-elb.${var.domain}"               #レコード名(任意の名前)　=>ELB用
  type    = "A"                                   #レコードタイプをエイリアス

  #AWSリソースを指定する場合はaliasを指定する必要がある。
  alias {
    name                   = aws_lb.alb.dns_name #ELBの場合はDNS名を代入(リソースの種類によりvalueの種類が異なるので注意)
    zone_id                = aws_lb.alb.zone_id  #ELBのゾーンIDを指定
    evaluate_target_health = true                #ヘルスチェックの有効化
  }
}



