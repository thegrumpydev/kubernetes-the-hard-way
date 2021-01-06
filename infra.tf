provider "google" {
  project = local.project_id
  region  = local.region
  zone    = local.zone
}

resource "google_compute_instance" "controller" {
  count        = 3
  name         = "controller-${count.index}"
  machine_type = "e2-standard-2"

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
  machine_type = "e2-standard-2"

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
