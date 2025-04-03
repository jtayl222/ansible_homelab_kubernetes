#!/bin/bash
NAMESPACE="kubernetes-dashboard"
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"

echo "Creating service account for dashboard access..."
kubectl --kubeconfig=$KUBECONFIG create serviceaccount dashboard-admin -n $NAMESPACE

echo "Creating cluster role binding..."
kubectl --kubeconfig=$KUBECONFIG create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=$NAMESPACE:dashboard-admin

echo "Creating token..."
TOKEN=$(kubectl --kubeconfig=$KUBECONFIG create token dashboard-admin -n $NAMESPACE)

echo "============================================"
echo "Dashboard Access Token (Valid for 1 hour):"
echo "============================================"
echo "$TOKEN"
echo "============================================"
echo "Copy this token when prompted by the dashboard login screen."
