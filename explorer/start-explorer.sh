#!/bin/bash
#
# start-explorer.sh - Start Hyperledger Explorer
# Provides GUI visualization for both HOT and COLD blockchain networks
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Hyperledger Explorer Startup${NC}"
echo -e "${BLUE}  Chain of Custody Network Monitor${NC}"
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

# Check if HOT blockchain is running
if ! docker ps | grep -q "peer0.laborg.hot.coc.com"; then
    print_error "HOT blockchain network is not running"
    print_info "Start it with: cd ../hot-blockchain && ./scripts/start-network.sh"
    exit 1
fi
print_success "HOT blockchain network is running"

# Check if COLD blockchain is running
if ! docker ps | grep -q "peer0.laborg.cold.coc.com"; then
    print_error "COLD blockchain network is not running"
    print_info "Start it with: cd ../cold-blockchain && ./scripts/start-network.sh"
    exit 1
fi
print_success "COLD blockchain network is running"

# Check if crypto materials exist
print_section "Checking crypto materials"

HOT_CRYPTO="../hot-blockchain/crypto-config"
COLD_CRYPTO="../cold-blockchain/crypto-config"

if [[ ! -d "$HOT_CRYPTO/peerOrganizations" ]]; then
    print_error "HOT blockchain crypto materials not found"
    print_info "Generate them with: cd ../hot-blockchain && ./scripts/generate-crypto.sh"
    exit 1
fi
print_success "HOT blockchain crypto materials found"

if [[ ! -d "$COLD_CRYPTO/peerOrganizations" ]]; then
    print_error "COLD blockchain crypto materials not found"
    print_info "Generate them with: cd ../cold-blockchain && ./scripts/generate-crypto.sh"
    exit 1
fi
print_success "COLD blockchain crypto materials found"

# Check if channels are created
print_section "Checking channels"

# Test HOT chain channel
if docker exec peer0.laborg.hot.coc.com peer channel list 2>/dev/null | grep -q "hot-chain"; then
    print_success "HOT chain channel (hot-chain) exists"
else
    print_error "HOT chain channel (hot-chain) not found"
    print_info "Create it with: cd ../hot-blockchain && ./scripts/create-channel.sh"
    exit 1
fi

# Test COLD chain channel
if docker exec peer0.laborg.cold.coc.com peer channel list 2>/dev/null | grep -q "cold-chain"; then
    print_success "COLD chain channel (cold-chain) exists"
else
    print_error "COLD chain channel (cold-chain) not found"
    print_info "Create it with: cd ../cold-blockchain && ./scripts/create-channel.sh"
    exit 1
fi

# Stop any existing Explorer containers
print_section "Stopping any existing Explorer containers"
cd "${SCRIPT_DIR}"
docker-compose -f docker-compose-explorer.yaml down 2>/dev/null || true
print_success "Cleaned up existing containers"

# Start Explorer
print_section "Starting Hyperledger Explorer"
docker-compose -f docker-compose-explorer.yaml up -d

# Wait for containers to be healthy
print_info "Waiting for PostgreSQL to be ready..."
sleep 10

# Check PostgreSQL health
POSTGRES_HEALTHY=false
for i in {1..30}; do
    if docker exec postgres-explorer.coc pg_isready -U explorer -d fabricexplorer &>/dev/null; then
        POSTGRES_HEALTHY=true
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

if [[ "$POSTGRES_HEALTHY" == "true" ]]; then
    print_success "PostgreSQL is ready"
else
    print_error "PostgreSQL failed to start"
    docker logs postgres-explorer.coc
    exit 1
fi

print_info "Waiting for Explorer to initialize..."
sleep 20

# Check Explorer status
print_section "Checking Explorer status"

if docker ps | grep -q "explorer.coc"; then
    print_success "Explorer container is running"
else
    print_error "Explorer container is not running"
    docker logs explorer.coc
    exit 1
fi

# Test Explorer UI
EXPLORER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8090 2>/dev/null || echo "000")
if [[ "$EXPLORER_STATUS" == "200" ]]; then
    print_success "Explorer UI is accessible"
else
    print_info "Explorer UI status code: ${EXPLORER_STATUS} (may still be initializing)"
fi

# Display network information
print_section "Network information discovered by Explorer"

# Wait for Explorer to sync initial blocks
print_info "Waiting for Explorer to sync blockchain data..."
sleep 15

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Hyperledger Explorer Started!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Explorer UI:${NC}"
echo "  URL:        http://localhost:8090"
echo "  Status:     $(if [[ "$EXPLORER_STATUS" == "200" ]]; then echo -e "${GREEN}READY${NC}"; else echo -e "${YELLOW}Initializing...${NC}"; fi)"
echo ""
echo -e "${BLUE}Monitored Networks:${NC}"
echo "  HOT Chain:  hot-chain (peer0.laborg.hot.coc.com)"
echo "  COLD Chain: cold-chain (peer0.laborg.cold.coc.com, peer0.courtorg.cold.coc.com)"
echo ""
echo -e "${BLUE}Organizations:${NC}"
echo "  - OrdererOrg (OrdererOrgMSP)"
echo "  - LabOrg (LabOrgMSP)"
echo "  - CourtOrg (CourtOrgMSP)"
echo ""
echo -e "${BLUE}Database:${NC}"
echo "  PostgreSQL: postgres-explorer.coc:5432 (fabricexplorer)"
echo ""
echo -e "${BLUE}Containers running:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "explorer|postgres-explorer"
echo ""
echo -e "${YELLOW}What Explorer shows:${NC}"
echo "  ✓ Blocks on both chains (hot-chain, cold-chain)"
echo "  ✓ Transactions (evidence records, investigations, GUID mappings)"
echo "  ✓ Chaincode (hot_chaincode, cold_chaincode)"
echo "  ✓ Organizations (LabOrg, CourtOrg, OrdererOrg)"
echo "  ✓ Peers (peer0.laborg hot/cold, peer0.courtorg cold)"
echo "  ✓ Network topology and TLS configuration"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Open browser: http://localhost:8090"
echo "  2. Select 'hot-chain' or 'cold-chain' channel"
echo "  3. View blocks, transactions, and chaincodes"
echo "  4. Monitor evidence uploads in real-time"
echo "  5. View logs: docker logs -f explorer.coc"
echo "  6. Stop Explorer: ./stop-explorer.sh"
echo ""
echo -e "${GREEN}Explorer is now monitoring your Chain of Custody network!${NC}"
echo ""
