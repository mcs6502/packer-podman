# Podman Remote

Given the lack of equivalent to Docker Desktop for Podman, and that MacOS is a popular developer workstation, this shim has appeared.

## Requirements

- [Packer](https://www.packer.io/) >= v1.6.0
- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)
- [Podman](https://www.podman.io/)
- (optional) `timeout` from GNU coreutils

## Usage

It is fair to use `thelonelyghost/podman-remote` from https://app.vagrantup.com/ since every tagged version there correlates exactly to a tag in the git repo. A suggested, idempotent workflow might look like this:

```shell
~/workspace $ ./setup-podman-remote.sh
[a lot of output]

~/workspace $ podman info
host:
  arch: amd64
  buildahVersion: 1.18.0
  cgroupManager: cgroupfs
  cgroupVersion: v1
  conmon:
    package: 'conmon: /usr/libexec/podman/conmon'
    path: /usr/libexec/podman/conmon
    version: 'conmon version 2.0.22, commit: '
  cpus: 2
  distribution:
    distribution: debian
    version: "10"
  eventLogger: journald
  hostname: podman-remote
  idMappings:
    gidmap:
    - container_id: 0
      host_id: 1000
      size: 1
    - container_id: 1
      host_id: 100000
      size: 65536
    uidmap:
    - container_id: 0
      host_id: 1000
      size: 1
    - container_id: 1
      host_id: 100000
      size: 65536
  kernel: 4.19.0-9-amd64
  linkmode: dynamic
  memFree: 3842957312
  memTotal: 4138524672
  ociRuntime:
    name: runc
    package: 'cri-o-runc: /usr/lib/cri-o-runc/sbin/runc'
    path: /usr/lib/cri-o-runc/sbin/runc
    version: 'runc version spec: 1.0.2-dev'
  os: linux
  rootless: true
  slirp4netns:
    executable: /usr/bin/slirp4netns
    package: 'slirp4netns: /usr/bin/slirp4netns'
    version: |-
      slirp4netns version 0.2.3
      commit: be6d34ba4c7ac62b9f31b0ea931ec91a5f16dc3b
  swapFree: 1070592000
  swapTotal: 1070592000
  uptime: 33m 32.99s
registries:
  search:
  - docker.io
  - quay.io
store:
  configFile: /home/vagrant/.config/containers/storage.conf
  containerStore:
    number: 0
    paused: 0
    running: 0
    stopped: 0
  graphDriverName: vfs
  graphOptions: {}
  graphRoot: /home/vagrant/.local/share/containers/storage
  graphStatus: {}
  imageStore:
    number: 0
  runRoot: /run/user/1000/containers
  volumePath: /home/vagrant/.local/share/containers/storage/volumes
version:
  APIVersion: 2.1.0
  Built: 0
  BuiltTime: Thu Jan  1 00:00:00 1970
  GitCommit: ""
  GoVersion: go1.14
  OsArch: linux/amd64
  Version: 2.2.1
```

```bash
#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2223
: ${BOX:=thelonelyghost/podman-remote}
# shellcheck disable=SC2223
: ${PUBKEY:=podman}
# shellcheck disable=SC2223
: ${PORT:=65022}

if ! [ -e ~/.ssh/"${PUBKEY}" ]; then
  ssh-keygen -t ed25519 -f ~/.ssh/"${PUBKEY}" -N '' -C 'podman-remote (vagrant)'
fi

if ! grep -qFe "\"~/.ssh/$PUBKEY\"" -e "\"${BOX}\"" -e "host: ${PORT}" Vagrantfile &>/dev/null; then
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
    cat ~/.ssh/me.pub > ~/.ssh/authorized_keys
    chmod 755 ~/.ssh
    chmod 644 ~/.ssh/authorized_keys
  SHELL
end
EOH
  vagrant destroy --force || true
fi

vagrant up

ssh -i ~/.ssh/"${PUBKEY}" -p "${PORT}" vagrant@127.0.0.1 'hostname'

set -x
podman system connection remove vagrant
podman system connection add --identity ~/.ssh/"${PUBKEY}" --port "${PORT}" vagrant vagrant@127.0.0.1
podman system connection default vagrant
set +x

# FIXME: The first time connecting always seems to hang
timeout --signal HUP 2 podman info || true
set -x
podman info
```

## Building from source

Another option if Vagrant Cloud isn't trustworthy is to build it yourself with Packer, then run `vagrant up` using the box you've built.

```shell
~/workspace $ packer build .
[a lot of output]

~/workspace $ ./setup.sh
[a lot more output]

~/workspace $ podman info
host:
  arch: amd64
  buildahVersion: 1.18.0
  cgroupManager: cgroupfs
  cgroupVersion: v1
  conmon:
    package: 'conmon: /usr/libexec/podman/conmon'
    path: /usr/libexec/podman/conmon
    version: 'conmon version 2.0.22, commit: '
  cpus: 2
  distribution:
    distribution: debian
    version: "10"
  eventLogger: journald
  hostname: podman-remote
  idMappings:
    gidmap:
    - container_id: 0
      host_id: 1000
      size: 1
    - container_id: 1
      host_id: 100000
      size: 65536
    uidmap:
    - container_id: 0
      host_id: 1000
      size: 1
    - container_id: 1
      host_id: 100000
      size: 65536
  kernel: 4.19.0-9-amd64
  linkmode: dynamic
  memFree: 3843481600
  memTotal: 4138524672
  ociRuntime:
    name: runc
    package: 'cri-o-runc: /usr/lib/cri-o-runc/sbin/runc'
    path: /usr/lib/cri-o-runc/sbin/runc
    version: 'runc version spec: 1.0.2-dev'
  os: linux
  rootless: true
  slirp4netns:
    executable: /usr/bin/slirp4netns
    package: 'slirp4netns: /usr/bin/slirp4netns'
    version: |-
      slirp4netns version 0.2.3
      commit: be6d34ba4c7ac62b9f31b0ea931ec91a5f16dc3b
  swapFree: 1070592000
  swapTotal: 1070592000
  uptime: 31m 43.92s
registries:
  search:
  - docker.io
  - quay.io
store:
  configFile: /home/vagrant/.config/containers/storage.conf
  containerStore:
    number: 0
    paused: 0
    running: 0
    stopped: 0
  graphDriverName: vfs
  graphOptions: {}
  graphRoot: /home/vagrant/.local/share/containers/storage
  graphStatus: {}
  imageStore:
    number: 0
  runRoot: /run/user/1000/containers
  volumePath: /home/vagrant/.local/share/containers/storage/volumes
version:
  APIVersion: 2.1.0
  Built: 0
  BuiltTime: Thu Jan  1 00:00:00 1970
  GitCommit: ""
  GoVersion: go1.14
  OsArch: linux/amd64
  Version: 2.2.1
```
