# ---------------------------------------------------
# RDS Parameter Group データベースエンジンのパラメータ群の設定
# ---------------------------------------------------
resource "aws_db_parameter_group" "mysql_standalone_patametergroup" {
  name   = "${var.project}-${var.environment}-mysql-standalone-parametergroup"
  family = "mysql8.0"

  # データ型がブロックの属性は「＝」は不要。 
  # データベースの文字コードを追加
  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}


# ---------------------------------------------------
# RDS Option Group データベースに対する追加機能を設定
# ---------------------------------------------------

resource "aws_db_option_group" "mysql_standalone_optiongroup" {
  name                 = "${var.project}-${var.environment}-mysql-standalone-optiongroup"
  engine_name          = "mysql"
  major_engine_version = "8.0"

}


# ---------------------------------------------------
# RDS Subnet Group
# ---------------------------------------------------
resource "aws_db_subnet_group" "mysql_standalone_subnetroup" {
  name = "${var.project}-${var.environment}-mysql-standalonesubnetgroup"
  subnet_ids = [
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1c.id
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone-subnetgroup"
    Project = var.project
    Env     = var.environment
  }
}


# ---------------------------------------------------
# RDS instance
# ---------------------------------------------------
#　パスワードのランダム生成
resource "random_string" "db_password" {
  length  = 16
  special = false
}

# DBインスタンスの生成
resource "aws_db_instance" "mysql_standalone" {
  #基本設定
  engine         = "mysql"
  engine_version = "8.0.20"
  identifier     = "${var.project}-${var.environment}-mysql-standalone" #RDSのID

  username = "admin"
  password = random_string.db_password.result

  instance_class = "db.t2.micro"

  #ストレージ設定
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_encrypted     = false

  #ネットワーク周り
  multi_az               = false
  availability_zone      = "ap-northeast-1a"
  db_subnet_group_name   = aws_db_subnet_group.mysql_standalone_subnetroup.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  port                   = 3306

  #DB設定
  name                 = "tastylog" #データベース名
  parameter_group_name = aws_db_parameter_group.mysql_standalone_patametergroup.name
  option_group_name    = aws_db_option_group.mysql_standalone_optiongroup.name

  #バックアップ設定　- メンテナンスより先にバックアップ時間を設定すること。
  backup_window              = "04:00-05:00"
  backup_retention_period    = 7
  maintenance_window         = "Mon:05:00-Mon:08:00"
  auto_minor_version_upgrade = false

  #削除防止
  deletion_protection = false
  skip_final_snapshot = true

  apply_immediately = true

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone"
    Project = var.project
    Env     = var.environment
  }

}
