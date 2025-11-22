#!/bin/bash
#
# stop-ipfs.sh - Stop IPFS storage infrastructure
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
echo -e "${BLUE}  IPFS Infrastructure Shutdown${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Stop IPFS infrastructure
cd "${SCRIPT_DIR}"
print_info "Stopping IPFS infrastructure..."

# Stop containers
docker-compose -f docker-compose-ipfs.yaml down

print_success "IPFS infrastructure stopped"

# Option to remove volumes
read -p "Remove IPFS data volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose -f docker-compose-ipfs.yaml down -v
    print_success "IPFS data volumes removed"
fi

echo ""
echo -e "${GREEN}IPFS infrastructure shutdown complete${NC}"
echo ""
