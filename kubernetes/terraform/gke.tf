provider "google" {
  credentials = "${file("gce_account.json")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_compute_firewall" "default" {
  name    = "out2kubernetes"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }
}

resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}"
  zone               = "${var.zone}"
  initial_node_count = "${var.node_count}"
  min_master_version = "1.8.3-gke.0"
  node_version       = "1.8.3-gke.0"

  node_config {
    disk_size_gb = "${var.disk_size_gb}"
    machine_type = "${var.machine_type}"
  }

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project}"
  }
}

resource "google_compute_disk" "default" {
  name  = "reddit-mongo-disk"
  zone  = "${var.zone}"
  size = "${var.mongodb_disk_size_gb}"
}
