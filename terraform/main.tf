# Сетевая инфраструктура
resource "yandex_vpc_network" "network" {
  name = "redmine-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "redmine-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.8.0.0/24"]
}

# Группы безопасности
resource "yandex_vpc_security_group" "alb_sg" {
  name        = "alb-security-group"
  network_id  = yandex_vpc_network.network.id
  description = "Security group for Application Load Balancer"

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTPS from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow health checks from ALB load balancer"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }

  egress {
    protocol       = "ANY"
    description    = "Allow outbound to anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "vm_sg" {
  name        = "vm-security-group"
  network_id  = yandex_vpc_network.network.id
  description = "Security group for Web Server VMs"

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow HTTP from Load Balancer"
    security_group_id = yandex_vpc_security_group.alb_sg.id
    port              = 80
  }

  egress {
    protocol       = "ANY"
    description    = "Allow outbound to anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "db_sg" {
  name        = "db-security-group"
  network_id  = yandex_vpc_network.network.id
  description = "Security group for PostgreSQL Database"

  ingress {
    protocol          = "TCP"
    description       = "Allow PostgreSQL from VMs"
    security_group_id = yandex_vpc_security_group.vm_sg.id
    port              = 6432
  }

  egress {
    protocol       = "ANY"
    description    = "Allow outbound to anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Генерация самоподписанного SSL-сертификата для HTTPS на балансировщике
resource "tls_private_key" "cert_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.cert_key.private_key_pem

  subject {
    common_name  = "magical-lovelace.ru"
    organization = "Hexlet Student"
  }

  validity_period_hours = 8760 # 1 год

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "yandex_cm_certificate" "my_cert" {
  name        = "self-signed-cert"
  description = "Self-signed certificate for ALB TLS Termination"

  self_managed {
    certificate = tls_self_signed_cert.cert.cert_pem
    private_key = tls_private_key.cert_key.private_key_pem
  }
}

# Поиск образа Ubuntu
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# Виртуальные машины для веб-серверов
resource "yandex_compute_instance" "web" {
  count = 2

  name        = "redmine-web-${count.index + 1}"
  platform_id = "standard-v3"
  zone        = var.yc_zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 15
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.vm_sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# База данных PostgreSQL как сервис
resource "yandex_mdb_postgresql_cluster" "db_cluster" {
  name               = "redmine-db-cluster"
  environment        = "PRESTABLE"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.db_sg.id]

  config {
    version = 15
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 10
    }
  }

  host {
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.subnet.id
  }
}

resource "yandex_mdb_postgresql_user" "user" {
  cluster_id = yandex_mdb_postgresql_cluster.db_cluster.id
  name       = "redmine_user"
  password   = var.db_password
}

resource "yandex_mdb_postgresql_database" "db" {
  cluster_id = yandex_mdb_postgresql_cluster.db_cluster.id
  name       = "redmine"
  owner      = yandex_mdb_postgresql_user.user.name
}

# Настройка балансировщика нагрузки (Application Load Balancer)
resource "yandex_alb_target_group" "web_targets" {
  name = "web-targets"

  dynamic "target" {
    for_each = yandex_compute_instance.web
    content {
      subnet_id  = target.value.network_interface[0].subnet_id
      ip_address = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_alb_backend_group" "web_backend_group" {
  name = "web-backend-group"

  http_backend {
    name             = "web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_targets.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout             = "2s"
      interval            = "2s"
      healthy_threshold   = 2
      unhealthy_threshold = 2
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web_router" {
  name = "web-router"
}

resource "yandex_alb_virtual_host" "web_virtual_host" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "route-all"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_backend_group.id
        timeout          = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web_alb" {
  name               = "web-load-balancer"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.alb_sg.id]

  allocation_policy {
    location {
      zone_id   = var.yc_zone
      subnet_id = yandex_vpc_subnet.subnet.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }

  listener {
    name = "https-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [443]
    }
    tls {
      default_handler {
        certificate_ids = [yandex_cm_certificate.my_cert.id]
        http_handler {
          http_router_id = yandex_alb_http_router.web_router.id
        }
      }
    }
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

# Генерация инвентаря для Ansible
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
  content         = <<EOT
[webservers]
%{for idx, ip in yandex_compute_instance.web[*].network_interface[0].nat_ip_address~}
app-${idx + 1} ansible_host=${ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
%{endfor~}
EOT
}

# Генерация переменных БД для Ansible
resource "local_file" "ansible_vars" {
  filename        = "${path.module}/../ansible/group_vars/all/terraform_vars.yml"
  file_permission = "0644"
  content         = <<EOT
---
redmine_db_host: "${[for h in yandex_mdb_postgresql_cluster.db_cluster.host : h.fqdn][0]}"
EOT
}

# Данные существующей DNS зоны
data "yandex_dns_zone" "zone" {
  dns_zone_id = var.dns_zone_id
}

# DNS A-запись для основного домена
resource "yandex_dns_recordset" "a_record" {
  zone_id = data.yandex_dns_zone.zone.id
  name    = "magical-lovelace.ru."
  type    = "A"
  ttl     = 600
  data    = [yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address]
}

# DNS A-запись для поддомена www
resource "yandex_dns_recordset" "www_record" {
  zone_id = data.yandex_dns_zone.zone.id
  name    = "www.magical-lovelace.ru."
  type    = "A"
  ttl     = 600
  data    = [yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address]
}

