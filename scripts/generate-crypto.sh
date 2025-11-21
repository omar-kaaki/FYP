#!/bin/bash
#
# generate-crypto.sh - Generate all cryptographic material for FYP Blockchain
# Hyperledger Fabric v2.5.14
#
# This script:
# 1. Starts all Certificate Authority containers
# 2. Initializes CAs with proper configurations
# 3. Registers all identities (orderers, peers, admins, clients)
# 4. Enrolls all identities to generate certificates
# 5. Generates TLS certificates for all nodes
# 6. Organizes MSP directory structure
#
# Usage: ./generate-crypto.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base paths
BASE_DIR="/home/user/FYPBcoc"
CRYPTO_DIR="${BASE_DIR}/crypto-config"
FABRIC_CA_CLIENT_HOME="${BASE_DIR}/.fabric-ca-client"

# CA admin credentials
# Identity CAs use ca-admin:ca-adminpw
# TLS CAs use tls-ca-admin:tlscapw
IDENTITY_CA_ADMIN="ca-admin"
IDENTITY_CA_PASS="ca-adminpw"
TLS_CA_ADMIN="tls-ca-admin"
TLS_CA_PASS="tlscapw"

echo -e "${GREEN}===== FYP Blockchain - Crypto Material Generation =====${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${YELLOW}>>> $1${NC}"
    echo ""
}

# Function to wait for CA to be ready
wait_for_ca() {
    local ca_url=$1
    local ca_name=$2
    local max_attempts=30
    local attempt=1

    print_section "Waiting for $ca_name to be ready..."

    while [ $attempt -le $max_attempts ]; do
        if curl -sSf -k "${ca_url}/cainfo" > /dev/null 2>&1; then
            echo -e "${GREEN}$ca_name is ready!${NC}"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: $ca_name not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo -e "${RED}ERROR: $ca_name failed to start after $max_attempts attempts${NC}"
    exit 1
}

# ============================================================================
# STEP 1: Start Certificate Authority containers
# ============================================================================

print_section "STEP 1: Starting Certificate Authority containers"

docker-compose -f "${BASE_DIR}/docker-compose-ca.yaml" up -d

# Wait for all CAs to be ready
wait_for_ca "https://localhost:7054" "OrdererOrg Identity CA"
wait_for_ca "https://localhost:8054" "OrdererOrg TLS CA"
wait_for_ca "https://localhost:7055" "LabOrg Identity CA"
wait_for_ca "https://localhost:8055" "LabOrg TLS CA"
wait_for_ca "https://localhost:7056" "CourtOrg Identity CA"
wait_for_ca "https://localhost:8056" "CourtOrg TLS CA"

sleep 5

# ============================================================================
# STEP 2: Enroll CA Admins and get root certificates
# ============================================================================

print_section "STEP 2: Enrolling CA Admins"

# OrdererOrg Identity CA Admin
print_section "Enrolling OrdererOrg Identity CA Admin"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com"
mkdir -p "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/msp/cacerts"
fabric-ca-client enroll -u https://${IDENTITY_CA_ADMIN}:${IDENTITY_CA_PASS}@localhost:7054 --caname ca.ordererorg.example.com --tls.certfiles "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/ca/tls-cert.pem"

# Copy CA cert to MSP with consistent naming
cp "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/msp/cacerts/"* "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/msp/cacerts/ca-ordererorg-example-com.pem"

# OrdererOrg TLS CA Admin
print_section "Enrolling OrdererOrg TLS CA Admin"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/tlsca-admin"
mkdir -p "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/msp/tlscacerts"
fabric-ca-client enroll -u https://${TLS_CA_ADMIN}:${TLS_CA_PASS}@localhost:8054 --caname tlsca.ordererorg.example.com --tls.certfiles "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/tlsca/tls-cert.pem"

# Copy TLS CA cert to org MSP
cp "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/tlsca-admin/msp/cacerts/"* "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/msp/tlscacerts/tlsca-ordererorg-example-com.pem"

