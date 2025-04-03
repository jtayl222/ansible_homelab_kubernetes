#!/bin/bash
NODE_IP="192.168.1.85"
PORT="31605"
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"

kubectl --kubeconfig=$KUBECONFIG port-forward -n kube-system svc/traefik 9000:80 &
PF_PID=$!

sleep 2

echo "Opening dashboard in browser..."
echo "Username: admin"
echo "Password: admin"

xdg-open "http://localhost:9000/dashboard/" 2>/dev/null || open "http://localhost:9000/dashboard/" 2>/dev/null || echo "Please open http://localhost:9000/dashboard/ in your browser"

echo
echo "Press Enter to stop port-forwarding and exit"
read

kill $PF_PID
