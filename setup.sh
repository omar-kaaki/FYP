#!/bin/bash
#
# setup.sh - Master Setup Script for Chain of Custody Blockchain System
# Orchestrates complete deployment from prerequisites to production-ready system
#
# Usage:
#   ./setup.sh               # Full setup
#   ./setup.sh --skip-prereq # Skip prerequisites installation
#   ./setup.sh --clean       # Clean teardown first, then full setup
#   ./setup.sh --test-only   # Run tests only
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

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOT_DIR="${SCRIPT_DIR}/hot-blockchain"
COLD_DIR="${SCRIPT_DIR}/cold-blockchain"
CHAINCODE_DIR="${SCRIPT_DIR}/coc_chaincode"
IPFS_DIR="${SCRIPT_DIR}/ipfs-storage"
EXPLORER_DIR="${SCRIPT_DIR}/explorer"

# Configuration
SKIP_PREREQ=false
CLEAN_FIRST=false
TEST_ONLY=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-prereq)
            SKIP_PREREQ=true
            ;;
        --clean)
            CLEAN_FIRST=true
            ;;
        --test-only)
            TEST_ONLY=true
            ;;
        --help)
            echo "Chain of Custody Blockchain - Master Setup Script"
            echo ""
            echo "Usage:"
            echo "  ./setup.sh               # Full setup from scratch"
            echo "  ./setup.sh --skip-prereq # Skip prerequisites installation"
            echo "  ./setup.sh --clean       # Clean teardown first, then setup"
            echo "  ./setup.sh --test-only   # Run comprehensive tests only"
            echo ""
            echo "What this script does:"
            echo "  1. Install prerequisites (Docker, Go, Node.js, Fabric, etc.)"
            echo "  2. Start CA infrastructure (HOT + COLD chains)"
            echo "  3. Generate crypto materials"
            echo "  4. Generate channel artifacts"
            echo "  5. Start blockchain networks"
            echo "  6. Create and join channels"
            echo "  7. Build and deploy chaincode"
            echo "  8. Build Evidence Upload Service"
            echo "  9. Start IPFS infrastructure"
            echo " 10. Start Hyperledger Explorer"
            echo " 11. Run comprehensive tests"
            echo ""
            exit 0
            ;;
    esac
done

# Banner
print_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                ║${NC}"
    echo -e "${CYAN}║     CHAIN OF CUSTODY BLOCKCHAIN - MASTER SETUP SCRIPT          ║${NC}"
    echo -e "${CYAN}║     Digital Forensics Evidence Management System              ║${NC}"
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

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Cleanup function
cleanup() {
    print_section "CLEANUP: Tearing down existing infrastructure"

    # Stop Explorer
    if [[ -f "${EXPLORER_DIR}/stop-explorer.sh" ]]; then
        print_step "Stopping Hyperledger Explorer..."
        cd "${EXPLORER_DIR}"
        ./stop-explorer.sh <<< "y" || true
        print_success "Explorer stopped"
    fi

    # Stop IPFS
    if [[ -f "${IPFS_DIR}/stop-ipfs.sh" ]]; then
        print_step "Stopping IPFS infrastructure..."
        cd "${IPFS_DIR}"
        ./stop-ipfs.sh <<< "y" || true
        print_success "IPFS stopped"
    fi

    # Stop COLD network
    if [[ -f "${COLD_DIR}/scripts/stop-network.sh" ]]; then
        print_step "Stopping COLD blockchain network..."
        cd "${COLD_DIR}"
        ./scripts/stop-network.sh <<< "y" || true
        print_success "COLD network stopped"
    fi

    # Stop HOT network
    if [[ -f "${HOT_DIR}/scripts/stop-network.sh" ]]; then
        print_step "Stopping HOT blockchain network..."
        cd "${HOT_DIR}"
        ./scripts/stop-network.sh <<< "y" || true
        print_success "HOT network stopped"
    fi

    # Stop CAs
    print_step "Stopping Certificate Authorities..."
    cd "${HOT_DIR}"
    docker-compose -f docker-compose-ca.yaml down -v 2>/dev/null || true
    cd "${COLD_DIR}"
    docker-compose -f docker-compose-ca.yaml down -v 2>/dev/null || true
    print_success "CAs stopped"

    # Clean crypto materials
    print_step "Cleaning crypto materials..."
    rm -rf "${HOT_DIR}/crypto-config/"* 2>/dev/null || true
    rm -rf "${COLD_DIR}/crypto-config/"* 2>/dev/null || true
    rm -rf "${SCRIPT_DIR}/.fabric-ca-client" 2>/dev/null || true
    print_success "Crypto materials cleaned"

    # Clean channel artifacts
    print_step "Cleaning channel artifacts..."
    rm -rf "${HOT_DIR}/channel-artifacts/"* 2>/dev/null || true
    rm -rf "${COLD_DIR}/channel-artifacts/"* 2>/dev/null || true
    print_success "Channel artifacts cleaned"

    print_success "Cleanup complete"
}