# LabOrg Identity CA Admin
print_section "Enrolling LabOrg Identity CA Admin"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/laborg.example.com"
mkdir -p "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/cacerts"
fabric-ca-client enroll -u https://${IDENTITY_CA_ADMIN}:${IDENTITY_CA_PASS}@localhost:7055 --caname ca.laborg.example.com --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/ca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/cacerts/"* "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/cacerts/ca-laborg-example-com.pem"

# LabOrg TLS CA Admin
print_section "Enrolling LabOrg TLS CA Admin"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/laborg.example.com/tlsca-admin"
mkdir -p "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/tlscacerts"
fabric-ca-client enroll -u https://${TLS_CA_ADMIN}:${TLS_CA_PASS}@localhost:8055 --caname tlsca.laborg.example.com --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/tlsca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/tlsca-admin/msp/cacerts/"* "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/tlscacerts/tlsca-laborg-example-com.pem"

# CourtOrg Identity CA Admin
print_section "Enrolling CourtOrg Identity CA Admin"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/courtorg.example.com"
mkdir -p "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/msp/cacerts"
fabric-ca-client enroll -u https://${IDENTITY_CA_ADMIN}:${IDENTITY_CA_PASS}@localhost:7056 --caname ca.courtorg.example.com --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/ca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/msp/cacerts/"* "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/msp/cacerts/ca-courtorg-example-com.pem"

# CourtOrg TLS CA Admin
print_section "Enrolling CourtOrg TLS CA Admin"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/tlsca-admin"
mkdir -p "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/msp/tlscacerts"
fabric-ca-client enroll -u https://${TLS_CA_ADMIN}:${TLS_CA_PASS}@localhost:8056 --caname tlsca.courtorg.example.com --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/tlsca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/tlsca-admin/msp/cacerts/"* "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/msp/tlscacerts/tlsca-courtorg-example-com.pem"

# ============================================================================
# STEP 3: Register and enroll all identities
# ============================================================================

print_section "STEP 3: Registering and enrolling identities"

# ============================================================================
# OrdererOrg Identities
# ============================================================================

print_section "Registering OrdererOrg identities"

export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com"

# Register orderer1.ordererorg.example.com
fabric-ca-client register --caname ca.ordererorg.example.com --id.name orderer1.ordererorg.example.com --id.secret orderer1pw --id.type orderer --tls.certfiles "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/ca/tls-cert.pem"

# Register orderer-admin@ordererorg.example.com
fabric-ca-client register --caname ca.ordererorg.example.com --id.name orderer-admin@ordererorg.example.com --id.secret ordereradminpw --id.type admin --id.attrs "admin=true:ecert" --tls.certfiles "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/ca/tls-cert.pem"

print_section "Enrolling orderer1.ordererorg.example.com"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com"
fabric-ca-client enroll -u https://orderer1.ordererorg.example.com:orderer1pw@localhost:7054 --caname ca.ordererorg.example.com -M "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/msp" --csr.hosts orderer1.ordererorg.example.com --csr.hosts localhost --tls.certfiles "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/ca/tls-cert.pem"

# Copy NodeOUs config
cp "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/msp/config.yaml" "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/msp/config.yaml"

print_section "Enrolling orderer1 TLS certificate"
mkdir -p "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls"
fabric-ca-client enroll -u https://orderer1.ordererorg.example.com:orderer1pw@localhost:8054 --caname tlsca.ordererorg.example.com -M "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls" --enrollment.profile tls --csr.hosts orderer1.ordererorg.example.com --csr.hosts localhost --tls.certfiles "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/tlsca/tls-cert.pem"

# Copy TLS certs to proper locations
cp "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls/tlscacerts/"* "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls/ca.crt"
cp "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls/signcerts/"* "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls/server.crt"
cp "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls/keystore/"* "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls/server.key"

