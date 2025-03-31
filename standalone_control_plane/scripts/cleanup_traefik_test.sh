#!/bin/bash

KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"
NAMESPACE="traefik-test"

echo "Cleaning up Traefik test resources..."
kubectl --kubeconfig=$KUBECONFIG delete namespace $NAMESPACE
echo "Test resources removed."
