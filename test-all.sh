#!/bin/bash
#
# test-all.sh - Comprehensive Test Suite for FYP Blockchain
# Tests both HOT and COLD blockchain configurations
#
# This script validates:
# - All prerequisites and tools
# - Both blockchain configurations
# - MSP structures for all organizations
# - TLS configurations
# - CA infrastructure
# - Crypto material generation (optional)
#
# Usage:
#   ./test-all.sh              # Full test including crypto generation
#   ./test-all.sh --skip-crypto # Quick validation only
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Counters
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
HOT_TESTS=0
HOT_PASSED=0
HOT_FAILED=0
COLD_TESTS=0
COLD_PASSED=0
COLD_FAILED=0

# Parse arguments
SKIP_CRYPTO=false
if [[ "$1" == "--skip-crypto" ]]; then
    SKIP_CRYPTO=true
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

print_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}║         FYP BLOCKCHAIN - COMPREHENSIVE TEST SUITE              ║${NC}"
    echo -e "${CYAN}║         Chain of Custody System                                ║${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}TEST: $1${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

pass() {
    echo -e "${GREEN}  ✓ PASS: $1${NC}"
    TOTAL_PASSED=$((TOTAL_PASSED + 1))
}

fail() {
    echo -e "${RED}  ✗ FAIL: $1${NC}"
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
}

warn() {
    echo -e "${YELLOW}  ⚠ WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}  ℹ INFO: $1${NC}"
}

print_banner

# ============================================================================
# PHASE 1: Prerequisites and Tools Validation
# ============================================================================

print_section "PHASE 1: Prerequisites and Tools Validation"

print_test "Checking system requirements"
if [[ $(uname -m) == "x86_64" ]]; then
    pass "System architecture is x86_64"
else
    fail "System architecture is not x86_64: $(uname -m)"
fi

print_test "Checking required command-line tools"

tools=(
    "docker:Docker container runtime"
    "docker-compose:Docker Compose orchestration"
    "git:Version control"
    "curl:HTTP client"
    "wget:Download utility"
    "jq:JSON processor (required for CA API)"
    "tree:Directory tree viewer"
    "openssl:Cryptographic toolkit"
)

for tool_info in "${tools[@]}"; do
    IFS=':' read -r tool desc <<< "$tool_info"
    if command -v $tool &> /dev/null; then
        pass "$desc installed ($tool)"
    else
        fail "$desc not installed ($tool)"
    fi
done

print_test "Checking Hyperledger Fabric binaries"

fabric_bins=(
    "peer:Fabric peer binary"
    "orderer:Fabric orderer binary"
    "configtxgen:Channel configuration generator"
    "configtxlator:Config translation tool"
    "fabric-ca-client:Fabric CA client"
    "fabric-ca-server:Fabric CA server"
)

for bin_info in "${fabric_bins[@]}"; do
    IFS=':' read -r bin desc <<< "$bin_info"
    if command -v $bin &> /dev/null; then
        version_output=$($bin version 2>&1 | head -1 || echo "unknown")
        pass "$desc installed"
    else
        fail "$desc not installed"
    fi
done

print_test "Checking Docker service"
if systemctl is-active --quiet docker 2>/dev/null || docker info &> /dev/null; then
    pass "Docker service is running"
else
    fail "Docker service is not running"
fi

print_test "Checking Docker permissions"
if docker ps &> /dev/null; then
    pass "Current user can run Docker commands"
else
    fail "Current user cannot run Docker (add user to docker group)"
fi

# ============================================================================
# PHASE 2: Project Structure Validation
# ============================================================================

print_section "PHASE 2: Project Structure Validation"

print_test "Checking project directory structure"

required_dirs=(
    "hot-blockchain"
    "cold-blockchain"
    "hot-blockchain/ca-config"
    "hot-blockchain/crypto-config"
    "hot-blockchain/scripts"
    "cold-blockchain/ca-config"
    "cold-blockchain/crypto-config"
    "cold-blockchain/scripts"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "${SCRIPT_DIR}/$dir" ]]; then
        pass "Directory exists: $dir"
    else
        fail "Directory missing: $dir"
    fi
