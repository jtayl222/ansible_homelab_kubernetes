#!/bin/bash
# Test Grafana access through Traefik Ingress

KUBECONFIG="${1:-./fetched_tokens/k3s-kubeconfig}"
NAMESPACE="${2:-monitoring}"
RELEASE="${3:-grafana}"

# Check if kubeconfig exists
if [ ! -f "$KUBECONFIG" ]; then
  echo "Error: Kubeconfig file not found at $KUBECONFIG"
  exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
  echo "Error: kubectl could not be found. Please install kubectl."
  exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
  echo "Error: curl could not be found. Please install curl."
  exit 1
fi

# Get Traefik service nodePort
TRAEFIK_PORT=$(kubectl --kubeconfig="$KUBECONFIG" get svc -n kube-system traefik \
  -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}' 2>/dev/null)

if [ -z "$TRAEFIK_PORT" ]; then
  echo "Error: Could not determine Traefik port"
  exit 1
fi

# Get ONLY the IPv4 address of the control plane node (fixed)
MASTER_IP=$(kubectl --kubeconfig="$KUBECONFIG" get nodes -l node-role.kubernetes.io/master \
  -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null | awk -F' ' '{print $1}')

# If no master label or still getting both IPs, try using the first address only
if [ -z "$MASTER_IP" ] || [[ "$MASTER_IP" == *":"* ]]; then
  # Get all nodes and extract only the first IPv4 address
  MASTER_IP=$(kubectl --kubeconfig="$KUBECONFIG" get nodes \
    -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' | grep -v ":" | head -n1)
  
  # If still empty or we're getting IPv6, just use the first node's first address
  if [ -z "$MASTER_IP" ]; then
    MASTER_IP=$(kubectl --kubeconfig="$KUBECONFIG" get nodes \
      -o jsonpath='{.items[0].status.addresses[0].address}' | grep -v ":")
      
    # If we still have no IP, try a different approach
    if [ -z "$MASTER_IP" ]; then
      echo "Trying to extract IP directly..."
      MASTER_IP=$(kubectl --kubeconfig="$KUBECONFIG" get nodes -o wide | grep -v NAME | awk '{print $6}' | head -n1)
    fi
  fi
  
  if [ -z "$MASTER_IP" ]; then
    echo "Error: Could not determine node IP address"
    exit 1
  fi
fi

echo "Using node IP: $MASTER_IP"

# Get Grafana admin password
GRAFANA_PASSWORD=$(kubectl --kubeconfig="$KUBECONFIG" get secret -n "$NAMESPACE" "$RELEASE" \
  -o jsonpath="{.data.admin-password}" | base64 --decode 2>/dev/null)

echo ""
echo "Grafana Access Information:"
echo "=========================================="
echo "Path-based URL: http://$MASTER_IP:$TRAEFIK_PORT/grafana/"
echo "Host-based URL: http://grafana.$MASTER_IP.nip.io:$TRAEFIK_PORT"
echo "Username: admin"
if [ -n "$GRAFANA_PASSWORD" ]; then
  echo "Password: $GRAFANA_PASSWORD"
else
  echo "Password: [Could not retrieve password]"
fi
echo "=========================================="

echo ""
echo "Testing access to Grafana..."
echo "--------------------------------------------"
echo "Testing path-based access (/grafana/):"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$MASTER_IP:$TRAEFIK_PORT/grafana/")
if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "302" ]]; then
  echo "✅ Grafana is accessible at /grafana/ path (HTTP $HTTP_CODE)"
else
  echo "❌ Grafana is NOT accessible at /grafana/ path (HTTP $HTTP_CODE)"
  echo "   Run ansible-playbook -i inventory/hosts fix_grafana_traefik_alt.yml to fix this issue"
fi

echo ""
echo "Testing host-based access (grafana.$MASTER_IP.nip.io):"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: grafana.$MASTER_IP.nip.io" "http://$MASTER_IP:$TRAEFIK_PORT/")
if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "302" ]]; then
  echo "✅ Grafana is accessible via host-based routing (HTTP $HTTP_CODE)"
else
  echo "❌ Grafana is NOT accessible via host-based routing (HTTP $HTTP_CODE)"
fi