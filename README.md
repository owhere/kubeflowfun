# Deploying Kubeflow on OpenStack Cloud

Kubeflow is fun, is it really!?

No, deploying Kubeflow could be challenging because it has many components and the built-in and third-party dependencies, for example, how to make sure a Jupyter Notebook run with proper amount of storage created for the run, which is not only the configuration in kubeflow, but also in kubernetes and in underlying infrastructure, in this case, OpenStack.

This repository provides a comprehensive guide and necessary configurations to deploy **Kubeflow** on a **Kubernetes (k8s)** cluster within an **OpenStack** cloud platform. The deployment process leverages tools like **Ansible**, **Kubespray**, **Kubeflow Manifest** to automate and streamline the setup.

The following repositories and resources were used for this deployment:

- [Kubeflow](https://github.com/kubeflow/kubeflow): The primary repository for Kubeflow, a machine learning toolkit for Kubernetes.
- [Kubespray](https://github.com/kubernetes-sigs/kubespray): A collection of Ansible playbooks for provisioning and managing Kubernetes clusters.
- [cloud-provider-openstack](https://github.com/kubernetes/cloud-provider-openstack): Repository for OpenStack cloud provider integrations with Kubernetes.
- [Helm](https://github.com/helm/helm): The Kubernetes package manager used for deploying additional components.
- [Kubeflow Manifests](https://github.com/kubeflow/manifests): The repository containing manifests for deploying and managing Kubeflow components.


## Table of Contents

- [Overview](#overview)
- [Folder Structure](#folder-structure)
- [Prerequisites](#prerequisites)
- [Deployment Steps](#deployment-steps)
  - [Step 0: Prepare the Bastion Node](#step-0-prepare-the-bastion-node)
  - [Step 1: Create OpenStack Instances](#step-1-create-openstack-instances)
  - [Step 2: Run Ansible Playbooks](#step-2-run-ansible-playbooks)
  - [Step 3: Deploy Kubernetes with Kubespray](#step-3-deploy-kubernetes-with-kubespray)
  - [Step 4: Apply Kubeflow Common Manifests](#step-4-apply-kubeflow-common-manifests)
  - [Step 5: Apply Kubeflow Application Manifests](#step-5-apply-kubeflow-application-manifests)
- [Not essentional but important](#additional-components)
- [License](#license)

## Overview

This repository is designed to facilitate the deployment of Kubeflow on a Kubernetes cluster hosted on an OpenStack cloud platform. The deployment process includes the following tasks:

0. **Prepare a bastion node**: Set up a control node where Kubespray will be executed to deploy Kubernetes.
1. **Create OpenStack instances**: Provision three instances—one for the control plane and two for worker nodes.
2. **Run Ansible playbooks**: Install necessary prerequisites on all nodes before deploying Kubernetes.
3. **Deploy Kubernetes with Kubespray**: Use Kubespray to set up a Kubernetes cluster on the prepared nodes.
4. **Apply Kubeflow common manifests**: Deploy common Kubeflow components.
5. **Apply Kubeflow application manifests**: Deploy Kubeflow applications like Notebooks.

## Folder Structure

```plaintext
├── LICENSE
├── README.md
├── ansible
│   ├── ansible.cfg
│   ├── inventory
│   └── playbooks
├── cloud-provider-openstack
│   └── manifests
├── helm
│   ├── echo-server
│   ├── ingress.sh
│   ├── matrix.sh
│   └── storage.yaml
├── kubeflow-manifests
│   ├── apps
│   ├── common
│   └── tests
└── kubespray-inventory
    └── funkube
```

- **ansible/**: Contains Ansible configurations and playbooks for preparing nodes.
  - `ansible.cfg`: Ansible configuration file.
  - `inventory`: Hosts inventory file.
  - `playbooks/`: Directory with Ansible playbooks.
- **cloud-provider-openstack/**: Holds manifests for integrating Kubernetes with OpenStack, this only holds the changes that made to original repo, [cloud-provider-openstack](https://github.com/kubernetes/cloud-provider-openstack)
  - `manifests/`: OpenStack-specific Kubernetes manifests.
- **helm/**: Includes Helm charts and scripts for deploying additional services.
  - `echo-server/`: Helm chart for deploying an Echo server.
  - `ingress.sh`: Script to set up ingress controllers.
  - `matrix.sh`: Script for deploying Matrix component.
  - `storage.yaml`: Configuration for persistent storage.
- **kubeflow-manifests/**: Contains manifests for deploying Kubeflow components.
  - `apps/`: Application-specific manifests (e.g., Notebooks).
  - `common/`: Common Kubeflow components.
  - `tests/`: Test manifests for validation.
  The apps and common folder are copied from the original repo, [Kubeflow Manifests](https://github.com/kubeflow/manifests), but only the components that deployed/tested up to the latest update here. You do NOT need original repo to run.
- **kubespray-inventory/**: Inventory files for Kubespray deployment.
  - `funkube/`: Specific inventory for the Kubernetes cluster.
  This folder only holds the customisation part that needs to the original repo, [Kubespray](https://github.com/kubernetes-sigs/kubespray). You do need to original repo to run.

## Prerequisites

- Access to an OpenStack cloud environment. (have openrc.sh file)
- Create instances of bastion at Openstack
- Basic understanding of Ansible, Kubernetes, Kubeflow.

## Deployment Steps

### Step 0: Prepare the Bastion Node

- **System update**: Ensure latest kernel

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

- **Install Openstack CLI**

```bash
sudo apt install build-essential
sudo apt install -y python3 python3-pip python3-venv
python3 -m venv env
source env/bin/activate
pip install openstackclient
source openrc.sh
openstack server list
```

- **Install Ansible**: Ensure Ansible is installed on the bastion node.

```bash
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
```

- **Set up Kubespray**: Clone the Kubespray repository.

```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
```

### Step 1: Create OpenStack Instances

- **Provision Instances**: Create three instances in OpenStack.
  - **Control Plane Node**: Manages cluster state.
  - **Worker Nodes**: Run workloads.
- **Configure Networking**: Ensure instances can communicate and are accessible from the bastion node.
- **Assign Floating IPs**: If necessary, assign floating IPs for external access. Otherwise, we can use SSL tunnel to test.

### Step 2: Set up nodes with ansible

Have IP and hosts information ready and make your own [hosts file](ansible/inventory/hosts) copy 

- **Run Playbooks**: Execute the playbooks to install prerequisites.
```bash
ansible-playbook -i inventory playbooks/prepare_nodes.yml
```

### Step 3: Deploy Kubernetes with Kubespray

Have IP and hosts information ready and make your own [inventory file](kubespray-inventory/funkube/inventory.ini)
- **Copy Inventory**:

  ```bash
  cp -r kubespray/inventory/sample kubespray-inventory/funkube
  ```
- **Update Inventory**: Modify `kubespray-inventory/funkube/hosts.yaml` with your cluster nodes.
- **Deploy Cluster**:

```bash
cp -r kubespray/inventory sample funkube
cp kubeflowfun/ansible/inventory/hosts kubespray/inventory/funkube/inventory.ini
cd kubespray
ansible-playbook -i inventory/funkube/inventory.ini cluster.yml
```

### Step 4: Apply Kubeflow Common Manifests

- **Navigate to Manifests**:

  ```bash
  cd kubeflow-manifests/common
  ```

- **Apply Manifests**:

  ```bash
  kubectl apply -k .
  ```

### Step 5: Apply Kubeflow Application Manifests

- **Navigate to Apps**:

  ```bash
  cd ../apps
  ```

- **Apply Manifests**:

  ```bash
  kubectl apply -k .
  ```

## Additional Components

- **Deploy Echo Server**:

  ```bash
  cd helm/echo-server
  helm install echo-server .
  ```

- **Set Up Ingress**:

  ```bash
  cd helm
  ./ingress.sh
  ```

- **Deploy Matrix Component**:

  ```bash
  ./matrix.sh
  ```

- **Configure Storage**:

  ```bash
  kubectl apply -f storage.yaml
  ```

## License

This project is licensed under the [Apache License](LICENSE).

---

Feel free to open issues or submit pull requests for improvements or fixes.

