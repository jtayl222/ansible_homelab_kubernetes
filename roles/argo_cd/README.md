Here is a fully documented `roles/argo_cd/README.md` — clean, practical, and GitOps-ready. This will make your repository shine to hiring managers who care about Git-based deployment workflows:

---

# Argo CD Role

This Ansible role installs [Argo CD](https://argo-cd.readthedocs.io/en/stable/) into your Kubernetes cluster.  
Argo CD is a declarative, GitOps-based continuous delivery tool that automatically deploys and manages Kubernetes resources defined in Git repositories.

> **Status:** This role uses the official installation manifests and is validated on K3s clusters. It supports internal access or optional ingress exposure via Traefik.

---

## ✅ Features

- Installs Argo CD using official manifests
- Sets up namespaces, services, and RBAC
- Enables GitOps workflows by syncing applications from Git
- Optionally exposes Argo CD UI via Ingress
- Provides variable customization for image versions, hostnames, and sync policies

---

## 📁 Role Structure

```
roles/argo_cd/
├── defaults/
│   └── main.yml              # Default role variables
├── files/
│   └── install-argo-cd.yaml  # Official Argo CD manifest
├── tasks/
│   └── main.yml              # Main task list
└── README.md                 # You're here!
```

---

## ⚙️ Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `argo_cd_namespace` | Namespace to deploy Argo CD into | `argocd` |
| `argo_cd_manifest_path` | Path to Argo CD installation YAML | `files/install-argo-cd.yaml` |
| `argo_cd_ingress_enabled` | Whether to expose Argo CD via Ingress | `false` |
| `argo_cd_ingress_hostname` | Hostname for Argo CD ingress route | `argocd.example.com` |
| `argo_cd_service_type` | Kubernetes service type (ClusterIP, NodePort) | `ClusterIP` |

---

## 🚀 Usage

### Inventory Example

```ini
[k3s_control_plane]
192.168.1.10 ansible_user=ubuntu
```

### Playbook Example

```yaml
- name: Install Argo CD
  hosts: k3s_control_plane
  become: true
  roles:
    - role: argo_cd
```

### Run the Playbook

```bash
ansible-playbook playbooks/install_argo_cd.yml -i inventory/production/hosts
```

---

## 🌐 Accessing the Argo CD UI

- **Internal URL:**  
  `http://argocd-server.argocd.svc.cluster.local:80`
- **Ingress URL (if enabled):**  
  `https://{{ argo_cd_ingress_hostname }}`

To port-forward for local access:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Then open:  
`http://localhost:8080`

---

## 🔐 Login Credentials

To get the initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode && echo
```

Login via CLI:

```bash
argocd login localhost:8080
```

---

## 🎯 Managing Applications

### Create an Argo CD App

```bash
argocd app create mlops-demo \
  --repo https://github.com/your-org/mlops-demo.git \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

### Sync App from Git

```bash
argocd app sync mlops-demo
```

### Watch Application Status

```bash
argocd app get mlops-demo
```

---

## 🔁 GitOps Workflow Overview

Argo CD continuously syncs Kubernetes resources from a Git repository:

```
Git Repository (YAML Manifests)
          ↓
      Argo CD Controller
          ↓
   Kubernetes Cluster State
```

Changes pushed to Git are automatically reflected in the cluster (pull-based delivery model).

---

## 📌 Future Enhancements

- Add Argo CD ApplicationSet controller
- Enable SSO/OIDC login for the Argo UI
- Define reusable base apps for multi-env (dev/stage/prod) deployment

---

## 📄 License

MIT — freely usable and extensible.

