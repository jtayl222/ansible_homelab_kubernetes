#!/bin/bash
NODE_IP="192.168.1.85"
PORT="30235"

clear
echo "==============================================="
echo "      Traefik Dashboard Access Checker"
echo "==============================================="
echo
echo "Testing direct access to Traefik API..."

# Test direct API access
RESULT=$(curl -s -u admin:admin http://$NODE_IP:$PORT/api/version)
if [[ "$RESULT" == *"Version"* ]]; then
  echo "✅ API is accessible!"
  VERSION=$(echo $RESULT | sed 's/.*"Version":"\([^"]*\)".*/\1/')
  echo "   Traefik version: $VERSION"
else
  echo "❌ API access failed!"
fi

echo
echo "Testing dashboard access with Host header..."
DASH=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: traefik.$NODE_IP.nip.io" http://$NODE_IP:$PORT/dashboard/)
echo "Dashboard access HTTP status code: $DASH"

echo
echo "Options to access the dashboard:"
echo "----------------------------------------------"
echo "1. Browser with Host header: http://$NODE_IP:$PORT/dashboard/"
echo "   (Set Host header to: traefik.$NODE_IP.nip.io)"
echo
echo "2. Using nip.io: http://traefik.$NODE_IP.nip.io:$PORT/dashboard/"
echo
echo "3. Direct port-forward: Run ./scripts/traefik-dashboard.sh"
echo "   Then access: http://localhost:9000/dashboard/"
echo
echo "4. If all else fails, try accessing the API directly:"
echo "   curl -u admin:admin http://$NODE_IP:$PORT/api/version"
echo "==============================================="
