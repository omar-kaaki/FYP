#!/bin/bash
#
# install-prerequisites.sh - Automated installation script for FYP Blockchain
# Hyperledger Fabric v2.5.14 LTS
#
# This script installs all required dependencies for the FYP Blockchain project
# on Kali Linux / Debian-based systems
#
# Usage: ./install-prerequisites.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version configuration
GO_VERSION="1.25.4"
FABRIC_VERSION="2.5.14"
FABRIC_CA_VERSION="1.5.15"
NODE_VERSION="20"
NVM_VERSION="v0.40.0"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  FYP Blockchain - Prerequisites Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "This script will install:"
echo "  - Docker and Docker Compose"
echo "  - Go ${GO_VERSION}"
echo "  - Node.js ${NODE_VERSION}.x LTS (required for Evidence Upload Service)"
echo "  - Hyperledger Fabric ${FABRIC_VERSION} binaries"
echo "  - Hyperledger Fabric CA ${FABRIC_CA_VERSION}"
echo "  - Nginx (HTTPS reverse proxy for IPFS)"
echo "  - Required Docker images (Fabric, CouchDB, IPFS Kubo)"
echo "  - Essential tools (jq, tree, openssl, etc.)"
echo ""
read -p "Continue with installation? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

# Function to print section headers
print_section() {
    echo ""
    echo -e "${YELLOW}>>> $1${NC}"
    echo ""
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root"
        echo "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Function to fix Kali GPG keys
fix_kali_gpg() {
    echo "Attempting to fix Kali GPG keys..."

    # Try multiple methods
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED65462EC8D5E4C5 2>/dev/null || \
    sudo wget -O /etc/apt/trusted.gpg.d/kali-archive-keyring.asc https://archive.kali.org/archive-key.asc 2>/dev/null || \
    sudo apt install --reinstall kali-archive-keyring -y --allow-unauthenticated 2>/dev/null

    # Try update again
    sudo apt update 2>/dev/null
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        OS_VERSION=$VERSION_ID
    else
        OS=$(uname -s)
        OS_VERSION=$(uname -r)
    fi
}

# ============================================================================
# STEP 0: Pre-flight checks
# ============================================================================

check_root
detect_os

echo "Detected OS: $OS"
echo ""

# ============================================================================
# STEP 1: Update System and Install Core Tools
# ============================================================================

print_section "STEP 1: Updating system and installing core tools"

# Try apt update with error handling
if ! sudo apt update 2>&1 | tee /tmp/apt-update.log; then
    print_error "apt update failed"

    # Check if it's a GPG key issue
    if grep -qi "NO_PUBKEY\|not signed" /tmp/apt-update.log; then
        echo ""
        echo "Detected GPG key issue. Attempting to fix..."
        fix_kali_gpg

        # Check if fix worked
        if sudo apt update 2>/dev/null; then
            print_success "GPG key issue resolved"
        else
            print_error "Could not fix GPG key issue automatically"
            echo ""
            echo "You can try manually:"
            echo "  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED65462EC8D5E4C5"
            echo "  sudo apt install --reinstall kali-archive-keyring -y --allow-unauthenticated"
            echo ""
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        echo ""
        read -p "apt update failed. Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Try apt upgrade (optional, continue if fails)
echo "Upgrading packages (this may take a while)..."
sudo apt upgrade -y 2>/dev/null || echo "Warning: apt upgrade had issues, continuing..."

# Install core tools (allow unauthenticated if needed)
echo "Installing core tools..."
if ! sudo apt install -y \
    git \
    curl \
    wget \
    tar \
    unzip \
    jq \
    openssl \
    build-essential \
    tree \
    htop \
    python3 \
    python3-pip 2>/dev/null; then

    echo "Retrying with --allow-unauthenticated..."
    sudo apt install -y --allow-unauthenticated \
        git \
        curl \
        wget \
        tar \
        unzip \
        jq \
        openssl \
        build-essential \
        tree \
        htop \
        python3 \
        python3-pip
fi

print_success "Core tools installed"

# ============================================================================
# STEP 2: Install Docker and Docker Compose
# ============================================================================

print_section "STEP 2: Installing Docker and Docker Compose"

if command_exists docker; then
    print_success "Docker is already installed ($(docker --version))"
else
    if sudo apt install -y docker.io 2>/dev/null || sudo apt install -y --allow-unauthenticated docker.io; then
        sudo systemctl start docker 2>/dev/null || true
        sudo systemctl enable docker 2>/dev/null || true
        print_success "Docker installed successfully"
    else
        print_error "Failed to install Docker"
        echo "Please install Docker manually: https://docs.docker.com/engine/install/"
        exit 1
    fi
fi

if command_exists docker-compose; then
    print_success "Docker Compose is already installed ($(docker-compose --version))"
else
    if sudo apt install -y docker-compose 2>/dev/null || sudo apt install -y --allow-unauthenticated docker-compose; then
        print_success "Docker Compose installed successfully"
    else
        print_error "Failed to install Docker Compose"
        echo "Please install Docker Compose manually"
        exit 1
    fi
fi

# Add user to docker group
if groups $USER | grep &>/dev/null '\bdocker\b'; then
    print_success "User already in docker group"
else
    sudo usermod -aG docker $USER
    print_success "User added to docker group"
    echo -e "${YELLOW}NOTE: You need to log out and back in for docker group changes to take effect${NC}"
    echo -e "${YELLOW}      Or run: newgrp docker${NC}"
fi

# ============================================================================
# STEP 3: Install Go
# ============================================================================

print_section "STEP 3: Installing Go ${GO_VERSION}"

# Function to download with retry
download_with_retry() {
    local url=$1
    local output=$2
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo "Download attempt $attempt/$max_attempts..."
        if wget -q --show-progress "$url" -O "$output" 2>/dev/null || curl -fsSL "$url" -o "$output" 2>/dev/null; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    return 1
}

if command_exists go; then
    CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    if [[ "$CURRENT_GO_VERSION" == "$GO_VERSION" ]]; then
        print_success "Go ${GO_VERSION} is already installed"
    else
        echo "Current Go version: ${CURRENT_GO_VERSION}"
        echo "Installing Go ${GO_VERSION}..."

        cd ~
        if download_with_retry "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" "go${GO_VERSION}.linux-amd64.tar.gz"; then
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
            rm go${GO_VERSION}.linux-amd64.tar.gz
            print_success "Go ${GO_VERSION} installed"
        else
            print_error "Failed to download Go ${GO_VERSION}"
            echo "Please download manually from: https://go.dev/dl/"
            exit 1
        fi
    fi
else
    cd ~
    echo "Downloading Go ${GO_VERSION}..."
    if download_with_retry "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" "go${GO_VERSION}.linux-amd64.tar.gz"; then
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
        rm go${GO_VERSION}.linux-amd64.tar.gz
        print_success "Go ${GO_VERSION} installed"
    else
        print_error "Failed to download Go ${GO_VERSION}"
        echo "Please download manually from: https://go.dev/dl/"
        exit 1
    fi
fi

# Add Go to PATH
if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    print_success "Go added to PATH in ~/.bashrc"
fi

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin

# ============================================================================
# STEP 4: Install Node.js (Required for Evidence Upload Service)
# ============================================================================

print_section "STEP 4: Installing Node.js ${NODE_VERSION}.x LTS"

if command_exists node; then
    CURRENT_NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
    if [[ "$CURRENT_NODE_VERSION" -ge "${NODE_VERSION}" ]]; then
        print_success "Node.js is already installed ($(node --version))"
    else
        echo "Current Node.js version: $(node --version)"
        echo "Upgrading to Node.js ${NODE_VERSION}.x..."

        # Install nvm if not present
        if [ ! -d "$HOME/.nvm" ]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            print_success "nvm installed"
        fi

        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        nvm install ${NODE_VERSION}
        nvm use ${NODE_VERSION}
        nvm alias default ${NODE_VERSION}

        print_success "Node.js ${NODE_VERSION}.x installed"
    fi
else
    # Install nvm
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        print_success "nvm installed"
    fi

    # Install Node.js
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    nvm install ${NODE_VERSION}
    nvm use ${NODE_VERSION}
    nvm alias default ${NODE_VERSION}

    print_success "Node.js ${NODE_VERSION}.x installed"
fi

# Install global packages for development
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command_exists typescript; then
    npm install -g typescript
    print_success "TypeScript installed globally"
else
    print_success "TypeScript is already installed ($(tsc --version))"
fi

if ! command_exists ts-node; then
    npm install -g ts-node
    print_success "ts-node installed globally"
else
    print_success "ts-node is already installed"
fi

# ============================================================================
# STEP 5: Install Hyperledger Fabric Binaries
# ============================================================================

print_section "STEP 5: Installing Hyperledger Fabric ${FABRIC_VERSION} binaries"

# Navigate to project directory
PROJECT_DIR="$HOME/FYPBcoc"
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory not found: $PROJECT_DIR"
    echo "Please clone the repository first:"
    echo "  cd ~"
    echo "  git clone https://github.com/rae81/FYPBcoc.git"
    exit 1
fi

cd "$PROJECT_DIR"

# Download Fabric binaries
if [ -f "bin/fabric-ca-client" ] && [ -f "bin/configtxgen" ] && [ -f "bin/peer" ]; then
    print_success "Fabric binaries already exist in bin/"
else
    curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- binary ${FABRIC_VERSION} ${FABRIC_CA_VERSION}
    print_success "Fabric binaries downloaded to bin/"
fi

# Add to PATH
if ! grep -q "$PROJECT_DIR/bin" ~/.bashrc; then
    echo "export PATH=\$PATH:$PROJECT_DIR/bin" >> ~/.bashrc
    print_success "Fabric binaries added to PATH in ~/.bashrc"
fi

export PATH=$PATH:$PROJECT_DIR/bin

# Copy binaries to system-wide location (optional)
read -p "Copy binaries to /usr/local/bin for system-wide access? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo cp bin/* /usr/local/bin/
    print_success "Binaries copied to /usr/local/bin"
fi

# ============================================================================
# STEP 5.5: Install Nginx (HTTPS Reverse Proxy for IPFS)
# ============================================================================

print_section "STEP 5.5: Installing Nginx"

if command_exists nginx; then
    print_success "Nginx is already installed ($(nginx -v 2>&1))"
else
    sudo apt install -y nginx
    print_success "Nginx installed successfully"
fi

# Enable nginx service
if sudo systemctl is-active --quiet nginx; then
    print_success "Nginx service is running"
else
    sudo systemctl enable nginx
    sudo systemctl start nginx
    print_success "Nginx service enabled and started"
fi

# ============================================================================
# STEP 6: Pull Docker Images
# ============================================================================

print_section "STEP 6: Pulling Hyperledger Fabric Docker images"

# Fabric images
docker pull hyperledger/fabric-peer:${FABRIC_VERSION}
docker pull hyperledger/fabric-orderer:${FABRIC_VERSION}
docker pull hyperledger/fabric-ca:${FABRIC_CA_VERSION}
docker pull hyperledger/fabric-tools:${FABRIC_VERSION}

print_success "Fabric Docker images pulled"

# Tag as latest (optional)
docker tag hyperledger/fabric-peer:${FABRIC_VERSION} hyperledger/fabric-peer:latest
docker tag hyperledger/fabric-orderer:${FABRIC_VERSION} hyperledger/fabric-orderer:latest
docker tag hyperledger/fabric-ca:${FABRIC_CA_VERSION} hyperledger/fabric-ca:latest
docker tag hyperledger/fabric-tools:${FABRIC_VERSION} hyperledger/fabric-tools:latest

print_success "Images tagged as 'latest'"

# ============================================================================
# STEP 7: Pull Additional Docker Images
# ============================================================================

print_section "STEP 7: Pulling additional Docker images"

# CouchDB
docker pull couchdb:3.3
print_success "CouchDB 3.3 image pulled"

# IPFS Kubo (required for evidence storage)
docker pull ipfs/kubo:v0.24.0
docker tag ipfs/kubo:v0.24.0 ipfs/kubo:latest
print_success "IPFS Kubo v0.24.0 image pulled and tagged"

# Nginx (for IPFS reverse proxy)
docker pull nginx:1.25-alpine
print_success "Nginx 1.25 Alpine image pulled"

# PostgreSQL (for Hyperledger Explorer)
docker pull postgres:14-alpine
print_success "PostgreSQL 14 Alpine image pulled"

# Hyperledger Explorer
docker pull hyperledger/explorer:1.1.8
print_success "Hyperledger Explorer 1.1.8 image pulled"

# ============================================================================
# STEP 8: Verification
# ============================================================================

print_section "STEP 8: Verifying installations"

echo "Checking installed versions..."
echo ""

# Docker
if command_exists docker; then
    print_success "Docker: $(docker --version)"
else
    print_error "Docker not found"
fi

# Docker Compose
if command_exists docker-compose; then
    print_success "Docker Compose: $(docker-compose --version)"
else
    print_error "Docker Compose not found"
fi

# Go
if command_exists go; then
    print_success "Go: $(go version)"
else
    print_error "Go not found"
fi

# Node.js
if command_exists node; then
    print_success "Node.js: $(node --version)"
    print_success "npm: $(npm --version)"

    # TypeScript
    if command_exists tsc; then
        print_success "TypeScript: $(tsc --version)"
    else
        print_error "TypeScript not found"
    fi

    # ts-node
    if command_exists ts-node; then
        print_success "ts-node: installed"
    else
        print_error "ts-node not found"
    fi
else
    print_error "Node.js not found"
fi

# Nginx
if command_exists nginx; then
    print_success "Nginx: $(nginx -v 2>&1)"
else
    print_error "Nginx not found"
fi

# Fabric tools
if command_exists fabric-ca-client; then
    print_success "fabric-ca-client: $(fabric-ca-client version | head -1)"
else
    print_error "fabric-ca-client not found"
fi

if command_exists configtxgen; then
    print_success "configtxgen: $(configtxgen --version 2>&1 | head -1)"
else
    print_error "configtxgen not found"
fi

if command_exists peer; then
    print_success "peer: $(peer version 2>&1 | head -1)"
else
    print_error "peer not found"
fi

# Docker images
echo ""
echo "Checking Docker images..."
docker images | grep hyperledger

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}All prerequisites have been installed successfully!${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
echo ""
echo "1. Reload your shell configuration:"
echo "   ${BLUE}source ~/.bashrc${NC}"
echo ""
echo "2. If you added your user to the docker group, log out and back in"
echo "   Or run: ${BLUE}newgrp docker${NC}"
echo ""
echo "3. Verify installations:"
echo "   ${BLUE}docker --version${NC}"
echo "   ${BLUE}docker-compose --version${NC}"
echo "   ${BLUE}go version${NC}"
echo "   ${BLUE}node --version${NC}"
echo "   ${BLUE}tsc --version${NC}"
echo "   ${BLUE}nginx -v${NC}"
echo "   ${BLUE}fabric-ca-client version${NC}"
echo "   ${BLUE}peer version${NC}"
echo ""
echo "4. Run comprehensive tests:"
echo "   ${BLUE}cd ~/FYPBcoc${NC}"
echo "   ${BLUE}./test-all.sh${NC}"
echo ""
echo "5. Build evidence upload service:"
echo "   ${BLUE}cd ~/FYPBcoc/ipfs-storage/evidence-upload-service${NC}"
echo "   ${BLUE}npm install${NC}"
echo "   ${BLUE}npm run build${NC}"
echo ""
echo "6. For deployment instructions, see:"
echo "   - requirements.md (comprehensive guide with Sections 1-8)"
echo "   - requirements.txt (quick reference)"
echo "   - INTEGRATION_JUMPSERVER.md (JumpServer integration)"
echo ""
echo "7. Quick deployment workflow:"
echo "   a. Start CA infrastructure:"
echo "      ${BLUE}cd hot-blockchain && docker-compose -f docker-compose-ca.yaml up -d${NC}"
echo "      ${BLUE}cd cold-blockchain && docker-compose -f docker-compose-ca.yaml up -d${NC}"
echo ""
echo "   b. Generate crypto materials:"
echo "      ${BLUE}cd hot-blockchain && ./scripts/generate-crypto.sh${NC}"
echo "      ${BLUE}cd cold-blockchain && ./scripts/generate-crypto.sh${NC}"
echo ""
echo "   c. Generate channel artifacts:"
echo "      ${BLUE}cd hot-blockchain && ./scripts/generate-channel-artifacts.sh${NC}"
echo "      ${BLUE}cd cold-blockchain && ./scripts/generate-channel-artifacts.sh${NC}"
echo ""
echo "   d. Start blockchain networks:"
echo "      ${BLUE}cd hot-blockchain && ./scripts/start-network.sh${NC}"
echo "      ${BLUE}cd cold-blockchain && ./scripts/start-network.sh${NC}"
echo ""
echo "   e. Deploy chaincode:"
echo "      ${BLUE}cd coc_chaincode && ./build.sh${NC}"
echo "      ${BLUE}cd ../hot-blockchain && ./scripts/deploy-chaincode.sh${NC}"
echo "      ${BLUE}cd ../cold-blockchain && ./scripts/deploy-chaincode.sh${NC}"
echo ""
echo "   f. Start IPFS infrastructure:"
echo "      ${BLUE}cd ipfs-storage && ./start-ipfs.sh${NC}"
echo ""
echo -e "${GREEN}Installation complete! Ready for blockchain deployment.${NC}"
echo ""
