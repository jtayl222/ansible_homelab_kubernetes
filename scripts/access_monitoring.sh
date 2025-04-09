#!/bin/bash

KUBECONFIG="/home/user/ansible_homelab_kubernetes/fetched_tokens/k3s-kubeconfig"
NODE_IP="192.168.1.85"
TRAEFIK_PORT="32441"
GRAFANA_PASSWORD="prom-operator"

echo "========== Kubernetes Monitoring Stack =========="
echo
echo "Grafana:"
echo "  URL: http://$NODE_IP:$TRAEFIK_PORT/grafana"
echo "  Username: admin"
echo "  Password: $GRAFANA_PASSWORD"
echo
echo "Prometheus:"
echo "  URL: http://$NODE_IP:$TRAEFIK_PORT/prometheus"
echo
echo "Alertmanager:"
echo "  URL: http://$NODE_IP:$TRAEFIK_PORT/alertmanager"
echo
echo "=============================================="
echo
echo "Interesting Dashboards:"
echo "1. K3s Pod Monitoring (custom)"
echo "2. Node Exporter / Full"
echo "3. Kubernetes / API server"
echo "4. Kubernetes / Compute Resources / Cluster"
echo "5. Kubernetes / Compute Resources / Namespace (Pods)"
echo "6. Kubernetes / Compute Resources / Workload"
echo
echo "To port-forward services directly:"
echo
echo "Grafana: kubectl --kubeconfig=$KUBECONFIG -n monitoring port-forward svc/prometheus-grafana 3000:80"
echo "Prometheus: kubectl --kubeconfig=$KUBECONFIG -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo

# Open Grafana in the default browser
echo "Opening Grafana in your browser..."
xdg-open "http://$NODE_IP:$TRAEFIK_PORT/grafana" 2>/dev/null || \
open "http://$NODE_IP:$TRAEFIK_PORT/grafana" 2>/dev/null || \
echo "Please open http://$NODE_IP:$TRAEFIK_PORT/grafana manually"
