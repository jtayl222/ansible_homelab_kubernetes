#!/bin/bash
# filepath: /home/user/ansible_homelab_kubernetes/scripts/update-hosts-file.sh

set -e

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}*******************************************************************${NC}"
echo -e "${GREEN}*             KUBERNETES HOMELAB HOSTS FILE UPDATER              *${NC}"
echo -e "${GREEN}*******************************************************************${NC}"
echo ""

# Get only IPv4 address from control plane nodes
echo -n "Detecting control plane IP address... "
CONTROL_PLANE_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o 'jsonpath={.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

# If automatic detection fails, use localhost or prompt
if [ -z "$CONTROL_PLANE_IP" ]; then
    echo -e "${YELLOW}not found automatically.${NC}"
    echo -n "Please enter your control plane IP address: "
    read -r CONTROL_PLANE_IP

    if [ -z "$CONTROL_PLANE_IP" ]; then
        echo -e "${RED}No IP provided. Exiting.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}found $CONTROL_PLANE_IP${NC}"
fi

# Check if user has sudo access
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}This script requires sudo privileges to modify /etc/hosts${NC}"
    echo "You will be prompted for your password."
fi

# Check if entries already exist
HOSTS_CHECK=$(grep "# Kubernetes homelab services begin" /etc/hosts 2>/dev/null || echo "")
if [ -n "$HOSTS_CHECK" ]; then
    echo -e "${YELLOW}Kubernetes homelab entries already exist in /etc/hosts${NC}"
    echo -n "Do you want to update them? (y/n): "
    read -r UPDATE_HOSTS
    if [[ "$UPDATE_HOSTS" != "y" && "$UPDATE_HOSTS" != "Y" ]]; then
        echo "Skipping hosts file update."
        exit 0
    fi

    # Create a backup of the hosts file
    echo "Creating backup of /etc/hosts to /etc/hosts.bak"
    sudo cp /etc/hosts /etc/hosts.bak

    # Remove existing entries
    echo "Removing existing Kubernetes homelab entries..."
    sudo sed -i '/# Kubernetes homelab services begin/,/# Kubernetes homelab services end/d' /etc/hosts
fi

# Prepare the hosts file entries
echo "Adding Kubernetes homelab entries to /etc/hosts..."
HOSTS_ENTRIES="
# Kubernetes homelab services begin
$CONTROL_PLANE_IP    traefik.local
$CONTROL_PLANE_IP    dashboard.local
$CONTROL_PLANE_IP    grafana.local
$CONTROL_PLANE_IP    prometheus.local
$CONTROL_PLANE_IP    kibana.local
$CONTROL_PLANE_IP    mlflow.local
$CONTROL_PLANE_IP    minio.local
$CONTROL_PLANE_IP    seldon.local
$CONTROL_PLANE_IP    iris.local
$CONTROL_PLANE_IP    traefik.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    dashboard.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    grafana.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    prometheus.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    kibana.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    mlflow.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    minio.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    minio-console.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    seldon.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    whoami.$CONTROL_PLANE_IP.nip.io
# Kubernetes homelab services end"

# Add entries to hosts file
echo "$HOSTS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null

echo -e "${GREEN}Successfully updated /etc/hosts with Kubernetes homelab entries${NC}"
echo ""
echo -e "${YELLOW}Testing service connectivity:${NC}"

# Define services to test
declare -a SERVICES=(
    "traefik.local:80:/dashboard/"
    "grafana.local:80:/"
    "prometheus.local:80:/"
    "mlflow.local:80:/"
    "minio.local:80:/"
    "seldon.local:80:/seldon/"
)

# Test connectivity to each service
for service in "${SERVICES[@]}"; do
    IFS=':' read -r host port path <<< "$service"
    echo -n "Testing $host... "

    # Use curl with a short timeout to check if service is responding
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://$host$path" 2>/dev/null || echo "Failed")

    if [[ "$status" =~ ^(2|3)[0-9][0-9]$ ]]; then
        echo -e "${GREEN}Online (HTTP $status)${NC}"
    elif [[ "$status" =~ ^4[0-9][0-9]$ ]]; then
        echo -e "${YELLOW}Returns HTTP $status${NC}"
    elif [[ "$status" =~ ^5[0-9][0-9]$ ]]; then
        echo -e "${RED}Error (HTTP $status)${NC}"
    else
        echo -e "${RED}Unreachable${NC}"
    fi
done

