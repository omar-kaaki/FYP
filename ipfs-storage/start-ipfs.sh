#!/bin/bash
#
# start-ipfs.sh - Start IPFS storage infrastructure
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
echo -e "${BLUE}  IPFS Storage Infrastructure Startup${NC}"
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

# Check if Fabric networks are running
if ! docker ps | grep -q "peer0.laborg.hot.coc.com"; then
    print_error "HOT blockchain network is not running"
    print_info "Start it with: cd ../hot-blockchain && ./scripts/start-network.sh"
    exit 1
fi
print_success "HOT blockchain network is running"

if ! docker ps | grep -q "peer0.laborg.cold.coc.com"; then
    print_error "COLD blockchain network is not running"
    print_info "Start it with: cd ../cold-blockchain && ./scripts/start-network.sh"
    exit 1
fi
print_success "COLD blockchain network is running"

# Generate SSL certificates if not present
print_section "Checking SSL certificates"
if [[ ! -f "${SCRIPT_DIR}/nginx/ssl/server.crt" ]]; then
    print_info "Generating SSL certificates..."
    cd "${SCRIPT_DIR}/nginx"
    bash generate-ssl.sh
else
    print_success "SSL certificates found"
fi

# Create uploads directory
mkdir -p "${SCRIPT_DIR}/uploads"

# Stop any existing IPFS infrastructure
print_section "Stopping any existing IPFS infrastructure"
cd "${SCRIPT_DIR}"
docker-compose -f docker-compose-ipfs.yaml down 2>/dev/null || true
print_success "Cleaned up existing containers"

# Start IPFS infrastructure
print_section "Starting IPFS infrastructure"
docker-compose -f docker-compose-ipfs.yaml up -d

# Wait for containers to be healthy
print_info "Waiting for containers to start..."
sleep 10

# Check container status
print_section "Checking container status"

CONTAINERS=(
    "ipfs.coc"
    "ipfs-proxy.coc"
    "evidence-upload.coc"
)

for container in "${CONTAINERS[@]}"; do
    if docker ps | grep -q "$container"; then
        print_success "$container is running"
    else
        print_error "$container is not running"
        docker logs "$container" 2>&1 | tail -20
        exit 1
    fi
done

# Test IPFS connectivity
print_section "Testing IPFS connectivity"

# Test IPFS API
IPFS_VERSION=$(curl -s -X POST http://localhost:5001/api/v0/version | jq -r '.Version' 2>/dev/null || echo "unknown")
if [[ "$IPFS_VERSION" != "unknown" ]]; then
    print_success "IPFS API is accessible (version: ${IPFS_VERSION})"
else
    print_error "IPFS API is not accessible"
fi

# Test IPFS Gateway
IPFS_GATEWAY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ipfs/QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn 2>/dev/null || echo "000")
if [[ "$IPFS_GATEWAY_STATUS" == "200" ]]; then
    print_success "IPFS Gateway is accessible"
else
    print_info "IPFS Gateway status: ${IPFS_GATEWAY_STATUS}"
fi

# Test Evidence Upload Service
print_section "Testing Evidence Upload Service"
UPLOAD_SERVICE_HEALTH=$(curl -s http://localhost:3000/health | jq -r '.status' 2>/dev/null || echo "unknown")
if [[ "$UPLOAD_SERVICE_HEALTH" == "healthy" ]]; then
    print_success "Evidence Upload Service is healthy"
else
    print_error "Evidence Upload Service is not healthy"
    docker logs evidence-upload.coc 2>&1 | tail -20
fi

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  IPFS Infrastructure Started!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Service endpoints:${NC}"
echo "  IPFS API:             http://localhost:5001"
echo "  IPFS API (HTTPS):     https://localhost:5443"
echo "  IPFS Gateway:         http://localhost:8080"
echo "  IPFS Gateway (HTTPS): https://localhost:8443"
echo "  Evidence Upload:      http://localhost:3000"
echo ""
echo -e "${BLUE}API Documentation:${NC}"
echo "  Health Check:  GET  http://localhost:3000/health"
echo "  Upload File:   POST http://localhost:3000/api/evidence/upload"
echo "  Get Evidence:  GET  http://localhost:3000/api/evidence/:evidenceId?chain=hot"
echo "  Get File:      GET  http://localhost:3000/api/evidence/:evidenceId/file?chain=hot"
echo ""
echo -e "${BLUE}Containers running:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "ipfs|evidence"
echo ""
echo -e "${YELLOW}Test upload example:${NC}"
echo "  curl -X POST http://localhost:3000/api/evidence/upload \\"
echo "    -F 'file=@test.jpg' \\"
echo "    -F 'investigationId=inv-123' \\"
echo "    -F 'description=Test evidence' \\"
echo "    -F 'userId=investigator1' \\"
echo "    -F 'userRole=BlockchainInvestigator' \\"
echo "    -F 'chain=hot'"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. View logs: docker logs -f evidence-upload.coc"
echo "  2. Stop IPFS: ./stop-ipfs.sh"
echo ""
