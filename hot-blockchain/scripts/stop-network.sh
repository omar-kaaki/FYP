#!/bin/bash
#
# stop-network.sh - Stop HOT blockchain network
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
echo -e "${BLUE}  HOT Blockchain Network Shutdown${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Stop network
cd "${BASE_DIR}"
print_info "Stopping HOT blockchain network..."

# Stop containers
docker-compose -f docker-compose-network.yaml down

print_success "Network stopped"

# Option to remove volumes
read -p "Remove data volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose -f docker-compose-network.yaml down -v
    print_success "Data volumes removed"
fi

echo ""
echo -e "${GREEN}HOT blockchain network shutdown complete${NC}"
echo ""
