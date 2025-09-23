# mobik-automation-challenge

## Setting up local DevOps environment

I separated infrastructure (Vagrantfile) from configuration (ansible/), which is a
best practice in DevOps. The VM was configured to use the Debian Bookworm 64-bit
base image, assigned the name `k8s-vm`, set its hostname to `k8s-vm`, and given a
static private IP address of `192.168.56.10`. Resources allocated included 4096 MB
of memory and 2 CPU cores. The VM was provisioned using Ansible with the
`ansible_local` provisioner, meaning Ansible was installed and executed inside the
VM itself, rather than on the host machine.

```code
mobik-automation-challenge/
├── Vagrantfile
└── ansible/
    ├── setup.yml
    └── hosts.ini
```

## Automated Provisioning with Ansible (Inside the VM)

To support Ansible provisioning, an `ansible` subdirectory was created inside the
project folder. Within this directory, two files were added: `setup.yml` and
`hosts.ini`. The `hosts.ini` file defined a group named `[k8s]` and listed `k8s-vm`
as the target host, using a local connection method. This ensured that Ansible
would run commands directly inside the VM.

- Created an `ansible/setup.yml` playbook to install:
  - Docker
  - Minikube
  - kubectl

The `setup.yml` file is an Ansible playbook containing tasks to automate the
installation of essential tools for Kubernetes development. These tasks include
installing system dependencies like `curl` and `gnupg`, installing Docker using
the official convenience script, downloading and installing Minikube from its
latest release, and downloading and installing the latest stable version of
`kubectl`. The playbook was carefully structured to use shell commands and ensured
that each installation step was idempotent by using the `creates` argument to
prevent redundant execution.

- Used `ansible_local` provisioning so Ansible runs inside the VM.
- Defined an inventory file (`ansible/hosts.ini`) to target the VM locally.

## Provisioned the VM Automatically

Once the configuration was complete, `vagrant up` was run to launch the VM,
followed by `vagrant provision` to execute the Ansible playbook. Vagrant installed
Ansible inside the VM and ran the setup tasks. The VM was accessed using
`vagrant ssh` to manually verify that Docker, Minikube, and kubectl were installed
correctly. A shell quoting issue in the kubectl installation task was resolved to
ensure the command executed properly.

- Ran `vagrant up` and `vagrant provision`.
- Vagrant installed Ansible inside the VM, as it was not possible on the Windows
  machine.
- Ansible executed the playbook and installed all required tools.
- Accessed the VM using `vagrant ssh`.
- Confirmed Docker, Minikube, and kubectl were installed and working.

## Ready to Launch Kubernetes

Prepared to start Minikube using the `none` driver:

```bash
sudo -u vagrant CHANGE_MINIKUBE_NONE_USER=true minikube start --driver=none
```

This initializes a single-node Kubernetes cluster inside the VM.

Initially, basic system packages such as `curl`, `apt-transport-https`,
`ca-certificates`, `gnupg`, and `lsb-release` were included. Docker was installed
using the official convenience script. Minikube was downloaded and installed using
its Debian package, and kubectl was dynamically fetched and placed in the system
path.

As Minikube was started, missing dependencies were reported one by one. The
playbook was updated each time to address these issues:

- Added `conntrack` to the list of apt packages for Kubernetes networking.
- Added a shell task to download and extract `crictl` for Kubernetes to interact
  with the container runtime.
- Added a shell task to download and install the pre-built Debian package for
  `cri-dockerd` version 0.3.20.
- Added a shell task to download and extract container networking plugins into the
  appropriate directory.

Each modification to `setup.yml` ensured tasks were idempotent by using conditions
to prevent repeated execution. `vagrant provision` was run to apply the changes,
and the results were verified by attempting to start Minikube again. Through this
process, the playbook evolved into a complete automation script capable of
preparing a fully functional Kubernetes environment using the `none` driver.

The Ansible playbook was further updated to fix permission issues and missing
directories that were blocking Minikube. Tasks included adding the `vagrant` user
to the `docker` group, creating the CNI configuration directory, and adding a
reboot step to apply the group membership change. This made the setup fully
automated and ready for Minikube to start without manual intervention.

To automate cluster startup, the following task was added:

```yaml
- name: Start Minikube with none driver and adjusted memory
  become: true
  become_user: vagrant
  shell: |
    CHANGE_MINIKUBE_NONE_USER=true minikube start --driver=none --memory=2800mb
  args:
    creates: /home/vagrant/.minikube
```

### Additional Fixes

- Installed `iptables` as part of the system dependencies to satisfy Minikube’s
  requirement for the `none` driver.
- Removed the `--memory` flag from the Minikube startup command because the `none`
  driver doesn’t support memory allocation—it runs directly on the host.
- Ensured Docker was installed before Minikube started, so Minikube could detect
  and use the container runtime correctly.
- Added the `vagrant` user to the `docker` group, allowing Minikube to access the
  Docker socket without permission errors.
- Used a login shell (`su - vagrant -c '...'`) to start Minikube, ensuring the
  Docker group membership was applied immediately without needing a reboot.
- Set a custom `PATH` environment during Minikube startup to include `/usr/sbin`,
  ensuring system binaries like `iptables` were accessible to the `vagrant` user.
- Added a verification step to confirm the setup was successful.

