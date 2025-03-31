#!/bin/bash

NODE_IP="192.168.1.85"
PORT="30080"
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"

echo "========== Traefik Connectivity Diagnostics =========="
echo

echo "1. Testing direct port access with 5s timeout:"
timeout 5 curl -v http://$NODE_IP:$PORT 2>&1 || echo "Connection timed out"
echo

echo "2. Checking if port is open:"
nc -zv $NODE_IP $PORT -w 2 && echo "Port is open" || echo "Port is closed"
echo

echo "3. Checking Traefik pod status:"
kubectl --kubeconfig=$KUBECONFIG get pods -n kube-system -l app.kubernetes.io/name=traefik
echo

echo "4. Testing path-based routing to test service:"
curl -v -m 5 http://$NODE_IP:$PORT/test 2>&1 || echo "Connection failed"
echo

echo "5. Checking Traefik service definition:"
kubectl --kubeconfig=$KUBECONFIG get svc traefik -n kube-system -o yaml | grep -A 10 "ports:"
echo

echo "========== Connectivity Tests Done =========="
echo
echo "If everything is still failing, try the following fix:"
echo
echo "1. Reset the Traefik configuration:"
echo "   kubectl --kubeconfig=$KUBECONFIG rollout restart deployment traefik -n kube-system"
echo
echo "2. Set up port-forwarding for direct access:"
echo "   kubectl --kubeconfig=$KUBECONFIG port-forward -n kube-system service/traefik 8000:80 &"
echo
echo "3. Test local access:"
echo "   curl http://localhost:8000"
