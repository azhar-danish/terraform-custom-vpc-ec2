output "instance_name" {
    value = {
        for k, v in aws_instance.my_instance : k => v.tags.Name
    }
}

output "public_ip" {
    value = {
        for k, v in aws_instance.my_instance : k => v.public_ip
    }
}

output "private_ip" {
    value = {
        for k, v in aws_instance.my_instance : k => v.private_ip
    }
}