done

print_test "Checking required scripts"

required_scripts=(
    "hot-blockchain/scripts/generate-crypto.sh"
    "hot-blockchain/scripts/test-ca-setup.sh"
    "cold-blockchain/scripts/generate-crypto.sh"
    "cold-blockchain/scripts/test-ca-setup.sh"
    "install-prerequisites.sh"
)

for script in "${required_scripts[@]}"; do
    if [[ -f "${SCRIPT_DIR}/$script" ]]; then
        if [[ -x "${SCRIPT_DIR}/$script" ]]; then
            pass "Script exists and is executable: $script"
        else
            warn "Script exists but not executable: $script"
        fi
    else
        fail "Script missing: $script"
    fi
done

print_test "Checking configuration files"

config_files=(
    "hot-blockchain/configtx.yaml"
    "hot-blockchain/docker-compose-ca.yaml"
    "cold-blockchain/configtx.yaml"
    "cold-blockchain/docker-compose-ca.yaml"
    "requirements.txt"
    "requirements.md"
)

for config in "${config_files[@]}"; do
    if [[ -f "${SCRIPT_DIR}/$config" ]]; then
        pass "Config file exists: $config"
    else
        fail "Config file missing: $config"
    fi
done

# ============================================================================
# PHASE 3: Hot Blockchain CA Configuration
# ============================================================================

print_section "PHASE 3: Hot Blockchain CA Configuration"

print_test "Checking hot blockchain CA config files"

hot_ca_configs=(
    "hot-blockchain/ca-config/ordererorg-ca/fabric-ca-server-config.yaml"
    "hot-blockchain/ca-config/ordererorg-tlsca/fabric-ca-server-config.yaml"
    "hot-blockchain/ca-config/laborg-ca/fabric-ca-server-config.yaml"
    "hot-blockchain/ca-config/laborg-tlsca/fabric-ca-server-config.yaml"
)

for config in "${hot_ca_configs[@]}"; do
    if [[ -f "${SCRIPT_DIR}/$config" ]]; then
        pass "CA config exists: $(basename $(dirname $config))"
    else
        fail "CA config missing: $(basename $(dirname $config))"
    fi
done

print_test "Checking hot blockchain MSP structure"

hot_msp_dirs=(
    "hot-blockchain/crypto-config/ordererOrganizations/ordererorg.hot.coc.com/msp"
    "hot-blockchain/crypto-config/peerOrganizations/laborg.hot.coc.com/msp"
    "hot-blockchain/crypto-config/ordererOrganizations/ordererorg.hot.coc.com/orderers/orderer.hot.coc.com/msp"
    "hot-blockchain/crypto-config/peerOrganizations/laborg.hot.coc.com/peers/peer0.laborg.hot.coc.com/msp"
)

for msp_dir in "${hot_msp_dirs[@]}"; do
    if [[ -d "${SCRIPT_DIR}/$msp_dir" ]]; then
        # Check for config.yaml
        if [[ -f "${SCRIPT_DIR}/$msp_dir/config.yaml" ]]; then
            pass "MSP structure with NodeOUs: $(basename $(dirname $msp_dir))"
        else
            warn "MSP exists but missing config.yaml: $(basename $(dirname $msp_dir))"
        fi
    else
        fail "MSP directory missing: $(basename $(dirname $msp_dir))"
    fi
done

# ============================================================================
# PHASE 4: Cold Blockchain CA Configuration
# ============================================================================

print_section "PHASE 4: Cold Blockchain CA Configuration"

print_test "Checking cold blockchain CA config files"

