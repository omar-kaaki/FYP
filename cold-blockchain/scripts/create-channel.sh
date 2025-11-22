#!/bin/bash
#
# create-channel.sh - Create and join COLD blockchain channel
# Hyperledger Fabric v2.5.14 - Archival Chain
#
# This script:
# 1. Creates the cold-chain channel
# 2. Joins LabOrg peer to the channel
# 3. Joins CourtOrg peer to the channel
# 4. Updates anchor peers for LabOrg and CourtOrg
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
CHANNEL_NAME="cold-chain"
ORDERER_ADDRESS="localhost:7150"
ORDERER_TLS_CA="${CRYPTO_DIR}/ordererOrganizations/ordererorg.cold.coc.com/tlsca/tlsca.ordererorg.cold.coc.com-cert.pem"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  COLD Blockchain Channel Creation${NC}"
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

# Helper function to set LabOrg environment
set_laborg_env() {
    export CORE_PEER_LOCALMSPID="LabOrgMSP"
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_TLS_ROOTCERT_FILE="${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/peers/peer0.laborg.cold.coc.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/users/Admin@laborg.cold.coc.com/msp"
    export CORE_PEER_ADDRESS="localhost:8051"
}

# Helper function to set CourtOrg environment
set_courtorg_env() {
    export CORE_PEER_LOCALMSPID="CourtOrgMSP"
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_TLS_ROOTCERT_FILE="${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/peers/peer0.courtorg.cold.coc.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/users/Admin@courtorg.cold.coc.com/msp"
    export CORE_PEER_ADDRESS="localhost:9051"
}

# Verify artifacts exist
print_section "Verifying channel artifacts"

