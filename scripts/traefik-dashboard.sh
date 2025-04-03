#!/bin/bash
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"

echo "Starting port-forward to Traefik dashboard..."
echo "Access the dashboard at: http://localhost:9000/dashboard/"
echo "Username: admin"
echo "Password: admin"
echo
echo "Press Ctrl+C to stop"

kubectl --kubeconfig=$KUBECONFIG port-forward -n kube-system svc/traefik 9000:80
