#!/bin/bash
#
# generate-channel-artifacts.sh - Generate channel artifacts for COLD Blockchain
# Hyperledger Fabric v2.5.14 - Archival Chain
#
# This script generates:
# 1. Genesis block for orderer bootstrapping
# 2. Channel creation transaction for cold-chain
# 3. Anchor peer update transactions for LabOrg and CourtOrg
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
CHANNEL_NAME="cold-chain"
ORDERER_GENESIS_PROFILE="ColdChainGenesis"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  COLD Blockchain Channel Artifacts${NC}"
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
# STEP 1: Generate Genesis Block for Orderer
# ============================================================================

print_section "STEP 1: Generating genesis block for orderer"

configtxgen -profile ${ORDERER_GENESIS_PROFILE} \
    -outputBlock "${ARTIFACTS_DIR}/genesis.block" \
    -channelID system-channel

if [[ $? -eq 0 ]] && [[ -f "${ARTIFACTS_DIR}/genesis.block" ]]; then
    print_success "Genesis block generated: genesis.block"
    ls -lh "${ARTIFACTS_DIR}/genesis.block"
else
    print_error "Failed to generate genesis block"
    exit 1
fi

# ============================================================================
# STEP 2: Generate Channel Creation Transaction
# ============================================================================

print_section "STEP 2: Generating channel creation transaction"

configtxgen -profile ${ORDERER_GENESIS_PROFILE} \
    -outputCreateChannelTx "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx" \
    -channelID ${CHANNEL_NAME}

if [[ $? -eq 0 ]] && [[ -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx" ]]; then
    print_success "Channel creation tx generated: ${CHANNEL_NAME}.tx"
    ls -lh "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx"
else
    print_error "Failed to generate channel creation transaction"
    exit 1
fi

# ============================================================================
# STEP 3: Generate Anchor Peer Update Transactions
# ============================================================================

print_section "STEP 3: Generating anchor peer update transactions"

# LabOrg anchor peer update
configtxgen -profile ${ORDERER_GENESIS_PROFILE} \
    -outputAnchorPeersUpdate "${ARTIFACTS_DIR}/LabOrgAnchors.tx" \
    -channelID ${CHANNEL_NAME} \
    -asOrg LabOrg

if [[ $? -eq 0 ]] && [[ -f "${ARTIFACTS_DIR}/LabOrgAnchors.tx" ]]; then
    print_success "LabOrg anchor peer update tx generated"
    ls -lh "${ARTIFACTS_DIR}/LabOrgAnchors.tx"
else
    print_error "Failed to generate LabOrg anchor peer update"
    exit 1
fi

# CourtOrg anchor peer update
configtxgen -profile ${ORDERER_GENESIS_PROFILE} \
    -outputAnchorPeersUpdate "${ARTIFACTS_DIR}/CourtOrgAnchors.tx" \
    -channelID ${CHANNEL_NAME} \
    -asOrg CourtOrg

if [[ $? -eq 0 ]] && [[ -f "${ARTIFACTS_DIR}/CourtOrgAnchors.tx" ]]; then
    print_success "CourtOrg anchor peer update tx generated"
    ls -lh "${ARTIFACTS_DIR}/CourtOrgAnchors.tx"
else
    print_error "Failed to generate CourtOrg anchor peer update"
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
echo "  1. genesis.block - Orderer bootstrap block"
echo "  2. ${CHANNEL_NAME}.tx - Channel creation transaction"
echo "  3. LabOrgAnchors.tx - LabOrg anchor peer update"
echo "  4. CourtOrgAnchors.tx - CourtOrg anchor peer update"
echo ""
echo -e "${BLUE}Artifacts location:${NC}"
echo "  ${ARTIFACTS_DIR}/"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Start orderer with genesis block"
echo "  2. Create channel: peer channel create ..."
echo "  3. Join peers to channel: peer channel join ..."
echo "  4. Update anchor peers: peer channel update ..."
echo ""
