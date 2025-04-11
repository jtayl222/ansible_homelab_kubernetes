#!/bin/bash
# Deep debug of Grafana configuration and Traefik routing

NODE_IP="192.168.1.85"
PORT="31722"
KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"
NAMESPACE="monitoring"
GRAFANA_RELEASE="grafana"

echo "=== DETAILED GRAFANA TROUBLESHOOTING ==="
echo "----------------------------------------"

echo "1. Testing direct access to Grafana service (bypassing Traefik):"
# Get Grafana service details
GRAFANA_SVC_PORT=$(kubectl --kubeconfig=$KUBECONFIG get svc -n $NAMESPACE $GRAFANA_RELEASE -o jsonpath='{.spec.ports[0].port}')
GRAFANA_SVC_TYPE=$(kubectl --kubeconfig=$KUBECONFIG get svc -n $NAMESPACE $GRAFANA_RELEASE -o jsonpath='{.spec.type}')

echo "   Grafana service: $GRAFANA_RELEASE (type: $GRAFANA_SVC_TYPE, port: $GRAFANA_SVC_PORT)"

# If ClusterIP, set up port-forward to test direct access
if [[ "$GRAFANA_SVC_TYPE" == "ClusterIP" ]]; then
  echo "   Setting up port-forward to test Grafana directly..."
  kubectl --kubeconfig=$KUBECONFIG port-forward -n $NAMESPACE svc/$GRAFANA_RELEASE 3000:$GRAFANA_SVC_PORT &
  PORT_FORWARD_PID=$!
  sleep 5

  echo "   Testing direct Grafana response on localhost:3000:"
  curl -s -I http://localhost:3000 | grep -E "(^HTTP|^Location)"

  # Kill port-forward
  kill $PORT_FORWARD_PID
  wait $PORT_FORWARD_PID 2>/dev/null
fi

echo
echo "2. Current Traefik and Ingress configuration:"
echo "   Middleware definitions:"
kubectl --kubeconfig=$KUBECONFIG get middleware -A -o wide

echo
echo "   Ingress definitions:"
kubectl --kubeconfig=$KUBECONFIG get ingress -A

echo
echo "   IngressRoute definitions:"
kubectl --kubeconfig=$KUBECONFIG get ingressroute -A

echo
echo "3. Grafana configuration details:"
echo "   ConfigMaps in $NAMESPACE namespace:"
kubectl --kubeconfig=$KUBECONFIG get cm -n $NAMESPACE

# If we can find grafana config maps, show their content
GRAFANA_CM=$(kubectl --kubeconfig=$KUBECONFIG get cm -n $NAMESPACE | grep -E "grafana.*config|grafana-ini" | head -1 | awk '{print $1}')
if [ -n "$GRAFANA_CM" ]; then
  echo
  echo "   Content of $GRAFANA_CM:"
  kubectl --kubeconfig=$KUBECONFIG get cm -n $NAMESPACE $GRAFANA_CM -o yaml | grep -A20 "grafana.ini"
fi

echo
echo "4. Testing Traefik routing rules:"
echo "   Testing /grafana endpoint:"
curl -s -I -v "http://$NODE_IP:$PORT/grafana" 2>&1 | grep -E "(^> GET|^< HTTP|^< Location|Host:|^* Connected to)"

echo
echo "   Testing /grafana/ endpoint (with trailing slash):"
curl -s -I -v "http://$NODE_IP:$PORT/grafana/" 2>&1 | grep -E "(^> GET|^< HTTP|^< Location|Host:|^* Connected to)"

echo
echo "5. Grafana pod details:"
GRAFANA_POD=$(kubectl --kubeconfig=$KUBECONFIG get pods -n $NAMESPACE | grep grafana | grep Running | head -1 | awk '{print $1}')
if [ -n "$GRAFANA_POD" ]; then
  echo "   Grafana pod $GRAFANA_POD environment variables:"
  kubectl --kubeconfig=$KUBECONFIG exec -n $NAMESPACE $GRAFANA_POD -- env | grep -E "GF_SERVER|HOSTNAME|PATH"

  echo
  echo "   Checking if grafana.ini exists in pod:"
  kubectl --kubeconfig=$KUBECONFIG exec -n $NAMESPACE $GRAFANA_POD -- ls -la /etc/grafana/
fi

echo
echo "=== TROUBLESHOOTING COMPLETE ==="
echo "Check the output above for clues about Grafana configuration and routing issues."