if [[ ! -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx" ]]; then
    print_error "Channel creation transaction not found: ${CHANNEL_NAME}.tx"
    print_info "Run ./generate-channel-artifacts.sh first"
    exit 1
fi
print_success "Found ${CHANNEL_NAME}.tx"

if [[ ! -f "${ARTIFACTS_DIR}/LabOrgAnchors.tx" ]]; then
    print_error "LabOrg anchor peer update not found"
    exit 1
fi
print_success "Found LabOrgAnchors.tx"

if [[ ! -f "${ARTIFACTS_DIR}/CourtOrgAnchors.tx" ]]; then
    print_error "CourtOrg anchor peer update not found"
    exit 1
fi
print_success "Found CourtOrgAnchors.tx"

# Verify orderer TLS CA exists
if [[ ! -f "${ORDERER_TLS_CA}" ]]; then
    print_error "Orderer TLS CA certificate not found"
    print_info "Run ./generate-crypto.sh first"
    exit 1
fi
print_success "Found orderer TLS CA certificate"

# ============================================================================
# STEP 1: Create Channel (as LabOrg Admin)
# ============================================================================

print_section "STEP 1: Creating channel '${CHANNEL_NAME}' (as LabOrg)"

set_laborg_env

print_success "LabOrg admin environment configured"
print_info "MSP ID: ${CORE_PEER_LOCALMSPID}"
print_info "Peer address: ${CORE_PEER_ADDRESS}"

peer channel create \
    -o ${ORDERER_ADDRESS} \
    -c ${CHANNEL_NAME} \
    -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx" \
    --outputBlock "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block" \
    --tls \
    --cafile "${ORDERER_TLS_CA}"

if [[ $? -eq 0 ]] && [[ -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block" ]]; then
    print_success "Channel '${CHANNEL_NAME}' created successfully"
    ls -lh "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"
else
    print_error "Failed to create channel"
    exit 1
fi

# ============================================================================
# STEP 2: Join LabOrg Peer to Channel
# ============================================================================

print_section "STEP 2: Joining LabOrg peer0 to channel"

set_laborg_env

peer channel join \
    -b "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"

if [[ $? -eq 0 ]]; then
    print_success "peer0.laborg.cold.coc.com joined channel '${CHANNEL_NAME}'"
else
    print_error "Failed to join LabOrg peer to channel"
    exit 1
fi

# Verify LabOrg peer joined
sleep 2
CHANNELS=$(peer channel list 2>/dev/null | grep "${CHANNEL_NAME}" || true)
if [[ -n "${CHANNELS}" ]]; then
    print_success "Verified LabOrg peer is member of channel"
else
    print_error "LabOrg peer not showing as channel member"
    exit 1
fi

# ============================================================================
# STEP 3: Join CourtOrg Peer to Channel
# ============================================================================

print_section "STEP 3: Joining CourtOrg peer0 to channel"

set_courtorg_env

print_success "CourtOrg admin environment configured"
print_info "MSP ID: ${CORE_PEER_LOCALMSPID}"
print_info "Peer address: ${CORE_PEER_ADDRESS}"

peer channel join \
    -b "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"

if [[ $? -eq 0 ]]; then
    print_success "peer0.courtorg.cold.coc.com joined channel '${CHANNEL_NAME}'"
else
    print_error "Failed to join CourtOrg peer to channel"
    exit 1
fi

# Verify CourtOrg peer joined
sleep 2
CHANNELS=$(peer channel list 2>/dev/null | grep "${CHANNEL_NAME}" || true)
if [[ -n "${CHANNELS}" ]]; then
    print_success "Verified CourtOrg peer is member of channel"
else
    print_error "CourtOrg peer not showing as channel member"
    exit 1
fi

# ============================================================================
# STEP 4: Update Anchor Peers for LabOrg
# ============================================================================

print_section "STEP 4: Updating anchor peers for LabOrg"

set_laborg_env

peer channel update \
    -o ${ORDERER_ADDRESS} \
    -c ${CHANNEL_NAME} \
    -f "${ARTIFACTS_DIR}/LabOrgAnchors.tx" \
    --tls \
    --cafile "${ORDERER_TLS_CA}"

if [[ $? -eq 0 ]]; then
    print_success "Anchor peer updated for LabOrg"
else
    print_error "Failed to update LabOrg anchor peer"
    exit 1
fi

# ============================================================================
# STEP 5: Update Anchor Peers for CourtOrg
# ============================================================================

print_section "STEP 5: Updating anchor peers for CourtOrg"

set_courtorg_env

peer channel update \
    -o ${ORDERER_ADDRESS} \
    -c ${CHANNEL_NAME} \
    -f "${ARTIFACTS_DIR}/CourtOrgAnchors.tx" \
    --tls \
    --cafile "${ORDERER_TLS_CA}"

if [[ $? -eq 0 ]]; then
    print_success "Anchor peer updated for CourtOrg"
else
    print_error "Failed to update CourtOrg anchor peer"
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
echo "  Organizations: LabOrg, CourtOrg"
echo "  Peers joined:"
echo "    - peer0.laborg.cold.coc.com"
echo "    - peer0.courtorg.cold.coc.com"
echo "  Anchor peers:"
echo "    - peer0.laborg.cold.coc.com (LabOrg)"
echo "    - peer0.courtorg.cold.coc.com (CourtOrg)"
echo ""
echo -e "${YELLOW}Verification commands:${NC}"
echo "  # List channels (as LabOrg)"
echo "  export CORE_PEER_ADDRESS=localhost:8051"
echo "  export CORE_PEER_LOCALMSPID=LabOrgMSP"
echo "  export CORE_PEER_MSPCONFIGPATH=${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/users/Admin@laborg.cold.coc.com/msp"
echo "  peer channel list"
echo ""
echo "  # List channels (as CourtOrg)"
echo "  export CORE_PEER_ADDRESS=localhost:9051"
echo "  export CORE_PEER_LOCALMSPID=CourtOrgMSP"
echo "  export CORE_PEER_MSPCONFIGPATH=${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/users/Admin@courtorg.cold.coc.com/msp"
echo "  peer channel list"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Install chaincode on both peers"
echo "  2. Approve chaincode for both organizations"
echo "  3. Commit chaincode definition to channel"
echo "  4. Invoke/query chaincode"
echo ""
