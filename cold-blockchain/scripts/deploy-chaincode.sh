#!/bin/bash
#
# deploy-chaincode.sh - Deploy chaincode to COLD blockchain
# Hyperledger Fabric v2.5.14 - Archival Chain
#
# This script:
# 1. Packages the chaincode
# 2. Installs on both LabOrg and CourtOrg peers
# 3. Approves for both organizations
# 4. Commits chaincode definition to channel
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
CRYPTO_DIR="${BASE_DIR}/crypto-config"
CHAINCODE_DIR="$(dirname "$BASE_DIR")/coc_chaincode"

# Chaincode configuration
CHAINCODE_NAME="cold_chaincode"
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE=1
CHANNEL_NAME="cold-chain"
CHAINCODE_LABEL="${CHAINCODE_NAME}_${CHAINCODE_VERSION}"

# Orderer configuration
ORDERER_ADDRESS="localhost:7150"
ORDERER_TLS_CA="${CRYPTO_DIR}/ordererOrganizations/ordererorg.cold.coc.com/tlsca/tlsca.ordererorg.cold.coc.com-cert.pem"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  COLD Blockchain Chaincode Deployment${NC}"
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

# Set LabOrg environment
set_laborg_env() {
    export CORE_PEER_LOCALMSPID="LabOrgMSP"
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_TLS_ROOTCERT_FILE="${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/peers/peer0.laborg.cold.coc.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/users/Admin@laborg.cold.coc.com/msp"
    export CORE_PEER_ADDRESS="localhost:8051"
}

# Set CourtOrg environment
set_courtorg_env() {
    export CORE_PEER_LOCALMSPID="CourtOrgMSP"
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_TLS_ROOTCERT_FILE="${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/peers/peer0.courtorg.cold.coc.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/users/Admin@courtorg.cold.coc.com/msp"
    export CORE_PEER_ADDRESS="localhost:9051"
}

# ============================================================================
# STEP 1: Build and Package Chaincode
# ============================================================================

print_section "STEP 1: Building and packaging chaincode"

if [[ ! -d "${CHAINCODE_DIR}" ]]; then
    print_error "Chaincode directory not found: ${CHAINCODE_DIR}"
    exit 1
fi

# Build chaincode
print_info "Building chaincode..."
cd "${CHAINCODE_DIR}"
chmod +x build.sh
./build.sh

CHAINCODE_PACKAGE="${CHAINCODE_DIR}/coc_chaincode.tar.gz"
if [[ ! -f "${CHAINCODE_PACKAGE}" ]]; then
    print_error "Chaincode package not found after build"
    exit 1
fi

print_success "Chaincode package ready: coc_chaincode.tar.gz"

# ============================================================================
# STEP 2: Install Chaincode on Both Peers
# ============================================================================

print_section "STEP 2: Installing chaincode on both peers"

# Package for Fabric (lifecycle package)
FABRIC_PACKAGE="${BASE_DIR}/${CHAINCODE_LABEL}.tar.gz"
set_laborg_env
peer lifecycle chaincode package "${FABRIC_PACKAGE}" \
    --path "${CHAINCODE_DIR}" \
    --lang golang \
    --label "${CHAINCODE_LABEL}"

if [[ ! -f "${FABRIC_PACKAGE}" ]]; then
    print_error "Failed to create Fabric chaincode package"
    exit 1
fi
print_success "Fabric chaincode package created"

# Install on LabOrg peer
print_info "Installing on LabOrg peer0..."
set_laborg_env
peer lifecycle chaincode install "${FABRIC_PACKAGE}"

if [[ $? -eq 0 ]]; then
    print_success "Chaincode installed on peer0.laborg.cold.coc.com"
else
    print_error "Failed to install chaincode on LabOrg peer"
    exit 1
fi

# Install on CourtOrg peer
print_info "Installing on CourtOrg peer0..."
set_courtorg_env
peer lifecycle chaincode install "${FABRIC_PACKAGE}"

if [[ $? -eq 0 ]]; then
    print_success "Chaincode installed on peer0.courtorg.cold.coc.com"
else
    print_error "Failed to install chaincode on CourtOrg peer"
    exit 1
fi

# Get package ID (from LabOrg peer)
set_laborg_env
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled 2>/dev/null | grep "${CHAINCODE_LABEL}" | awk '{print $3}' | sed 's/,$//')

if [[ -z "${PACKAGE_ID}" ]]; then
    print_error "Failed to get package ID"
    exit 1
fi

print_success "Package ID: ${PACKAGE_ID}"

# ============================================================================
# STEP 3: Approve Chaincode for Both Organizations
# ============================================================================

