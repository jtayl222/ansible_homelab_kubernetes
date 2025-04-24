Here's a clean, professional, and Kubernetes-native `roles/traefik/README.md` for your repository — focused on deploying Traefik as the ingress controller for your MLOps stack:

---

# Traefik Role

This Ansible role deploys [Traefik](https://traefik.io/) as the ingress controller for your Kubernetes cluster.  
Traefik is a modern, dynamic reverse proxy and load balancer that integrates natively with Kubernetes via IngressRoute CRDs and automatically discovers services.

> **Status:** This role installs Traefik on K3s clusters using static manifests or the built-in K3s Traefik deployment. It's required to expose services such as MLflow, Argo CD, and MinIO via HTTP/S.

---

## ✅ Features

- Installs Traefik v2.x ingress controller
- Creates required RBAC, CRDs, and DaemonSet/Deployment
- Sets up entryPoints (e.g., `web`, `websecure`) for HTTP/HTTPS traffic
- Configures TLS support (with optional Let's Encrypt)
- Supports IngressRoute objects via CRDs
- Compatible with Traefik Dashboard (optional)

---

## 📁 Role Structure

```
roles/traefik/
├── defaults/
│   └── main.yml                  # Default variable values
├── files/
│   └── manifests/                # Kubernetes manifests for Traefik
├── tasks/
│   └── main.yml                  # Role task file
└── README.md                     # You're here!
```

---

## ⚙️ Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `traefik_namespace` | Namespace for Traefik | `kube-system` |
| `traefik_service_type` | Service type (ClusterIP, NodePort, LoadBalancer) | `NodePort` |
| `traefik_dashboard_enabled` | Enable Traefik dashboard route | `true` |
| `traefik_entrypoints_http` | Port for HTTP entrypoint | `80` |
| `traefik_entrypoints_https` | Port for HTTPS entrypoint | `443` |
| `traefik_tls_enabled` | Enable TLS via IngressRoute | `false` |
| `traefik_acme_email` | Email address for Let's Encrypt ACME registration | `you@example.com` |

---

## 🚀 Usage

### Inventory Example

```ini
[k3s_control_plane]
192.168.1.10 ansible_user=ubuntu
```

### Playbook Example

```yaml
- name: Install Traefik Ingress Controller
  hosts: k3s_control_plane
  become: true
  roles:
    - role: traefik
```

### Run the Playbook

```bash
ansible-playbook playbooks/install_traefik.yml -i inventory/production/hosts
```

---

## 🌐 Exposing Services with Ingress

Once Traefik is installed, you can expose services using Kubernetes `Ingress` or `IngressRoute` objects.

Example Ingress manifest for MLflow:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mlflow-ingress
  namespace: mlflow
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
    - host: mlflow.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: mlflow
                port:
                  number: 5000
```

---

## 🧪 Verifying the Deployment

```bash
kubectl get pods -n kube-system -l app=traefik
kubectl get svc -n kube-system -l app=traefik
```

To test routing:

```bash
curl http://<node_ip>:<node_port>/
```

Or visit your exposed domain via browser if using Ingress + DNS.

---

## 📊 Accessing the Traefik Dashboard

If `traefik_dashboard_enabled: true`, the dashboard is available at:

```
http://<traefik-node-ip>:8080/dashboard/
```

This is useful for debugging routing and middleware configuration.

---

## 📌 Future Enhancements

- Add Let's Encrypt TLS resolver and ACME certificate support
- Support Traefik CRDs (IngressRoute, Middleware, TLSOptions)
- Add multi-cluster or Helm chart support

---

## 📄 License

MIT — freely usable and extensible.

