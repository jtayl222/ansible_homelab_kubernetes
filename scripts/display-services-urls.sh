#!/bin/bash
# filepath: /home/user/ansible_homelab_kubernetes/scripts/display-services-urls.sh
# Show access URLs for all Kubernetes homelab services with Traefik URLs and credentials

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define default ports if environment variables are not set
K8S_DASHBOARD_PORT=${K8S_DASHBOARD_PORT:-30443}
TRAEFIK_NODE_PORT=${TRAEFIK_NODE_PORT:-32080}
KIBANA_NODE_PORT=${KIBANA_NODE_PORT:-30056}
MINIO_CONSOLE_PORT=${MINIO_CONSOLE_PORT:-30141} # Updated to detected port
SELDON_NODE_PORT=${SELDON_NODE_PORT:-30150}

# Define colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get only IPv4 address from control plane nodes
echo -n "Detecting control plane IP... "
CONTROL_PLANE_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o 'jsonpath={.items[0].status.addresses[?(@.type=="InternalIP")].address}' | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

# If automatic detection fails, use localhost or prompt
if [ -z "$CONTROL_PLANE_IP" ]; then
    echo -e "${YELLOW}not found${NC}"
    echo -n "Please enter your control plane IP address: "
    read -r CONTROL_PLANE_IP
    
    if [ -z "$CONTROL_PLANE_IP" ]; then
        CONTROL_PLANE_IP="localhost"
        echo "Using $CONTROL_PLANE_IP as fallback."
    fi
else
    echo -e "${GREEN}$CONTROL_PLANE_IP${NC}"
fi

# Try to get Traefik credentials from fetched_tokens
TRAEFIK_USER="admin"
if [ -f "${SCRIPT_DIR}/../fetched_tokens/traefik_password.txt" ]; then
    TRAEFIK_PASSWORD=$(cat "${SCRIPT_DIR}/../fetched_tokens/traefik_password.txt")
else
    TRAEFIK_PASSWORD=$(kubectl get secret -n kube-system traefik-dashboard-auth -o jsonpath='{.data.users}' 2>/dev/null | base64 -d | cut -d: -f2 || echo "admin")
fi

# Try to get Grafana credentials from fetched_tokens
GRAFANA_USER="admin"
if [ -f "${SCRIPT_DIR}/../fetched_tokens/grafana_password.txt" ]; then
    GRAFANA_PASSWORD=$(cat "${SCRIPT_DIR}/../fetched_tokens/grafana_password.txt")
else
    GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 -d || echo "<check fetched_tokens directory>")
fi

# Try to get Kibana/Elastic credentials from fetched_tokens
if [ -f "${SCRIPT_DIR}/../fetched_tokens/elastic_password.txt" ]; then
    ELASTIC_PASSWORD=$(cat "${SCRIPT_DIR}/../fetched_tokens/elastic_password.txt")
else
    ELASTIC_PASSWORD="<check fetched_tokens/elastic_password.txt>"
fi

# MinIO credentials from fetched_tokens
if [ -f "${SCRIPT_DIR}/../fetched_tokens/minio_credentials.txt" ]; then
    MINIO_USER=$(grep "accessKey:" "${SCRIPT_DIR}/../fetched_tokens/minio_credentials.txt" | awk '{print $2}')
    MINIO_PASSWORD=$(grep "secretKey:" "${SCRIPT_DIR}/../fetched_tokens/minio_credentials.txt" | awk '{print $2}')
else
    MINIO_USER=$(kubectl get secret -n minio-operator minio-api-credentials -o jsonpath="{.data.accesskey}" 2>/dev/null | base64 -d || echo "minio")
    MINIO_PASSWORD=$(kubectl get secret -n minio-operator minio-api-credentials -o jsonpath="{.data.secretkey}" 2>/dev/null | base64 -d || echo "<check fetched_tokens directory>")
fi

