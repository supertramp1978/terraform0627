## ---------------------------------------------------
# S3のprefix list (ドメイン名に割り当てられるIPアドレス群)取得　
# ---------------------------------------------------
data "aws_prefix_list" "s3_pl" {
  name = "com.amazonaws.*.s3"
}


## ---------------------------------------------------
# Amazon Linux 最新のAMIを取得　(APPサーバ用)　
# ---------------------------------------------------
data "aws_ami" "app" {
  #複数のAMIが検索でヒットした場合、最新のAMIを適用
  most_recent = true
  #AMIの所有者を指定。=> 自分で登録したものとamazonが登録したAMI
  owners = ["self", "amazon"]

  filter {
    name = "name"
    #Valueが配列の場合は要素が一つでも[]で定義。
    values = ["tastylog-app-ami"]
  }
  #   filter {
  #     #ws ec2 describe-images --image-ids[AMIのID]コマンドで表示された情報を基に指定。
  #     name = "name"
  #     #Valueが配列の場合は要素が一つでも[]で定義。
  #     values = ["amzn2-ami-hvm-2.0.20210525.0-x86_64-gp2"]
  #   }

  #   filter {
  #     name = "root-device-type"
  #     #Valueが配列の場合は要素が一つでも[]で定義。
  #     values = ["ebs"]
  #   }

  #   filter {
  #     name = "virtualization-type"
  #     #Valueが配列の場合は要素が一つでも[]で定義。
  #     values = ["hvm"]
  #   }
  # }

  #aws_amiデータブロック　エンド
}
