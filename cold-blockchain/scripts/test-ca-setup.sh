#!/bin/bash
#
# test-ca-setup.sh - Comprehensive test script for FYP Blockchain CA setup
# Hyperledger Fabric v2.5.14
#
# This script tests:
# 1. Docker Compose configuration validity
# 2. CA container startup and health
# 3. CA API responsiveness
# 4. Crypto material generation (optional)
# 5. MSP directory structure verification
# 6. Certificate validity checks
# 7. configtx.yaml validation
#
# Usage: ./test-ca-setup.sh [--skip-crypto]
#        --skip-crypto: Skip crypto generation and only test existing setup
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base paths
BASE_DIR="/home/user/FYPBcoc"
CRYPTO_DIR="${BASE_DIR}/crypto-config"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Parse command line arguments
SKIP_CRYPTO=false
if [ "$1" == "--skip-crypto" ]; then
    SKIP_CRYPTO=true
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  FYP Blockchain CA Setup Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print test headers
print_test() {
    echo ""
    echo -e "${YELLOW}[TEST $1] $2${NC}"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

# Function to print failure
print_failure() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Function to check command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_failure "Command '$1' not found. Please install it."
        return 1
    fi
    return 0
}

# ============================================================================
# TEST 1: Check required tools
# ============================================================================

print_test "1" "Checking required tools"

if check_command "docker"; then
    print_success "Docker is installed ($(docker --version))"
else
    print_failure "Docker is not installed"
fi

if check_command "docker-compose"; then
    print_success "Docker Compose is installed ($(docker-compose --version))"
else
    print_failure "Docker Compose is not installed"
fi

if check_command "fabric-ca-client"; then
    print_success "Fabric CA Client is installed ($(fabric-ca-client version | head -1))"
else
    print_failure "Fabric CA Client is not installed"
fi

if check_command "configtxgen"; then
    print_success "configtxgen is installed ($(configtxgen --version 2>&1 | head -1))"
else
    print_failure "configtxgen is not installed"
fi

# ============================================================================
# TEST 2: Verify configuration files exist
# ============================================================================

print_test "2" "Verifying configuration files exist"

if [ -f "${BASE_DIR}/docker-compose-ca.yaml" ]; then
    print_success "docker-compose-ca.yaml exists"
else
    print_failure "docker-compose-ca.yaml not found"
fi

if [ -f "${BASE_DIR}/configtx.yaml" ]; then
    print_success "configtx.yaml exists"
else
    print_failure "configtx.yaml not found"
fi

# Check CA config files
CA_CONFIGS=(
    "ca-config/ordererorg-ca/fabric-ca-server-config.yaml"
    "ca-config/ordererorg-tlsca/fabric-ca-server-config.yaml"
    "ca-config/laborg-ca/fabric-ca-server-config.yaml"
    "ca-config/laborg-tlsca/fabric-ca-server-config.yaml"
    "ca-config/courtorg-ca/fabric-ca-server-config.yaml"
    "ca-config/courtorg-tlsca/fabric-ca-server-config.yaml"
)

for config in "${CA_CONFIGS[@]}"; do
    if [ -f "${BASE_DIR}/${config}" ]; then
        print_success "${config} exists"
    else
        print_failure "${config} not found"
    fi
done

# ============================================================================
# TEST 3: Validate docker-compose-ca.yaml syntax
# ============================================================================

print_test "3" "Validating docker-compose-ca.yaml syntax"

if docker-compose -f "${BASE_DIR}/docker-compose-ca.yaml" config > /dev/null 2>&1; then
    print_success "docker-compose-ca.yaml syntax is valid"
else
    print_failure "docker-compose-ca.yaml has syntax errors"
    docker-compose -f "${BASE_DIR}/docker-compose-ca.yaml" config
fi

# ============================================================================
# TEST 4: Start CA containers
# ============================================================================

print_test "4" "Starting CA containers"

echo "Stopping any existing CA containers..."
docker-compose -f "${BASE_DIR}/docker-compose-ca.yaml" down > /dev/null 2>&1 || true

echo "Starting CA containers..."
if docker-compose -f "${BASE_DIR}/docker-compose-ca.yaml" up -d; then
    print_success "CA containers started successfully"
    sleep 5  # Wait for containers to initialize
else
    print_failure "Failed to start CA containers"
fi

# ============================================================================
# TEST 5: Verify CA containers are running
# ============================================================================

print_test "5" "Verifying CA containers are running"

CA_CONTAINERS=(
    "ca.ordererorg.example.com"
    "tlsca.ordererorg.example.com"
    "ca.laborg.example.com"
    "tlsca.laborg.example.com"
    "ca.courtorg.example.com"
    "tlsca.courtorg.example.com"
)

for container in "${CA_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        print_success "Container ${container} is running"
    else
        print_failure "Container ${container} is not running"
    fi
