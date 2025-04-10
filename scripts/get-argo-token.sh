#!/bin/bash
# Script to generate a token for accessing Argo Workflows UI in Kubernetes 1.24+

NAMESPACE="argo"
SA_NAME="argo-admin"

# Check if the service account exists
if ! kubectl -n $NAMESPACE get serviceaccount $SA_NAME &>/dev/null; then
  echo "Service account $SA_NAME not found in namespace $NAMESPACE"
  exit 1
fi

# Create a token using kubectl
echo "Creating token for service account $SA_NAME..."
TOKEN=$(kubectl -n $NAMESPACE create token $SA_NAME)

if [ -z "$TOKEN" ]; then
  echo "Failed to generate token for service account $SA_NAME"
  exit 1
fi

echo "===== ARGO UI TOKEN ====="
echo "$TOKEN"
echo "========================="
echo "Copy this token and use it to log in to the Argo UI at:"
echo "https://192.168.1.85:30130/"
echo ""
echo "NOTE: This token is short-lived and will expire."
echo "Run this script again to generate a new token if needed."
