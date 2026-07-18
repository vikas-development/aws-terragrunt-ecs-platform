locals {
  environment    = "prod"
  vpc_cidr       = "10.2.0.0/16"
  instance_size  = "medium"
  min_capacity   = 2
  max_capacity   = 4
  enable_deletion_protection = true
}
