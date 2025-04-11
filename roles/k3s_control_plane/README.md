# K3s Control Plane Role

This Ansible role deploys and configures a K3s control plane node (or nodes) in a homelab Kubernetes cluster. It is designed to work alongside other roles and playbooks in the [ansible_homelab_kubernetes](../..) repository, specifically:

- **install_020_k3s_control_plane.yml** (installs and configures control-plane hosts)
- **install_030_k3s_workers.yml** (installs and configures worker nodes)
- **uninstall_010_k3s.yml** (removes K3s from control-plane and worker nodes)

## Contents

- [Requirements](#requirements)
- [Role Variables](#role-variables)
- [Usage](#usage)
- [Maintenance Procedures](#maintenance-procedures)
  - [K3s Patching (Monthly or Critical)](#k3s-patching-monthly-or-critical)
  - [Ubuntu Kernel Patching](#ubuntu-kernel-patching)
- [License](#license)

---

## Requirements

- Ubuntu (or a similar distribution) on your control-plane node(s).
- SSH access configured for Ansible.
- The `k3s_control_plane` role is meant to be run with root or sudo privileges to install system packages and manage services.

## Role Variables

Below is a non-exhaustive list of variables you may wish to configure for your environment:

- **k3s_version**: (Optional) Specific K3s version to install.
- **k3s_config_dir**: Directory for K3s configuration (commonly `/etc/rancher/k3s`).
- **k3s_binary_url**: (Optional) Override the default URL for downloading the K3s binary.
- **k3s_token**: Token used for worker nodes to join the cluster. If not set, one is generated automatically.

Additional variables may be found in this role’s `defaults/main.yml` and `vars/*.yml` files. Adjust as needed for your homelab.

## Usage

1. **Include this role in a playbook** (e.g., `install_020_k3s_control_plane.yml`):

    - name: Install and Configure K3s Control Plane
      hosts: k3s_control_plane
      become: true
      roles:
        - role: k3s_control_plane

2. **Set any needed variables** in your inventory or in `group_vars/k3s_control_plane.yml`. For example:

    k3s_version: "v1.24.8+k3s1"
    k3s_token: "MY_SECURE_TOKEN"

3. **Run your playbook** to configure the control-plane node(s):

    ```bash
    ansible-playbook install_020_k3s_control_plane.yml
    ```

This will install the specified (or latest stable) version of K3s, set up the control-plane services, and generate cluster credentials.

---

## Maintenance Procedures

Below are recommended maintenance and patching steps for your K3s cluster, focusing on two primary update scenarios:

1. **K3s patching** (monthly or critical updates).
2. **Ubuntu kernel patching** (or other OS-level updates).

### K3s Patching (Monthly or Critical)

To ensure minimal downtime, patch your cluster in an orderly manner. Generally, patch worker nodes first, then patch the control-plane node(s).

#### Patch Worker Nodes

1. Cordoning and draining each node one at a time:

    ```bash
    kubectl cordon <node-name>
    kubectl drain <node-name> --ignore-daemonsets --delete-local-data
    ```

1. Stop K3s on the worker node:

    ```bash
    sudo systemctl stop k3s-agent
    ```

1. Apply the K3s update (via Ansible or manually).

1. Restart K3s:

    ```bash
    sudo systemctl start k3s-agent
    ```

1. Uncordon the node:

    ```bash
    kubectl uncordon <node-name>
    ```

#### Patch Control-Plane Node(s)

1. If you have multiple control-plane nodes (an HA setup), you can patch them one at a time. For a single control-plane node, note there will be downtime.

1. Cordon/drain the control-plane node if desired (this is disruptive if only one control-plane node):

    ```bash
    kubectl cordon <control-plane-node-name>
    kubectl drain <control-plane-node-name> --ignore-daemonsets --delete-local-data
    ```

1. Stop K3s:

    ```bash
    sudo systemctl stop k3s
    ```

1. Update K3s.

1. Start K3s again:

    ```bash
    sudo systemctl start k3s
    ```

1. Uncordon the node (if previously cordoned):

    ```bash
    kubectl uncordon <control-plane-node-name>
    ```

#### Validate the Cluster

- Check `kubectl get nodes` and ensure all nodes are in `Ready` state.
- Verify workloads with `kubectl get pods -A`.

### Ubuntu Kernel Patching

When applying kernel or OS-level patches, follow a similar cordon/drain approach:

#### Worker Nodes

1. Cordon and drain:

    ```bash
    kubectl cordon <worker-node>
    kubectl drain <worker-node> --ignore-daemonsets --delete-local-data
    ```

1. Stop K3s agent:

    ```bash
    sudo systemctl stop k3s-agent
    ```

1. Apply kernel/OS updates (e.g., via apt).

1. Reboot if necessary, or simply start K3s:

    ```bash
    sudo systemctl start k3s-agent
    ```

1. Uncordon:

    ```bash
    kubectl uncordon <worker-node>
    ```

#### Control-Plane Node(s)

1. Cordon and drain (if you have multiple control-plane nodes or can handle downtime on a single-node setup):

    ```bash
    kubectl cordon <control-plane-node>
    kubectl drain <control-plane-node> --ignore-daemonsets --delete-local-data
    ```

1. Stop K3s:

    ```bash
    sudo systemctl stop k3s
    ```

1. Apply kernel/OS updates.

1. Reboot or restart K3s:

    ```bash
    sudo systemctl start k3s
    ```

1. Uncordon:

    ```bash
    kubectl uncordon <control-plane-node>
    ```

#### Verification

- Ensure `kubectl get nodes` shows all nodes in `Ready`.
- Confirm pods have restarted successfully: `kubectl get pods -A`.

---

## License

This repository is available under the [MIT License](../../LICENSE).