echo ""
echo -e "${GREEN}Services should now be accessible using .local domains${NC}"
echo -e "For example: http://grafana.local"
echo ""

# Create a helper table with all service URLs
echo -e "${GREEN}*******************************************************************${NC}"
echo -e "${GREEN}*                   SERVICE ACCESS SUMMARY                        *${NC}"
echo -e "${GREEN}*******************************************************************${NC}"
echo "Traefik Dashboard:  http://traefik.local/dashboard/"
echo "                    http://traefik.$CONTROL_PLANE_IP.nip.io/dashboard/"
echo "                    http://$CONTROL_PLANE_IP:32080/dashboard/"
echo ""
echo "Grafana:            http://grafana.local"
echo "                    http://grafana.$CONTROL_PLANE_IP.nip.io"
echo "                    http://$CONTROL_PLANE_IP:32080/grafana"
echo ""
echo "Prometheus:         http://prometheus.local"
echo "                    http://prometheus.$CONTROL_PLANE_IP.nip.io"
echo "                    http://$CONTROL_PLANE_IP:32080/prometheus"
echo ""
echo "Kibana:             http://kibana.local"
echo "                    https://kibana.local"
echo "                    http://kibana.$CONTROL_PLANE_IP.nip.io"
echo "                    https://$CONTROL_PLANE_IP:30056/kibana"
echo ""
echo "MLflow:             http://mlflow.local"
echo "                    http://mlflow.$CONTROL_PLANE_IP.nip.io"
echo "                    http://$CONTROL_PLANE_IP:32080/mlflow"
echo ""
echo "MinIO Console:      http://minio.local"
echo "                    http://minio.$CONTROL_PLANE_IP.nip.io"
echo "                    http://$CONTROL_PLANE_IP:30141"
echo ""
echo "Seldon:             http://seldon.local/seldon/"
echo "                    http://seldon.$CONTROL_PLANE_IP.nip.io/seldon/"
echo -e "${GREEN}*******************************************************************${NC}"#!/bin/bash
# filepath: /home/user/ansible_homelab_kubernetes/scripts/update-hosts-file.sh

set -e

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}*******************************************************************${NC}"
echo -e "${GREEN}*             KUBERNETES HOMELAB HOSTS FILE UPDATER              *${NC}"
echo -e "${GREEN}*******************************************************************${NC}"
echo ""

# Get only IPv4 address from control plane nodes
echo -n "Detecting control plane IP address... "
CONTROL_PLANE_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o 'jsonpath={.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

# If automatic detection fails, use localhost or prompt
if [ -z "$CONTROL_PLANE_IP" ]; then
    echo -e "${YELLOW}not found automatically.${NC}"
    echo -n "Please enter your control plane IP address: "
    read -r CONTROL_PLANE_IP

    if [ -z "$CONTROL_PLANE_IP" ]; then
        echo -e "${RED}No IP provided. Exiting.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}found $CONTROL_PLANE_IP${NC}"
fi

# Check if user has sudo access
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}This script requires sudo privileges to modify /etc/hosts${NC}"
    echo "You will be prompted for your password."
fi

# Check if entries already exist
HOSTS_CHECK=$(grep "# Kubernetes homelab services begin" /etc/hosts 2>/dev/null || echo "")
if [ -n "$HOSTS_CHECK" ]; then
    echo -e "${YELLOW}Kubernetes homelab entries already exist in /etc/hosts${NC}"
    echo -n "Do you want to update them? (y/n): "
    read -r UPDATE_HOSTS
    if [[ "$UPDATE_HOSTS" != "y" && "$UPDATE_HOSTS" != "Y" ]]; then
        echo "Skipping hosts file update."
        exit 0
    fi

    # Create a backup of the hosts file
    echo "Creating backup of /etc/hosts to /etc/hosts.bak"
    sudo cp /etc/hosts /etc/hosts.bak

    # Remove existing entries
    echo "Removing existing Kubernetes homelab entries..."
    sudo sed -i '/# Kubernetes homelab services begin/,/# Kubernetes homelab services end/d' /etc/hosts
fi

