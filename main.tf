#vpc
module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "my-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["us-east-1a", "us-east-1b"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

    enable_nat_gateway = true
    enable_vpn_gateway = true

    tags = {
        Terraform = "true"
        Environment = var.env
    }
}

#key pair
resource "aws_key_pair" "my-key-pair" {
    key_name = "node-app-keypair"
    public_key = file("keys/myapp.pub")
}

#security group
resource "aws_security_group" "ec2_SG" {
    name        = "ec2-SG"
    description = "Allow TLS inbound traffic and all outbound traffic"
    vpc_id      = module.vpc.vpc_id

    tags = {
        Name = "ec2-SG"
    }

    #inbound rules
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH Open"
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Http Open"
    }

    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Custom Open"
    }

    #outbound rules

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All access open outbound"
    }
}

resource "aws_instance" "my_instance" {
    for_each = tomap({
        react-app-master = {
            type = "t2.small"
            ami_id = "ami-0567589d25e06853e"
            subnet_id = module.vpc.public_subnets[0]
        }
        react-app-worker1 = {
            type = "t2.micro"
            ami_id = "ami-0b6d9d3d33ba97d99"
            subnet_id = module.vpc.public_subnets[1]
        }   
    })

    depends_on = [ module.vpc, aws_security_group.ec2_SG, aws_key_pair.my-key-pair ]
    key_name = aws_key_pair.my-key-pair.key_name
    
    vpc_security_group_ids = [aws_security_group.ec2_SG.id] 
    
    instance_type = each.value.type
    ami = each.value.ami_id
    subnet_id = each.value.subnet_id

    # user_data = file("user_data/install-nginx.sh")
   
    associate_public_ip_address = true 
    root_block_device {
      volume_size = var.env == "dev" ? var.ec2_root_storage_size : 10
      volume_type = "gp2"
    }

    tags = {
        Name = each.key
        Environment = var.env
    }
}
