output "alb_dns_name" {
  description = "DNS name of the ECS Application Load Balancer"
  value       = module.alb.alb_dns_name
}
