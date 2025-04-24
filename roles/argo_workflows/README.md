Here’s a complete and professional `roles/argo_workflows/README.md`, aligned with your MLOps portfolio style — clean, useful, and tailored to real-world Kubernetes usage:

---

# Argo Workflows Role

This Ansible role installs [Argo Workflows](https://argo-workflows.readthedocs.io/en/stable/) into your Kubernetes cluster.  
Argo Workflows is a powerful Kubernetes-native workflow engine for orchestrating complex machine learning pipelines, data processing jobs, and CI/CD automation.

> **Status:** This role deploys Argo Workflows using the official manifests, tested on lightweight K3s clusters. Compatible with GitOps and MLflow integration strategies.

---

## ✅ Features

- Installs Argo Workflows components (controller, UI, executor)
- Applies official YAML manifests
- Creates namespace and RBAC configuration
- Optional ingress exposure via Traefik
- Enables Kubernetes-native workflow orchestration
- Compatible with MinIO and MLflow integration via ENV injection

---

## 📁 Role Structure

```
roles/argo_workflows/
├── defaults/
│   └── main.yml              # Default role variables
├── files/
│   └── install-argo-workflows.yaml  # Official manifest
├── tasks/
│   └── main.yml              # Role tasks
└── README.md                 # You're here!
```

---

## ⚙️ Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `argo_namespace` | Namespace where Argo Workflows will be installed | `argo` |
| `argo_workflows_manifest_path` | Path to Argo Workflows install YAML | `files/install-argo-workflows.yaml` |
| `argo_ingress_enabled` | Whether to expose Argo UI via Ingress | `false` |
| `argo_ingress_hostname` | Hostname for Argo UI ingress route | `argo.example.com` |
| `argo_service_type` | Kubernetes Service type (ClusterIP, NodePort) | `ClusterIP` |

---

## 🚀 Usage

### Inventory Example

```ini
[k3s_control_plane]
192.168.1.10 ansible_user=ubuntu
```

### Playbook Example

```yaml
- name: Install Argo Workflows
  hosts: k3s_control_plane
  become: true
  roles:
    - role: argo_workflows
```

### Run the Playbook

```bash
ansible-playbook playbooks/install_argo_workflows.yml -i inventory/production/hosts
```

---

## 🌐 Accessing the Argo UI

- **Internal URL (default):**  
  `http://argo-server.argo.svc.cluster.local:2746`
- **Ingress URL (if enabled):**  
  `https://{{ argo_ingress_hostname }}`

To port-forward locally:

```bash
kubectl port-forward svc/argo-server -n argo 2746:2746
```

Then open:  
`http://localhost:2746`

---

## 🧪 Testing Deployment

After deployment:

```bash
kubectl get pods -n argo
kubectl get svc -n argo
```

Create a sample workflow:

```bash
argo submit -n argo --watch https://raw.githubusercontent.com/argoproj/argo-workflows/master/examples/hello-world.yaml
```

Check status:

```bash
argo list -n argo
```

---

## 🔁 Integration with MLflow

To log experiments to MLflow from Argo Workflows:

- Inject environment variables into your workflow templates:
  ```yaml
  env:
    - name: MLFLOW_TRACKING_URI
      value: http://mlflow.mlflow.svc.cluster.local:5000
    - name: MLFLOW_S3_ENDPOINT_URL
      value: http://minio.minio.svc.cluster.local:9000
    - name: AWS_ACCESS_KEY_ID
      value: minioadmin
    - name: AWS_SECRET_ACCESS_KEY
      value: minioadmin
  ```
- Call MLflow APIs from your Python script inside the Argo container steps

---

## 📌 Future Enhancements

- Add optional CRDs for Argo Events or Argo Rollouts
- Integrate GitOps triggers via Argo CD
- Configure secure auth for the Argo UI (e.g., OIDC)

---

## 📄 License

MIT — freely usable and extensible.