cold_ca_configs=(
    "cold-blockchain/ca-config/ordererorg-ca/fabric-ca-server-config.yaml"
    "cold-blockchain/ca-config/ordererorg-tlsca/fabric-ca-server-config.yaml"
    "cold-blockchain/ca-config/laborg-ca/fabric-ca-server-config.yaml"
    "cold-blockchain/ca-config/laborg-tlsca/fabric-ca-server-config.yaml"
    "cold-blockchain/ca-config/courtorg-ca/fabric-ca-server-config.yaml"
    "cold-blockchain/ca-config/courtorg-tlsca/fabric-ca-server-config.yaml"
)

for config in "${cold_ca_configs[@]}"; do
    if [[ -f "${SCRIPT_DIR}/$config" ]]; then
        pass "CA config exists: $(basename $(dirname $config))"
    else
        fail "CA config missing: $(basename $(dirname $config))"
    fi
done

print_test "Checking cold blockchain MSP structure"

cold_msp_dirs=(
    "cold-blockchain/crypto-config/ordererOrganizations/ordererorg.cold.coc.com/msp"
    "cold-blockchain/crypto-config/peerOrganizations/laborg.cold.coc.com/msp"
    "cold-blockchain/crypto-config/peerOrganizations/courtorg.cold.coc.com/msp"
    "cold-blockchain/crypto-config/ordererOrganizations/ordererorg.cold.coc.com/orderers/orderer.cold.coc.com/msp"
    "cold-blockchain/crypto-config/peerOrganizations/laborg.cold.coc.com/peers/peer0.laborg.cold.coc.com/msp"
    "cold-blockchain/crypto-config/peerOrganizations/courtorg.cold.coc.com/peers/peer0.courtorg.cold.coc.com/msp"
)

for msp_dir in "${cold_msp_dirs[@]}"; do
    if [[ -d "${SCRIPT_DIR}/$msp_dir" ]]; then
        if [[ -f "${SCRIPT_DIR}/$msp_dir/config.yaml" ]]; then
            pass "MSP structure with NodeOUs: $(basename $(dirname $msp_dir))"
        else
            warn "MSP exists but missing config.yaml: $(basename $(dirname $msp_dir))"
        fi
    else
        fail "MSP directory missing: $(basename $(dirname $msp_dir))"
    fi
done

# ============================================================================
# PHASE 5: Docker Compose Validation
# ============================================================================

print_section "PHASE 5: Docker Compose Validation"

print_test "Validating hot blockchain docker-compose files"
if docker-compose -f "${SCRIPT_DIR}/hot-blockchain/docker-compose-ca.yaml" config > /dev/null 2>&1; then
    pass "hot-blockchain/docker-compose-ca.yaml is valid"
else
    fail "hot-blockchain/docker-compose-ca.yaml has syntax errors"
fi

print_test "Validating cold blockchain docker-compose files"
if docker-compose -f "${SCRIPT_DIR}/cold-blockchain/docker-compose-ca.yaml" config > /dev/null 2>&1; then
    pass "cold-blockchain/docker-compose-ca.yaml is valid"
else
    fail "cold-blockchain/docker-compose-ca.yaml has syntax errors"
fi

# ============================================================================
# PHASE 6: CA Container Health (if running)
# ============================================================================

print_section "PHASE 6: CA Container Health Checks"

print_test "Checking hot blockchain CA containers"

hot_ca_containers=(
    "ca.ordererorg.hot.coc.com:7054:OrdererOrg Identity CA"
    "tlsca.ordererorg.hot.coc.com:8054:OrdererOrg TLS CA"
    "ca.laborg.hot.coc.com:7055:LabOrg Identity CA"
    "tlsca.laborg.hot.coc.com:8055:LabOrg TLS CA"
)

hot_running=0
for container_info in "${hot_ca_containers[@]}"; do
    IFS=':' read -r container port name <<< "$container_info"
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        if curl -sSf -k "https://localhost:${port}/cainfo" > /dev/null 2>&1; then
            pass "$name running and responsive"
            hot_running=$((hot_running + 1))
        else
            warn "$name container running but API not responsive"
        fi
    else
        info "$name not running (start with docker-compose up)"
    fi
