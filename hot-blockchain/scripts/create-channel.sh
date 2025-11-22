#!/bin/bash
#
# create-channel.sh - Create and join HOT blockchain channel
# Hyperledger Fabric v2.5.14 - Active Investigation Chain
#
# This script uses Fabric 2.x Channel Participation API:
# 1. Joins the orderer to the channel using osnadmin
# 2. Joins LabOrg peer to the channel
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
CRYPTO_DIR="${BASE_DIR}/crypto-config"

# Channel configuration
CHANNEL_NAME="hot-chain"
ORDERER_ADDRESS="localhost:7050"
ORDERER_ADMIN_ADDRESS="localhost:7053"
ORDERER_TLS_CA="${CRYPTO_DIR}/ordererOrganizations/ordererorg.hot.coc.com/tlsca/tls-cert.pem"
ORDERER_ADMIN_TLS_CERT="${CRYPTO_DIR}/ordererOrganizations/ordererorg.hot.coc.com/orderers/orderer.hot.coc.com/tls/server.crt"
ORDERER_ADMIN_TLS_KEY="${CRYPTO_DIR}/ordererOrganizations/ordererorg.hot.coc.com/orderers/orderer.hot.coc.com/tls/server.key"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HOT Blockchain Channel Creation${NC}"
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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Verify artifacts exist
print_section "Verifying channel artifacts"

if [[ ! -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block" ]]; then
    print_error "Channel genesis block not found: ${CHANNEL_NAME}.block"
    print_info "Run ./generate-channel-artifacts.sh first"
    exit 1
fi
print_success "Found ${CHANNEL_NAME}.block"

# Verify orderer TLS CA exists
if [[ ! -f "${ORDERER_TLS_CA}" ]]; then
    print_error "Orderer TLS CA certificate not found"
    print_info "Run ./generate-crypto.sh first"
    exit 1
fi
print_success "Found orderer TLS CA certificate"

# ============================================================================
# STEP 1: Join Orderer to Channel using osnadmin
# ============================================================================

print_section "STEP 1: Joining orderer to channel '${CHANNEL_NAME}'"

# Check if channel already exists on orderer
EXISTING_CHANNELS=$(osnadmin channel list \
    -o ${ORDERER_ADMIN_ADDRESS} \
    --ca-file "${ORDERER_TLS_CA}" \
    --client-cert "${ORDERER_ADMIN_TLS_CERT}" \
    --client-key "${ORDERER_ADMIN_TLS_KEY}" 2>/dev/null | grep "${CHANNEL_NAME}" || true)

if [[ -n "${EXISTING_CHANNELS}" ]]; then
    print_info "Channel '${CHANNEL_NAME}' already exists on orderer"
else
    osnadmin channel join \
        --channelID ${CHANNEL_NAME} \
        --config-block "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block" \
        -o ${ORDERER_ADMIN_ADDRESS} \
        --ca-file "${ORDERER_TLS_CA}" \
        --client-cert "${ORDERER_ADMIN_TLS_CERT}" \
        --client-key "${ORDERER_ADMIN_TLS_KEY}"

    if [[ $? -eq 0 ]]; then
        print_success "Orderer joined channel '${CHANNEL_NAME}'"
    else
        print_error "Failed to join orderer to channel"
        exit 1
    fi
fi

# Verify channel on orderer
print_info "Verifying channel on orderer..."
osnadmin channel list \
    -o ${ORDERER_ADMIN_ADDRESS} \
    --ca-file "${ORDERER_TLS_CA}" \
    --client-cert "${ORDERER_ADMIN_TLS_CERT}" \
    --client-key "${ORDERER_ADMIN_TLS_KEY}"

# ============================================================================
# STEP 2: Set environment for LabOrg Admin
# ============================================================================

print_section "STEP 2: Setting up LabOrg admin environment"

export CORE_PEER_LOCALMSPID="LabOrgMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE="${CRYPTO_DIR}/peerOrganizations/laborg.hot.coc.com/peers/peer0.laborg.hot.coc.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${CRYPTO_DIR}/peerOrganizations/laborg.hot.coc.com/users/Admin@laborg.hot.coc.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"

print_success "LabOrg admin environment configured"
print_info "MSP ID: ${CORE_PEER_LOCALMSPID}"
print_info "Peer address: ${CORE_PEER_ADDRESS}"

# ============================================================================
# STEP 3: Join LabOrg Peer to Channel
# ============================================================================

print_section "STEP 3: Joining LabOrg peer0 to channel"

# Check if peer already joined
JOINED_CHANNELS=$(peer channel list 2>/dev/null | grep "${CHANNEL_NAME}" || true)

if [[ -n "${JOINED_CHANNELS}" ]]; then
    print_info "peer0.laborg.hot.coc.com already member of '${CHANNEL_NAME}'"
else
    peer channel join \
        -b "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"

    if [[ $? -eq 0 ]]; then
        print_success "peer0.laborg.hot.coc.com joined channel '${CHANNEL_NAME}'"
    else
        print_error "Failed to join peer to channel"
        exit 1
    fi
fi

# Verify peer joined
sleep 2
CHANNELS=$(peer channel list 2>/dev/null | grep "${CHANNEL_NAME}" || true)
if [[ -n "${CHANNELS}" ]]; then
    print_success "Verified peer is member of channel"
else
    print_error "Peer not showing as channel member"
    exit 1
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Channel Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Channel information:${NC}"
echo "  Channel name: ${CHANNEL_NAME}"
echo "  Organizations: LabOrg"
echo "  Peers joined: peer0.laborg.hot.coc.com"
echo ""
echo -e "${YELLOW}Verification commands:${NC}"
echo "  # List channels peer has joined"
echo "  peer channel list"
echo ""
echo "  # Get channel info"
echo "  peer channel getinfo -c ${CHANNEL_NAME}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Install chaincode on peer"
echo "  2. Approve chaincode for your organization"
echo "  3. Commit chaincode definition to channel"
echo "  4. Invoke/query chaincode"
echo ""
