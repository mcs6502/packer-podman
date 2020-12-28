# Podman Remote

Given the lack of equivalent to Docker Desktop for Podman, and that MacOS is a popular developer workstation, this shim has appeared.

## Requirements

- [Packer](https://www.packer.io/) >= v1.6.0
- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)
- [Podman](https://www.podman.io/)
- (optional) `timeout` from GNU coreutils

## Usage

It is fair to use `thelonelyghost/podman-remote` from https://app.vagrantup.com/ since every tagged version there correlates exactly to a tag in the git repo.

There are 2 main scripts for setting up a VM and connecting your local podman client to it: `setup-from-dist.sh` and `setup-from-source.sh`. Each one is very similar to the other, but the main exception is `setup-from-source.sh` uses the local vagrant box that is output from running `packer build .` instead of the one uploaded to Vagrant Cloud.

A suggested, idempotent workflow might leverage `./setup-from-dist.sh` to look like this:

```shell
~/workspace $ ./setup-from-dist.sh
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

If Vagrant Cloud doesn't seem trustworthy, one can build it on their own with Packer, then start the VM and configure it to work with `podman`. Everything you need for that build is either contained in this repository or available publicly:

```shell
~/workspace $ packer build .
[a lot of output]

~/workspace $ ./setup-from-source.sh
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
