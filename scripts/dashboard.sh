#!/bin/bash
KUBECONFIG="/home/user/ansible_homelab_kubernetes/fetched_tokens/k3s-kubeconfig"

echo "Starting port-forward to Traefik..."
echo "Use http://localhost:9000/dashboard/"
echo "Username: admin"
echo "Password: admin"
kubectl --kubeconfig=$KUBECONFIG port-forward -n kube-system svc/traefik 9000:80 &
PF_PID=$!
sleep 3
xdg-open "http://localhost:9000/dashboard/" 2>/dev/null || open "http://localhost:9000/dashboard/" 2>/dev/null || echo "Open http://localhost:9000/dashboard/ manually"
wait $PF_PID