done

if [[ $hot_running -eq 0 ]]; then
    warn "No hot blockchain CA containers running"
fi

print_test "Checking cold blockchain CA containers"

cold_ca_containers=(
    "ca.ordererorg.cold.coc.com:7154:OrdererOrg Identity CA"
    "tlsca.ordererorg.cold.coc.com:8154:OrdererOrg TLS CA"
    "ca.laborg.cold.coc.com:7155:LabOrg Identity CA"
    "tlsca.laborg.cold.coc.com:8155:LabOrg TLS CA"
    "ca.courtorg.cold.coc.com:7156:CourtOrg Identity CA"
    "tlsca.courtorg.cold.coc.com:8156:CourtOrg TLS CA"
)

cold_running=0
for container_info in "${cold_ca_containers[@]}"; do
    IFS=':' read -r container port name <<< "$container_info"
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        if curl -sSf -k "https://localhost:${port}/cainfo" > /dev/null 2>&1; then
            pass "$name running and responsive"
            cold_running=$((cold_running + 1))
        else
            warn "$name container running but API not responsive"
        fi
    else
        info "$name not running (start with docker-compose up)"
    fi
done

if [[ $cold_running -eq 0 ]]; then
    warn "No cold blockchain CA containers running"
fi

# ============================================================================
# PHASE 7: Run Individual Blockchain Tests
# ============================================================================

if [[ "$SKIP_CRYPTO" == "true" ]]; then
    print_section "PHASE 7: Running Individual Blockchain Tests (QUICK MODE)"
    
    print_test "Running hot blockchain quick test"
    if cd "${SCRIPT_DIR}/hot-blockchain" && ./scripts/test-ca-setup.sh --skip-crypto > /tmp/hot-test.log 2>&1; then
        pass "Hot blockchain quick test passed"
        HOT_PASSED=1
    else
        fail "Hot blockchain quick test failed (see /tmp/hot-test.log)"
        HOT_FAILED=1
    fi
    HOT_TESTS=1
    
    print_test "Running cold blockchain quick test"
    if cd "${SCRIPT_DIR}/cold-blockchain" && ./scripts/test-ca-setup.sh --skip-crypto > /tmp/cold-test.log 2>&1; then
        pass "Cold blockchain quick test passed"
        COLD_PASSED=1
    else
        fail "Cold blockchain quick test failed (see /tmp/cold-test.log)"
        COLD_FAILED=1
    fi
    COLD_TESTS=1
else
    print_section "PHASE 7: Running Individual Blockchain Tests (FULL MODE)"
    
    print_test "Running hot blockchain full test with crypto generation"
    echo "  This may take several minutes..."
    if cd "${SCRIPT_DIR}/hot-blockchain" && ./scripts/test-ca-setup.sh > /tmp/hot-test-full.log 2>&1; then
        pass "Hot blockchain full test passed"
        HOT_PASSED=1
    else
        fail "Hot blockchain full test failed (see /tmp/hot-test-full.log)"
        HOT_FAILED=1
    fi
    HOT_TESTS=1
    
    print_test "Running cold blockchain full test with crypto generation"
    echo "  This may take several minutes..."
    if cd "${SCRIPT_DIR}/cold-blockchain" && ./scripts/test-ca-setup.sh > /tmp/cold-test-full.log 2>&1; then
        pass "Cold blockchain full test passed"
        COLD_PASSED=1
    else
        fail "Cold blockchain full test failed (see /tmp/cold-test-full.log)"
        COLD_FAILED=1
    fi
    COLD_TESTS=1
fi

cd "${SCRIPT_DIR}"

# ============================================================================
# PHASE 8: Verify Domain Names
# ============================================================================

print_section "PHASE 8: Domain Name Validation"

