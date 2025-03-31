#!/bin/bash

KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"
NAMESPACE="kubernetes-dashboard"
TOKEN=$(kubectl --kubeconfig=$KUBECONFIG -n $NAMESPACE get secret dashboard-admin-token -o jsonpath="{.data.token}" | base64 -d)

echo "Starting Kubernetes Dashboard using port-forwarding..."
echo "Token is:"
echo "$TOKEN"
echo
echo "Starting port-forward - press Ctrl+C to exit when done"

# Start port-forwarding in background using the correct service name
kubectl --kubeconfig=$KUBECONFIG -n $NAMESPACE port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 &
PF_PID=$!

# Wait 3 seconds for port-forward to establish
sleep 3

# Open browser
echo "Opening browser to https://localhost:8443/"
xdg-open https://localhost:8443/ 2>/dev/null || open https://localhost:8443/ 2>/dev/null || echo "Please open https://localhost:8443/ in your browser"

# Wait for port-forward process to end (when user presses Ctrl+C)
wait $PF_PID
