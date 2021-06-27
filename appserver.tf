# ---------------------------------------------------
# VPC
# ---------------------------------------------------

resource "aws_key_pair" "keypair" {
  key_name   = "${var.project}-${var.environment}-keypair"
  public_key = file("./src/tastylog-dev-keypair.pub")

  tags = {
    Name    = "${var.project}-${var.environment}-keypair"
    Project = var.project
    Env     = var.environment
  }

}


# ---------------------------------------------------
# SSM Parameter Store
# ---------------------------------------------------
#ホスト名の定義
resource "aws_ssm_parameter" "host" {
  name = "/${var.project}/${var.environment}/app/MYSQL_HOST"
  #Stringの「S」は大文字であることに注意
  type = "String"
  #tfstateファイルのaddressの値をvalueに代入　コマンド$ terraform state show aws_db_instance.mysql_standalone　(addressはエンドポイントのこと)
  value = aws_db_instance.mysql_standalone.address
}

#ポート番号の定義
resource "aws_ssm_parameter" "port" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_PORT"
  type  = "String"
  value = aws_db_instance.mysql_standalone.port
}

#データベース名の定義
resource "aws_ssm_parameter" "database" {
  name = "/${var.project}/${var.environment}/app/MYSQL_DATABASE"
  type = "String"
  #データベース名はtfstateファイル上では「name」となっている。
  value = aws_db_instance.mysql_standalone.name
}

#ユーザー名の定義
resource "aws_ssm_parameter" "username" {
  name = "/${var.project}/${var.environment}/app/MYSQL_USERNAME"
  #「SecureString」はキャメルケースで表記
  type = "SecureString"
  #データベース名はtfstateファイル上では「name」となっている。
  value = aws_db_instance.mysql_standalone.username
}

#
resource "aws_ssm_parameter" "password" {
  name = "/${var.project}/${var.environment}/app/MYSQL_PASSWORD"
  type = "SecureString"
  #データベース名はtfstateファイル上では「sensitive value」となっていて直接表示されていないが、tfstateファイルには保存されている。
  value = aws_db_instance.mysql_standalone.password
}

# ---------------------------------------------------
# EC2 Instance  起動テンプレートなしのとき
# ---------------------------------------------------

# resource "aws_instance" "app_server" {
#   #data.tfファイルから参照。拡張子なしのファイル名＋リソース名＋論理名＋属性(今回はID)
#   ami           = data.aws_ami.app.id
#   instance_type = "t2.micro"
#   #リソース名＋論理名＋属性
#   subnet_id = aws_subnet.public_subnet_1a.id
#   #パブリックIPアドレスの有効化
#   associate_public_ip_address = true
#   #IAMロールのアタッチ
#   iam_instance_profile = aws_iam_instance_profile.app_ec2_profile.name
#   vpc_security_group_ids = [
#     aws_security_group.app_sg.id,
#     #運用管理用SGのIDを取得
#     aws_security_group.opmng_sg.id
#   ]
#   #キーペアの指定　論理名の後の属性はnameではなくて「key_name」とすること
#   key_name = aws_key_pair.keypair.key_name

#   tags = {
#     Name    = "${var.project}-${var.environment}-app-ec2"
#     Project = var.project
#     Env     = var.environment
#     Type    = "app"
#   }
# }


# ---------------------------------------------------
# 手動で作ったEC2 Instanceの追加 
# ---------------------------------------------------

#1.マネコンでつくったEC2を入れる 空のresouce ブロックを作る。
# resource "aws_instance" "test" {
#   #2.作成したEC2インスタンスの情報を参照して必須属性をここに後から追加
#   ami           = "ami-001f026eaf69770b4"
#   instance_type = "t2.micro"

# }


# ---------------------------------------------------
# launch template
# ---------------------------------------------------
resource "aws_launch_template" "app_lt" {
  #ヴァージョン管理を自動でやってくれるか
  update_default_version = true
  name                   = "${var.project}-${var.environment}-app-lt"

  #data.tfで変数化したaws_ami appから参照
  image_id = data.aws_ami.app.id
  key_name = aws_key_pair.keypair.key_name
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project}-${var.environment}-app-ec2"
      Project = var.project
      Env     = var.environment
      Type    = "app"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      aws_security_group.app_sg.id,
      aws_security_group.opmng_sg.id
    ]
    #EC2が落ちたときネットワークの設定も削除
    delete_on_termination = true
  }


  iam_instance_profile {
    name = aws_iam_instance_profile.app_ec2_profile.name
  }

  #アプリケーションのソースコードをs3から取得しEC2で起動するにあたり、初期化するためのスクリプトを記述
  user_data = filebase64("./src/initialize.sh")
}



# ---------------------------------------------------
# auto scaling group 
# ---------------------------------------------------
resource "aws_autoscaling_group" "app_asg" {
  name = "${var.project}-${var.environment}-app-asg"

  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  #起動後ヘルスチェックをかけるまでのインターバル
  health_check_grace_period = 300
  #ヘルスチェックはELBで実施
  health_check_type = "ELB"
  #ELBが所属するサブネットのIDを指定
  vpc_zone_identifier = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1c.id
  ]
  #ELBのターゲットグループを参照
  target_group_arns = [aws_lb_target_group.alb_target_group.arn]

  #起動テンプレートの設定。
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        #上記で設定した起動テンプレートのIDを参照
        launch_template_id = aws_launch_template.app_lt.id
        #テンプレートの最新バージョンを使用
        version = "$Latest"
      }
      override {
        instance_type = "t2.micro"
      }
    }
  }
}