echo -e "${BLUE}*******************************************************************${NC}"
echo -e "${BLUE}*             KUBERNETES HOMELAB SERVICES ACCESS                  *${NC}"
echo -e "${BLUE}*******************************************************************${NC}"
echo ""
echo -e "${BOLD}Access your services at:${NC}"
echo ""
echo -e "${BOLD}TRAEFIK DASHBOARD:${NC}"
echo "  URL (.local): http://traefik.local/dashboard/"
echo "  URL (.nip.io): http://traefik.$CONTROL_PLANE_IP.nip.io/dashboard/"
echo "  URL (direct): http://$CONTROL_PLANE_IP:$TRAEFIK_NODE_PORT/dashboard/"
echo "  Username: $TRAEFIK_USER"
echo "  Password: $TRAEFIK_PASSWORD"
echo ""
echo -e "${BOLD}KUBERNETES DASHBOARD:${NC}"
echo "  URL (.local): https://dashboard.local"
echo "  URL (.nip.io): https://dashboard.$CONTROL_PLANE_IP.nip.io"
echo "  URL (direct): https://$CONTROL_PLANE_IP:$K8S_DASHBOARD_PORT"
echo "  Token: $([ -f "${SCRIPT_DIR}/../fetched_tokens/k8s_dashboard_token.txt" ] && echo "<see fetched_tokens/k8s_dashboard_token.txt>" || echo "<use 'kubectl -n kubernetes-dashboard create token admin-user'>")"
echo ""
echo -e "${BOLD}GRAFANA:${NC}"
echo "  URL (.local): http://grafana.local/"
echo "  URL (.nip.io): http://grafana.$CONTROL_PLANE_IP.nip.io/"
echo "  URL (via Traefik): http://$CONTROL_PLANE_IP:$TRAEFIK_NODE_PORT/grafana"
echo "  Username: $GRAFANA_USER"
echo "  Password: $GRAFANA_PASSWORD"
echo ""
echo -e "${BOLD}PROMETHEUS:${NC}"
echo "  URL (.local): http://prometheus.local/"
echo "  URL (.nip.io): http://prometheus.$CONTROL_PLANE_IP.nip.io/"
echo "  URL (via Traefik): http://$CONTROL_PLANE_IP:$TRAEFIK_NODE_PORT/prometheus"
echo ""
echo -e "${BOLD}KIBANA:${NC}"
echo "  URL (.local): http://kibana.local/"
echo "  URL (.nip.io): http://kibana.$CONTROL_PLANE_IP.nip.io/"
echo "  URL (direct): https://$CONTROL_PLANE_IP:$KIBANA_NODE_PORT/kibana"
echo "  Username: elastic"
echo "  Password: $ELASTIC_PASSWORD"
echo ""
echo -e "${BOLD}MLFLOW:${NC}"
echo "  URL (.local): http://mlflow.local/"
echo "  URL (.nip.io): http://mlflow.$CONTROL_PLANE_IP.nip.io/"
echo "  URL (via Traefik): http://$CONTROL_PLANE_IP:$TRAEFIK_NODE_PORT/mlflow"
echo ""
echo -e "${BOLD}MINIO CONSOLE:${NC}"
echo "  URL (.local): http://minio.local/"
echo "  URL (.nip.io): http://minio.$CONTROL_PLANE_IP.nip.io/"
echo "  URL (direct): http://$CONTROL_PLANE_IP:$MINIO_CONSOLE_PORT"
echo "  Username: $MINIO_USER"
echo "  Password: $MINIO_PASSWORD"
echo ""
echo -e "${BOLD}SELDON CORE API:${NC}"
echo "  URL (.local): http://seldon.local/seldon/"
echo "  URL (.nip.io): http://seldon.$CONTROL_PLANE_IP.nip.io/seldon/"
echo "  URL (direct): http://$CONTROL_PLANE_IP:$SELDON_NODE_PORT/seldon/"
echo ""
echo -e "${BOLD}Service Status:${NC}"

