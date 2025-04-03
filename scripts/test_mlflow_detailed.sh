#!/bin/bash
NODE_IP="192.168.1.85"
TRAEFIK_PORT="31722"
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"

echo "=== MLflow Connectivity Test ==="
echo

echo "1. Checking MLflow pod status:"
kubectl --kubeconfig=$KUBECONFIG get pods -n mlflow -o wide
echo

echo "2. Checking MLflow service:"
kubectl --kubeconfig=$KUBECONFIG get svc -n mlflow
echo

echo "3. Checking Traefik IngressRoutes:"
kubectl --kubeconfig=$KUBECONFIG get ingressroute -n mlflow
echo

echo "4. Checking Traefik Middleware:"
kubectl --kubeconfig=$KUBECONFIG get middleware -n mlflow
echo

echo "5. Testing direct HTTP access with verbose output:"
echo "GET /mlflow HTTP/1.1" | nc -v $NODE_IP $TRAEFIK_PORT
echo

echo "6. Testing with curl (verbose):"
curl -v http://$NODE_IP:$TRAEFIK_PORT/mlflow
echo

echo "7. Testing with curl and Host header:"
curl -v -H "Host: mlflow.$NODE_IP.nip.io" http://$NODE_IP:$TRAEFIK_PORT/
echo

echo "=== End of Tests ==="