done

# ============================================================================
# TEST 6: Check CA API health
# ============================================================================

print_test "6" "Checking CA API health endpoints"

CA_URLS=(
    "https://localhost:7054|OrdererOrg Identity CA"
    "https://localhost:8054|OrdererOrg TLS CA"
    "https://localhost:7055|LabOrg Identity CA"
    "https://localhost:8055|LabOrg TLS CA"
    "https://localhost:7056|CourtOrg Identity CA"
    "https://localhost:8056|CourtOrg TLS CA"
)

echo "Waiting for CAs to become ready (max 30 seconds)..."
sleep 10

for entry in "${CA_URLS[@]}"; do
    IFS='|' read -r url name <<< "$entry"

    max_attempts=15
    attempt=1
    success=false

    while [ $attempt -le $max_attempts ]; do
        if curl -sSf -k "${url}/cainfo" > /dev/null 2>&1; then
            success=true
            break
        fi
        sleep 2
        attempt=$((attempt + 1))
    done

    if [ "$success" = true ]; then
        print_success "${name} API is responsive at ${url}"
    else
        print_failure "${name} API is not responsive at ${url}"
    fi
done

# ============================================================================
# TEST 7: Verify CA operations endpoints
# ============================================================================

print_test "7" "Verifying CA operations endpoints"

OPS_URLS=(
    "http://localhost:17054|OrdererOrg Identity CA Operations"
    "http://localhost:18054|OrdererOrg TLS CA Operations"
    "http://localhost:17055|LabOrg Identity CA Operations"
    "http://localhost:18055|LabOrg TLS CA Operations"
    "http://localhost:17056|CourtOrg Identity CA Operations"
    "http://localhost:18056|CourtOrg TLS CA Operations"
)

for entry in "${OPS_URLS[@]}"; do
    IFS='|' read -r url name <<< "$entry"

    if curl -sSf "${url}/healthz" > /dev/null 2>&1; then
        print_success "${name} endpoint is accessible"
    else
        print_failure "${name} endpoint is not accessible"
    fi
done

# ============================================================================
# TEST 8: Generate crypto material (if not skipped)
# ============================================================================

if [ "$SKIP_CRYPTO" = false ]; then
    print_test "8" "Generating crypto material"

    if [ -f "${BASE_DIR}/scripts/generate-crypto.sh" ]; then
        echo "Running generate-crypto.sh..."
        if bash "${BASE_DIR}/scripts/generate-crypto.sh"; then
            print_success "Crypto material generated successfully"
        else
            print_failure "Crypto material generation failed"
        fi
    else
        print_failure "generate-crypto.sh not found"
    fi
else
    print_test "8" "Skipping crypto material generation (--skip-crypto flag)"
    echo "Skipped by user request"
fi

# ============================================================================
# TEST 9: Verify crypto-config directory structure
# ============================================================================

print_test "9" "Verifying crypto-config directory structure"

# Check organization MSP directories
ORG_MSPS=(
    "ordererOrganizations/ordererorg.example.com/msp"
    "peerOrganizations/laborg.example.com/msp"
    "peerOrganizations/courtorg.example.com/msp"
)

for msp in "${ORG_MSPS[@]}"; do
    msp_path="${CRYPTO_DIR}/${msp}"
    if [ -d "$msp_path" ]; then
        # Check required subdirectories
        required_dirs=("cacerts" "tlscacerts")
        all_exist=true

        for dir in "${required_dirs[@]}"; do
            if [ ! -d "${msp_path}/${dir}" ]; then
                all_exist=false
                break
            fi
        done

        if [ -f "${msp_path}/config.yaml" ] && [ "$all_exist" = true ]; then
            print_success "MSP structure for ${msp} is valid"
        else
            print_failure "MSP structure for ${msp} is incomplete"
        fi
    else
        print_failure "MSP directory ${msp} not found (crypto not generated yet)"
    fi
done

# ============================================================================
# TEST 10: Verify NodeOUs configuration
# ============================================================================

print_test "10" "Verifying NodeOUs configuration files"

NODE_OU_CONFIGS=(
    "ordererOrganizations/ordererorg.example.com/msp/config.yaml"
    "peerOrganizations/laborg.example.com/msp/config.yaml"
    "peerOrganizations/courtorg.example.com/msp/config.yaml"
)

for config in "${NODE_OU_CONFIGS[@]}"; do
    config_path="${CRYPTO_DIR}/${config}"
    if [ -f "$config_path" ]; then
        if grep -q "NodeOUs:" "$config_path" && grep -q "Enable: true" "$config_path"; then
            print_success "NodeOUs enabled in ${config}"
        else
            print_failure "NodeOUs not properly configured in ${config}"
        fi
    else
        print_failure "Config file ${config} not found"
    fi
done

# ============================================================================
# TEST 11: Verify identity certificates (if crypto generated)
# ============================================================================