print_section "Enrolling orderer-admin@ordererorg.example.com"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/users/orderer-admin@ordererorg.example.com"
fabric-ca-client enroll -u https://orderer-admin@ordererorg.example.com:ordereradminpw@localhost:7054 --caname ca.ordererorg.example.com -M "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/users/orderer-admin@ordererorg.example.com/msp" --tls.certfiles "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/ca/tls-cert.pem"

cp "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/msp/config.yaml" "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/users/orderer-admin@ordererorg.example.com/msp/config.yaml"

# Copy admin cert to org MSP admincerts
mkdir -p "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/msp/admincerts"
cp "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/users/orderer-admin@ordererorg.example.com/msp/signcerts/"* "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/msp/admincerts/orderer-admin-cert.pem"

# ============================================================================
# LabOrg Identities
# ============================================================================

print_section "Registering LabOrg identities"

export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/laborg.example.com"

# Register peer0.laborg.example.com
fabric-ca-client register --caname ca.laborg.example.com --id.name peer0.laborg.example.com --id.secret peer0pw --id.type peer --id.affiliation laborg.dfir --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/ca/tls-cert.pem"

# Register lab-admin@laborg.example.com
fabric-ca-client register --caname ca.laborg.example.com --id.name lab-admin@laborg.example.com --id.secret labadminpw --id.type admin --id.affiliation laborg.dfir --id.attrs "admin=true:ecert" --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/ca/tls-cert.pem"

# Register lab-gw@laborg.example.com (Gateway client)
fabric-ca-client register --caname ca.laborg.example.com --id.name lab-gw@laborg.example.com --id.secret labgwpw --id.type client --id.affiliation laborg.dfir --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/ca/tls-cert.pem"

print_section "Enrolling peer0.laborg.example.com"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com"
fabric-ca-client enroll -u https://peer0.laborg.example.com:peer0pw@localhost:7055 --caname ca.laborg.example.com -M "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/msp" --csr.hosts peer0.laborg.example.com --csr.hosts localhost --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/ca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/config.yaml" "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/msp/config.yaml"

print_section "Enrolling peer0.laborg TLS certificate"
mkdir -p "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls"
fabric-ca-client enroll -u https://peer0.laborg.example.com:peer0pw@localhost:8055 --caname tlsca.laborg.example.com -M "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls" --enrollment.profile tls --csr.hosts peer0.laborg.example.com --csr.hosts localhost --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/tlsca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls/tlscacerts/"* "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls/ca.crt"
cp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls/signcerts/"* "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls/server.crt"
cp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls/keystore/"* "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls/server.key"

print_section "Enrolling lab-admin@laborg.example.com"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/laborg.example.com/users/lab-admin@laborg.example.com"
fabric-ca-client enroll -u https://lab-admin@laborg.example.com:labadminpw@localhost:7055 --caname ca.laborg.example.com -M "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/users/lab-admin@laborg.example.com/msp" --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/ca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/config.yaml" "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/users/lab-admin@laborg.example.com/msp/config.yaml"

mkdir -p "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/admincerts"
cp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/users/lab-admin@laborg.example.com/msp/signcerts/"* "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/admincerts/lab-admin-cert.pem"

print_section "Enrolling lab-gw@laborg.example.com (Gateway client)"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/laborg.example.com/users/lab-gw@laborg.example.com"
fabric-ca-client enroll -u https://lab-gw@laborg.example.com:labgwpw@localhost:7055 --caname ca.laborg.example.com -M "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/users/lab-gw@laborg.example.com/msp" --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/ca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/msp/config.yaml" "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/users/lab-gw@laborg.example.com/msp/config.yaml"

# Optional: Enroll TLS cert for lab-gw if client mTLS is needed
mkdir -p "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/users/lab-gw@laborg.example.com/tls"
fabric-ca-client enroll -u https://lab-gw@laborg.example.com:labgwpw@localhost:8055 --caname tlsca.laborg.example.com -M "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/users/lab-gw@laborg.example.com/tls" --enrollment.profile tls --csr.hosts localhost --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/tlsca/tls-cert.pem"

# ============================================================================
# CourtOrg Identities
# ============================================================================

