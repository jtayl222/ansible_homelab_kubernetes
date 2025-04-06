#!/bin/bash
# filepath: /home/user/ansible_homelab_kubernetes/scripts/verify_060_nfs.sh
#
# NFS Storage Verification Script
# This script verifies all aspects of the NFS storage setup:
# - NFS server status
# - NFS exports
# - NFS client connectivity
# - NFS provisioner functionality
# - PVC creation and binding
# - Pod scheduling and volume mounting
# - ReadWriteMany capabilities
# - File accessibility across nodes

set -e

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
NFS_SERVER="192.168.1.100"  # IP of U850
NFS_PATH="/srv/nfs/kubernetes"
KUBECONFIG="${HOME}/ansible_homelab_kubernetes/fetched_tokens/k3s-kubeconfig"
TEST_NAMESPACE="nfs-test"
TEST_PVC="nfs-test-claim"
TEST_POD="nfs-test-pod"
TEST_POD2="nfs-test-pod2"

# Print header
echo -e "${BLUE}${BOLD}========== NFS Storage Verification ===========${NC}"

# Function to check if command exists
command_exists() {
    type "$1" &> /dev/null
}

# Function to print status
print_status() {
    if [ "$2" = "SUCCESS" ]; then
        echo -e "$1: ${GREEN}$2${NC}"
    elif [ "$2" = "RUNNING" ]; then
        echo -e "$1: ${GREEN}$2${NC}"
    elif [ "$2" = "EXISTS" ]; then
        echo -e "$1: ${GREEN}$2${NC}"
    else
        echo -e "$1: ${RED}$2${NC}"
    fi
}

# Check NFS server status
echo -e "\n${BOLD}1. Checking NFS server status...${NC}"
if ssh ${NFS_SERVER} "systemctl status nfs-server" | grep -q "Active: active"; then
    NFS_STATUS="RUNNING"
else
    NFS_STATUS="NOT RUNNING"
fi
print_status "NFS Server Status" "$NFS_STATUS"

# Check NFS exports
echo -e "\n${BOLD}2. Checking NFS exports...${NC}"
EXPORTS=$(ssh ${NFS_SERVER} "exportfs -v" 2>/dev/null || echo "Failed to get exports")
if [[ "$EXPORTS" == *"$NFS_PATH"* ]]; then
    echo -e "NFS Exports: ${GREEN}CONFIGURED${NC}"
    echo -e "Export details:\n$EXPORTS"
else
    echo -e "NFS Exports: ${RED}NOT CONFIGURED${NC}"
    echo "$EXPORTS"
fi

# Test NFS mount locally on the server
echo -e "\n${BOLD}3. Testing NFS mount locally on the server...${NC}"
ssh ${NFS_SERVER} "mkdir -p /tmp/nfs_test && \
  mount -t nfs localhost:${NFS_PATH} /tmp/nfs_test && \
  echo 'NFS mount test' > /tmp/nfs_test/verify_test.txt && \
  cat /tmp/nfs_test/verify_test.txt && \
  umount /tmp/nfs_test && \
  rm -rf /tmp/nfs_test" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "Local NFS mount test: ${GREEN}SUCCESS${NC}"
else
    echo -e "Local NFS mount test: ${RED}FAILED${NC}"
fi

# Verify NFS StorageClass exists
echo -e "\n${BOLD}4. Checking for NFS StorageClass...${NC}"
if [ ! -f "$KUBECONFIG" ]; then
    echo -e "${RED}Kubeconfig file not found at $KUBECONFIG${NC}"
    exit 1
fi

if kubectl --kubeconfig=$KUBECONFIG get sc nfs-client &>/dev/null; then
    SC_STATUS="EXISTS"
else
    SC_STATUS="NOT FOUND"
fi
print_status "NFS Storage Class" "$SC_STATUS"

# Check NFS provisioner
echo -e "\n${BOLD}5. Checking NFS provisioner deployment...${NC}"
if kubectl --kubeconfig=$KUBECONFIG -n nfs-provisioner get deployment nfs-client-provisioner &>/dev/null; then
    PROV_STATUS=$(kubectl --kubeconfig=$KUBECONFIG -n nfs-provisioner get deployment nfs-client-provisioner -o jsonpath='{.status.availableReplicas}')
    if [ "$PROV_STATUS" -gt 0 ]; then
        PROVISIONER_STATUS="RUNNING"
    else
        PROVISIONER_STATUS="NOT RUNNING"
    fi
else
    PROVISIONER_STATUS="NOT DEPLOYED"
fi
print_status "NFS Provisioner" "$PROVISIONER_STATUS"