# Prepare the hosts file entries
echo "Adding Kubernetes homelab entries to /etc/hosts..."
HOSTS_ENTRIES="
# Kubernetes homelab services begin
$CONTROL_PLANE_IP    traefik.local
$CONTROL_PLANE_IP    dashboard.local
$CONTROL_PLANE_IP    grafana.local
$CONTROL_PLANE_IP    prometheus.local
$CONTROL_PLANE_IP    kibana.local
$CONTROL_PLANE_IP    mlflow.local
$CONTROL_PLANE_IP    minio.local
$CONTROL_PLANE_IP    seldon.local
$CONTROL_PLANE_IP    iris.local
$CONTROL_PLANE_IP    argo.local
$CONTROL_PLANE_IP    traefik.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    dashboard.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    grafana.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    prometheus.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    kibana.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    mlflow.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    minio.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    minio-console.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    seldon.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    argo.$CONTROL_PLANE_IP.nip.io
$CONTROL_PLANE_IP    whoami.$CONTROL_PLANE_IP.nip.io
# Kubernetes homelab services end"

# Add entries to hosts file
echo "$HOSTS_ENTRIES" | sudo tee -a /etc/hosts > /dev/null

echo -e "${GREEN}Successfully updated /etc/hosts with Kubernetes homelab entries${NC}"
echo ""
echo -e "${YELLOW}Testing service connectivity:${NC}"

# Define services to test
declare -a SERVICES=(
    "traefik.local:80:/dashboard/"
    "grafana.local:80:/"
    "prometheus.local:80:/"
    "mlflow.local:80:/"
    "minio.local:80:/"
    "seldon.local:80:/seldon/"
    "argo.local:443:/"
)

# Test connectivity to each service
for service in "${SERVICES[@]}"; do
    IFS=':' read -r host port path <<< "$service"
    echo -n "Testing $host... "

    # Use curl with a short timeout to check if service is responding
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://$host$path" 2>/dev/null || echo "Failed")

    if [[ "$status" =~ ^(2|3)[0-9][0-9]$ ]]; then
        echo -e "${GREEN}Online (HTTP $status)${NC}"
    elif [[ "$status" =~ ^4[0-9][0-9]$ ]]; then
        echo -e "${YELLOW}Returns HTTP $status${NC}"
    elif [[ "$status" =~ ^5[0-9][0-9]$ ]]; then
        echo -e "${RED}Error (HTTP $status)${NC}"
    else
        echo -e "${RED}Unreachable${NC}"
    fi
done

echo ""
echo -e "${GREEN}Services should now be accessible using .local domains${NC}"
echo -e "For example: http://grafana.local"
echo ""

# Create a helper table with all service URLs
echo -e "${GREEN}*******************************************************************${NC}"
echo -e "${GREEN}*                   SERVICE ACCESS SUMMARY                        *${NC}"
echo -e "${GREEN}*******************************************************************${NC}"
echo "Traefik Dashboard:  http://traefik.local/dashboard/"
echo "                    http://traefik.$CONTROL_PLANE_IP.nip.io/dashboard/"
echo "                    http://$CONTROL_PLANE_IP:32080/dashboard/"
echo ""
echo "Grafana:            http://grafana.local"
echo "                    http://grafana.$CONTROL_PLANE_IP.nip.io"
echo "                    http://$CONTROL_PLANE_IP:32080/grafana"
echo ""
echo "Prometheus:         http://prometheus.local"
echo "                    http://prometheus.$CONTROL_PLANE_IP.nip.io"
echo "                    http://$CONTROL_PLANE_IP:32080/prometheus"
echo ""
echo "Kibana:             http://kibana.local"
echo "                    https://kibana.local"
echo "                    http://kibana.$CONTROL_PLANE_IP.nip.io"
echo "                    https://$CONTROL_PLANE_IP:30056/kibana"
echo ""
echo "MLflow:             http://mlflow.local"
echo "                    http://mlflow.$CONTROL_PLANE_IP.nip.io"
echo "                    http://$CONTROL_PLANE_IP:32080/mlflow"
echo ""
echo "MinIO Console:      http://minio.local"
echo "                    http://minio.$CONTROL_PLANE_IP.nip.io"
echo "                    http://$CONTROL_PLANE_IP:30141"
echo ""
echo "Seldon:             http://seldon.local/seldon/"
echo "                    http://seldon.$CONTROL_PLANE_IP.nip.io/seldon/"
echo ""
echo "Seldon:             http://seldon.local/seldon/"
echo "                    http://seldon.$CONTROL_PLANE_IP.nip.io/seldon/"
echo ""
echo "Argo Workflows:     https://argo.local/"
echo "                    https://argo.$CONTROL_PLANE_IP.nip.io/"
echo "                    https://$CONTROL_PLANE_IP:30130/"
echo -e "${GREEN}*******************************************************************${NC}"