print_section "STEP 3: Approving chaincode for both organizations"

# Approve for LabOrg
print_info "Approving for LabOrg..."
set_laborg_env

peer lifecycle chaincode approveformyorg \
    -o ${ORDERER_ADDRESS} \
    --ordererTLSHostnameOverride orderer.cold.coc.com \
    --tls \
    --cafile "${ORDERER_TLS_CA}" \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence ${CHAINCODE_SEQUENCE} \
    --init-required

if [[ $? -eq 0 ]]; then
    print_success "Chaincode approved by LabOrg"
else
    print_error "Failed to approve chaincode for LabOrg"
    exit 1
fi

# Approve for CourtOrg
print_info "Approving for CourtOrg..."
set_courtorg_env

peer lifecycle chaincode approveformyorg \
    -o ${ORDERER_ADDRESS} \
    --ordererTLSHostnameOverride orderer.cold.coc.com \
    --tls \
    --cafile "${ORDERER_TLS_CA}" \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence ${CHAINCODE_SEQUENCE} \
    --init-required

if [[ $? -eq 0 ]]; then
    print_success "Chaincode approved by CourtOrg"
else
    print_error "Failed to approve chaincode for CourtOrg"
    exit 1
fi

# Check commit readiness
print_info "Checking commit readiness..."
set_laborg_env
peer lifecycle chaincode checkcommitreadiness \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --sequence ${CHAINCODE_SEQUENCE} \
    --init-required \
    --output json

# ============================================================================
# STEP 4: Commit Chaincode Definition
# ============================================================================

print_section "STEP 4: Committing chaincode definition to channel"

set_laborg_env

peer lifecycle chaincode commit \
    -o ${ORDERER_ADDRESS} \
    --ordererTLSHostnameOverride orderer.cold.coc.com \
    --tls \
    --cafile "${ORDERER_TLS_CA}" \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${CHAINCODE_VERSION} \
    --sequence ${CHAINCODE_SEQUENCE} \
    --init-required \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles "${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/peers/peer0.laborg.cold.coc.com/tls/ca.crt" \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles "${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/peers/peer0.courtorg.cold.coc.com/tls/ca.crt"

if [[ $? -eq 0 ]]; then
    print_success "Chaincode definition committed to channel"
else
    print_error "Failed to commit chaincode"
    exit 1
fi

# ============================================================================
# STEP 5: Initialize Chaincode
# ============================================================================

print_section "STEP 5: Initializing chaincode"

set_laborg_env

peer chaincode invoke \
    -o ${ORDERER_ADDRESS} \
    --ordererTLSHostnameOverride orderer.cold.coc.com \
    --tls \
    --cafile "${ORDERER_TLS_CA}" \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles "${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/peers/peer0.laborg.cold.coc.com/tls/ca.crt" \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles "${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/peers/peer0.courtorg.cold.coc.com/tls/ca.crt" \
    --isInit \
    -c '{"function":"Init","Args":[]}'

if [[ $? -eq 0 ]]; then
    print_success "Chaincode initialized"
else
    print_error "Failed to initialize chaincode"
    exit 1
fi

# Verify deployment
print_section "Verifying deployment"

sleep 3

peer lifecycle chaincode querycommitted \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME}

if [[ $? -eq 0 ]]; then
    print_success "Chaincode deployment verified"
else
    print_error "Failed to verify chaincode deployment"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Chaincode Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Deployment details:${NC}"
echo "  Chaincode name: ${CHAINCODE_NAME}"
echo "  Version: ${CHAINCODE_VERSION}"
echo "  Sequence: ${CHAINCODE_SEQUENCE}"
echo "  Channel: ${CHANNEL_NAME}"
echo "  Package ID: ${PACKAGE_ID}"
echo "  Endorsement policy: AND('LabOrgMSP.peer','CourtOrgMSP.peer')"
echo ""
echo -e "${YELLOW}Test the chaincode:${NC}"
echo "  # Set user roles for court user (as admin)"
echo "  peer chaincode invoke -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} \\"
echo "    -c '{\"function\":\"SetUserRoles\",\"Args\":[\"LabOrgMSP|lab-gw|user:court1\",\"BlockchainCourt\"]}'"
echo ""
echo "  # Query user roles"
echo "  peer chaincode query -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} \\"
echo "    -c '{\"function\":\"GetUserRoles\",\"Args\":[\"LabOrgMSP|lab-gw|user:court1\"]}'"
echo ""
echo -e "${BLUE}Note:${NC} Transactions on cold-chain require endorsements from BOTH LabOrg and CourtOrg peers"
echo ""
