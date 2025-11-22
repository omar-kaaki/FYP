#!/bin/bash
#
# generate-channel-artifacts.sh - Generate channel artifacts for HOT Blockchain
# Hyperledger Fabric v2.5.14 - Active Investigation Chain
#
# This script generates the channel genesis block using Fabric 2.x approach.
# In Fabric 2.x, channels are created using osnadmin with the genesis block,
# and anchor peer updates are done via configtxlator after channel creation.
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
ARTIFACTS_DIR="${BASE_DIR}/channel-artifacts"

# Channel configuration
CHANNEL_NAME="hot-chain"
CHANNEL_PROFILE="HotChainGenesis"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HOT Blockchain Channel Artifacts${NC}"
echo -e "${BLUE}  Active Investigation Chain${NC}"
echo -e "${BLUE}  Fabric 2.x Channel Participation API${NC}"
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

# Create artifacts directory
print_section "Creating channel artifacts directory"
mkdir -p "${ARTIFACTS_DIR}"
print_success "Directory created: ${ARTIFACTS_DIR}"

# Set FABRIC_CFG_PATH to base directory (where configtx.yaml is)
export FABRIC_CFG_PATH="${BASE_DIR}"

# Verify configtx.yaml exists
if [[ ! -f "${BASE_DIR}/configtx.yaml" ]]; then
    print_error "configtx.yaml not found in ${BASE_DIR}"
    exit 1
fi
print_success "Found configtx.yaml"

# ============================================================================
# STEP 1: Generate Channel Genesis Block
# ============================================================================
# In Fabric 2.x, we generate the channel genesis block directly.
# This block is used by osnadmin to join the orderer to the channel,
# and by peer channel join to join peers to the channel.
# ============================================================================

print_section "STEP 1: Generating channel genesis block"

configtxgen -profile ${CHANNEL_PROFILE} \
    -outputBlock "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block" \
    -channelID ${CHANNEL_NAME}

if [[ $? -eq 0 ]] && [[ -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block" ]]; then
    print_success "Channel genesis block generated: ${CHANNEL_NAME}.block"
    ls -lh "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"
else
    print_error "Failed to generate channel genesis block"
    exit 1
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Channel Artifacts Generated!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Generated artifacts:${NC}"
echo "  1. ${CHANNEL_NAME}.block - Channel genesis block"
echo ""
echo -e "${BLUE}Artifacts location:${NC}"
echo "  ${ARTIFACTS_DIR}/"
echo ""
echo -e "${YELLOW}Next steps (Fabric 2.x approach):${NC}"
echo "  1. Start orderer"
echo "  2. Join orderer to channel: osnadmin channel join --channelID ${CHANNEL_NAME} --config-block ${ARTIFACTS_DIR}/${CHANNEL_NAME}.block ..."
echo "  3. Join peers to channel: peer channel join -b ${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"
echo "  4. Update anchor peers via configtxlator (after channel creation)"
echo ""
