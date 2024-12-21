output "Public-ec2" {
    value = aws_instance.public_whiz.id
  
}

output "Private-ec2" {
    value = aws_instance.privateinstance
  
}