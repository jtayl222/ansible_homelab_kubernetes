#!/bin/bash

NODE_IP="192.168.1.85"
PORT="31605"
DASHBOARD_HOST="traefik.192.168.1.85.nip.io"
TEST_APP_HOST="test-app.192.168.1.85.nip.io"

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===============================================${NC}"
echo -e "${YELLOW}     Traefik Verification Test Suite${NC}"
echo -e "${YELLOW}===============================================${NC}"
echo

# Test 1: Check if Traefik is accessible
echo -e "Test 1: Checking if Traefik is accessible..."
if curl -s -o /dev/null -w "%{http_code}" "http://$NODE_IP:$PORT" | grep -q "2[0-9][0-9]\|404"; then
  echo -e "${GREEN}✓ Traefik is accessible at http://$NODE_IP:$PORT${NC}"
else
  echo -e "${RED}✗ Traefik is not accessible at http://$NODE_IP:$PORT${NC}"
fi
echo

# Test 2: Check Dashboard access
echo -e "Test 2: Checking Traefik dashboard..."
DASHBOARD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $DASHBOARD_HOST" "http://$NODE_IP:$PORT/dashboard/")
if [ "$DASHBOARD_STATUS" == "200" ]; then
  echo -e "${GREEN}✓ Traefik dashboard is accessible at http://$DASHBOARD_HOST:$PORT/dashboard/${NC}"
else
  echo -e "${RED}✗ Traefik dashboard returned HTTP $DASHBOARD_STATUS - not accessible${NC}"
  echo -e "  Try accessing: http://$DASHBOARD_HOST:$PORT/dashboard/"
fi
echo

# Test 3: Check metrics endpoint
echo -e "Test 3: Checking Prometheus metrics endpoint..."
METRICS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$NODE_IP:$PORT/metrics")
if [ "$METRICS_STATUS" == "200" ]; then
  echo -e "${GREEN}✓ Prometheus metrics endpoint is accessible${NC}"
else
  echo -e "${RED}✗ Prometheus metrics endpoint returned HTTP $METRICS_STATUS - not accessible${NC}"
fi
echo

# Test 4: Check test application routing
echo -e "Test 4: Checking routing to test application..."
TEST_APP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $TEST_APP_HOST" "http://$NODE_IP:$PORT/")
if [ "$TEST_APP_STATUS" == "200" ]; then
  echo -e "${GREEN}✓ Test application is accessible via Traefik${NC}"
  echo -e "  Access URL: http://$TEST_APP_HOST:$PORT/"
else
  echo -e "${RED}✗ Test application returned HTTP $TEST_APP_STATUS - routing may not be working${NC}"
fi
echo

# Test 5: Check Traefik API routing
echo -e "Test 5: Checking Traefik API access..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $DASHBOARD_HOST" "http://$NODE_IP:$PORT/api/version")
if [ "$API_STATUS" == "200" ]; then
  echo -e "${GREEN}✓ Traefik API is accessible${NC}"
  echo -e "  API version: $(curl -s -H "Host: $DASHBOARD_HOST" "http://$NODE_IP:$PORT/api/version" | sed 's/{"Version":"\(.*\)"}/\1/')"
else
  echo -e "${RED}✗ Traefik API returned HTTP $API_STATUS - not accessible${NC}"
fi
echo

# Summary
echo -e "${YELLOW}===============================================${NC}"
echo -e "${YELLOW}     Traefik Verification Summary${NC}"
echo -e "${YELLOW}===============================================${NC}"
echo
echo -e "Traefik Service: http://$NODE_IP:$PORT"
echo -e "Dashboard URL: http://$DASHBOARD_HOST:$PORT/dashboard/"
echo -e "Test App URL: http://$TEST_APP_HOST:$PORT/"
echo -e "API URL: http://$DASHBOARD_HOST:$PORT/api/"
echo
echo -e "${YELLOW}Note:${NC} If using nip.io hostnames, make sure your network can resolve them."
echo -e "${YELLOW}Tip:${NC} You can add entries to /etc/hosts for local testing if needed."
echo
