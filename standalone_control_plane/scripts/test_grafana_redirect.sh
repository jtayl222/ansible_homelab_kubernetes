#!/bin/bash
# Enhanced test script that handles redirects

NODE_IP="192.168.1.85"
PORT="31722"

echo "Testing Grafana access with redirect handling..."
echo "-------------------------------------------------"

# Test with explicit trailing slash (should work directly)
echo "Testing /grafana/ (with trailing slash):"
RESP_CODE=$(curl -s -L -o /dev/null -w "%{http_code}" "http://$NODE_IP:$PORT/grafana/")
if [[ "$RESP_CODE" == "200" ]]; then
  echo "✅ /grafana/ path works: HTTP $RESP_CODE"
else
  echo "❌ /grafana/ path returned: HTTP $RESP_CODE"
fi

# Test without trailing slash (should redirect)
echo
echo "Testing /grafana (without trailing slash):"
REDIRECT=$(curl -s -I "http://$NODE_IP:$PORT/grafana" | grep -i location)
RESP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$NODE_IP:$PORT/grafana")

if [[ "$RESP_CODE" == "301" ]] && [[ "$REDIRECT" == *"/grafana/"* ]]; then
  echo "✅ /grafana correctly redirects to /grafana/ (HTTP $RESP_CODE)"
  echo "   $REDIRECT"
else
  echo "❌ /grafana redirect not working properly: HTTP $RESP_CODE"
fi

# Test with redirect following
echo
echo "Following redirects from /grafana to final destination:"
FINAL_CODE=$(curl -s -L -o /dev/null -w "%{http_code}" "http://$NODE_IP:$PORT/grafana")
if [[ "$FINAL_CODE" == "200" ]]; then
  echo "✅ Final destination works after redirects: HTTP $FINAL_CODE"
else
  echo "❌ Redirect chain not working: HTTP $FINAL_CODE" 
fi

echo
echo "For manual testing, open: http://$NODE_IP:$PORT/grafana/"
