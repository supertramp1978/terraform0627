# ---------------------------------------------------
# IAM ROle
# ---------------------------------------------------
resource "aws_iam_instance_profile" "app_ec2_profile" {
  name = aws_iam_role.app_iam_role.name
  role = aws_iam_role.app_iam_role.name
}

resource "aws_iam_role" "app_iam_role" {
  name = "${var.project}-${var.environment}-app-iam-role"
  #dataブロックのaws_iam_policy_documentリソースの論理ID「ec2_assume_role」のjsonを取得
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

}
data "aws_iam_policy_document" "ec2_assume_role" {
  #定型文なので機械的にかけばよい
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy_attachment" "app_iam_role_ec2_readonly" {
  role = aws_iam_role.app_iam_role.name
  #マネジメントコンソールから該当のポリシーを探し「arn」をコピペする。ここは「EC2ReadOnlyAccess」
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "app_iam_role_ssm_managed" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "app_iam_role_ssm_readonly" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "app_iam_role_s3_readonly" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
