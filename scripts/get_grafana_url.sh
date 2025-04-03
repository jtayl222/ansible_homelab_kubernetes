#!/bin/bash
# Get Grafana access URL from Kubernetes

KUBECONFIG="${1:-./fetched_tokens/k3s-kubeconfig}"
NAMESPACE="${2:-monitoring}"
RELEASE="${3:-grafana}"

# Check if kubeconfig exists
if [ ! -f "$KUBECONFIG" ]; then
  echo "Error: Kubeconfig file not found at $KUBECONFIG"
  exit 1
fi

# Get Traefik service nodePort
TRAEFIK_PORT=$(kubectl --kubeconfig="$KUBECONFIG" get svc -n kube-system traefik \
  -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}')

# Get control plane node IP
MASTER_IP=$(kubectl --kubeconfig="$KUBECONFIG" get nodes -l node-role.kubernetes.io/master \
  -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Get Grafana admin password
GRAFANA_PASSWORD=$(kubectl --kubeconfig="$KUBECONFIG" get secret -n "$NAMESPACE" "$RELEASE" \
  -o jsonpath="{.data.admin-password}" | base64 --decode)

echo ""
echo "Grafana Access Information:"
echo "=========================================="
echo "Path-based URL: http://$MASTER_IP:$TRAEFIK_PORT/grafana/"
echo "Host-based URL: http://grafana.$MASTER_IP.nip.io:$TRAEFIK_PORT"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"
echo "=========================================="

# Make the script executable
chmod +x scripts/get_grafana_url.sh