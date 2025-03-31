#!/bin/bash
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"

echo "Starting port-forward to Kubernetes Dashboard..."
echo "Access via: https://localhost:8443"
echo "IMPORTANT: Accept the certificate warning in your browser"
echo "Press Ctrl+C to stop"

kubectl --kubeconfig=$KUBECONFIG port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-kong-proxy 8443:443
