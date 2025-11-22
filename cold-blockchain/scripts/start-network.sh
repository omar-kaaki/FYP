#!/bin/bash
#
# start-network.sh - Start COLD blockchain network
# Hyperledger Fabric v2.5.14 - Archival Chain
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
echo -e "${BLUE}  COLD Blockchain Network Startup${NC}"
echo -e "${BLUE}  Archival Chain${NC}"
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
print_section "Starting COLD blockchain network"
docker-compose -f docker-compose-network.yaml up -d

# Wait for containers to be healthy
print_info "Waiting for containers to start..."
sleep 10

# Check container status
print_section "Checking container status"

CONTAINERS=(
    "orderer.cold.coc.com"
    "peer0.laborg.cold.coc.com"
    "peer0.courtorg.cold.coc.com"
    "couchdb.peer0.laborg.cold.coc.com"
    "couchdb.peer0.courtorg.cold.coc.com"
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
docker exec cli.cold peer channel list \
    -o orderer.cold.coc.com:7150 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ordererorg.cold.coc.com/tlsca/tlsca.ordererorg.cold.coc.com-cert.pem 2>&1 | grep -q "Channels peers has joined"

if [[ $? -eq 0 ]]; then
    print_success "Orderer is accessible"
else
    print_info "Orderer is accessible (no channels joined yet)"
fi

# Create channel (if not already created)
print_section "Creating channel"
if docker exec cli.cold test -f /tmp/cold-chain-created.flag 2>/dev/null; then
    print_info "Channel already created, skipping"
else
    bash "${SCRIPT_DIR}/create-channel.sh"
    docker exec cli.cold touch /tmp/cold-chain-created.flag
fi

# Check network health
print_section "Network health check"

# Check LabOrg peer health
LABORG_PEER_HEALTH=$(curl -s http://localhost:9543/healthz | jq -r '.status' 2>/dev/null || echo "unknown")
if [[ "$LABORG_PEER_HEALTH" == "OK" ]]; then
    print_success "LabOrg peer health check: OK"
else
    print_info "LabOrg peer health check: ${LABORG_PEER_HEALTH}"
fi

# Check CourtOrg peer health
COURTORG_PEER_HEALTH=$(curl -s http://localhost:9643/healthz | jq -r '.status' 2>/dev/null || echo "unknown")
if [[ "$COURTORG_PEER_HEALTH" == "OK" ]]; then
    print_success "CourtOrg peer health check: OK"
else
    print_info "CourtOrg peer health check: ${COURTORG_PEER_HEALTH}"
fi

# Check CouchDB instances
LABORG_COUCHDB_HEALTH=$(curl -s http://admin:adminpw@localhost:6984/_up | jq -r '.status' 2>/dev/null || echo "unknown")
if [[ "$LABORG_COUCHDB_HEALTH" == "ok" ]]; then
    print_success "LabOrg CouchDB health check: OK"
else
    print_info "LabOrg CouchDB health check: ${LABORG_COUCHDB_HEALTH}"
fi

COURTORG_COUCHDB_HEALTH=$(curl -s http://admin:adminpw@localhost:7984/_up | jq -r '.status' 2>/dev/null || echo "unknown")
if [[ "$COURTORG_COUCHDB_HEALTH" == "ok" ]]; then
    print_success "CourtOrg CouchDB health check: OK"
else
    print_info "CourtOrg CouchDB health check: ${COURTORG_COUCHDB_HEALTH}"
fi

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  COLD Blockchain Network Started!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Network endpoints:${NC}"
echo "  Orderer:           localhost:7150"
echo "  Peer0 (LabOrg):    localhost:8051"
echo "  Peer0 (CourtOrg):  localhost:9051"
echo "  CouchDB (LabOrg):  localhost:6984"
echo "  CouchDB (CourtOrg): localhost:7984"
echo "  Operations (Lab):  localhost:9543"
echo "  Operations (Court): localhost:9643"
echo ""
echo -e "${BLUE}Containers running:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep cold
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Deploy chaincode: ./scripts/deploy-chaincode.sh"
echo "  2. View LabOrg logs: docker logs -f peer0.laborg.cold.coc.com"
echo "  3. View CourtOrg logs: docker logs -f peer0.courtorg.cold.coc.com"
echo "  4. Stop network: ./scripts/stop-network.sh"
echo ""
