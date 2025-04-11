#!/usr/bin/env bash
set -e

echo "============ FINAL VERIFICATION SCRIPT ============"
echo "This script will attempt to curl endpoints and run basic kubectl checks."
echo "If a component responds, we assume it's healthy."

# 1. Verify K3s Control Plane & Workers
echo
echo "[CHECK] K3s Nodes"
kubectl get nodes -o wide

# 2. Verify Traefik (assuming traefik.local resolves to your Traefik ingress IP)
echo
echo "[CHECK] Traefik Ingress"
curl -s -I http://traefik.local/dashboard/ | head -1 || echo "Traefik check failed"

# 3. Verify Kubernetes Dashboard (assuming dashboard.local, or use 'kubectl get pods -n kubernetes-dashboard')
echo
echo "[CHECK] Kubernetes Dashboard"
curl -s -I http://dashboard.local/ | head -1 || echo "Dashboard check failed"

# 4. Verify NFS Provisioner
echo
echo "[CHECK] NFS Provisioner (namespace nfs-provisioner assumed)"
kubectl get pods -n nfs-provisioner -o wide || echo "NFS check failed"

# 5. Verify Prometheus & Grafana (assuming they share 'monitoring.local' or separate subpaths)
echo
echo "[CHECK] Prometheus"
curl -s -I http://monitoring.local/prometheus/ | head -1 || echo "Prometheus check failed"

echo
echo "[CHECK] Grafana"
curl -s -I http://monitoring.local/grafana/ | head -1 || echo "Grafana check failed"

# 6. Verify Elastic Stack (ECK) – Elasticsearch & Kibana
echo
echo "[CHECK] Elasticsearch"
curl -s -I http://elasticsearch.local:9200 | head -1 || echo "Elasticsearch check failed"

echo
echo "[CHECK] Kibana"
curl -k -s -I "https://kibana.local/kibana/login?next=%2Fkibana%2Fapp%2Fhome#/" | head -1 || echo "Kibana check failed"
#http://kibana.local/kibana/

# 7. Verify MLflow (assuming mlflow.local)
echo
echo "[CHECK] MLflow"
curl -s -I http://mlflow.local/ | head -1 || echo "MLflow check failed"

# 8. Verify Argo Workflows (assuming argo.local)
echo
echo "[CHECK] Argo Workflows UI"
curl -s -I http://argo.local/ | head -1 || echo "Argo check failed"

# 9. Verify MinIO
echo
echo "[CHECK] MinIO"
curl -s -I http://minio.local/ | head -1 || echo "MinIO check failed"

# 10. Verify Seldon (assuming seldon.local and an example iris-model)
echo
echo "[CHECK] Seldon Iris Model Predictions"
curl -s -X POST "http://seldon.local/seldon/seldon-system/iris-model/api/v1.0/predictions" \
     -H "Content-Type: application/json" \
     -d '{"data": {"ndarray": [[5.1, 3.5, 1.4, 0.2]]}}' \
     | head -c 200 || echo "Seldon Iris model check failed"

# curl -X GET "http://seldon.local/seldon/seldon-system/iris-model/api/v1.0/doc/"

echo
echo "============ VERIFICATION COMPLETE ============"
echo "Check the responses above. A valid 200 OK or JSON response typically indicates success."
