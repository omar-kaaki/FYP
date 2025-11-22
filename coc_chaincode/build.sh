#!/bin/bash
#
# build.sh - Build and package the Chain of Custody chaincode
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHAINCODE_NAME="coc_chaincode"
CHAINCODE_VERSION="1.0"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Chain of Custody Chaincode Builder${NC}"
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

# Check prerequisites
print_section "Checking prerequisites"

if ! command -v go &> /dev/null; then
    print_error "Go is not installed"
    exit 1
fi
print_success "Go is installed: $(go version)"

# Clean previous builds
print_section "Cleaning previous builds"
rm -rf "${SCRIPT_DIR}/vendor"
rm -f "${SCRIPT_DIR}/${CHAINCODE_NAME}.tar.gz"
print_success "Cleaned previous builds"

# Download dependencies
print_section "Downloading Go dependencies"
cd "${SCRIPT_DIR}"
go mod tidy
go mod vendor
print_success "Dependencies downloaded and vendored"

# Build chaincode binary (optional - for testing)
print_section "Building chaincode binary"
go build -o "${SCRIPT_DIR}/${CHAINCODE_NAME}"
print_success "Chaincode binary built: ${CHAINCODE_NAME}"

# Package chaincode for Fabric
print_section "Packaging chaincode"
cd "${SCRIPT_DIR}/.."
tar czf "${CHAINCODE_NAME}.tar.gz" \
    -C "${SCRIPT_DIR}" \
    --exclude=".git" \
    --exclude="*.tar.gz" \
    --exclude="${CHAINCODE_NAME}" \
    --exclude="build.sh" \
    .
mv "${CHAINCODE_NAME}.tar.gz" "${SCRIPT_DIR}/"
print_success "Chaincode packaged: ${CHAINCODE_NAME}.tar.gz"

# Show package info
print_section "Package information"
ls -lh "${SCRIPT_DIR}/${CHAINCODE_NAME}.tar.gz"
echo ""
echo -e "${BLUE}Package contents:${NC}"
tar -tzf "${SCRIPT_DIR}/${CHAINCODE_NAME}.tar.gz" | head -20
echo "..."
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Package location:${NC}"
echo "  ${SCRIPT_DIR}/${CHAINCODE_NAME}.tar.gz"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Deploy to hot-chain: cd ../hot-blockchain && ./scripts/deploy-chaincode.sh"
echo "  2. Deploy to cold-chain: cd ../cold-blockchain && ./scripts/deploy-chaincode.sh"
echo ""