# Check which services are actually deployed by testing their endpoints
check_service() {
    local name=$1
    local url=$2
    
    echo -n "- $name: "
    
    # Use curl with a short timeout to check if service is responding
    # We silence all output and just check the HTTP status code range
    status=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$url" 2>/dev/null || echo "Failed")
    
    if [[ "$status" =~ ^(2|3)[0-9][0-9]$ ]]; then
        echo -e "${GREEN}Online${NC} (HTTP $status)"
    elif [[ "$status" =~ ^4[0-9][0-9]$ ]]; then
        echo -e "${YELLOW}Returning Error${NC} (HTTP $status)"
    elif [[ "$status" =~ ^5[0-9][0-9]$ ]]; then
        echo -e "${RED}Service Error${NC} (HTTP $status)"
    else
        echo -e "${RED}Offline${NC}"
    fi
}

# Check URLs using three access methods for each service
echo "--- Host-based (.local) Access ---"
check_service "Traefik Dashboard" "http://traefik.local/dashboard/"
check_service "Grafana" "http://grafana.local/"
check_service "Prometheus" "http://prometheus.local/"
check_service "Kibana" "http://kibana.local/"
check_service "MLflow" "http://mlflow.local/"
check_service "MinIO Console" "http://minio.local/"
check_service "Seldon Core API" "http://seldon.local/seldon/"

echo ""
echo "--- NIP.IO Domain Access ---"
check_service "Traefik Dashboard" "http://traefik.$CONTROL_PLANE_IP.nip.io/dashboard/"
check_service "Grafana" "http://grafana.$CONTROL_PLANE_IP.nip.io/"
check_service "Prometheus" "http://prometheus.$CONTROL_PLANE_IP.nip.io/"
check_service "Kibana" "http://kibana.$CONTROL_PLANE_IP.nip.io/"
check_service "MLflow" "http://mlflow.$CONTROL_PLANE_IP.nip.io/"
check_service "MinIO Console" "http://minio.$CONTROL_PLANE_IP.nip.io/"
check_service "Seldon Core API" "http://seldon.$CONTROL_PLANE_IP.nip.io/seldon/"

echo ""
echo "--- Direct Access ---"
check_service "Traefik Dashboard" "http://$CONTROL_PLANE_IP:$TRAEFIK_NODE_PORT/dashboard/"
check_service "Kubernetes Dashboard" "https://$CONTROL_PLANE_IP:$K8S_DASHBOARD_PORT"
check_service "Grafana" "http://$CONTROL_PLANE_IP:$TRAEFIK_NODE_PORT/grafana"
check_service "Prometheus" "http://$CONTROL_PLANE_IP:$TRAEFIK_NODE_PORT/prometheus"
check_service "Kibana" "https://$CONTROL_PLANE_IP:$KIBANA_NODE_PORT/kibana"
check_service "MLflow" "http://$CONTROL_PLANE_IP:$TRAEFIK_NODE_PORT/mlflow"
check_service "MinIO Console" "http://$CONTROL_PLANE_IP:$MINIO_CONSOLE_PORT"
check_service "Seldon Core API" "http://$CONTROL_PLANE_IP:$SELDON_NODE_PORT/seldon/"

echo ""
echo -e "${YELLOW}NOTE:${NC}"
echo "  • If host-based URLs aren't working, ensure /etc/hosts entries are configured correctly"
echo "  • Run ./scripts/update-hosts-file.sh to add required host entries"
echo "  • For service-specific issues, check their respective logs with kubectl logs commands"
echo ""
echo "See documentation for additional credentials and further instructions."
echo -e "${BLUE}*******************************************************************${NC}"

# Provide a helpful tip about checking logs for troubleshooting
echo ""
echo -e "${BOLD}Troubleshooting Tips:${NC}"
echo "• If services show errors, check their pod status:"
echo "  kubectl get pods --all-namespaces | grep -E 'traefik|grafana|prometheus|kibana|mlflow|minio|seldon'"
echo ""
echo "• For detailed logs from a specific service, use: "
echo "  kubectl logs -n <namespace> <pod-name>"
echo ""
echo "• To check ingress routes: "
echo "  kubectl get ingressroute --all-namespaces"
echo ""