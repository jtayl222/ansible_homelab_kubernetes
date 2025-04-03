#!/bin/bash
# Complete rebuild of Grafana ingress configuration

KUBECONFIG="/home/user/ansible_homelab_kubernetes/standalone_control_plane/fetched_tokens/k3s-kubeconfig"
NAMESPACE="monitoring"
GRAFANA="grafana"
NODE_IP="192.168.1.85"

# Get Traefik port
PORT=$(kubectl --kubeconfig=$KUBECONFIG get svc -n kube-system traefik -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}')

echo "=== REBUILDING GRAFANA INGRESS CONFIGURATION ==="
echo "Using node IP: $NODE_IP and port: $PORT"

# 1. Remove any existing ingress configurations
echo "1. Removing existing ingress configurations..."
kubectl --kubeconfig=$KUBECONFIG delete ingressroute -n $NAMESPACE --all
kubectl --kubeconfig=$KUBECONFIG delete middleware -n $NAMESPACE --all
kubectl --kubeconfig=$KUBECONFIG delete ingress -n $NAMESPACE --all

# 2. Create a fresh middleware configuration
echo "2. Creating fresh middleware for path handling..."
cat <<EOF | kubectl --kubeconfig=$KUBECONFIG apply -f -
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: grafana-strip
  namespace: $NAMESPACE
spec:
  stripPrefix:
    prefixes:
      - /grafana
EOF

# 3. Create a simple IngressRoute
echo "3. Creating simple IngressRoute..."
cat <<EOF | kubectl --kubeconfig=$KUBECONFIG apply -f -
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: grafana-route
  namespace: $NAMESPACE
spec:
  entryPoints:
    - web
  routes:
    - match: PathPrefix(\`/grafana\`) || PathPrefix(\`/grafana/\`)
      kind: Rule
      middlewares:
        - name: grafana-strip
      services:
        - name: $GRAFANA
          port: 80
EOF

# 4. Create a ConfigMap for Grafana configuration
echo "4. Creating ConfigMap for Grafana configuration..."
cat <<EOF | kubectl --kubeconfig=$KUBECONFIG apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-config-custom
  namespace: $NAMESPACE
data:
  grafana.ini: |
    [server]
    root_url = http://$NODE_IP:$PORT/grafana
    serve_from_sub_path = true
EOF

# 5. Patching Grafana deployment to use our ConfigMap
echo "5. Patching Grafana deployment..."

# First check if volume already exists
VOLUMES=$(kubectl --kubeconfig=$KUBECONFIG get deployment -n $NAMESPACE $GRAFANA -o json | \
          jq '.spec.template.spec.volumes[] | select(.name=="config-custom")' | wc -l)

if [ "$VOLUMES" -eq "0" ]; then
  echo "   Adding config volume to deployment..."
  kubectl --kubeconfig=$KUBECONFIG patch deployment $GRAFANA -n $NAMESPACE --type=json -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/volumes/-",
      "value": {
        "name": "config-custom",
        "configMap": {
          "name": "grafana-config-custom"
        }
      }
    }
  ]'
fi

# Now check if mount already exists
MOUNTS=$(kubectl --kubeconfig=$KUBECONFIG get deployment -n $NAMESPACE $GRAFANA -o json | \
         jq '.spec.template.spec.containers[0].volumeMounts[] | select(.name=="config-custom")' | wc -l)

if [ "$MOUNTS" -eq "0" ]; then
  echo "   Adding config mount to container..."
  kubectl --kubeconfig=$KUBECONFIG patch deployment $GRAFANA -n $NAMESPACE --type=json -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/volumeMounts/-",
      "value": {
        "name": "config-custom",
        "mountPath": "/etc/grafana/grafana.ini",
        "subPath": "grafana.ini"
      }
    }
  ]'
fi

# 6. Restart the deployment
echo "6. Restarting Grafana deployment..."
kubectl --kubeconfig=$KUBECONFIG rollout restart deployment $GRAFANA -n $NAMESPACE

# 7. Wait for deployment to be ready
echo "7. Waiting for deployment to be ready..."
kubectl --kubeconfig=$KUBECONFIG rollout status deployment $GRAFANA -n $NAMESPACE

echo
echo "Configuration rebuilt! Waiting 10 seconds for changes to take effect..."
sleep 10

# 8. Test access
echo "8. Testing access to Grafana..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$NODE_IP:$PORT/grafana/")
echo "HTTP Status Code: $HTTP_CODE"

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "✅ SUCCESS! Grafana is now accessible at http://$NODE_IP:$PORT/grafana/"
else
  echo "❌ Still having issues. HTTP code: $HTTP_CODE"
  echo "Run deep debugging: ./scripts/deep_debug_grafana.sh"
fi