print_test "11" "Verifying identity certificates"

IDENTITIES=(
    "ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/msp/signcerts"
    "ordererOrganizations/ordererorg.example.com/users/orderer-admin@ordererorg.example.com/msp/signcerts"
    "peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/msp/signcerts"
    "peerOrganizations/laborg.example.com/users/lab-admin@laborg.example.com/msp/signcerts"
    "peerOrganizations/laborg.example.com/users/lab-gw@laborg.example.com/msp/signcerts"
    "peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/msp/signcerts"
    "peerOrganizations/courtorg.example.com/users/court-admin@courtorg.example.com/msp/signcerts"
)

for identity in "${IDENTITIES[@]}"; do
    cert_dir="${CRYPTO_DIR}/${identity}"
    if [ -d "$cert_dir" ]; then
        cert_file=$(ls "$cert_dir"/*.pem 2>/dev/null | head -1)
        if [ -f "$cert_file" ]; then
            # Verify certificate using openssl
            if openssl x509 -in "$cert_file" -noout -text > /dev/null 2>&1; then
                subject=$(openssl x509 -in "$cert_file" -noout -subject | sed 's/subject=//')
                print_success "Certificate valid for ${identity}: ${subject}"
            else
                print_failure "Invalid certificate in ${identity}"
            fi
        else
            print_failure "No certificate found in ${identity}"
        fi
    else
        echo "  ⊘ Skipping ${identity} (not yet generated)"
    fi
done

# ============================================================================
# TEST 12: Verify TLS certificates
# ============================================================================

print_test "12" "Verifying TLS certificates"

TLS_CERTS=(
    "ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls/server.crt"
    "peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls/server.crt"
    "peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls/server.crt"
)

for cert in "${TLS_CERTS[@]}"; do
    cert_path="${CRYPTO_DIR}/${cert}"
    if [ -f "$cert_path" ]; then
        if openssl x509 -in "$cert_path" -noout -text > /dev/null 2>&1; then
            san=$(openssl x509 -in "$cert_path" -noout -ext subjectAltName 2>/dev/null || echo "No SAN")
            print_success "TLS certificate valid: ${cert}"
        else
            print_failure "Invalid TLS certificate: ${cert}"
        fi
    else
        echo "  ⊘ Skipping ${cert} (not yet generated)"
    fi
done

# ============================================================================
# TEST 13: Validate configtx.yaml
# ============================================================================

print_test "13" "Validating configtx.yaml"

# Try to generate a test genesis block to validate configtx.yaml
TEST_BLOCK="/tmp/test-genesis.block"
export FABRIC_CFG_PATH="${BASE_DIR}"

if configtxgen -profile HotChainGenesis -channelID test-channel -outputBlock "$TEST_BLOCK" > /dev/null 2>&1; then
    print_success "configtx.yaml is valid (HotChainGenesis profile)"
    rm -f "$TEST_BLOCK"
else
    print_failure "configtx.yaml validation failed (HotChainGenesis profile)"
fi

if configtxgen -profile ColdChainGenesis -channelID test-channel -outputBlock "$TEST_BLOCK" > /dev/null 2>&1; then
    print_success "configtx.yaml is valid (ColdChainGenesis profile)"
    rm -f "$TEST_BLOCK"
else
    print_failure "configtx.yaml validation failed (ColdChainGenesis profile)"
fi

# ============================================================================
# TEST 14: Check CA container logs for errors
# ============================================================================

print_test "14" "Checking CA container logs for errors"

for container in "${CA_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        error_count=$(docker logs "$container" 2>&1 | grep -i "error\|fatal\|panic" | wc -l)
        if [ "$error_count" -eq 0 ]; then
            print_success "No errors in ${container} logs"
        else
            print_failure "Found ${error_count} error(s) in ${container} logs"
            echo "  Recent errors:"
            docker logs "$container" 2>&1 | grep -i "error\|fatal\|panic" | tail -3 | sed 's/^/    /'
        fi
    fi
done

# ============================================================================
# TEST 15: Verify network connectivity
# ============================================================================

print_test "15" "Verifying Docker network"

if docker network inspect fyp-blockchain-network > /dev/null 2>&1; then
    network_containers=$(docker network inspect fyp-blockchain-network -f '{{len .Containers}}')
    print_success "Docker network 'fyp-blockchain-network' exists with ${network_containers} containers"
else
    print_failure "Docker network 'fyp-blockchain-network' not found"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Total Tests:  ${TESTS_TOTAL}"
echo -e "${GREEN}Passed:       ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed:       ${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review CA configuration files in ca-config/"
    echo "  2. Generate channel genesis blocks if not done yet"
    echo "  3. Start peer and orderer containers"
    echo "  4. Create and join channels"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review the output above.${NC}"
    echo ""
    exit 1
fi
