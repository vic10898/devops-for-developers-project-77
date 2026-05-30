variable "yc_token" {
  type        = string
  description = "Yandex Cloud OAuth token"
  sensitive   = true
}

variable "yc_cloud_id" {
  type        = string
  description = "Yandex Cloud Cloud ID"
}

variable "yc_folder_id" {
  type        = string
  description = "Yandex Cloud Folder ID"
}

variable "yc_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Yandex Cloud Zone"
}

variable "db_password" {
  type        = string
  description = "PostgreSQL Database password"
  sensitive   = true
  default     = "Qwerty10ka"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key used to connect to VMs"
  default     = "~/.ssh/id_ed25519.pub"
}

variable "dns_zone_id" {
  type        = string
  description = "Yandex Cloud DNS Zone ID for magical-lovelace.ru"
  default     = "dnsd98oc0ilc5s1f69bj"
}

