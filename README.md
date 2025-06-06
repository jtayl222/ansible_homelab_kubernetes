![Lint Status](https://github.com/jtayl222/ansible_homelab_kubernetes/actions/workflows/lint.yml/badge.svg)

# Kubernetes Homelab Setup with K3s, NFS, Prometheus, and Grafana

This repository contains Ansible playbooks to deploy and manage a lightweight Kubernetes cluster using K3s in a homelab environment. The setup includes NFS for persistent storage, Prometheus and Grafana for monitoring, and Traefik for ingress routing. These playbooks automate the installation, configuration, testing, and cleanup of the cluster and its components.

## Purpose

This project aims to simplify the deployment of a K3s-based Kubernetes cluster with essential services for a homelab. It includes:
- A single-node or multi-node K3s cluster setup.
- NFS-based persistent storage.
- Monitoring with Prometheus and Grafana.
- Troubleshooting and cleanup tools for experimentation.

## K3S Usage Instructions

### To Install K3s Cluster:

```bash
# Install K3s (default behavior)
ansible-playbook -i inventory/production/hosts playbooks/k3s.yml
```

### To Uninstall K3s Cluster:

```bash
# Uninstall K3s
ansible-playbook -i inventory/production/hosts playbooks/k3s.yml -e "k3s_state=absent"
```

### To Reinstall K3s Cluster:

```bash
# Uninstall then install K3s
ansible-playbook -i inventory/production/hosts playbooks/k3s.yml -e "k3s_state=absent"
ansible-playbook -i inventory/production/hosts playbooks/k3s.yml
```

These changes allow complete control over the K3s installation state by adding conditional tasks to the existing roles rather than creating new roles or playbooks. The uninstall process will properly clean up both control plane and worker nodes, making it easy to reinstall from scratch if needed.

## NOTES

### get kube config
```bash
MY_K3S_CONTROL_PLANE=192.168.1.85
ssh $MY_K3S_CONTROL_PLANE "sudo cat /etc/rancher/k3s/k3s.yaml"  | sed -e "s/127.0.0.1/$MY_K3S_CONTROL_PLANE/" > ~/.kube/config
```

### Events ordered by time
```bash
kubectl -n kube-system get events --sort-by='.lastTimestamp'
```

### Traefik
```bash
# Visit: http://dashboard.local/dashboard/dashboard/#/

# Get the port:
$ kubectl -n kube-system get svc traefik
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP                                              PORT(S)                      AGE
traefik   LoadBalancer   10.43.161.248   192.168.1.103,192.168.1.104,192.168.1.107,192.168.1.85   80:31391/TCP,443:30841/TCP   55m

# Get Credentials
kubectl -n kube-system get secret/traefik-dashboard-auth -o jsonpath='{.data.users}'

# Just joking: admin/admin

# visit http://192.168.1.85:31391/dashboard/dashboard/#/
```

### K8 Dashboard:

```bash
# Extract dashboard admin token
kubectl -n kubernetes-dashboard \
          get secret dashboard-admin-token -o jsonpath='{.data.token}' | base64 -d

# port-forward 
kubectl -n kubernetes-dashboard port-forward service/kubernetes-dashboard-kong-proxy 8443:443

# Visit https://localhost:8443

```

### Grafana
```bash
# admin user
kubectl -n kube-system get secrets -n monitoring prometheus-grafana -o jsonpath='{.data.admin-user}' | base64 -d
# admin password
kubectl -n kube-system get secrets -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d

# visit http://grafana.local/login
```

### Kibana
```
# user: elastic
# password:
kubectl get secrets -n elastic elasticsearch-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d

visit https://kibana.local/kibana/
```

## Directory Contents

### Core Setup Playbooks
- **`pre_flight_checks.yml`**: Verifies the target environment meets prerequisites (e.g., OS, dependencies).
- **`cluster_setup.yml`**: Installs and configures a K3s Kubernetes cluster.
- **`setup_nfs_server.yml`**: Sets up an NFS server for persistent storage.
- **`install_nfs_client.yml`**: Installs the NFS client on cluster nodes.
- **`deploy_nfs_provisioner.yml`**: Deploys an NFS provisioner for dynamic volume provisioning.

### Monitoring Playbooks
- **`install_prometheus_grafana.yml`**: Installs Prometheus and Grafana for cluster monitoring.
- **`install_grafana.yml`**: Performs additional Grafana installation steps.
- **`configure_grafana_traefik.yml`**: Configures Grafana with Traefik for external access.

### Testing and Validation Playbooks
- **`check_template.yml`**: Validates configuration templates.
- **`test_nfs_pvc.yml`**: Tests NFS persistent volume claims.
- **`test_grafana_config.yml`**: Verifies Grafana configuration.

### Cleanup Playbooks
- **`cleanup_grafana_config.yml`**: Removes Grafana configuration.
- **`cleanup_grafana.yml`**: Uninstalls Grafana.
- **`cleanup_k3s.yml`**: Resets the K3s cluster.
- **`cleanup_prometheus_grafana.yml`**: Removes Prometheus and Grafana.

### Fix Playbooks
- **`fix_grafana_404.yml`**: Resolves Grafana 404 errors.
- **`fix_grafana_direct_cm.yml`**: Fixes Grafana direct config map issues.
- **`fix_grafana_redirect.yml`**: Corrects Grafana redirect problems.
- **`fix_grafana_traefik_ipv4.yml`**: Adjusts Grafana-Traefik IPv4 settings.

## Prerequisites

Before running the playbooks, ensure:
1. **Ansible**: Installed on the control machine.
2. **Target Hosts**: Linux machines (e.g., Ubuntu) with:
   - SSH access for the Ansible user.
   - `sudo` privileges.
   - Internet access for package downloads.
3. **Inventory**: An Ansible inventory file defining hosts (e.g., `k3s_nodes` for cluster nodes, `nfs_server` for the NFS server).
   Example:
   ```ini
   [k3s_nodes]
   k3s-node-1 ansible_host=192.168.1.10 ansible_user=admin

   [nfs_server]
   nfs-server-1 ansible_host=192.168.1.11 ansible_user=admin
   ```
4. **Variables**: Define necessary variables in `group_vars` or `host_vars` (e.g., K3s version, NFS paths).

## Initial Install Order

For a fresh install of the K3s cluster with NFS, Prometheus, and Grafana:
1. **`pre_flight_checks.yml`**: Validate the environment.
   ```bash
   ansible-playbook -i inventory/my_inventory.yml pre_flight_checks.yml
   ```
2. **`cluster_setup.yml`**: Deploy the K3s cluster.
   ```bash
   ansible-playbook -i inventory/my_inventory.yml cluster_setup.yml
   ```
3. **`setup_nfs_server.yml`**: Configure the NFS server.
   ```bash
   ansible-playbook -i inventory/my_inventory.yml setup_nfs_server.yml
   ```
4. **`install_nfs_client.yml`**: Install the NFS client on cluster nodes.
   ```bash
   ansible-playbook -i inventory/my_inventory.yml install_nfs_client.yml
   ```
5. **`deploy_nfs_provisioner.yml`**: Set up the NFS provisioner.
   ```bash
   ansible-playbook -i inventory/my_inventory.yml deploy_nfs_provisioner.yml
   ```
6. **`install_prometheus_grafana.yml`**: Install Prometheus and Grafana.
   ```bash
   ansible-playbook -i inventory/my_inventory.yml install_prometheus_grafana.yml
   ```
7. **`install_grafana.yml`**: Complete Grafana installation.
   ```bash
   ansible-playbook -i inventory/my_inventory.yml install_grafana.yml
   ```
8. **`configure_grafana_traefik.yml`**: Configure Grafana with Traefik.
   ```bash
   ansible-playbook -i inventory/my_inventory.yml configure_grafana_traefik.yml
   ```

### Post-Install Testing
- Validate storage: `ansible-playbook -i inventory/my_inventory.yml test_nfs_pvc.yml`
- Check Grafana: `ansible-playbook -i inventory/my_inventory.yml test_grafana_config.yml`

## Configuration

This project uses Ansible's variable hierarchy to manage configuration:

1. Copy `group_vars/all/common.yml.example` to `group_vars/all/common.yml`
2. Edit the values to match your environment
3. This file is gitignored to prevent exposing sensitive information

Variables are used across playbooks to maintain consistent settings.

## MLflow Installation

This repository includes playbooks to deploy MLflow, a platform for the machine learning lifecycle.

### Installation

1. Install MLflow:
   ```bash
   ansible-playbook -i inventory/my_inventory.yml install_mlflow.yml
   ```

2. Clean up MLflow if needed:
   ```bash
   ansible-playbook -i inventory/my_inventory.yml uninstall_mlflow.yml
   ```

### MLflow Configuration

MLflow is configured with default settings that should work for most homelab environments.
You can customize the following variables in `group_vars/all.yml`:

```yaml
# MLflow Configuration
mlflow_namespace: mlflow
mlflow_release_name: mlflow
mlflow_image: "ghcr.io/mlflow/mlflow:v2.10.2"
mlflow_replicas: 1
mlflow_persistent_volume: true
mlflow_storage_size: "10Gi"
mlflow_storage_class: "nfs-client"  # Use your cluster's storage class
```

Once deployed, MLflow will be available at: `http://mlflow.<node-ip>.nip.io`

## Customization

Adjust the setup by defining variables in `group_vars/all.yml`. Examples:
```yaml
k3s_version: "v1.28.3+k3s1"
nfs_server_path: "/srv/nfs"
grafana_admin_password: "admin123"
traefik_enabled: true
```

## Notes

- **Single Node**: For a single-node setup, target all playbooks to one host.
- **Networking**: Ensure Traefik is configured correctly for Grafana access (e.g., domain or IP).
- **Cleanup**: Use cleanup playbooks (e.g., `cleanup_k3s.yml`) to reset the environment.
- **Fixes**: Run fix playbooks (e.g., `fix_grafana_404.yml`) if issues arise post-install.

## Contributing

Submit issues or pull requests to enhance this setup. Feedback on automation or documentation is appreciated!

## License

This project is licensed under the [MIT License](LICENSE).
