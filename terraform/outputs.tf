output "ecr_repository_url" {
  value = aws_ecr_repository.strapi.repository_url
}

output "alb_url" {
  value = "http://${aws_lb.strapi.dns_name}"
}

output "target_group_arn" {
  value = aws_lb_target_group.strapi.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}