resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type

  subnet_id = aws_subnet.private.id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  associate_public_ip_address = false

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-app"
    }
  )
}
