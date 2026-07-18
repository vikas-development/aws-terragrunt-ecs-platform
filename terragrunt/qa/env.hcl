locals {
  environment    = "qa"
  vpc_cidr       = "10.1.0.0/16"
  instance_size  = "small"
  min_capacity   = 1
  max_capacity   = 2
  enable_deletion_protection = false
}
