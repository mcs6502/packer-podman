packer {
  required_version = "~> 1.6"
}

source "vagrant" "main" {
  communicator = "ssh"
  provider     = "virtualbox"
  add_force    = true
  source_path  = "bento/debian-10.8"

  # box_name = "thelonelyghost/podman-remote"
}
