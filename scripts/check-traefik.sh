#!/bin/bash
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"
NODE_IP="192.168.1.85"
PORT="31605"

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}==================================${NC}"
echo -e "${YELLOW}   Traefik Status Check${NC}"
echo -e "${YELLOW}==================================${NC}"

# Check if Traefik pods are running
echo -e "\n${YELLOW}Checking Traefik pods:${NC}"
kubectl --kubeconfig=$KUBECONFIG get pods -n kube-system -l app.kubernetes.io/name=traefik

# Check if IngressRoutes are properly defined
echo -e "\n${YELLOW}Checking IngressRoutes:${NC}"
kubectl --kubeconfig=$KUBECONFIG get ingressroutes -n kube-system

# Check direct access - this might redirect
echo -e "\n${YELLOW}Testing direct access (HTTP):${NC}"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$NODE_IP:$PORT/dashboard/")
if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "401" ]]; then
  echo -e "${GREEN}✅ Dashboard HTTP endpoint accessible: $HTTP_STATUS${NC}"
else
  echo -e "${RED}❌ Dashboard HTTP access issue: $HTTP_STATUS${NC}"
fi

# Check port-forward - this should work reliably
echo -e "\n${YELLOW}Testing port-forward access:${NC}"
echo -e "Starting port-forward in background..."
kubectl --kubeconfig=$KUBECONFIG port-forward -n kube-system svc/traefik 9999:80 &> /dev/null &
PF_PID=$!
sleep 2

PF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://localhost:9999/dashboard/")
if [[ "$PF_STATUS" == "200" || "$PF_STATUS" == "401" ]]; then
  echo -e "${GREEN}✅ Port-forward works: $PF_STATUS${NC}"
  echo -e "   Try: ./scripts/dashboard.sh"
else
  echo -e "${RED}❌ Port-forward issue: $PF_STATUS${NC}"
fi

# Kill port-forward
kill $PF_PID &> /dev/null

echo -e "\n${YELLOW}==================================${NC}"
echo -e "For reliable dashboard access, run:"
echo -e "${GREEN}./scripts/dashboard.sh${NC}"
echo -e "Username: admin"
echo -e "Password: admin"
