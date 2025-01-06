# Deploying Kubeflow on OpenStack Cloud

Kubeflow is fun.

However, deploying Kubeflow could be challenging because it has many components, the built-in and the third-party dependencies. 

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

This repository provides a comprehensive guide and necessary configurations to deploy **Kubeflow** on a **Kubernetes (k8s)** cluster within an **OpenStack** cloud platform. The deployment process leverages tools like **Ansible**, **Kubespray**, **Kubeflow Manifest** to automate and streamline the setup. The deployment process includes the following tasks:

0. **Prepare a bastion node**: Set up a control node where Kubespray will be executed to deploy Kubernetes.
1. **Create OpenStack instances**: Provision three instances—one for the control plane and two for worker nodes.
2. **Run Ansible playbooks**: Install necessary prerequisites on all nodes before deploying Kubernetes.
3. **Deploy Kubernetes with Kubespray**: Use Kubespray to set up a Kubernetes cluster on the prepared nodes.
4. **Apply Kubeflow common manifests**: Deploy common Kubeflow components.
5. **Apply Kubeflow application manifests**: Deploy Kubeflow applications like Notebooks.

The following repositories and resources were used for this deployment:

- [Kubeflow](https://github.com/kubeflow/kubeflow): The primary repository for Kubeflow, a machine learning toolkit for Kubernetes.
- [Kubespray](https://github.com/kubernetes-sigs/kubespray): A collection of Ansible playbooks for provisioning and managing Kubernetes clusters.
- [cloud-provider-openstack](https://github.com/kubernetes/cloud-provider-openstack): Repository for OpenStack cloud provider integrations with Kubernetes.
- [Helm](https://github.com/helm/helm): The Kubernetes package manager used for deploying additional components.
- [Kubeflow Manifests](https://github.com/kubeflow/manifests): The repository containing manifests for deploying and managing Kubeflow components.

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

### Step 4: Prepare the k8s cluster for Kubeflow

To prepare Kubeflow deployment, we prepare 
- an echo server, to test out k8s API works properly
- an ingress server, to test out web app traffic routing
- a matrix server, to monitor the cluster load
- a storage class, to dynamically provision and manage storage resources

**Note: alias k=kubectl**

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
cd helm
./matrix.sh
k top nodes
k top pods
```

- **Configure Storage**:
```bash
k apply -f storage.yaml
```

### Step 5: Apply Kubeflow Common Manifests

- **Install kubeflow namespace**:

```bash
cd kubeflow-manifests/common/
k apply -k kubeflow-namespace/base
``` 

- **Install kubeflow roles**:

```bash
cd kubeflow-manifests/common/
k apply -k kubeflow-roles/base
``` 

- **Install cert-manager**:

```bash
cd kubeflow-manifests/common/
k apply -k cert-manger/base
k apply -k kubeflow-issuer/base
k get pods -n cert-manager
k get apiservices | grep cert-manager
```

- **Test cert-manager**:

```bash
cd kubeflow-manifests/tests/
cd cert-manager/
k apply -f self-signed-issuer.yaml 
k apply -f test-certificate.yaml 
k describe certificate test-certificate -n default
k get secret test-certificate-secret -n default
```

- **Install Istio**:

```bash
cd kubeflow-manifests/common/
k apply -k istio-1-23/istio-crds/base/
k apply -k istio-1-23/istio-namespace/base
k apply -k istio-1-23/istio-install/overlays/oauth2-proxy/
k apply -k istio-1-23/kubeflow-istio-resources/base
k wait --for=condition=Ready pods --all -n istio-system --timeout 300s
k get pods -n istio-system
k get svc -n istio-system
```

- **Test Istio**:

Follow this file: [Istio test](kubeflow-manifests/tests/istio/test.sh)

Also check out the resources

```bash
k get all -n istio-system
k get all -n kubeflow
k get gateway -n istio-system
k get clusterroles | grep kubeflow-istio
k get virtualservice -A
k get pods -n istio-system
```

- **Install oauth2-proxy**:

```bash
cd kubeflow-manifests/common/
k apply -k oauth2-proxy/overlays/m2m-dex-and-kind/
k wait --for=condition=ready pod -l 'app.kubernetes.io/name=oauth2-proxy' --timeout=180s -n oauth2-proxy
k wait --for=condition=ready pod -l 'app.kubernetes.io/name=cluster-jwks-proxy' --timeout=180s -n istio-system
k get all -n oauth2-proxy
```

- **Install dex**:

```bash
cd kubeflow-manifests/common/
k apply -k dex/overlays/oauth2-proxy/
k wait --for=condition=ready pods --all --timeout=180s -n auth
```

- **Install networkpolicies**:

```bash
cd kubeflow-manifests/common/
k apply -k networkpolicies/base
k get networkpolicy -A
k describe networkpolicy jupyter-web-app -n kubeflow
```

- **Install kubeflow roles**:

```bash
cd kubeflow-manifests/common/
k apply -k kubeflow-roles/base
```

- **Install user namespace**:

```bash
cd kubeflow-manifests/common/
k apply -k user-namespace/base
```

### Step 6: Apply Kubeflow Application Manifests

- **CentralDashboard**:

```bash
cd kubeflow-manifests/apps/
k apply -k centraldashboard/upstream/base
k apply -k centraldashboard/overlays/oauth2-proxy/
```

 **Jupyter web app**:

```bash
cd kubeflow-manifests/apps/
k apply -k jupyter/notebook-controller/upstream/overlays/kubeflow/
k apply -k jupyter/jupyter-web-app/upstream/overlays/istio/
```

- **Profiles**:

```bash
cd kubeflow-manifests/apps/
k apply -k profiles/upstream/default/
k apply -k profiles/upstream/overlays/kubeflow/
```

- **Admission-webhook**
```bash
cd kubeflow-manifests/apps/
k apply -k admission-webhook/upstream/overlays/
k apply -k admission-webhook/upstream/overlays/cert-manager/
k get secret webhook-certs -n kubeflow
k describe validatingwebhookconfiguration -A
```

- **Cinder CSI Plugin**

```bash
cd cloud-provider-openstack/manifests/cinder-csi-plugin
k apply -f cinder-csi-controllerplugin.yaml 
k apply -f cinder-csi-nodeplugin.yaml 
k apply -f csi-cinder-driver.yaml 
k apply -f csi-secret-cinderplugin.yaml 
k apply -f cinder-csi-nodeplugin-rbac.yaml 
k apply -f cinder-csi-controllerplugin-rbac.yaml 
k get secret cloud-config -n kube-system
```

- **Cinder CSI Plugin Fix**

Update authenticate with clouds.yaml as clouds.conf not working

Changes made here: [Cloud Provider OpenStack Repo](https://github.com/kubernetes/cloud-provider-openstack/compare/master...owhere:cloud-provider-openstack:clouds-auth)

```bash
cd cloud-provider-openstack/manifests/cinder-csi-plugin
k apply -f cinder-csi-controllerplugin.yaml 
k get svc -n kubeflow
k delete secret cloud-config -n kube-system
k create secret generic cloud-config -n kube-system   --from-file=cloud.conf=/path/to/cloud.conf   --from-file=clouds.yaml=/path/to/clouds.yaml
k get secret cloud-config -n kube-system -o yaml
k rollout restart deployment csi-cinder-controllerplugin -n kube-systemc
```

- **PVC viewer (volumes)**

```bash
cd kubeflow-manifests/apps
k apply -k pvcviewer-controller/upstream/base
k apply -k pvcviewer-controller/upstream/default/
k apply -k apps/volumes-web-app/upstream/overlays/istio/
```

- **Test volume**

```bash
cd kubeflow-manifests/tests
k apply -f test-pvc.yaml
k get pvc test-pvc
k get pod test-pod
k exec -it test-pod -- cat /data/testfile
```

- **Tensorboard**
```bash
cd kubeflow-manifests/apps
k apply -k tensorboard/tensorboard-controller/upstream/overlays/kubeflow/
k apply -k apps/tensorboard/tensorboards-web-app/upstream/overlays/istio/
```

## More Fun

- **Drain a node to update the kernel**
- **Add a new node to the cluster using Kubespray**
- **Run a DNS test**

## License

This project is licensed under the [Apache License](LICENSE).

---

Feel free to open issues or submit pull requests for improvements or fixes.

