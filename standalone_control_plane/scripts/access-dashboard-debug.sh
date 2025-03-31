#!/bin/bash
NODE_IP="192.168.1.85"
HOST="dashboard.192.168.1.85.nip.io"
PORT="31722"
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"

echo "===== Kubernetes Dashboard Debug Script ====="
echo "1. Check access via Ingress (standard)"
echo "2. Check access via NodePort"
echo "3. Check access via port-forward"
echo "4. Check access via host header direct to Traefik"
echo "5. Debug dashboard connectivity"
echo
echo "Choose an option (1-5):"
read -r choice

case "$choice" in
  1)
    echo "Checking access via Ingress..."
    curl -v "http://${HOST}"
    echo -e "\nTrying to open dashboard at http://${HOST}"
    xdg-open "http://${HOST}" 2>/dev/null || open "http://${HOST}" 2>/dev/null
    ;;
  2)
    echo "Checking access via NodePort direct to service..."
    kubectl --kubeconfig=$KUBECONFIG get service -n kubernetes-dashboard
    NODE_PORT=$(kubectl --kubeconfig=$KUBECONFIG get service dashboard-direct-access -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "31000")
    echo "Using NodePort: $NODE_PORT"
    curl -v "http://${NODE_IP}:${NODE_PORT}"
    echo -e "\nTrying to open dashboard at http://${NODE_IP}:${NODE_PORT}"
    xdg-open "http://${NODE_IP}:${NODE_PORT}" 2>/dev/null || open "http://${NODE_IP}:${NODE_PORT}" 2>/dev/null
    ;;
  3)
    echo "Starting port-forward to dashboard-web service..."
    echo "This will open a direct connection to the dashboard web UI"
    kubectl --kubeconfig=$KUBECONFIG port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-web 8080:8000 &
    PF_PID=$!
    echo "Port-forward started (PID: $PF_PID)"
    echo "Access at: http://localhost:8080"
    sleep 2
    curl -v "http://localhost:8080"
    echo -e "\nTrying to open dashboard at http://localhost:8080"
    xdg-open "http://localhost:8080" 2>/dev/null || open "http://localhost:8080" 2>/dev/null
    echo "Press Enter to stop port-forwarding"
    read
    kill $PF_PID
    ;;
  4)
    echo "Testing direct access to Traefik with Host header..."
    echo "Accessing: http://${NODE_IP}:${PORT} with Host: ${HOST}"
    curl -v -H "Host: ${HOST}" "http://${NODE_IP}:${PORT}"
    ;;
  5)
    echo "Running full debug on dashboard connectivity..."
    
    echo -e "\n=== Checking Dashboard Pod Status ==="
    kubectl --kubeconfig=$KUBECONFIG get pods -n kubernetes-dashboard -o wide
    
    echo -e "\n=== Checking Dashboard Services ==="
    kubectl --kubeconfig=$KUBECONFIG get svc -n kubernetes-dashboard
    
    echo -e "\n=== Checking IngressRoutes ==="
    kubectl --kubeconfig=$KUBECONFIG get ingressroute -n kubernetes-dashboard
    
    echo -e "\n=== Checking Traefik Logs ==="
    kubectl --kubeconfig=$KUBECONFIG logs -n kube-system -l app.kubernetes.io/name=traefik --tail=20
    
    echo -e "\n=== Checking Dashboard Web Pod Logs ==="
    WEB_POD=$(kubectl --kubeconfig=$KUBECONFIG get pods -n kubernetes-dashboard -l app.kubernetes.io/component=web -o jsonpath='{.items[0].metadata.name}')
    kubectl --kubeconfig=$KUBECONFIG logs -n kubernetes-dashboard $WEB_POD
    
    echo -e "\n=== Testing connectivity between components ==="
    kubectl --kubeconfig=$KUBECONFIG run -n kubernetes-dashboard debug-pod --image=curlimages/curl --rm -i --tty -- sh -c "
    echo 'Testing web service:'; 
    curl -v kubernetes-dashboard-web.kubernetes-dashboard.svc.cluster.local:8000;
    echo -e '\nTesting API service:'; 
    curl -v kubernetes-dashboard-api.kubernetes-dashboard.svc.cluster.local:8000/api/v1/csrftoken;
    "
    ;;
  *)
    echo "Invalid option"
    ;;
esac
