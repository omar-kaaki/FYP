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
# PHASE 8: Channel Artifacts Scripts Validation
# ============================================================================

print_section "PHASE 8: Channel Artifacts Scripts Validation"

print_test "Checking channel artifacts scripts exist"

channel_scripts=(
    "hot-blockchain/scripts/generate-channel-artifacts.sh"
    "hot-blockchain/scripts/create-channel.sh"
    "cold-blockchain/scripts/generate-channel-artifacts.sh"
    "cold-blockchain/scripts/create-channel.sh"
)

for script in "${channel_scripts[@]}"; do
    if [[ -f "${SCRIPT_DIR}/$script" ]]; then
        if [[ -x "${SCRIPT_DIR}/$script" ]]; then
            pass "Channel script exists and is executable: $(basename $script)"
        else
            warn "Channel script exists but not executable: $(basename $script)"
        fi
    else
        fail "Channel script missing: $script"
    fi
done

print_test "Validating configtx.yaml can generate artifacts"

# Test hot blockchain configtx.yaml
cd "${SCRIPT_DIR}/hot-blockchain"
export FABRIC_CFG_PATH="${SCRIPT_DIR}/hot-blockchain"
if configtxgen -profile HotChainGenesis -inspectBlock /dev/null 2>&1 | grep -q "HotChainGenesis"; then
    pass "Hot blockchain configtx.yaml is valid (HotChainGenesis profile)"
else
    fail "Hot blockchain configtx.yaml validation failed"
fi

# Test cold blockchain configtx.yaml
cd "${SCRIPT_DIR}/cold-blockchain"
export FABRIC_CFG_PATH="${SCRIPT_DIR}/cold-blockchain"
if configtxgen -profile ColdChainGenesis -inspectBlock /dev/null 2>&1 | grep -q "ColdChainGenesis"; then
    pass "Cold blockchain configtx.yaml is valid (ColdChainGenesis profile)"
else
    fail "Cold blockchain configtx.yaml validation failed"
fi

cd "${SCRIPT_DIR}"

print_test "Checking for existing channel artifacts"

