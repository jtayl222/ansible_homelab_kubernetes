#!/bin/bash
NODE_IP="192.168.1.85"
TRAEFIK_PORT="31722"
echo "Testing MLflow access..."
echo "Direct path access: http://$NODE_IP:$TRAEFIK_PORT/mlflow"
curl -s -I http://$NODE_IP:$TRAEFIK_PORT/mlflow | head -n 1
echo
echo "Host-based access: http://mlflow.$NODE_IP.nip.io"
curl -s -I -H "Host: mlflow.$NODE_IP.nip.io" http://$NODE_IP:$TRAEFIK_PORT | head -n 1
