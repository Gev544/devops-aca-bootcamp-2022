#Create an EC2
resource "aws_instance" "ec2" {
	ami                         = "ami-0cff7528ff583bf9a"
	instance_type               = "${var.instance_type}"
	key_name                    = "${var.key_name}-keypair"
	security_groups             = ["${aws_security_group.public.id}"]
	subnet_id                   = "${aws_subnet.public-subnet.id}"
	associate_public_ip_address = true
	lifecycle {
		create_before_destroy = true
	}
	tags = {
		"Name" = "${var.key_name}-ec2"
	}
	# copies the ssh key file to home dir
	provisioner "file" {
		source      = "./${var.key_name}-keypair.pem"
		destination = "/home/ec2-user/${var.key_name}-keypair.pem"
		connection {
			type        = "ssh"
			user        = "ec2-user"
			private_key = file("${var.key_name}-keypair.pem")
			host        = self.public_ip
		}
	}
	# chmod key 400 on EC2 instance
	provisioner "remote-exec" {
		inline = ["chmod 400 ~/${var.key_name}-keypair.pem"]
		connection {
			type        = "ssh"
			user        = "ec2-user"
			private_key = file("${var.key_name}-keypair.pem")
			host        = self.public_ip
		}
	}
}
