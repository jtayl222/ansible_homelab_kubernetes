#!/bin/bash
NODE_IP="192.168.1.85"
HOST="dashboard.192.168.1.85.nip.io"
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"

# Generate a fresh token
echo "Generating dashboard access token..."
TOKEN=$(kubectl --kubeconfig=$KUBECONFIG create token dashboard-admin -n kubernetes-dashboard --duration=24h)

clear
echo "===== Kubernetes Dashboard Access ====="
echo
echo "Try these access methods (in order of preference):"
echo
echo "1. Via Traefik Ingress: http://${HOST}"
echo "2. Via Direct NodePort: https://${NODE_IP}:32443 (accept certificate warning)"
echo
echo "Authentication Token (valid for 24h):"
echo "${TOKEN}"
echo

# Test Traefik ingress route
echo "Testing Traefik ingress route..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://${HOST})
echo "Ingress status: HTTP ${STATUS}"

if [ "$STATUS" = "200" ] || [ "$STATUS" = "302" ]; then
  echo "Ingress route is working! Opening in browser..."
  xdg-open "http://${HOST}" 2>/dev/null || open "http://${HOST}" 2>/dev/null || echo "Please open: http://${HOST}"
else
  echo "Ingress route returned HTTP ${STATUS}. Trying direct NodePort..."
  xdg-open "https://${NODE_IP}:32443" 2>/dev/null || open "https://${NODE_IP}:32443" 2>/dev/null || echo "Please open: https://${NODE_IP}:32443"
  echo "IMPORTANT: Accept the self-signed certificate warning in your browser"
fi

echo
echo "If none of the above methods work, try port-forwarding:"
echo "kubectl --kubeconfig=$KUBECONFIG port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-kong-proxy 8443:443"
echo "Then access: https://localhost:8443 (accept certificate warning)"