print_section "Registering CourtOrg identities"

export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/courtorg.example.com"

# Register peer0.courtorg.example.com
fabric-ca-client register --caname ca.courtorg.example.com --id.name peer0.courtorg.example.com --id.secret peer0pw --id.type peer --id.affiliation courtorg.legal --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/ca/tls-cert.pem"

# Register court-admin@courtorg.example.com
fabric-ca-client register --caname ca.courtorg.example.com --id.name court-admin@courtorg.example.com --id.secret courtadminpw --id.type admin --id.affiliation courtorg.legal --id.attrs "admin=true:ecert" --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/ca/tls-cert.pem"

print_section "Enrolling peer0.courtorg.example.com"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com"
fabric-ca-client enroll -u https://peer0.courtorg.example.com:peer0pw@localhost:7056 --caname ca.courtorg.example.com -M "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/msp" --csr.hosts peer0.courtorg.example.com --csr.hosts localhost --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/ca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/msp/config.yaml" "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/msp/config.yaml"

print_section "Enrolling peer0.courtorg TLS certificate"
mkdir -p "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls"
fabric-ca-client enroll -u https://peer0.courtorg.example.com:peer0pw@localhost:8056 --caname tlsca.courtorg.example.com -M "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls" --enrollment.profile tls --csr.hosts peer0.courtorg.example.com --csr.hosts localhost --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/tlsca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls/tlscacerts/"* "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls/ca.crt"
cp "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls/signcerts/"* "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls/server.crt"
cp "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls/keystore/"* "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls/server.key"

print_section "Enrolling court-admin@courtorg.example.com"
export FABRIC_CA_CLIENT_HOME="${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/users/court-admin@courtorg.example.com"
fabric-ca-client enroll -u https://court-admin@courtorg.example.com:courtadminpw@localhost:7056 --caname ca.courtorg.example.com -M "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/users/court-admin@courtorg.example.com/msp" --tls.certfiles "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/ca/tls-cert.pem"

cp "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/msp/config.yaml" "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/users/court-admin@courtorg.example.com/msp/config.yaml"

mkdir -p "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/msp/admincerts"
cp "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/users/court-admin@courtorg.example.com/msp/signcerts/"* "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/msp/admincerts/court-admin-cert.pem"

# ============================================================================
# STEP 4: Verification
# ============================================================================

print_section "STEP 4: Verifying generated crypto material"

verify_msp() {
    local msp_path=$1
    local org_name=$2

    if [ ! -d "$msp_path/cacerts" ] || [ ! -d "$msp_path/keystore" ] || [ ! -d "$msp_path/signcerts" ]; then
        echo -e "${RED}ERROR: Missing required directories in $org_name MSP${NC}"
        return 1
    fi

    if [ ! -f "$msp_path/config.yaml" ]; then
        echo -e "${RED}ERROR: Missing config.yaml in $org_name MSP${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ $org_name MSP structure verified${NC}"
    return 0
}

# Verify all MSPs
verify_msp "${CRYPTO_DIR}/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/msp" "orderer1"
verify_msp "${CRYPTO_DIR}/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/msp" "peer0.laborg"
verify_msp "${CRYPTO_DIR}/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/msp" "peer0.courtorg"

echo ""
echo -e "${GREEN}===== Crypto Material Generation Complete! =====${NC}"
echo ""
echo "Summary:"
echo "  - 3 Organizations (OrdererOrg, LabOrg, CourtOrg)"
echo "  - 1 Orderer node (orderer1.ordererorg.example.com)"
echo "  - 2 Peer nodes (peer0.laborg.example.com, peer0.courtorg.example.com)"
echo "  - 3 Admin identities"
echo "  - 1 Gateway client (lab-gw@laborg.example.com)"
echo ""
echo "Next steps:"
echo "  1. Generate channel genesis blocks: ./scripts/generate-genesis.sh"
echo "  2. Start network containers: docker-compose up -d"
echo "  3. Create and join channels"
echo ""
