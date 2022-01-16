resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "${var.author_name}-eip"
  }
}
