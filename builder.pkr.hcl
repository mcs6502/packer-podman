build {
  sources = ["vagrant.main"]

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      # "apt-get -y upgrade",
      # "apt-get -y dist-upgrade",
      "apt-get -y install curl gnupg2",
      "curl -sL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/Release.key | apt-key add - 2>/dev/null",

      "usermod -a -G systemd-journal vagrant",
      "sysctl -w kernel.unprivileged_userns_clone=1",
      "echo kernel.unprivileged_userns_clone=1 > /etc/sysctl.d/00-local-userns.conf",
      "loginctl enable-linger vagrant",

      # Use buster-backports on Debian 10 for a newer libseccomp2
      "echo deb http://deb.debian.org/debian buster-backports main > /etc/apt/sources.list.d/buster-backports.list",
      # Add podman repo for debian 10 from opensuse.org
      "echo deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/ / > /etc/apt/sources.list.d/libcontainers.list",
      "apt-get update",
      "apt-get -y -t buster-backports install libseccomp2",
      "apt-get -y install podman",
      "apt-get -y autoremove",

      "loginctl enable-linger vagrant",
    ]
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} sh -c {{ .Path }}"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p ~/.config/systemd/user/podman.service.d",
      "{ echo '[Service]'; echo 'NotifyAccess=all'; } > ~/.config/systemd/user/podman.service.d/notify-access.conf",
      "systemctl --user daemon-reload",
      "systemctl --user enable --now podman.socket",
    ]
  }

  # post-processor "vagrant-cloud" {
  #   vagrant_cloud_url = "https://app.vagrantup.com/api/v1"
  # }
}
