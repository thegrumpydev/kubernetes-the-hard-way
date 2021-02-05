provider "google" {
  project = local.project_id
  region  = local.region
  zone    = local.zone
}

provider "google-beta" {
  project = local.project_id
  region  = local.region
  zone    = local.zone
}

resource "google_compute_instance" "controller" {
  count        = 3
  name         = "controller-${count.index}"
  machine_type = local.shapes.controller

  tags = ["kubernetes-the-hard-way", "controller"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 200
    }
  }

  can_ip_forward = true

  network_interface {
    subnetwork = google_compute_subnetwork.kubernetes.self_link
    network_ip = "10.240.0.1${count.index}"
    access_config {
    }
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
}

resource "google_compute_instance" "worker" {
  count        = 3
  name         = "worker-${count.index}"
  machine_type = local.shapes.worker

  tags = ["kubernetes-the-hard-way", "worker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 200
    }
  }

  can_ip_forward = true

  metadata = {
    pod-cidr = "10.200.${count.index}.0/24"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.kubernetes.self_link
    network_ip = "10.240.0.2${count.index}"
    access_config {
    }
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "kubernetes-the-hard-way"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "kubernetes" {
  name          = "kubernetes"
  ip_cidr_range = "10.240.0.0/24"
  region        = "us-west3"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_route" "pod_routes" {
  count       = 3
  name        = "kubernetes-route-10-200-${count.index}-0-24"
  dest_range  = "10.200.${count.index}.0/24"
  network     = google_compute_network.vpc_network.name
  next_hop_ip = "10.240.0.2${count.index}"
  priority    = 100
  depends_on  = [google_compute_instance.controller]
}

resource "google_compute_firewall" "internal" {
  name    = "kubernetes-the-hard-way-allow-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]
}

resource "google_compute_firewall" "external" {
  name    = "kubernetes-the-hard-way-allow-external"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }
}

resource "google_compute_address" "external" {
  name         = "kubernetes-the-hard-way"
  address_type = "EXTERNAL"
}

resource "google_compute_forwarding_rule" "kubernetes-forwarding-rule" {
  provider              = google-beta
  name                  = "kubernetes-forwarding-rule"
  region                = local.region
  port_range            = 6443
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_address.external.address
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.kubernetes-backend-service.id
  network_tier          = "PREMIUM"
}

resource "google_compute_region_backend_service" "kubernetes-backend-service" {
  provider                        = google-beta
  name                            = "kubernetes-backend-service"
  health_checks                   = [google_compute_region_health_check.kubernetes.id]
  connection_draining_timeout_sec = 10
  load_balancing_scheme           = "EXTERNAL"
  protocol                        = "TCP"
  backend {
    group = google_compute_instance_group.controllers.id
  }
}

resource "google_compute_region_health_check" "kubernetes" {
  provider = google-beta
  name     = "kubernetes-health-check"
  region   = local.region

  tcp_health_check {
    port = 6443
  }
}

resource "google_compute_instance_group" "controllers" {
  name      = "kubernetes-controllers"
  instances = google_compute_instance.controller[*].id

  named_port {
    name = "kube-apiserver"
    port = "6443"
  }
  zone = local.zone
}

locals {
  ansible_hosts = templatefile("${path.module}/../template/hosts.tpl", { controllers = google_compute_instance.controller, workers = google_compute_instance.worker })
  ansible_variables = templatefile("${path.module}/../template/variables.tpl", { public_ip = google_compute_address.external.address,
    controllers = google_compute_instance.controller,
  workers = google_compute_instance.worker })
}

resource "local_file" "hosts" {
  content  = local.ansible_hosts
  filename = "${path.module}/../inventory/hosts"
}

resource "local_file" "variables" {
  content  = local.ansible_variables
  filename = "${path.module}/../variables/variables.yml"
}