print_test "Checking for incorrect .example.com domains"
if grep -r "example\.com" "${SCRIPT_DIR}/hot-blockchain" "${SCRIPT_DIR}/cold-blockchain" --include="*.yaml" --include="*.sh" 2>/dev/null | grep -v "^Binary" | grep -v ".git"; then
    fail "Found .example.com domains (should be .hot.coc.com or .cold.coc.com)"
else
    pass "No .example.com domains found"
fi

print_test "Verifying correct domain usage"
hot_domains=$(grep -r "\.hot\.coc\.com" "${SCRIPT_DIR}/hot-blockchain" --include="*.yaml" 2>/dev/null | wc -l || echo "0")
cold_domains=$(grep -r "\.cold\.coc\.com" "${SCRIPT_DIR}/cold-blockchain" --include="*.yaml" 2>/dev/null | wc -l || echo "0")

if [[ $hot_domains -gt 0 ]]; then
    pass "Hot blockchain uses .hot.coc.com domains ($hot_domains references)"
else
    warn "Hot blockchain may not have proper domain names"
fi

if [[ $cold_domains -gt 0 ]]; then
    pass "Cold blockchain uses .cold.coc.com domains ($cold_domains references)"
else
    warn "Cold blockchain may not have proper domain names"
fi

# ============================================================================
# FINAL SUMMARY
# ============================================================================

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                     COMPREHENSIVE TEST SUMMARY                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Overall Results:${NC}"
echo "  Total tests run: $TOTAL_TESTS"
echo -e "  ${GREEN}Tests passed: $TOTAL_PASSED${NC}"
if [[ $TOTAL_FAILED -gt 0 ]]; then
    echo -e "  ${RED}Tests failed: $TOTAL_FAILED${NC}"
else
    echo -e "  ${GREEN}Tests failed: 0${NC}"
fi
echo ""

echo -e "${BLUE}Hot Blockchain:${NC}"
if [[ $HOT_PASSED -eq 1 ]]; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
elif [[ $HOT_FAILED -eq 1 ]]; then
    echo -e "  ${RED}✗ FAILED (see /tmp/hot-test*.log)${NC}"
else
    echo -e "  ${YELLOW}⚠ NOT TESTED${NC}"
fi

echo -e "${BLUE}Cold Blockchain:${NC}"
if [[ $COLD_PASSED -eq 1 ]]; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
elif [[ $COLD_FAILED -eq 1 ]]; then
    echo -e "  ${RED}✗ FAILED (see /tmp/cold-test*.log)${NC}"
else
    echo -e "  ${YELLOW}⚠ NOT TESTED${NC}"
fi

echo ""

if [[ $TOTAL_FAILED -eq 0 ]] && [[ $HOT_PASSED -eq 1 ]] && [[ $COLD_PASSED -eq 1 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ SUCCESS: All tests passed!                                 ║${NC}"
    echo -e "${GREEN}║  Both hot and cold blockchain configurations are ready.       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Start hot blockchain CAs:"
    echo "     cd hot-blockchain && docker-compose -f docker-compose-ca.yaml up -d"
    echo ""
    echo "  2. Start cold blockchain CAs:"
    echo "     cd cold-blockchain && docker-compose -f docker-compose-ca.yaml up -d"
    echo ""
    echo "  3. Generate crypto material:"
    echo "     cd hot-blockchain && ./scripts/generate-crypto.sh"
    echo "     cd cold-blockchain && ./scripts/generate-crypto.sh"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ FAILURE: Some tests failed                                 ║${NC}"
    echo -e "${RED}║  Please review the errors above and fix before proceeding.    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  - Check log files in /tmp/ for detailed error messages"
    echo "  - Ensure all prerequisites are installed: ./install-prerequisites.sh"
    echo "  - Verify Docker is running: sudo systemctl status docker"
    echo "  - Check file permissions: chmod +x scripts/*.sh"
    echo ""
    exit 1
fi