# Main setup function
main() {
    print_banner

    # Test-only mode
    if [[ "$TEST_ONLY" == "true" ]]; then
        print_section "RUNNING COMPREHENSIVE TESTS ONLY"
        cd "${SCRIPT_DIR}"
        ./test-all.sh
        exit 0
    fi

    # Clean first if requested
    if [[ "$CLEAN_FIRST" == "true" ]]; then
        cleanup
        echo ""
        print_info "Starting fresh setup in 5 seconds..."
        sleep 5
    fi

    # ========================================================================
    # STEP 1: Install Prerequisites
    # ========================================================================

    if [[ "$SKIP_PREREQ" == "false" ]]; then
        print_section "STEP 1: Installing Prerequisites"
        print_step "Running install-prerequisites.sh..."
        cd "${SCRIPT_DIR}"
        ./install-prerequisites.sh
        print_success "Prerequisites installed"

        # Reload environment
        print_info "Reloading shell environment..."
        export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:${SCRIPT_DIR}/bin"
        source ~/.bashrc 2>/dev/null || true
    else
        print_section "STEP 1: Skipping Prerequisites (--skip-prereq)"
    fi

    # ========================================================================
    # STEP 2: Start Certificate Authorities
    # ========================================================================

    print_section "STEP 2: Starting Certificate Authorities"

    print_step "Starting HOT chain CAs..."
    cd "${HOT_DIR}"
    docker-compose -f docker-compose-ca.yaml up -d
    print_success "HOT chain CAs started"

    print_step "Starting COLD chain CAs..."
    cd "${COLD_DIR}"
    docker-compose -f docker-compose-ca.yaml up -d
    print_success "COLD chain CAs started"

    print_info "Waiting for CAs to initialize (15 seconds)..."
    sleep 15

    # ========================================================================
    # STEP 3: Generate Crypto Materials
    # ========================================================================

    print_section "STEP 3: Generating Crypto Materials"

    print_step "Generating HOT chain crypto materials..."
    cd "${HOT_DIR}/scripts"
    ./generate-crypto.sh
    print_success "HOT chain crypto materials generated"

    print_step "Generating COLD chain crypto materials..."
    cd "${COLD_DIR}/scripts"
    ./generate-crypto.sh
    print_success "COLD chain crypto materials generated"

    # ========================================================================
    # STEP 4: Generate Channel Artifacts
    # ========================================================================

    print_section "STEP 4: Generating Channel Artifacts"

    print_step "Generating HOT chain channel artifacts..."
    cd "${HOT_DIR}/scripts"
    ./generate-channel-artifacts.sh
    print_success "HOT chain channel artifacts generated"

    print_step "Generating COLD chain channel artifacts..."
    cd "${COLD_DIR}/scripts"
    ./generate-channel-artifacts.sh
    print_success "COLD chain channel artifacts generated"

    # ========================================================================
    # STEP 5: Start Blockchain Networks
    # ========================================================================

    print_section "STEP 5: Starting Blockchain Networks"

    print_step "Starting HOT blockchain network..."
    cd "${HOT_DIR}/scripts"
    ./start-network.sh
    print_success "HOT blockchain network started"

    print_step "Starting COLD blockchain network..."
    cd "${COLD_DIR}/scripts"
    ./start-network.sh
    print_success "COLD blockchain network started"

    print_info "Networks are running and channels are created"

    # ========================================================================
    # STEP 6: Build and Deploy Chaincode
    # ========================================================================

    print_section "STEP 6: Building and Deploying Chaincode"

    print_step "Building chaincode..."
    cd "${CHAINCODE_DIR}"
    ./build.sh
    print_success "Chaincode built"

    print_step "Deploying chaincode to HOT chain..."
    cd "${HOT_DIR}/scripts"
    ./deploy-chaincode.sh
    print_success "Chaincode deployed to HOT chain"

    print_step "Deploying chaincode to COLD chain..."
    cd "${COLD_DIR}/scripts"
    ./deploy-chaincode.sh
    print_success "Chaincode deployed to COLD chain"

    # ========================================================================
    # STEP 7: Build Evidence Upload Service
    # ========================================================================

    print_section "STEP 7: Building Evidence Upload Service"

    print_step "Installing Node.js dependencies..."
    cd "${IPFS_DIR}/evidence-upload-service"

    if [[ -f "package.json" ]]; then
        npm install
        print_success "Dependencies installed"

        print_step "Building TypeScript..."
        npm run build
        print_success "Evidence Upload Service built"
    else
        print_error "package.json not found in ${IPFS_DIR}/evidence-upload-service"
    fi

    # ========================================================================
    # STEP 8: Start IPFS Infrastructure
    # ========================================================================

    print_section "STEP 8: Starting IPFS Infrastructure"

    print_step "Starting IPFS (Kubo + Nginx + Upload Service)..."
    cd "${IPFS_DIR}"
    ./start-ipfs.sh
    print_success "IPFS infrastructure started"

    # ========================================================================
    # STEP 9: Start Hyperledger Explorer
    # ========================================================================

    print_section "STEP 9: Starting Hyperledger Explorer"

    print_step "Starting Explorer (PostgreSQL + Explorer UI)..."
    cd "${EXPLORER_DIR}"
    ./start-explorer.sh
    print_success "Hyperledger Explorer started"

    # ========================================================================
    # STEP 10: Run Comprehensive Tests
    # ========================================================================

    print_section "STEP 10: Running Comprehensive Tests"

    print_step "Running test-all.sh..."
    cd "${SCRIPT_DIR}"
    ./test-all.sh

    # ========================================================================
    # FINAL SUMMARY
    # ========================================================================

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║           ✓ SETUP COMPLETE - SYSTEM READY FOR USE!            ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    SYSTEM STATUS SUMMARY                      ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${BLUE}🔗 HOT BLOCKCHAIN (Active Investigation):${NC}"
    echo "   Orderer:      http://localhost:7050"
    echo "   Peer:         http://localhost:7051"
    echo "   CouchDB:      http://localhost:5984"
    echo "   Operations:   http://localhost:9443/healthz"
    echo "   Channel:      hot-chain"
    echo "   Chaincode:    hot_chaincode"
    echo ""

    echo -e "${BLUE}❄️  COLD BLOCKCHAIN (Archival):${NC}"
    echo "   Orderer:        http://localhost:7150"
    echo "   Peer (Lab):     http://localhost:8051"
    echo "   Peer (Court):   http://localhost:9051"
    echo "   CouchDB (Lab):  http://localhost:6984"
    echo "   CouchDB (Court):http://localhost:7984"
    echo "   Operations:     http://localhost:9543/healthz (Lab)"
    echo "                   http://localhost:9643/healthz (Court)"
    echo "   Channel:        cold-chain"
    echo "   Chaincode:      cold_chaincode"
    echo ""

    echo -e "${BLUE}📦 IPFS INFRASTRUCTURE:${NC}"
    echo "   IPFS API:         http://localhost:5001"
    echo "   IPFS API (HTTPS): https://localhost:5443"
    echo "   IPFS Gateway:     http://localhost:8080"
    echo "   Upload Service:   http://localhost:3000"
    echo "   Health:           http://localhost:3000/health"
    echo ""

    echo -e "${BLUE}🔍 HYPERLEDGER EXPLORER:${NC}"
    echo "   Explorer UI:      http://localhost:8090"
    echo "   PostgreSQL:       localhost:5432 (fabricexplorer)"
    echo "   Monitored Chains: hot-chain, cold-chain"
    echo "   Organizations:    LabOrg, CourtOrg, OrdererOrg"
    echo ""

    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                       QUICK START GUIDE                       ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${GREEN}1. View Network in Explorer:${NC}"
    echo "   Open: http://localhost:8090"
    echo "   Select channel: hot-chain or cold-chain"
    echo "   View: Blocks, transactions, chaincodes, organizations"
    echo ""

    echo -e "${GREEN}2. Upload Evidence File:${NC}"
    echo "   curl -X POST http://localhost:3000/api/evidence/upload \\"
    echo "     -F 'file=@test-evidence.txt' \\"
    echo "     -F 'investigationId=inv-001' \\"
    echo "     -F 'description=Test evidence file' \\"
    echo "     -F 'userId=user:investigator1' \\"
    echo "     -F 'userRole=BlockchainInvestigator' \\"
    echo "     -F 'chain=hot'"
    echo ""

    echo -e "${GREEN}3. Query Evidence:${NC}"
    echo "   curl http://localhost:3000/api/evidence/<evidenceId>?chain=hot"
    echo ""

    echo -e "${GREEN}4. Retrieve Evidence File:${NC}"
    echo "   curl http://localhost:3000/api/evidence/<evidenceId>/file?chain=hot \\"
    echo "     --output retrieved-evidence.txt"
    echo ""

    echo -e "${GREEN}5. View Logs:${NC}"
    echo "   HOT Peer:        docker logs -f peer0.laborg.hot.coc.com"
    echo "   COLD Peer (Lab): docker logs -f peer0.laborg.cold.coc.com"
    echo "   IPFS Service:    docker logs -f evidence-upload.coc"
    echo "   Explorer:        docker logs -f explorer.coc"
    echo ""

    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                      MANAGEMENT COMMANDS                      ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}Stop Services:${NC}"
    echo "   cd explorer && ./stop-explorer.sh"
    echo "   cd ipfs-storage && ./stop-ipfs.sh"
    echo "   cd hot-blockchain && ./scripts/stop-network.sh"
    echo "   cd cold-blockchain && ./scripts/stop-network.sh"
    echo ""

    echo -e "${CYAN}Restart Services:${NC}"
    echo "   cd hot-blockchain && ./scripts/start-network.sh"
    echo "   cd cold-blockchain && ./scripts/start-network.sh"
    echo "   cd ipfs-storage && ./start-ipfs.sh"
    echo "   cd explorer && ./start-explorer.sh"
    echo ""

    echo -e "${CYAN}Complete Teardown:${NC}"
    echo "   ./setup.sh --clean"
    echo ""

    echo -e "${CYAN}Comprehensive Testing:${NC}"
    echo "   ./test-all.sh"
    echo ""

    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Chain of Custody System is fully operational!${NC}"
    echo -e "${GREEN}   All components tested and ready for evidence management.${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Run main function
main

