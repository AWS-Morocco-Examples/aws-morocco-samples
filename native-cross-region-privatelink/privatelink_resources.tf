resource "aws_lb" "nlb" {
  provider                   = aws.provider
  name                       = "service-nlb"
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = [aws_subnet.service.id]
  enable_deletion_protection = false
  tags = {
    Name = "service-nlb"
  }
}

resource "aws_lb_target_group" "tg" {
  provider    = aws.provider
  name        = "service-tg"
  port        = 22
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.service.id

  health_check {
    protocol = "TCP"
  }

  tags = {
    Name = "service-tg"
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  provider         = aws.provider
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.service.id
  port             = 22
}

resource "aws_lb_listener" "listener" {
  provider          = aws.provider
  load_balancer_arn = aws_lb.nlb.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_vpc_endpoint_service" "privatelink" {
  provider                   = aws.provider
  network_load_balancer_arns = [aws_lb.nlb.arn]
  acceptance_required        = false
  supported_regions          = ["eu-west-1"]
}

data "aws_caller_identity" "current" {}

resource "aws_vpc_endpoint_service_allowed_principal" "allow" {
  provider                = aws.provider
  vpc_endpoint_service_id = aws_vpc_endpoint_service.privatelink.id
  principal_arn           = data.aws_caller_identity.current.arn
}

output "privatelink_service_name" {
  value = aws_vpc_endpoint_service.privatelink.service_name
}
