Here you go — a **fully polished `roles/mlflow/README.md`** for your repository, modeled after the style we used for MinIO, with MLOps-specific touches that will resonate with hiring managers:

---

# MLflow Role

This Ansible role deploys the [MLflow](https://mlflow.org/) Tracking Server on a Kubernetes cluster.  
MLflow is a central tool in modern MLOps pipelines, used for tracking experiments, logging models and metrics, and managing the lifecycle of machine learning models.

> **Status:** This role is tested in K3s-based clusters. It runs the MLflow server as a Kubernetes Deployment, exposing it via internal ClusterIP or optional Ingress.

---

## ✅ Features

- Deploys MLflow Tracking Server as a Kubernetes Deployment
- Configures Persistent Volume Claims (PVCs) for artifact storage
- Supports MinIO integration for storing ML artifacts (via `S3`-compatible URIs)
- Creates a Kubernetes Service for internal access
- Optional ingress exposure via Traefik
- Customizable environment variables (e.g., backend store URI, artifact location)

---

## 📁 Role Structure

```
roles/mlflow/
├── defaults/
│   └── main.yml          # Default role variables
├── files/
│   └── manifests/        # YAML templates (deployment, PVC, service)
├── tasks/
│   └── main.yml          # Role execution tasks
└── README.md             # You're here!
```

---

## ⚙️ Role Variables

These variables can be overridden in your playbook or inventory:

| Variable | Description | Default |
|----------|-------------|---------|
| `mlflow_namespace` | Namespace where MLflow will be deployed | `mlflow` |
| `mlflow_server_image` | Container image for MLflow server | `ghcr.io/mlflow/mlflow:latest` |
| `mlflow_artifact_uri` | URI to store model artifacts (e.g., S3/MinIO path) | `s3://mlflow/` |
| `mlflow_backend_uri` | URI for MLflow backend store (e.g., SQLite, PostgreSQL) | `sqlite:///mlflow.db` |
| `mlflow_port` | Port MLflow server listens on | `5000` |
| `mlflow_service_type` | Kubernetes Service type | `ClusterIP` |
| `mlflow_ingress_enabled` | Whether to expose MLflow via Ingress | `false` |
| `mlflow_ingress_hostname` | Hostname to use with Ingress | `mlflow.example.com` |

---

## 🚀 Usage

### Inventory Example

```ini
[k3s_control_plane]
192.168.1.10 ansible_user=ubuntu
```

### Playbook Example

```yaml
- name: Deploy MLflow Tracking Server
  hosts: k3s_control_plane
  become: true
  roles:
    - role: mlflow
```

### Run the Playbook

```bash
ansible-playbook playbooks/install_mlflow.yml -i inventory/production/hosts
```

---

## 🌐 Accessing MLflow

- **Internal URL:**  
  `http://mlflow.mlflow.svc.cluster.local:5000`
- **Ingress URL (if enabled):**  
  `https://{{ mlflow_ingress_hostname }}`

To port-forward locally:

```bash
kubectl port-forward svc/mlflow -n mlflow 5000:5000
```

Then open:  
`http://localhost:5000`

---

## 📦 Example MLflow Usage

### 1. Set Environment Variables in Your Training Script

```python
import mlflow

mlflow.set_tracking_uri("http://mlflow.mlflow.svc.cluster.local:5000")
mlflow.set_experiment("iris_experiment")

with mlflow.start_run():
    mlflow.log_param("learning_rate", 0.01)
    mlflow.log_metric("accuracy", 0.95)
```

### 2. Configure MLflow Artifact Store with MinIO

To log models and artifacts to MinIO, set:

```bash
export MLFLOW_S3_ENDPOINT_URL=http://minio.minio.svc.cluster.local:9000
export AWS_ACCESS_KEY_ID=minioadmin
export AWS_SECRET_ACCESS_KEY=minioadmin
```

Then log a model:

```python
mlflow.sklearn.log_model(model, artifact_path="model")
```

---

## 🧪 Testing Deployment

```bash
kubectl get pods -n mlflow
kubectl get svc -n mlflow
```

Check logs:

```bash
kubectl logs deployment/mlflow -n mlflow
```

Verify service:

```bash
curl http://localhost:5000/api/2.0/mlflow/experiments/list
```

---

## 🧰 CLI & Automation Tips

- Use the MLflow CLI:

```bash
mlflow experiments list --tracking-uri http://localhost:5000
```

- Integrate with Argo Workflows by injecting the environment variables into training steps
- Artifact logging is S3-compatible (MinIO, AWS S3, GCS)

---

## 📌 Future Enhancements

- Add PostgreSQL backend store support (instead of SQLite)
- Enable basic auth for exposed Ingress
- Integrate with Argo Workflows for automated pipeline logging

---

## 📄 License

MIT — freely usable and extensible.

