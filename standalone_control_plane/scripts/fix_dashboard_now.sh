#!/bin/bash

KUBECONFIG=~/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig
NAMESPACE=kubernetes-dashboard

echo "=== Emergency Dashboard Fix Script ==="

# Create direct NodePort service for Web component
cat << 'YAML' | kubectl --kubeconfig=$KUBECONFIG apply -f -
apiVersion: v1
kind: Service
metadata:
  name: kubernetes-dashboard-direct
  namespace: kubernetes-dashboard
spec:
  selector:
    app.kubernetes.io/component: web
    app.kubernetes.io/instance: kubernetes-dashboard
  type: NodePort
  ports:
  - port: 8000
    nodePort: 32000
    targetPort: 8000
    protocol: TCP
YAML

# Create direct NodePort service for API component
cat << 'YAML' | kubectl --kubeconfig=$KUBECONFIG apply -f -
apiVersion: v1
kind: Service
metadata:
  name: kubernetes-dashboard-api-direct
  namespace: kubernetes-dashboard
spec:
  selector:
    app.kubernetes.io/component: api
    app.kubernetes.io/instance: kubernetes-dashboard
  type: NodePort
  ports:
  - port: 8000
    nodePort: 32001
    targetPort: 8000
    protocol: TCP
YAML

# Create dashboard admin account & token
kubectl --kubeconfig=$KUBECONFIG create serviceaccount dashboard-admin -n $NAMESPACE || true
kubectl --kubeconfig=$KUBECONFIG create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=$NAMESPACE:dashboard-admin || true
TOKEN=$(kubectl --kubeconfig=$KUBECONFIG create token dashboard-admin -n $NAMESPACE)

echo
echo "=== Dashboard Access Information ==="
echo "Dashboard URL: http://192.168.1.85:32000"
echo "API URL: http://192.168.1.85:32001"
echo
echo "Authentication Token:"
echo "$TOKEN"
echo
echo "Try accessing the dashboard now!"
