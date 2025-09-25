# mobik-automation-challenge

## Introduction

This project demonstrates the setup of a local DevOps environment using Vagrant,
Ansible, and Kubernetes. The goal was to automate the provisioning of a virtual
machine (VM) and deploy a containerized application with a backend, frontend, and
database. This README outlines the steps taken, challenges encountered, and
solutions implemented.

## Setup Instructions

To set up the project, follow these steps:

1. Open a terminal in the project directory.

2. Run the following command to create and start the VM:

  ```bash
  vagrant up
  ```

3. Once the VM is running, provision it with Ansible by executing:

  ```bash
  vagrant provision
  ```

4. Access the application by opening your browser and navigating to [http://192.168.56.10](http://192.168.56.10:30080).

After these steps, the VM will be configured and the application will be available at the specified address.

### Part One Contributions

In the first part of the project, I contributed to the Linux server administration tasks, which are documented in detail in the `answers/takehome_part_1.md` file. This file contains:

- Solutions to the Linux server administration challenges.
- Step-by-step explanations of the tasks performed.
- Insights and troubleshooting steps taken during the process.

These contributions laid the groundwork for the automated provisioning and deployment processes described in the subsequent sections.

## Setting up the Local DevOps Environment

I separated infrastructure (Vagrantfile) from configuration (ansible/), which is
a best practice in DevOps. The VM was configured to use the Debian Bookworm
64-bit base image, assigned the name `k8s-vm`, set its hostname to `k8s-vm`, and
given a static private IP address of `192.168.56.10`. Resources allocated
included 4096 MB of memory and 2 CPU cores. The VM was provisioned using Ansible
with the `ansible_local` provisioner, meaning Ansible was installed and executed
inside the VM itself, rather than on the host machine.

```code
mobik-automation-challenge/
├── Vagrantfile
└── ansible/
    ├── setup.yml
    └── hosts.ini
```

## Automated Provisioning with Ansible

### Ansible Setup

To support Ansible provisioning, an `ansible` subdirectory was created inside
the project folder. Within this directory, two files were added: `setup.yml` and
`hosts.ini`. The `hosts.ini` file defined a group named `[k8s]` and listed
`k8s-vm` as the target host, using a local connection method. This ensured that
Ansible would run commands directly inside the VM.

- Created an `ansible/setup.yml` playbook to install:
  - Docker
  - Minikube
  - kubectl

The `setup.yml` file is an Ansible playbook containing tasks to automate the
installation of essential tools for Kubernetes development. These tasks include
installing system dependencies like `curl` and `gnupg`, installing Docker using
the official convenience script, downloading and installing Minikube from its
latest release, and downloading and installing the latest stable version of
`kubectl`. The playbook was carefully structured to use shell commands and
ensured that each installation step was idempotent by using the `creates`
argument to prevent redundant execution.

- Used `ansible_local` provisioning so Ansible runs inside the VM.
- Defined an inventory file (`ansible/hosts.ini`) to target the VM locally.



These contributions were integral to automating the provisioning process and ensuring a robust and repeatable setup.

### Provisioning the VM

Once the configuration was complete, the following steps were executed:

1. Ran `vagrant up` to launch the VM.
2. Ran `vagrant provision` to execute the Ansible playbook.
3. Accessed the VM using `vagrant ssh` to verify installations.

### Verifications

- Confirmed Docker, Minikube, and kubectl were installed and working.
- Resolved a shell quoting issue in the kubectl installation task.

## Kubernetes Setup

### Preparing Minikube

Minikube was started using the `none` driver:

```bash
sudo -u vagrant CHANGE_MINIKUBE_NONE_USER=true minikube start --driver=none
```

This initializes a single-node Kubernetes cluster inside the VM. Initially,
basic system packages such as `curl`, `apt-transport-https`, `ca-certificates`,
`gnupg`, and `lsb-release` were included. Docker was installed using the
official convenience script. Minikube was downloaded and installed using its
Debian package, and kubectl was dynamically fetched and placed in the system
path.

As Minikube was started, missing dependencies were reported one by one. The
playbook was updated each time to address these issues:

- Added `conntrack` to the list of apt packages for Kubernetes networking.
- Added a shell task to download and extract `crictl` for Kubernetes to interact
  with the container runtime.
- Added a shell task to download and install the pre-built Debian package for
  `cri-dockerd` version 0.3.20.
- Added a shell task to download and extract container networking plugins into
the appropriate directory.

Each modification to `setup.yml` ensured tasks were idempotent by using
conditions to prevent repeated execution. `vagrant provision` was run to apply
the changes, and the results were verified by attempting to start Minikube
again. Through this process, the playbook evolved into a complete automation
script capable of preparing a fully functional Kubernetes environment using the
`none` driver.

### Automating Minikube Startup

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
- Removed the `--memory` flag from the Minikube startup command because the
  `none` driver doesn’t support memory allocation—it runs directly on the host.
- Ensured Docker was installed before Minikube started, so Minikube could detect
  and use the container runtime correctly.
- Added the `vagrant` user to the `docker` group, allowing Minikube to access
the Docker socket without permission errors.
- Used a login shell (`su - vagrant -c '...'`) to start Minikube, ensuring the
  Docker group membership was applied immediately without needing a reboot.
- Set a custom `PATH` environment during Minikube startup to include `/usr/sbin`,
  ensuring system binaries like `iptables` were accessible to the `vagrant`
  user.
- Added a verification step to confirm the setup was successful.

## Application Deployment

### Backend

- Developed a Go-based backend API that connects to a PostgreSQL database.
- Endpoints:
  - `/api/hello`: Verifies database connectivity and responds with a message.
  - `/health`: Provides a health check endpoint for readiness and liveness
    probes.
- Implemented error handling for database connectivity.

### Frontend

- Developed a simple web application serving a static HTML page.
- Implemented a script to fetch data from the backend API (`/api/hello`).
- Containerized the application using an Nginx-based Docker image.

### Kubernetes Manifests

- Created manifests for deploying the backend, database, and frontend.
- Configured environment variables, readiness/liveness probes, and resource
  limits.
- Exposed components using Kubernetes Services.

## Debugging and Troubleshooting

### Resolving Missing Files

1. **Issue**: The `db-deployment.yml` file was not synced to the VM.
   - **Solution**: Updated the `Vagrantfile` to sync the `kubernetes` directory.

     ```ruby
     config.vm.synced_folder "./kubernetes", "/home/vagrant/project/kubernetes"
     ```

2. **Verification**: SSHed into the VM and confirmed the presence of the file.

### Namespace Issues

- **Issue**: The `deploy-app.yml` playbook failed due to missing namespaces.
- **Solution**: Updated the playbook to dynamically create the `kubeapp`
  namespace:

  ```yaml
  - name: Create kubeapp namespace
    shell: |
      kubectl get namespace kubeapp || kubectl create namespace kubeapp
  ```

### Final Adjustments

- Ensured all tasks in the `deploy-app.yml` playbook are idempotent.
- Verified application functionality using `kubectl exec` and browser tests.

## Conclusion

This project demonstrates the automation of a Kubernetes-based application
deployment using Vagrant, Ansible, and Minikube. The detailed steps and
troubleshooting ensure a reproducible and robust setup.
