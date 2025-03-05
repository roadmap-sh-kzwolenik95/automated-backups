variable "do_token" {
  type      = string
  sensitive = false
}
variable "ssh_key_name" {
  type = string
}
variable "region" {
  type    = string
  default = "fra1"
}
variable "size" {
  type    = string
  default = "s-1vcpu-1gb"
}
variable "name" {
  description = "Droplet name"
  type        = string
  default     = "srv"
}