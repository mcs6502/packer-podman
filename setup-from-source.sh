#!/usr/bin/env bash
set -euo pipefail

run-verbosely() {
  printf '%q ' "$@" | bash -x
}

# shellcheck disable=SC2223
: ${BOX:=./output-main/package.box}
# : ${BOX:=thelonelyghost/podman-remote}
# shellcheck disable=SC2223
: ${PUBKEY:=podman}
# shellcheck disable=SC2223
: ${PORT:=65022}

if ! [ -e ~/.ssh/"${PUBKEY}" ]; then
  ssh-keygen -t ed25519 -f ~/.ssh/"${PUBKEY}" -N '' -C 'podman-remote (vagrant)'
fi

if ! grep -qFe "\"~/.ssh/$PUBKEY\"" -e "\"${BOX}\"" -e "host: ${PORT}" Vagrantfile &>/dev/null || test $0 -nt Vagrantfile; then
cat <<EOH > Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "${BOX}"
  config.vm.box_check_update = false
  config.vm.hostname = "podman-remote"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.network "forwarded_port", guest: 22, host: ${PORT}

  config.vm.provider "virtualbox" do |vb|
    # Customize the amount of memory on the VM:
    vb.memory = "4096"
  end

  config.ssh.insert_key = false
  config.vm.provision "file", source: "~/.ssh/${PUBKEY}.pub", destination: "~/.ssh/me.pub"
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    mkdir -p ~/.ssh
    if ! grep -qFe "\$(cat ~/.ssh/me.pub)" ~/.ssh/authorized_keys &>/dev/null; then
      cat ~/.ssh/me.pub >> ~/.ssh/authorized_keys
    fi
    chmod 755 ~/.ssh
    chmod 644 ~/.ssh/authorized_keys
  SHELL
end
EOH
  vagrant destroy --force || true
fi

vagrant up

# After first provisioning, we'll use the generated key for
# subsequent connections. Vagrant doesn't make this easy in
# the config file.
sed -i '' -e 's/#config.ssh.private_key_path/config.ssh.private_key_path/g' ./Vagrantfile || true

ssh-keyscan -p "${PORT}" 127.0.0.1 2>/dev/null | while read -r line; do
  if ! grep -qFe "$line" ~/.ssh/known_hosts; then
    printf '%s\n' "$line" >> ~/.ssh/known_hosts
  fi
done

run-verbosely podman system connection remove vagrant
run-verbosely podman system connection add --identity ~/.ssh/"${PUBKEY}" --port "${PORT}" vagrant vagrant@127.0.0.1
run-verbosely podman system connection default vagrant

timeout --signal HUP 2 podman info &>/dev/null || true
run-verbosely podman info
