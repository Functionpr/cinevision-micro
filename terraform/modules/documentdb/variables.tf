variable "identifier" {
  type = string
}


variable "cluster_name" {
  type = string
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type      = string
  sensitive = true
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_class" {
  type    = string
  default = "db.r6g.large"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "preferred_backup_window" {
  type    = string
  default = "04:00-05:00"
}

variable "enable_global_cluster" {
  type    = bool
  default = false
}

variable "dr_subnet_ids" {
  type    = list(string)
  default = []
}

variable "dr_security_group_ids" {
  type    = list(string)
  default = []
}

variable "dr_instance_class" {
  type    = string
  default = "db.r6g.large"
}

variable "dr_instance_count" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