hot_artifacts_exist=false
if [[ -d "${SCRIPT_DIR}/hot-blockchain/channel-artifacts" ]]; then
    artifact_count=$(ls -1 "${SCRIPT_DIR}/hot-blockchain/channel-artifacts"/*.block "${SCRIPT_DIR}/hot-blockchain/channel-artifacts"/*.tx 2>/dev/null | wc -l || echo "0")
    if [[ $artifact_count -gt 0 ]]; then
        pass "Hot blockchain has $artifact_count channel artifact(s)"
        hot_artifacts_exist=true
    else
        info "Hot blockchain channel-artifacts directory exists but is empty"
    fi
else
    info "Hot blockchain channel-artifacts directory does not exist yet"
fi

cold_artifacts_exist=false
if [[ -d "${SCRIPT_DIR}/cold-blockchain/channel-artifacts" ]]; then
    artifact_count=$(ls -1 "${SCRIPT_DIR}/cold-blockchain/channel-artifacts"/*.block "${SCRIPT_DIR}/cold-blockchain/channel-artifacts"/*.tx 2>/dev/null | wc -l || echo "0")
    if [[ $artifact_count -gt 0 ]]; then
        pass "Cold blockchain has $artifact_count channel artifact(s)"
        cold_artifacts_exist=true
    else
        info "Cold blockchain channel-artifacts directory exists but is empty"
    fi
else
    info "Cold blockchain channel-artifacts directory does not exist yet"
fi

# ============================================================================
# PHASE 9: Verify Domain Names
# ============================================================================

print_section "PHASE 9: Domain Name Validation"

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
# PHASE 10: Chaincode Validation
# ============================================================================

print_section "PHASE 10: Chaincode Validation"

print_test "Checking chaincode directory structure"

if [[ -d "${SCRIPT_DIR}/coc_chaincode" ]]; then
    pass "Chaincode directory exists"
else
    fail "Chaincode directory not found"
fi

chaincode_dirs=(
    "coc_chaincode/access"
    "coc_chaincode/rbac"
    "coc_chaincode/domain"
    "coc_chaincode/utils"
)

for dir in "${chaincode_dirs[@]}"; do
    if [[ -d "${SCRIPT_DIR}/$dir" ]]; then
        pass "Directory exists: $dir"
    else
        fail "Directory missing: $dir"
    fi
done

print_test "Checking chaincode source files"

chaincode_files=(
    "coc_chaincode/main.go"
    "coc_chaincode/go.mod"
    "coc_chaincode/build.sh"
    "coc_chaincode/README.md"
    "coc_chaincode/access/casbin_model.conf"
    "coc_chaincode/access/casbin_policy.csv"
    "coc_chaincode/rbac/gateway.go"
    "coc_chaincode/rbac/userroles.go"
    "coc_chaincode/domain/investigation.go"
    "coc_chaincode/domain/evidence.go"
    "coc_chaincode/domain/guidmap.go"
    "coc_chaincode/utils/json.go"
)

for file in "${chaincode_files[@]}"; do
    if [[ -f "${SCRIPT_DIR}/$file" ]]; then
        pass "Source file exists: $(basename $file)"
    else
        fail "Source file missing: $file"
    fi
done

print_test "Checking chaincode deployment scripts"

deploy_scripts=(
    "hot-blockchain/scripts/deploy-chaincode.sh"
    "cold-blockchain/scripts/deploy-chaincode.sh"
)

for script in "${deploy_scripts[@]}"; do
    if [[ -f "${SCRIPT_DIR}/$script" ]]; then
        if [[ -x "${SCRIPT_DIR}/$script" ]]; then
            pass "Deployment script exists and is executable: $(basename $script)"
        else
            warn "Deployment script exists but not executable: $(basename $script)"
        fi
    else
        fail "Deployment script missing: $script"
    fi
done

print_test "Validating go.mod file"

if [[ -f "${SCRIPT_DIR}/coc_chaincode/go.mod" ]]; then
    if grep -q "github.com/casbin/casbin/v2" "${SCRIPT_DIR}/coc_chaincode/go.mod"; then
        pass "Casbin dependency found in go.mod"
    else
        fail "Casbin dependency missing in go.mod"
    fi

    if grep -q "github.com/hyperledger/fabric-chaincode-go" "${SCRIPT_DIR}/coc_chaincode/go.mod"; then
        pass "Fabric chaincode-go dependency found"
    else
        fail "Fabric chaincode-go dependency missing"
    fi

    if grep -q "github.com/hyperledger/fabric-protos-go" "${SCRIPT_DIR}/coc_chaincode/go.mod"; then
        pass "Fabric protos-go dependency found"
    else
        fail "Fabric protos-go dependency missing"
    fi
fi

print_test "Checking Casbin policy configuration"

if [[ -f "${SCRIPT_DIR}/coc_chaincode/access/casbin_policy.csv" ]]; then
    policy_lines=$(grep -c "^p," "${SCRIPT_DIR}/coc_chaincode/access/casbin_policy.csv" || echo "0")
    if [[ $policy_lines -gt 0 ]]; then
        pass "Casbin policy has $policy_lines permission rules"
    else
        fail "No permission rules found in Casbin policy"
    fi

    # Check for required roles
    if grep -q "BlockchainInvestigator" "${SCRIPT_DIR}/coc_chaincode/access/casbin_policy.csv"; then
        pass "BlockchainInvestigator role defined"
    fi

    if grep -q "BlockchainAuditor" "${SCRIPT_DIR}/coc_chaincode/access/casbin_policy.csv"; then
        pass "BlockchainAuditor role defined"
    fi

    if grep -q "BlockchainCourt" "${SCRIPT_DIR}/coc_chaincode/access/casbin_policy.csv"; then
        pass "BlockchainCourt role defined"
    fi

    if grep -q "SystemAdmin" "${SCRIPT_DIR}/coc_chaincode/access/casbin_policy.csv"; then
        pass "SystemAdmin role defined"
    fi
fi

print_test "Checking chaincode build script"

if [[ -f "${SCRIPT_DIR}/coc_chaincode/build.sh" ]]; then
    if [[ -x "${SCRIPT_DIR}/coc_chaincode/build.sh" ]]; then
        pass "Build script is executable"
    else
        warn "Build script exists but not executable"
    fi

    if grep -q "go mod tidy" "${SCRIPT_DIR}/coc_chaincode/build.sh"; then
        pass "Build script includes go mod tidy"
    fi

    if grep -q "go mod vendor" "${SCRIPT_DIR}/coc_chaincode/build.sh"; then
        pass "Build script includes go mod vendor"
    fi
fi

print_test "Checking chaincode function implementations"

if [[ -f "${SCRIPT_DIR}/coc_chaincode/main.go" ]]; then
    # Check for key functions
    functions=(
        "SetUserRoles"
        "GetUserRoles"
        "CreateInvestigation"
        "AddEvidence"
        "ArchiveInvestigation"
        "CreateGUIDMapping"
    )

    for func in "${functions[@]}"; do
        if grep -q "func.*${func}" "${SCRIPT_DIR}/coc_chaincode/main.go"; then
            pass "Function implemented: ${func}"
        else
            # Check in domain files
            if grep -q "func.*${func}" "${SCRIPT_DIR}/coc_chaincode/domain/"*.go 2>/dev/null; then
                pass "Function implemented: ${func}"
            else
                warn "Function may be missing: ${func}"
            fi
        fi
    done
fi

print_test "Checking gateway identity validation"

if [[ -f "${SCRIPT_DIR}/coc_chaincode/rbac/gateway.go" ]]; then
    if grep -q "TrustedGatewayMSPID.*LabOrgMSP" "${SCRIPT_DIR}/coc_chaincode/rbac/gateway.go"; then
        pass "Gateway MSPID validation configured"
    fi

    if grep -q "TrustedGatewayCN.*lab-gw" "${SCRIPT_DIR}/coc_chaincode/rbac/gateway.go"; then
        pass "Gateway CN validation configured"
    fi

    if grep -q "ValidateGatewayIdentity" "${SCRIPT_DIR}/coc_chaincode/rbac/gateway.go"; then
        pass "Gateway identity validation function exists"
    fi
fi

# ============================================================================
# PHASE 11: Network Deployment Validation
# ============================================================================

print_section "PHASE 11: Network Deployment Validation"

# Hot blockchain network deployment
print_test "Hot blockchain docker-compose-network.yaml exists"
if [[ -f "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml" ]]; then
    pass "Found hot-blockchain/docker-compose-network.yaml"
else
    fail "Missing hot-blockchain/docker-compose-network.yaml"
fi

print_test "Hot blockchain network scripts exist"
if [[ -f "${SCRIPT_DIR}/hot-blockchain/scripts/start-network.sh" ]] && \
   [[ -f "${SCRIPT_DIR}/hot-blockchain/scripts/stop-network.sh" ]]; then
    pass "Found hot blockchain network scripts"
else
    fail "Missing hot blockchain network scripts"
fi

# Cold blockchain network deployment
print_test "Cold blockchain docker-compose-network.yaml exists"
if [[ -f "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" ]]; then
    pass "Found cold-blockchain/docker-compose-network.yaml"
else
    fail "Missing cold-blockchain/docker-compose-network.yaml"
fi

print_test "Cold blockchain network scripts exist"
if [[ -f "${SCRIPT_DIR}/cold-blockchain/scripts/start-network.sh" ]] && \
   [[ -f "${SCRIPT_DIR}/cold-blockchain/scripts/stop-network.sh" ]]; then
    pass "Found cold blockchain network scripts"
else
    fail "Missing cold blockchain network scripts"
fi

# Validate hot-blockchain docker-compose configuration
print_test "Hot blockchain network configuration validation"
if grep -q "orderer.hot.coc.com" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml" && \
   grep -q "peer0.laborg.hot.coc.com" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml" && \
   grep -q "couchdb.peer0.laborg.hot.coc.com" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml" && \
   grep -q "ORDERER_GENERAL_TLS_CLIENTAUTHREQUIRED=true" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml" && \
   grep -q "CORE_PEER_TLS_CLIENTAUTHREQUIRED=true" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml" && \
   grep -q "CORE_PEER_GATEWAY_ENABLED=true" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml"; then
    pass "Hot blockchain network configuration is valid (orderer, peer, CouchDB, mTLS, gateway)"
else
    fail "Hot blockchain network configuration is incomplete"
fi

# Validate cold-blockchain docker-compose configuration
print_test "Cold blockchain network configuration validation"
if grep -q "orderer.cold.coc.com" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "peer0.laborg.cold.coc.com" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "peer0.courtorg.cold.coc.com" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "couchdb.peer0.laborg.cold.coc.com" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "couchdb.peer0.courtorg.cold.coc.com" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "ORDERER_GENERAL_TLS_CLIENTAUTHREQUIRED=true" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "CORE_PEER_TLS_CLIENTAUTHREQUIRED=true" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml"; then
    pass "Cold blockchain network configuration is valid (orderer, 2 peers, 2 CouchDBs, mTLS)"
else
    fail "Cold blockchain network configuration is incomplete"
fi

# Validate port mappings
print_test "Hot blockchain port mappings"
if grep -q "7050:7050" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml" && \
   grep -q "7051:7051" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml" && \
   grep -q "5984:5984" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml"; then
    pass "Hot blockchain port mappings are correct"
else
    fail "Hot blockchain port mappings are incorrect"
fi

print_test "Cold blockchain port mappings"
if grep -q "7150:7150" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "8051:8051" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "9051:9051" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "6984:5984" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml" && \
   grep -q "7984:5984" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml"; then
    pass "Cold blockchain port mappings are correct (no conflicts)"
else
    fail "Cold blockchain port mappings are incorrect"
fi

# ============================================================================
# PHASE 12: IPFS Infrastructure Validation
# ============================================================================

print_section "PHASE 12: IPFS Infrastructure Validation"

print_test "IPFS docker-compose configuration exists"
if [[ -f "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" ]]; then
    pass "Found ipfs-storage/docker-compose-ipfs.yaml"
else
    fail "Missing ipfs-storage/docker-compose-ipfs.yaml"
fi

print_test "IPFS startup/shutdown scripts exist"
if [[ -f "${SCRIPT_DIR}/ipfs-storage/start-ipfs.sh" ]] && \
   [[ -f "${SCRIPT_DIR}/ipfs-storage/stop-ipfs.sh" ]]; then
    pass "Found IPFS management scripts"
else
    fail "Missing IPFS management scripts"
fi

print_test "Nginx reverse proxy configuration exists"
if [[ -f "${SCRIPT_DIR}/ipfs-storage/nginx/nginx.conf" ]] && \
   [[ -f "${SCRIPT_DIR}/ipfs-storage/nginx/generate-ssl.sh" ]]; then
    pass "Found Nginx reverse proxy configuration"
else
    fail "Missing Nginx reverse proxy configuration"
fi

# Validate IPFS docker-compose configuration
print_test "IPFS infrastructure configuration validation"
if grep -q "ipfs.coc" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" && \
   grep -q "ipfs-proxy.coc" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" && \
   grep -q "evidence-upload.coc" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" && \
   grep -q "ipfs/kubo" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml"; then
    pass "IPFS infrastructure configuration is valid"
else
    fail "IPFS infrastructure configuration is incomplete"
fi

# Validate evidence upload service
print_test "Evidence upload service exists"
if [[ -d "${SCRIPT_DIR}/ipfs-storage/evidence-upload-service" ]]; then
    pass "Found evidence-upload-service directory"
else
    fail "Missing evidence-upload-service directory"
fi

print_test "Evidence upload service package.json exists"
if [[ -f "${SCRIPT_DIR}/ipfs-storage/evidence-upload-service/package.json" ]]; then
    pass "Found evidence-upload-service/package.json"
else
    fail "Missing evidence-upload-service/package.json"
fi

print_test "Evidence upload service source files exist"
SRC_FILES=(
    "src/index.ts"
    "src/config.ts"
    "src/utils/logger.ts"
    "src/utils/hash.ts"
    "src/services/ipfs.ts"
    "src/services/fabric.ts"
)
MISSING_FILES=0
for file in "${SRC_FILES[@]}"; do
    if [[ ! -f "${SCRIPT_DIR}/ipfs-storage/evidence-upload-service/$file" ]]; then
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done
if [[ $MISSING_FILES -eq 0 ]]; then
    pass "All evidence upload service source files exist (${#SRC_FILES[@]} files)"
else
    fail "Missing $MISSING_FILES evidence upload service source files"
fi

print_test "Evidence upload service Dockerfile exists"
if [[ -f "${SCRIPT_DIR}/ipfs-storage/evidence-upload-service/Dockerfile" ]]; then
    pass "Found evidence-upload-service/Dockerfile"
else
    fail "Missing evidence-upload-service/Dockerfile"
fi

# Validate package dependencies
print_test "Evidence upload service dependencies validation"
if grep -q "@hyperledger/fabric-gateway" "${SCRIPT_DIR}/ipfs-storage/evidence-upload-service/package.json" && \
   grep -q "ipfs-http-client" "${SCRIPT_DIR}/ipfs-storage/evidence-upload-service/package.json" && \
   grep -q "express" "${SCRIPT_DIR}/ipfs-storage/evidence-upload-service/package.json" && \
   grep -q "multer" "${SCRIPT_DIR}/ipfs-storage/evidence-upload-service/package.json"; then
    pass "Required dependencies are declared (Fabric Gateway, IPFS, Express, Multer)"
else
    fail "Missing required dependencies in package.json"
fi

# Validate service endpoints in docker-compose
print_test "IPFS service endpoints validation"
if grep -q "3000:3000" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" && \
   grep -q "5001:5001" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" && \
   grep -q "5443:443" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml"; then
    pass "IPFS service endpoints are correctly configured"
else
    fail "IPFS service endpoint configuration is incorrect"
fi

# Validate network connectivity
print_test "IPFS infrastructure network connectivity"
if grep -q "cold-network" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" && \
   grep -q "hot-network" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" && \
   grep -q "ipfs-network" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml"; then
    pass "IPFS infrastructure is configured to connect to both blockchain networks"
else
    fail "IPFS infrastructure network configuration is incomplete"
fi

# Validate volume mounts for Fabric crypto materials
print_test "Evidence upload service Fabric crypto material mounts"
if grep -q "hot-blockchain/crypto-config" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" && \
   grep -q "cold-blockchain/crypto-config" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml" && \
   grep -q "lab-gw@laborg" "${SCRIPT_DIR}/ipfs-storage/docker-compose-ipfs.yaml"; then
    pass "Fabric crypto materials are mounted correctly (hot + cold, lab-gw identity)"
else
    fail "Fabric crypto material mounts are incomplete"
fi

# ============================================================================
# PHASE 13: Integration Documentation Validation
# ============================================================================

print_section "PHASE 13: Integration Documentation Validation"

print_test "JumpServer integration documentation exists"
if [[ -f "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md" ]]; then
    pass "Found INTEGRATION_JUMPSERVER.md"
else
    fail "Missing INTEGRATION_JUMPSERVER.md"
fi

print_test "Integration documentation completeness"
if grep -q "Evidence Upload Workflow" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md" && \
   grep -q "API Endpoints" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md" && \
   grep -q "Authentication and Security" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md" && \
   grep -q "Testing" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md" && \
   grep -q "Troubleshooting" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md"; then
    pass "Integration documentation is complete"
else
    fail "Integration documentation is incomplete"
fi

print_test "Integration documentation covers REST API"
if grep -q "POST /api/evidence/upload" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md" && \
   grep -q "GET /api/evidence/:evidenceId" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md" && \
   grep -q "GET /api/evidence/:evidenceId/file" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md"; then
    pass "Integration documentation covers all REST API endpoints"
else
    fail "Integration documentation is missing API endpoint details"
fi

print_test "Integration documentation includes curl examples"
if grep -q "curl -X POST" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md" && \
   grep -q "multipart/form-data" "${SCRIPT_DIR}/INTEGRATION_JUMPSERVER.md"; then
    pass "Integration documentation includes curl examples"
else
    fail "Integration documentation is missing curl examples"
fi

# ============================================================================
# PHASE 14: Hyperledger Explorer Validation
# ============================================================================

print_section "PHASE 14: Hyperledger Explorer Validation"

print_test "Explorer directory exists"
if [[ -d "${SCRIPT_DIR}/explorer" ]]; then
    pass "Found explorer/ directory"
else
    fail "Missing explorer/ directory"
fi

print_test "Explorer configuration files exist"
if [[ -f "${SCRIPT_DIR}/explorer/config.json" ]] && \
   [[ -f "${SCRIPT_DIR}/explorer/connection-profile/coc-network.json" ]]; then
    pass "Found Explorer configuration files"
else
    fail "Missing Explorer configuration files"
fi

print_test "Explorer docker-compose exists"
if [[ -f "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml" ]]; then
    pass "Found docker-compose-explorer.yaml"
else
    fail "Missing docker-compose-explorer.yaml"
fi

print_test "Explorer management scripts exist"
if [[ -f "${SCRIPT_DIR}/explorer/start-explorer.sh" ]] && \
   [[ -f "${SCRIPT_DIR}/explorer/stop-explorer.sh" ]]; then
    pass "Found Explorer management scripts"
else
    fail "Missing Explorer management scripts"
fi

print_test "Explorer configuration validation"
if grep -q "coc-network" "${SCRIPT_DIR}/explorer/config.json" && \
   grep -q "postgres-explorer" "${SCRIPT_DIR}/explorer/config.json" && \
   grep -q "fabricexplorer" "${SCRIPT_DIR}/explorer/config.json"; then
    pass "Explorer configuration is valid"
else
    fail "Explorer configuration is incomplete"
fi

print_test "Explorer connection profile validation"
if grep -q "hot-chain" "${SCRIPT_DIR}/explorer/connection-profile/coc-network.json" && \
   grep -q "cold-chain" "${SCRIPT_DIR}/explorer/connection-profile/coc-network.json" && \
   grep -q "LabOrgMSP" "${SCRIPT_DIR}/explorer/connection-profile/coc-network.json" && \
   grep -q "CourtOrgMSP" "${SCRIPT_DIR}/explorer/connection-profile/coc-network.json" && \
   grep -q "OrdererOrgMSP" "${SCRIPT_DIR}/explorer/connection-profile/coc-network.json"; then
    pass "Connection profile includes both chains and all organizations"
else
    fail "Connection profile is incomplete"
fi

print_test "Explorer peer endpoints validation"
if grep -q "peer0.laborg.hot.coc.com" "${SCRIPT_DIR}/explorer/connection-profile/coc-network.json" && \
   grep -q "peer0.laborg.cold.coc.com" "${SCRIPT_DIR}/explorer/connection-profile/coc-network.json" && \
   grep -q "peer0.courtorg.cold.coc.com" "${SCRIPT_DIR}/explorer/connection-profile/coc-network.json"; then
    pass "All peer endpoints configured (hot + cold, LabOrg + CourtOrg)"
else
    fail "Missing peer endpoints in connection profile"
fi

print_test "Explorer docker-compose services validation"
if grep -q "postgres-explorer" "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml" && \
   grep -q "explorer" "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml" && \
   grep -q "postgres:14-alpine" "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml" && \
   grep -q "hyperledger/explorer" "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml"; then
    pass "Explorer docker-compose includes PostgreSQL and Explorer services"
else
    fail "Explorer docker-compose services incomplete"
fi

print_test "Explorer network connectivity validation"
if grep -q "hot-network" "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml" && \
   grep -q "cold-network" "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml" && \
   grep -q "explorer-network" "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml"; then
    pass "Explorer configured to connect to both blockchain networks"
else
    fail "Explorer network configuration incomplete"
fi

print_test "Explorer crypto material mounts validation"
if grep -q "hot-blockchain/crypto-config" "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml" && \
   grep -q "cold-blockchain/crypto-config" "${SCRIPT_DIR}/explorer/docker-compose-explorer.yaml"; then
    pass "Explorer has access to crypto materials from both chains"
else
    fail "Explorer crypto material mounts incomplete"
fi

# ============================================================================
# PHASE 15: Database Configuration Validation
# ============================================================================

print_section "PHASE 15: Database Configuration Validation"

print_test "Database configuration documentation exists"
if [[ -f "${SCRIPT_DIR}/DATABASE_CONFIGURATION.md" ]]; then
    pass "Found DATABASE_CONFIGURATION.md"
else
    fail "Missing DATABASE_CONFIGURATION.md"
fi

print_test "Database documentation completeness"
if grep -q "Block Storage" "${SCRIPT_DIR}/DATABASE_CONFIGURATION.md" && \
   grep -q "World State Database" "${SCRIPT_DIR}/DATABASE_CONFIGURATION.md" && \
   grep -q "LevelDB" "${SCRIPT_DIR}/DATABASE_CONFIGURATION.md" && \
   grep -q "CouchDB" "${SCRIPT_DIR}/DATABASE_CONFIGURATION.md"; then
    pass "Database documentation covers both LevelDB and CouchDB"
else
    fail "Database documentation is incomplete"
fi

print_test "CouchDB configuration in network docker-compose"
if grep -q "CORE_LEDGER_STATE_STATEDATABASE=CouchDB" "${SCRIPT_DIR}/hot-blockchain/docker-compose-network.yaml" && \
   grep -q "CORE_LEDGER_STATE_STATEDATABASE=CouchDB" "${SCRIPT_DIR}/cold-blockchain/docker-compose-network.yaml"; then
    pass "CouchDB configured for world state on both chains"
else
    fail "CouchDB configuration missing or incomplete"
fi

# ============================================================================
# PHASE 16: Master Setup Script Validation
# ============================================================================

print_section "PHASE 16: Master Setup Script Validation"

print_test "Master setup script exists"
if [[ -f "${SCRIPT_DIR}/setup.sh" ]]; then
    pass "Found setup.sh"
else
    fail "Missing setup.sh"
fi

print_test "Setup script is executable"
if [[ -x "${SCRIPT_DIR}/setup.sh" ]]; then
    pass "setup.sh is executable"
else
    fail "setup.sh is not executable"
fi

print_test "Setup script includes all deployment phases"
if grep -q "Install Prerequisites" "${SCRIPT_DIR}/setup.sh" && \
   grep -q "Certificate Authorities" "${SCRIPT_DIR}/setup.sh" && \
   grep -q "Crypto Materials" "${SCRIPT_DIR}/setup.sh" && \
   grep -q "Channel Artifacts" "${SCRIPT_DIR}/setup.sh" && \
   grep -q "Blockchain Networks" "${SCRIPT_DIR}/setup.sh" && \
   grep -q "Deploy Chaincode" "${SCRIPT_DIR}/setup.sh" && \
   grep -q "Evidence Upload Service" "${SCRIPT_DIR}/setup.sh" && \
   grep -q "IPFS Infrastructure" "${SCRIPT_DIR}/setup.sh" && \
   grep -q "Hyperledger Explorer" "${SCRIPT_DIR}/setup.sh" && \
   grep -q "Comprehensive Tests" "${SCRIPT_DIR}/setup.sh"; then
    pass "Setup script includes all 10 deployment phases"
else
    fail "Setup script is missing some deployment phases"
fi

print_test "Setup script command-line options"
if grep -q -- "--skip-prereq" "${SCRIPT_DIR}/setup.sh" && \
   grep -q -- "--clean" "${SCRIPT_DIR}/setup.sh" && \
   grep -q -- "--test-only" "${SCRIPT_DIR}/setup.sh" && \
   grep -q -- "--help" "${SCRIPT_DIR}/setup.sh"; then
    pass "Setup script supports all command-line options"
else
    fail "Setup script missing some command-line options"
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
    echo "  4. Generate channel artifacts:"
    echo "     cd hot-blockchain && ./scripts/generate-channel-artifacts.sh"
    echo "     cd cold-blockchain && ./scripts/generate-channel-artifacts.sh"
    echo ""
    echo "  5. Start network and create channels:"
    echo "     cd hot-blockchain && ./scripts/create-channel.sh"
    echo "     cd cold-blockchain && ./scripts/create-channel.sh"
    echo ""
    echo "  6. Build and deploy chaincode:"
    echo "     cd coc_chaincode && ./build.sh"
    echo "     cd ../hot-blockchain && ./scripts/deploy-chaincode.sh"
    echo "     cd ../cold-blockchain && ./scripts/deploy-chaincode.sh"
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
