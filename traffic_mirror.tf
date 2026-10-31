# Making a security group for the traffic mirror source

resource "aws_security_group" "mirror_source" {
  vpc_id = "(VPC_for_mirror_source)"
}


# Making a security group for the traffic mirror target

resource "aws_security_group" "mirror_target" {
  vpc_id = "(VPC_for_mirror)"
}


# Making a security group rule to ingress all traffic in the source mirror sg

resource "aws_security_group_rule" "ingress_all" {
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mirror_source.id
}


# Making a security group rule to ingress all ssh in the target mirror sg
resource "aws_security_group_rule" "ssh" {
  type = "ingress"
  from_port = 22
  to_port   = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mirror_target.id
}


# Making a security group rule to ingress all port 4789 traffic in the target mirror sg
resource "aws_security_group_rule" "ingress_from_source" {
  type = "ingress"
  from_port = 4789 # Port needed for traffic Mirroring
  to_port   = 4789
  protocol = "udp"
  source_security_group_id = aws_security_group.mirror_source.id
  security_group_id = aws_security_group.mirror_target.id
}


# Deploying a Nitro instance with an image to be the  mirror source in the public network

resource "aws_instance" "mirror_source" {
  ami =  "(ami_id1)"
  instance_type = "t3.nano" # Nitro Instance
  subnet_id = "(subnet_id)"
  vpc_security_group_ids = [aws_security_group.mirror_source.id]
}


# Deploying a Nitro instance with an image to be the mirror target in the public network

resource "aws_instance" "mirror_target" {
  ami = "(ami_id2)"
  instance_type = "t3.nano" # Nitro  Instance
  subnet_id = aws_instance.mirror_source.subnet_id
  key_name = "sec510"
  vpc_security_group_ids = [aws_security_group.mirror_target.id]
}


# Created a traffic mirror filter

resource "aws_ec2_traffic_mirror_filter" "filter" {
}


# Created  rules that will be configured in the traffic mirror filter

resource "aws_ec2_traffic_mirror_filter_rule" "ingress" {
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "ingress"
}


# This resource will specify the network interface the mirrored traffic will be copied to.

resource "aws_ec2_traffic_mirror_target" "target" {
  network_interface_id = aws_instance.mirror_target.primary_network_interface_id
}


# Resource used to start copying data from the source instance to the target

resource "aws_ec2_traffic_mirror_session" "session" {
  network_interface_id =  aws_instance.mirror_source.primary_network_interface_id
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.target.id
  session_number = 1
}


# GCP Traffic Mirror Configuration


# Created an instance for the mirror collector.
resource "google_compute_instance" "mirror_collector" {
  name = "cloudwars-mirror-collector"
  machine_type =  "n1-standard-1"
  zone = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "ubuntu-2404-lts-amd64"
    }
  }

  network_interface {
    network = "(network_url)"
    subnetwork = "(subnetwork_url)"
    access_config {
      // Ephermeral IP
    }
  }

  metadata = {
    ssh-keys = "(SSH_KEY)"
  }

  metadata_startup_script = <<EOT
apt-get install -y nginx

cat > /etc/nginx/sites-enabled/default <<EOL
server {
  listen 80;

  location / {
    return 200;
  }
}
EOL

systemctl restart nginx
systemctl enable nginx
  EOT
}


# Added mirror collector instance to a instance group.

resource "google_compute_instance_group" "mirror_collector" {
  name = "cloudwars-mirror-collector"
  instances = [google_compute_instance.mirror_collector.id]
  zone = google_compute_instance.mirror_collector.zone
}


# Set health checks on http.

resource "google_compute_health_check" "cloudwars" {
  name = "cloudwars"
  http_health_check {
    port = 80
  }
}

# Set a backend service and associate the health checks to the instance group.

resource "google_compute_region_backend_service" "cloudwars" {
  name = "cloudwars"
  health_checks = [google_compute_health_check.cloudwars.id]
  backend {
    group = google_compute_instance_group.mirror_collector.id
    balancing_mode = "CONNECTION"
  }
}


# Made a forwarding rule for the mirror collector.

resource "google_compute_forwarding_rule" "cloudwars" {
  name                   = "cloudwars"
  is_mirroring_collector = true
  load_balancing_scheme  = "INTERNAL"
  backend_service        = google_compute_region_backend_service.cloudwars.id
  all_ports              = true
  network                = google_compute_instance.mirror_collector.network_interface[0].network
  subnetwork             = google_compute_instance.mirror_collector.network_interface[0].subnetwork
}


# Mirrored interface of the mirror collector netowrk interface

resource "google_compute_packet_mirroring" "cloudwars" {
  name = "cloudwars"
  network {
    url = google_compute_instance.mirror_collector.network_interface[0].network
  }

  collector_ilb {
    url = google_compute_forwarding_rule.cloudwars.id
  }
  mirrored_resources {
    instances {
      url = "(Instances_url)"
    }
  }

  filter {
    ip_protocols = ["tcp"]
    cidr_ranges = ["0.0.0.0/0"]
    direction = "INGRESS"
  }
}
