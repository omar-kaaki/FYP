#!/bin/bash
#
# test-ca-setup.sh - Comprehensive test for COLD Blockchain CA setup
# Tests MSP configuration, TLS setup, and crypto generation
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

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Parse arguments
SKIP_CRYPTO=false
if [[ "$1" == "--skip-crypto" ]]; then
    SKIP_CRYPTO=true
fi

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}TEST: $1${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

pass() {
    echo -e "${GREEN}  ✓ PASS: $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}  ✗ FAIL: $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_header "COLD Blockchain CA Setup Tests"

# ============================================================================
# TEST 1: Required Tools
# ============================================================================

print_test "Checking required tools"

if command -v docker &> /dev/null; then
    pass "Docker is installed ($(docker --version))"
else
    fail "Docker is not installed"
fi

if command -v docker-compose &> /dev/null; then
    pass "Docker Compose is installed ($(docker-compose --version))"
else
    fail "Docker Compose is not installed"
fi

if command -v fabric-ca-client &> /dev/null; then
    pass "fabric-ca-client is installed ($(fabric-ca-client version | head -1))"
else
    fail "fabric-ca-client is not installed"
fi

if command -v configtxgen &> /dev/null; then
    pass "configtxgen is installed ($(configtxgen version | head -1))"
else
    fail "configtxgen is not installed"
fi

if command -v peer &> /dev/null; then
    pass "peer is installed ($(peer version | head -1))"
else
    fail "peer is not installed"
fi

if command -v jq &> /dev/null; then
    pass "jq is installed"
else
    fail "jq is not installed (required for CA API parsing)"
fi

if command -v tree &> /dev/null; then
    pass "tree is installed"
else
    fail "tree is not installed (optional, for viewing structure)"
fi

# ============================================================================
# TEST 2: Configuration Files
# ============================================================================

print_test "Checking configuration files"

if [[ -f "${BASE_DIR}/configtx.yaml" ]]; then
    pass "configtx.yaml exists"
else
    fail "configtx.yaml not found"
fi

if [[ -f "${BASE_DIR}/docker-compose-ca.yaml" ]]; then
    pass "docker-compose-ca.yaml exists"
else
    fail "docker-compose-ca.yaml not found"
fi

# Check CA config files
for org in ordererorg laborg courtorg; do
    for ca_type in ca tlsca; do
        config_file="${BASE_DIR}/ca-config/${org}-${ca_type}/fabric-ca-server-config.yaml"
        if [[ -f "$config_file" ]]; then
            pass "CA config exists: ${org}-${ca_type}"
        else
            fail "CA config missing: ${org}-${ca_type}"
        fi
    done
done

# ============================================================================
# TEST 3: MSP Directory Structure
# ============================================================================

print_test "Checking MSP directory structure"

# Check org-level MSP directories
for org in "ordererOrganizations/ordererorg.cold.coc.com" "peerOrganizations/laborg.cold.coc.com" "peerOrganizations/courtorg.cold.coc.com"; do
    org_name=$(basename $(dirname $org))_$(basename $org | cut -d. -f1)
    
    if [[ -d "${CRYPTO_DIR}/$org/msp" ]]; then
        pass "$org_name org MSP directory exists"
        
        for dir in admincerts cacerts tlscacerts; do
            if [[ -d "${CRYPTO_DIR}/$org/msp/$dir" ]]; then
                pass "  $org_name MSP has $dir/"
            else
                fail "  $org_name MSP missing $dir/"
            fi
        done
        
        if [[ -f "${CRYPTO_DIR}/$org/msp/config.yaml" ]]; then
            pass "  $org_name MSP has config.yaml (NodeOUs)"
        else
            fail "  $org_name MSP missing config.yaml"
        fi
    else
        fail "$org_name org MSP directory not found"
    fi
done

# Check node-level MSP directories
if [[ -d "${CRYPTO_DIR}/ordererOrganizations/ordererorg.cold.coc.com/orderers/orderer.cold.coc.com/msp" ]]; then
    pass "Orderer node MSP directory exists"
    
    for dir in admincerts cacerts tlscacerts signcerts keystore; do
        if [[ -d "${CRYPTO_DIR}/ordererOrganizations/ordererorg.cold.coc.com/orderers/orderer.cold.coc.com/msp/$dir" ]]; then
            pass "  Orderer MSP has $dir/"
        else
            fail "  Orderer MSP missing $dir/"
        fi
    done
else
    fail "Orderer node MSP directory not found"
fi

if [[ -d "${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/peers/peer0.laborg.cold.coc.com/msp" ]]; then
    pass "LabOrg peer node MSP directory exists"
    
    for dir in admincerts cacerts tlscacerts signcerts keystore; do
        if [[ -d "${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/peers/peer0.laborg.cold.coc.com/msp/$dir" ]]; then
            pass "  LabOrg peer MSP has $dir/"
        else
            fail "  LabOrg peer MSP missing $dir/"
        fi
    done
else
    fail "LabOrg peer node MSP directory not found"
fi

if [[ -d "${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/peers/peer0.courtorg.cold.coc.com/msp" ]]; then
    pass "CourtOrg peer node MSP directory exists"
    
    for dir in admincerts cacerts tlscacerts signcerts keystore; do
        if [[ -d "${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/peers/peer0.courtorg.cold.coc.com/msp/$dir" ]]; then
            pass "  CourtOrg peer MSP has $dir/"
        else
            fail "  CourtOrg peer MSP missing $dir/"
        fi
    done
else
    fail "CourtOrg peer node MSP directory not found"
fi

# ============================================================================
# TEST 4: TLS Directory Structure
# ============================================================================

print_test "Checking TLS directory structure"

if [[ -d "${CRYPTO_DIR}/ordererOrganizations/ordererorg.cold.coc.com/orderers/orderer.cold.coc.com/tls" ]]; then
    pass "Orderer TLS directory exists"
else
    fail "Orderer TLS directory not found"
fi

if [[ -d "${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/peers/peer0.laborg.cold.coc.com/tls" ]]; then
    pass "LabOrg peer TLS directory exists"
else
    fail "LabOrg peer TLS directory not found"
fi

if [[ -d "${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/peers/peer0.courtorg.cold.coc.com/tls" ]]; then
    pass "CourtOrg peer TLS directory exists"
else
    fail "CourtOrg peer TLS directory not found"
fi

# ============================================================================
# TEST 5: Docker Compose Validation
# ============================================================================

print_test "Validating docker-compose files"

if docker-compose -f "${BASE_DIR}/docker-compose-ca.yaml" config > /dev/null 2>&1; then
    pass "docker-compose-ca.yaml is valid"
else
    fail "docker-compose-ca.yaml has syntax errors"
fi

# ============================================================================
# TEST 6: CA Container Tests (if running)
# ============================================================================

print_test "Checking CA containers"

# OrdererOrg CAs
if docker ps --format '{{.Names}}' | grep -q "ca.ordererorg.cold.coc.com"; then
    pass "OrdererOrg Identity CA container is running"
    
    if curl -sSf -k https://localhost:7154/cainfo > /dev/null 2>&1; then
        pass "  OrdererOrg Identity CA API is responsive"
    else
        fail "  OrdererOrg Identity CA API is not responsive"
    fi
else
    echo -e "${YELLOW}  ⚠ OrdererOrg Identity CA container not running${NC}"
fi

if docker ps --format '{{.Names}}' | grep -q "tlsca.ordererorg.cold.coc.com"; then
    pass "OrdererOrg TLS CA container is running"
    
    if curl -sSf -k https://localhost:8154/cainfo > /dev/null 2>&1; then
        pass "  OrdererOrg TLS CA API is responsive"
    else
        fail "  OrdererOrg TLS CA API is not responsive"
    fi
else
    echo -e "${YELLOW}  ⚠ OrdererOrg TLS CA container not running${NC}"
fi

# LabOrg CAs
if docker ps --format '{{.Names}}' | grep -q "ca.laborg.cold.coc.com"; then
    pass "LabOrg Identity CA container is running"
    
    if curl -sSf -k https://localhost:7155/cainfo > /dev/null 2>&1; then
        pass "  LabOrg Identity CA API is responsive"
    else
        fail "  LabOrg Identity CA API is not responsive"
    fi
else
    echo -e "${YELLOW}  ⚠ LabOrg Identity CA container not running${NC}"
fi

if docker ps --format '{{.Names}}' | grep -q "tlsca.laborg.cold.coc.com"; then
    pass "LabOrg TLS CA container is running"
    
    if curl -sSf -k https://localhost:8155/cainfo > /dev/null 2>&1; then
        pass "  LabOrg TLS CA API is responsive"
    else
        fail "  LabOrg TLS CA API is not responsive"
    fi
else
    echo -e "${YELLOW}  ⚠ LabOrg TLS CA container not running${NC}"
fi

# CourtOrg CAs
if docker ps --format '{{.Names}}' | grep -q "ca.courtorg.cold.coc.com"; then
    pass "CourtOrg Identity CA container is running"
    
    if curl -sSf -k https://localhost:7156/cainfo > /dev/null 2>&1; then
        pass "  CourtOrg Identity CA API is responsive"
    else
        fail "  CourtOrg Identity CA API is not responsive"
    fi
else
    echo -e "${YELLOW}  ⚠ CourtOrg Identity CA container not running${NC}"
fi

if docker ps --format '{{.Names}}' | grep -q "tlsca.courtorg.cold.coc.com"; then
    pass "CourtOrg TLS CA container is running"
    
    if curl -sSf -k https://localhost:8156/cainfo > /dev/null 2>&1; then
        pass "  CourtOrg TLS CA API is responsive"
    else
        fail "  CourtOrg TLS CA API is not responsive"
    fi
else
    echo -e "${YELLOW}  ⚠ CourtOrg TLS CA container not running${NC}"
fi

# ============================================================================
# TEST 7: Crypto Material Generation (Optional)
# ============================================================================

if [[ "$SKIP_CRYPTO" == "false" ]]; then
    print_test "Running crypto generation"
    
    if [[ -x "${SCRIPT_DIR}/generate-crypto.sh" ]]; then
        echo "  Running generate-crypto.sh..."
        if "${SCRIPT_DIR}/generate-crypto.sh" > /tmp/crypto-gen-cold.log 2>&1; then
            pass "Crypto generation completed successfully"
            
            # Verify generated certificates
            if [[ -f "${CRYPTO_DIR}/ordererOrganizations/ordererorg.cold.coc.com/msp/cacerts/ca.ordererorg.cold.coc.com-cert.pem" ]]; then
                pass "  OrdererOrg CA cert generated"
            else
                fail "  OrdererOrg CA cert not found"
            fi
            
            if [[ -f "${CRYPTO_DIR}/ordererOrganizations/ordererorg.cold.coc.com/orderers/orderer.cold.coc.com/tls/server.crt" ]]; then
                pass "  Orderer TLS cert generated"
            else
                fail "  Orderer TLS cert not found"
            fi
            
            if [[ -f "${CRYPTO_DIR}/peerOrganizations/laborg.cold.coc.com/peers/peer0.laborg.cold.coc.com/tls/server.crt" ]]; then
                pass "  LabOrg peer TLS cert generated"
            else
                fail "  LabOrg peer TLS cert not found"
            fi
            
            if [[ -f "${CRYPTO_DIR}/peerOrganizations/courtorg.cold.coc.com/peers/peer0.courtorg.cold.coc.com/tls/server.crt" ]]; then
                pass "  CourtOrg peer TLS cert generated"
            else
                fail "  CourtOrg peer TLS cert not found"
            fi
            
            # Verify TLS trust bundle
            if [[ -f "${CRYPTO_DIR}/tls-bundle/cold-chain-tls-ca-bundle.pem" ]]; then
                pass "  TLS trust bundle created"
            else
                fail "  TLS trust bundle not found"
            fi
        else
            fail "Crypto generation failed (see /tmp/crypto-gen-cold.log)"
            cat /tmp/crypto-gen-cold.log
        fi
    else
        fail "generate-crypto.sh not found or not executable"
    fi
else
    echo -e "${YELLOW}Skipping crypto generation (use without --skip-crypto to test)${NC}"
fi

# ============================================================================
# TEST 8: configtx.yaml Validation
# ============================================================================

print_test "Validating configtx.yaml"

cd "${BASE_DIR}"

if configtxgen -profile ColdChainGenesis -outputBlock /tmp/cold-genesis.block -channelID system-channel > /dev/null 2>&1; then
    pass "configtx.yaml can generate genesis block"
    rm -f /tmp/cold-genesis.block
else
    fail "configtx.yaml validation failed"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
else
    echo -e "${GREEN}Tests failed: 0${NC}"
fi
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed! COLD blockchain CA setup is ready.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Start CA containers: docker-compose -f docker-compose-ca.yaml up -d"
    echo "  2. Generate crypto: ./scripts/generate-crypto.sh"
    echo "  3. Start network: docker-compose -f docker-compose-network.yaml up -d"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review the errors above.${NC}"
    exit 1
fi
