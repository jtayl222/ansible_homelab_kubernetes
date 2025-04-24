

# MinIO Role

This Ansible role deploys a [MinIO](https://min.io/) server to a Kubernetes cluster using native manifests. MinIO provides high-performance, S3-compatible object storage that is ideal for storing machine learning artifacts, application data, and backups in your homelab MLOps environment.

> **Status:** This role is tested on K3s and tailored for internal cluster access. Ingress support via Traefik is optional.

---

## ✅ Features

- Installs MinIO into a dedicated Kubernetes namespace
- Creates Persistent Volume Claims (PVCs) for data storage
- Applies Kubernetes Deployment and Service manifests
- Optionally sets up Ingress routing
- Credentials are configurable via role variables

---

## 📁 Role Structure

```
roles/minio/
├── defaults/
│   └── main.yml          # Default variable definitions
├── files/
│   └── manifests/        # YAML files for K8s deployment
├── tasks/
│   └── main.yml          # Task list for deploying MinIO
├── templates/            # Optional: for future Helm or TLS templates
└── README.md             # You're here!
```

---

## ⚙️ Role Variables

These variables can be overridden in `group_vars`, `host_vars`, or your playbooks:

| Variable | Description | Default |
|----------|-------------|---------|
| `minio_namespace` | Namespace to deploy MinIO into | `minio` |
| `minio_storage_class` | Kubernetes storage class to use | `longhorn` |
| `minio_storage_size` | Size of Persistent Volume Claim for MinIO | `10Gi` |
| `minio_access_key` | MinIO access key (username) | `minioadmin` |
| `minio_secret_key` | MinIO secret key (password) | `minioadmin` |
| `minio_ingress_enabled` | Whether to expose MinIO via Ingress | `false` |
| `minio_hostname` | Hostname to use for Ingress (if enabled) | `minio.example.com` |

---

## 🚀 Usage

### Inventory Example

```ini
[k3s_control_plane]
192.168.1.10 ansible_user=ubuntu
```

### Playbook Example

```yaml
- name: Install MinIO object storage
  hosts: k3s_control_plane
  become: true
  roles:
    - role: minio
```

### Running the Playbook

```bash
ansible-playbook playbooks/install_minio.yml -i inventory/production/hosts
```

---

## 🔐 Accessing MinIO

Once deployed:

- **Internal Cluster URL:**  
  `http://minio.minio.svc.cluster.local:9000`
- **Ingress URL (if enabled):**  
  `https://{{ minio_hostname }}`

**Default credentials:**
- **Username:** `{{ minio_access_key }}`
- **Password:** `{{ minio_secret_key }}`

⚠️ **Security Note:**  
Rotate the default credentials before exposing MinIO publicly.

---

## 📦 Example Applications

- **MLflow artifact storage:**  
  Example setting: `artifact_location = s3://mlflow/`
- **Backup storage:**  
  Saving trained model checkpoints, datasets, or logs.
- **Input/output data for pipelines:**  
  Use MinIO buckets to exchange data across Argo Workflows or other ML pipelines.

---

## 🧪 Testing Deployment

After running the playbook, validate that MinIO pods and services are ready:

```bash
kubectl get pods -n minio
kubectl get svc -n minio
```

(Optional) Port-forward to access MinIO locally:

```bash
kubectl port-forward svc/minio -n minio 9000:9000
```

Open your browser at:

```
http://localhost:9000
```

and log in with the default credentials.

---

Absolutely — adding `curl` access is a nice touch for minimal setups, debugging, or scripting without AWS/MinIO CLIs.

Here’s the updated **CLI Access section** — now with `aws`, `mc`, and `curl` usage examples — ready to drop into your `README.md`.

---

## 🧰 CLI Access: `aws`, `mc`, and `curl`

You can interact with your MinIO deployment using common S3-compatible tools:

---

### ✅ Option 1: Access via AWS CLI

MinIO supports the S3 API, so you can use the AWS CLI with an endpoint override.

#### Set Credentials and Endpoint

```bash
export AWS_ACCESS_KEY_ID=minioadmin
export AWS_SECRET_ACCESS_KEY=minioadmin
export AWS_ENDPOINT_URL=http://localhost:9000  # or your ingress URL

aws --endpoint-url $AWS_ENDPOINT_URL s3 ls
```

#### Upload a File

```bash
aws --endpoint-url $AWS_ENDPOINT_URL s3 mb s3://mlflow
aws --endpoint-url $AWS_ENDPOINT_URL s3 cp model.pkl s3://mlflow/
```

---

### ✅ Option 2: Access via MinIO Client (`mc`)

[`mc`](https://docs.min.io/docs/minio-client-quickstart-guide.html) is MinIO's native CLI tool.

#### Set Up an Alias

```bash
mc alias set localminio http://minio.local/ minioadmin minioadmin
```

#### Create a Bucket and Upload a File

```bash
mc mb localminio/mlflow
mc cp model.pkl localminio/mlflow/
mc ls localminio/mlflow
```

---

### ✅ Option 3: Access via `curl` (Low-Level)

You can perform basic S3 API operations using raw HTTP with `curl`.  
Useful for debugging or minimal environments.

#### Create a Bucket

```bash
curl -X PUT \
  -u minioadmin:minioadmin \
  http://localhost:9000/mlflow
```

#### Upload a File

```bash
curl -X PUT \
  -u minioadmin:minioadmin \
  --upload-file ./model.pkl \
  http://localhost:9000/mlflow/model.pkl
```

#### List Bucket Contents

```bash
curl -u minioadmin:minioadmin http://localhost:9000/mlflow
```

---

### 🔐 Notes

- Replace `localhost:9000` with your ingress hostname or internal cluster IP if accessing remotely.
- These methods work as long as the MinIO server is reachable and your credentials are correct.
- Use HTTPS and rotate access credentials if exposing MinIO outside the cluster.

### Best Practice Tip

For integration with tools like MLflow, FastAPI, or TensorFlow, configure them to point to the MinIO S3 endpoint using credentials and URL similar to above.

---

## 📌 Future Enhancements

- Enable HTTPS/TLS certificates through Traefik Ingress and Let's Encrypt
- Support Distributed MinIO deployments for HA (High Availability)
- Extend with Helm chart support for advanced configurations

---

## 📄 License

MIT License — feel free to adapt this role for your own homelab or production clusters.

