# Deploying Kubeflow on Kubernetes Cluster in OpenStack Cloud

Kubeflow is fun, is it really?

No, deploying Kubeflow could be challenging due to many components and related dependencies, not only among the components but also on underlying k8s and infrastructure, in this case, the Openstack. 

The following repositories and resources were used as references for this deployment:

- [Kubeflow](https://github.com/kubeflow/kubeflow): The primary repository for Kubeflow, a machine learning toolkit for Kubernetes.
- [Kubespray](https://github.com/kubernetes-sigs/kubespray): A collection of Ansible playbooks for provisioning and managing Kubernetes clusters.
- [cloud-provider-openstack](https://github.com/kubernetes/cloud-provider-openstack): Repository for OpenStack cloud provider integrations with Kubernetes.
- [Helm](https://github.com/helm/helm): The Kubernetes package manager used for deploying additional components.
- [Kubeflow Manifests](https://github.com/kubeflow/manifests): The repository containing manifests for deploying and managing Kubeflow components.

This repository provides a comprehensive guide and necessary configurations to deploy **Kubeflow** on a **Kubernetes (k8s)** cluster within an **OpenStack** cloud platform. The deployment process leverages tools like **Ansible**, **Kubespray**, **Kubeflow Manifest** to automate and streamline the setup.

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
- [Additional Components](#additional-components)
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
- **cloud-provider-openstack/**: Holds manifests for integrating Kubernetes with OpenStack.
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
- **kubespray-inventory/**: Inventory files for Kubespray deployment.
  - `funkube/`: Specific inventory for the Kubernetes cluster.

## Prerequisites

- Access to an OpenStack cloud environment.
- A bastion node with:
  - **Ansible** installed.
  - **Kubespray** cloned and configured.
- OpenStack CLI tools installed on the bastion node.
- SSH access to all OpenStack instances.
- Basic understanding of Kubernetes, Kubeflow, and Ansible.

## Deployment Steps

### Step 0: Prepare the Bastion Node

- **Install Ansible**: Ensure Ansible is installed on the bastion node.
- **Clone Kubespray**: Clone the Kubespray repository.

  ```bash
  git clone https://github.com/kubernetes-sigs/kubespray.git
  ```

- **Install Dependencies**: Navigate to the Kubespray directory and install dependencies.

  ```bash
  cd kubespray
  pip install -r requirements.txt
  ```

### Step 1: Create OpenStack Instances

- **Provision Instances**: Create three instances in OpenStack.
  - **Control Plane Node**: Manages cluster state.
  - **Worker Nodes**: Run workloads.
- **Configure Networking**: Ensure instances can communicate and are accessible from the bastion node.
- **Assign Floating IPs**: If necessary, assign floating IPs for external access.

### Step 2: Run Ansible Playbooks

- **Navigate to Ansible Directory**:

  ```bash
  cd ansible
  ```

- **Update Inventory**: Edit the `inventory` file with the IP addresses of your instances.
- **Run Playbooks**: Execute the playbooks to install prerequisites.

  ```bash
  ansible-playbook -i inventory playbooks/prepare_nodes.yml
  ```

### Step 3: Deploy Kubernetes with Kubespray

- **Copy Inventory**:

  ```bash
  cp -r kubespray/inventory/sample kubespray-inventory/funkube
  ```

- **Update Inventory**: Modify `kubespray-inventory/funkube/hosts.yaml` with your cluster nodes.
- **Deploy Cluster**:

  ```bash
  cd kubespray
  ansible-playbook -i ../kubespray-inventory/funkube/hosts.yaml cluster.yml
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

