#!/bin/bash
#
# stop-explorer.sh - Stop Hyperledger Explorer
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
echo -e "${BLUE}  Hyperledger Explorer Shutdown${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Stop Explorer
cd "${SCRIPT_DIR}"
print_info "Stopping Hyperledger Explorer..."

# Stop containers
docker-compose -f docker-compose-explorer.yaml down

print_success "Explorer stopped"

# Option to remove volumes
read -p "Remove Explorer database volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose -f docker-compose-explorer.yaml down -v
    print_success "Explorer database volumes removed"
    print_info "Next start will sync blockchain from genesis"
fi

echo ""
echo -e "${GREEN}Hyperledger Explorer shutdown complete${NC}"
echo ""
