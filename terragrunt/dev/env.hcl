locals {
  environment    = "dev"
  vpc_cidr       = "10.0.0.0/16"
  instance_size  = "small"   # cheap sizing — this env gets destroyed often
  min_capacity   = 1
  max_capacity   = 2
  enable_deletion_protection = false
}
