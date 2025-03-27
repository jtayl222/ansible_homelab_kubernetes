#!/bin/bash
# Debug Grafana redirect behavior

NODE_IP="192.168.1.85"
PORT=$(kubectl --kubeconfig=/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig get svc -n kube-system traefik -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}')

echo "==== Debugging Grafana redirect behavior ===="
echo "Testing: http://$NODE_IP:$PORT/grafana"
echo 

echo "HEAD request to see redirect:"
curl -s -I "http://$NODE_IP:$PORT/grafana" | grep -E "(^HTTP|^Location)"

echo 
echo "Showing redirect chain:"
curl -s -I -L "http://$NODE_IP:$PORT/grafana" | grep -E "(^HTTP|^Location)"

echo
echo "==== Testing Traefik configuration ===="
kubectl --kubeconfig=/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig get middlewares -A
echo 
kubectl --kubeconfig=/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig get ingressroute -A

echo
echo "==== Checking Grafana configuration ===="
kubectl --kubeconfig=/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig get cm -n monitoring