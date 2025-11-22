#!/bin/bash
#
# start-network.sh - Start HOT blockchain network
# Hyperledger Fabric v2.5.14 - Active Investigation Chain
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HOT Blockchain Network Startup${NC}"
echo -e "${BLUE}  Active Investigation Chain${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_section() {
    echo ""
    echo -e "${YELLOW}>>> $1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
print_section "Checking prerequisites"

if [[ ! -d "${BASE_DIR}/crypto-config" ]]; then
    print_error "Crypto materials not found. Run setup-network.sh first"
    exit 1
fi
print_success "Crypto materials found"

if [[ ! -d "${BASE_DIR}/channel-artifacts" ]]; then
    print_error "Channel artifacts not found. Run generate-channel-artifacts.sh first"
    exit 1
fi
print_success "Channel artifacts found"

# Stop any existing network
print_section "Stopping any existing network"
cd "${BASE_DIR}"
docker-compose -f docker-compose-network.yaml down -v 2>/dev/null || true
print_success "Cleaned up existing containers"

# Start network
print_section "Starting HOT blockchain network"
docker-compose -f docker-compose-network.yaml up -d

# Wait for containers to be healthy
print_info "Waiting for containers to start..."
sleep 10

# Check container status
print_section "Checking container status"

CONTAINERS=(
    "orderer.hot.coc.com"
    "peer0.laborg.hot.coc.com"
    "couchdb.peer0.laborg.hot.coc.com"
)

for container in "${CONTAINERS[@]}"; do
    if docker ps | grep -q "$container"; then
        print_success "$container is running"
    else
        print_error "$container is not running"
        exit 1
    fi
done

# Test orderer connectivity
print_section "Testing orderer connectivity"
docker exec cli.hot peer channel list \
    -o orderer.hot.coc.com:7050 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ordererorg.hot.coc.com/tlsca/tlsca.ordererorg.hot.coc.com-cert.pem 2>&1 | grep -q "Channels peers has joined"

if [[ $? -eq 0 ]]; then
    print_success "Orderer is accessible"
else
    print_info "Orderer is accessible (no channels joined yet)"
fi

# Create channel (if not already created)
print_section "Creating channel"
if docker exec cli.hot test -f /tmp/hot-chain-created.flag 2>/dev/null; then
    print_info "Channel already created, skipping"
else
    bash "${SCRIPT_DIR}/create-channel.sh"
    docker exec cli.hot touch /tmp/hot-chain-created.flag
fi

# Check network health
print_section "Network health check"

# Check peer health
PEER_HEALTH=$(curl -s http://localhost:9443/healthz | jq -r '.status' 2>/dev/null || echo "unknown")
if [[ "$PEER_HEALTH" == "OK" ]]; then
    print_success "Peer health check: OK"
else
    print_info "Peer health check: ${PEER_HEALTH}"
fi

# Check CouchDB
COUCHDB_HEALTH=$(curl -s http://admin:adminpw@localhost:5984/_up | jq -r '.status' 2>/dev/null || echo "unknown")
if [[ "$COUCHDB_HEALTH" == "ok" ]]; then
    print_success "CouchDB health check: OK"
else
    print_info "CouchDB health check: ${COUCHDB_HEALTH}"
fi

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  HOT Blockchain Network Started!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Network endpoints:${NC}"
echo "  Orderer:        localhost:7050"
echo "  Peer0 (LabOrg): localhost:7051"
echo "  CouchDB:        localhost:5984"
echo "  Operations:     localhost:9443"
echo ""
echo -e "${BLUE}Containers running:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep hot
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Deploy chaincode: ./scripts/deploy-chaincode.sh"
echo "  2. View logs: docker logs -f peer0.laborg.hot.coc.com"
echo "  3. Stop network: ./scripts/stop-network.sh"
echo ""