# Create test namespace if it doesn't exist
echo -e "\n${BOLD}6. Setting up test environment...${NC}"
if ! kubectl --kubeconfig=$KUBECONFIG get namespace $TEST_NAMESPACE &>/dev/null; then
    kubectl --kubeconfig=$KUBECONFIG create namespace $TEST_NAMESPACE
    echo "Created test namespace: $TEST_NAMESPACE"
else
    echo "Using existing namespace: $TEST_NAMESPACE"
fi

# Create a test PVC
echo -e "\n${BOLD}7. Creating test PVC...${NC}"
cat <<EOF | kubectl --kubeconfig=$KUBECONFIG apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $TEST_PVC
  namespace: $TEST_NAMESPACE
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
  storageClassName: nfs-client
EOF

# Wait for PVC to be bound
echo "Waiting for PVC to be bound..."
for i in {1..10}; do
    PVC_STATUS=$(kubectl --kubeconfig=$KUBECONFIG -n $TEST_NAMESPACE get pvc $TEST_PVC -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")
    if [ "$PVC_STATUS" == "Bound" ]; then
        break
    fi
    echo -n "."
    sleep 3
done
echo ""

if [ "$PVC_STATUS" == "Bound" ]; then
    PVC_STATUS="SUCCESS"
else
    PVC_STATUS="FAILED"
fi
print_status "PVC Creation" "$PVC_STATUS"

# Get the associated PV
PV_NAME=$(kubectl --kubeconfig=$KUBECONFIG get pvc -n $TEST_NAMESPACE $TEST_PVC -o jsonpath='{.spec.volumeName}' 2>/dev/null || echo "No PV found")
echo "Associated PV: $PV_NAME"

# Create a pod that mounts the PVC
echo -e "\n${BOLD}8. Creating test pod with PVC mount...${NC}"
cat <<EOF | kubectl --kubeconfig=$KUBECONFIG apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $TEST_POD
  namespace: $TEST_NAMESPACE
spec:
  containers:
  - name: test-container
    image: busybox
    command: ["/bin/sh", "-c", "echo 'NFS test file content' > /data/test-file.txt && cat /data/test-file.txt && sleep 3600"]
    volumeMounts:
    - name: test-volume
      mountPath: /data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: $TEST_PVC
  restartPolicy: Never
EOF

# Wait for pod to be running
echo "Waiting for pod to start..."
for i in {1..15}; do
    POD_STATUS=$(kubectl --kubeconfig=$KUBECONFIG -n $TEST_NAMESPACE get pod $TEST_POD -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")
    if [ "$POD_STATUS" == "Running" ]; then
        break
    fi
    echo -n "."
    sleep 3
done
echo ""

if [ "$POD_STATUS" == "Running" ]; then
    POD_STATUS="SUCCESS"
else
    POD_STATUS="FAILED"
    echo -e "${YELLOW}Pod is not running. Checking pod details:${NC}"
    kubectl --kubeconfig=$KUBECONFIG -n $TEST_NAMESPACE describe pod $TEST_POD
fi
print_status "Pod Mount" "$POD_STATUS"

# Check if the file exists in the volume
echo -e "\n${BOLD}9. Verifying file was written to NFS volume...${NC}"
sleep 5  # Give it a moment to write the file
if [ "$POD_STATUS" == "SUCCESS" ]; then
    FILE_CONTENT=$(kubectl --kubeconfig=$KUBECONFIG -n $TEST_NAMESPACE exec $TEST_POD -- cat /data/test-file.txt 2>/dev/null || echo "")
    if [ "$FILE_CONTENT" == "NFS test file content" ]; then
        FILE_STATUS="SUCCESS"
    else
        FILE_STATUS="FAILED"
    fi
else
    FILE_STATUS="FAILED"
fi
print_status "File Writing" "$FILE_STATUS"

# Check file on NFS server directly
echo -e "\n${BOLD}10. Verifying file on NFS server...${NC}"
SERVER_FILE=$(ssh ${NFS_SERVER} "find ${NFS_PATH} -name 'test-file.txt' -exec cat {} \; 2>/dev/null" || echo "")
if [ "$SERVER_FILE" == "NFS test file content" ]; then
    echo -e "File on server: ${GREEN}FOUND${NC}"
else
    echo -e "File on server: ${RED}NOT FOUND${NC}"
    echo "Searched in: ${NFS_PATH}"
fi

# Test ReadWriteMany capability with second pod
echo -e "\n${BOLD}11. Testing ReadWriteMany access with second pod...${NC}"
cat <<EOF | kubectl --kubeconfig=$KUBECONFIG apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $TEST_POD2
  namespace: $TEST_NAMESPACE
spec:
  containers:
  - name: test-container
    image: busybox
    command: ["/bin/sh", "-c", "echo 'ReadWriteMany test' >> /data/test-file2.txt && cat /data/test-file.txt && sleep 3600"]
    volumeMounts:
    - name: test-volume
      mountPath: /data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: $TEST_PVC
  restartPolicy: Never
  # Try to schedule on different node if possible
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: name
              operator: In
              values:
              - $TEST_POD
          topologyKey: "kubernetes.io/hostname"
EOF

# Wait for second pod
echo "Waiting for second pod to start..."
for i in {1..10}; do
    POD2_STATUS=$(kubectl --kubeconfig=$KUBECONFIG -n $TEST_NAMESPACE get pod $TEST_POD2 -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")
    if [ "$POD2_STATUS" == "Running" ]; then
        break
    fi
    echo -n "."
    sleep 3
done
echo ""

if [ "$POD2_STATUS" == "Running" ]; then
    # Check if second pod can read the file created by first pod
    SECOND_READ=$(kubectl --kubeconfig=$KUBECONFIG -n $TEST_NAMESPACE exec $TEST_POD2 -- cat /data/test-file.txt 2>/dev/null || echo "")
    if [ "$SECOND_READ" == "NFS test file content" ]; then
        RWX_STATUS="SUCCESS"
    else
        RWX_STATUS="FAILED"
    fi
else
    RWX_STATUS="FAILED"
    echo -e "${YELLOW}Second pod is not running. Checking pod details:${NC}"
    kubectl --kubeconfig=$KUBECONFIG -n $TEST_NAMESPACE describe pod $TEST_POD2
fi
print_status "ReadWriteMany access" "$RWX_STATUS"

# Check if pods are scheduled on different nodes
echo -e "\n${BOLD}12. Checking pod scheduling...${NC}"
if [ "$POD_STATUS" == "SUCCESS" ] && [ "$POD2_STATUS" == "Running" ]; then
    NODE1=$(kubectl --kubeconfig=$KUBECONFIG -n $TEST_NAMESPACE get pod $TEST_POD -o jsonpath='{.spec.nodeName}')
    NODE2=$(kubectl --kubeconfig=$KUBECONFIG -n $TEST_NAMESPACE get pod $TEST_POD2 -o jsonpath='{.spec.nodeName}')
    echo "Pod 1 node: $NODE1"
    echo "Pod 2 node: $NODE2"
    if [ "$NODE1" != "$NODE2" ]; then
        SCHEDULING_STATUS="SUCCESS"
    else
        SCHEDULING_STATUS="SAME NODE"
    fi
else
    SCHEDULING_STATUS="CANNOT DETERMINE"
fi
print_status "Different node scheduling" "$SCHEDULING_STATUS"

# Generate summary
echo -e "\n${BLUE}${BOLD}======== NFS VERIFICATION SUMMARY ========${NC}"
print_status "NFS Server Status" "$NFS_STATUS"
print_status "NFS Storage Class" "$SC_STATUS"
print_status "NFS Provisioner" "$PROVISIONER_STATUS"
print_status "PVC Creation" "$PVC_STATUS"
print_status "Pod Mount" "$POD_STATUS"
print_status "File Writing" "$FILE_STATUS"
print_status "ReadWriteMany access" "$RWX_STATUS"
print_status "Different node scheduling" "$SCHEDULING_STATUS"
echo -e "${BLUE}${BOLD}========================================${NC}"

# Overall result
if [[ "$NFS_STATUS" == "RUNNING" && 
      "$SC_STATUS" == "EXISTS" && 
      "$PROVISIONER_STATUS" == "RUNNING" && 
      "$PVC_STATUS" == "SUCCESS" && 
      "$POD_STATUS" == "SUCCESS" && 
      "$FILE_STATUS" == "SUCCESS" && 
      "$RWX_STATUS" == "SUCCESS" ]]; then
    echo -e "${GREEN}${BOLD}All NFS tests passed successfully!${NC}"
else
    echo -e "${RED}${BOLD}One or more NFS tests failed. See details above.${NC}"
fi

# Optional cleanup
read -p "Do you want to clean up the test resources? (y/n): " CLEANUP
if [[ "$CLEANUP" == "y" || "$CLEANUP" == "Y" ]]; then
    echo "Cleaning up test resources..."
    kubectl --kubeconfig=$KUBECONFIG delete pod -n $TEST_NAMESPACE $TEST_POD $TEST_POD2 --grace-period=0 --force 2>/dev/null || true
    sleep 5  # Wait for pods to terminate
    kubectl --kubeconfig=$KUBECONFIG delete pvc -n $TEST_NAMESPACE $TEST_PVC 2>/dev/null || true
    kubectl --kubeconfig=$KUBECONFIG delete namespace $TEST_NAMESPACE 2>/dev/null || true
    echo "Cleanup completed."
fi

echo -e "\n${BLUE}${BOLD}NFS verification completed.${NC}"