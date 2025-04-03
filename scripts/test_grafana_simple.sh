#!/bin/bash
# Quick test for Grafana behind Traefik

NODE_IP="192.168.1.85"
PORT=$(kubectl --kubeconfig=/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig get svc -n kube-system traefik -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}')

echo "Testing Grafana at http://$NODE_IP:$PORT/grafana/"

# Check where the redirect is going
echo "Checking redirect location:"
REDIRECT_LOC=$(curl -s -I "http://$NODE_IP:$PORT/grafana/" | grep -i "location" | awk '{print $2}')
if [ -n "$REDIRECT_LOC" ]; then
  echo "Grafana is redirecting to: $REDIRECT_LOC"
fi

# Test with redirect following
echo "Testing with redirect following:"
curl -s -L -I "http://$NODE_IP:$PORT/grafana/" | grep "HTTP/"

# Get HTTP status with redirect following
HTTP_CODE=$(curl -s -L -o /dev/null -w "%{http_code}" "http://$NODE_IP:$PORT/grafana/")
echo "HTTP Status (following redirects): $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
  echo "✅ Grafana is accessible when following redirects!"
else
  echo "❌ Grafana is not accessible even when following redirects"
fi