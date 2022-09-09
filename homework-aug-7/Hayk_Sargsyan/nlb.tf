resource "aws_lb" "nlb" {
  name               = "nlb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public-us-east-1d.id, aws_subnet.public-us-east-1b.id, aws_subnet.public-us-east-1c.id]

  #   enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "nlb_tg" {
  name        = "tf-nlb-tg"
  port        = 30001
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.virtual_anhatakan_amp.id

  lifecycle {
    create_before_destroy = true
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    port                = "80"
    path                = "/healthz"
    protocol            = "HTTP"
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "nlb_lis" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}


resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_eks_node_group.public-noder.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = aws_lb_target_group.nlb_tg.arn

  depends_on = [
    # aws_eks_node_group.public_noder,
    aws_lb_target_group.nlb_tg
  ]
}