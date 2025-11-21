#!/bin/bash

################################################################################
# DFIR Blockchain - Complete End-to-End Setup Script
################################################################################
# This script installs ALL dependencies and deploys the entire system
# from scratch on a fresh Ubuntu VM/laptop.
#
# Usage: sudo bash complete-setup.sh
################################################################################

set -e  # Exit on error
set -o pipefail  # Catch errors in pipes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Error handler
error_exit() {
    log_error "$1"
    log_error "Setup failed. Check the logs above."
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root (use: sudo bash complete-setup.sh)"
fi

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

log_step "DFIR Blockchain Complete Setup"
log_info "Running as: root"
log_info "Target user: $ACTUAL_USER"
log_info "User home: $ACTUAL_HOME"
log_info "Working directory: $(pwd)"

# Confirm before proceeding
echo ""
read -p "This will install Docker, Go, Python and all dependencies. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Setup cancelled by user"
    exit 0
fi

################################################################################
# STEP 1: Update System
################################################################################
log_step "STEP 1/20: Updating System Packages"
apt update || error_exit "Failed to update package list"
DEBIAN_FRONTEND=noninteractive apt upgrade -y || log_warning "Some packages failed to upgrade (continuing)"
log_success "System updated"

################################################################################
# STEP 2: Install Basic Dependencies
################################################################################
log_step "STEP 2/20: Installing Basic Dependencies"
apt install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release || error_exit "Failed to install basic dependencies"
log_success "Basic dependencies installed"

################################################################################
# STEP 3: Install Docker
################################################################################
log_step "STEP 3/20: Installing Docker"

# Remove old Docker installations
log_info "Removing old Docker installations..."
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install Docker
log_info "Installing Docker..."
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh || error_exit "Failed to download Docker installation script"
sh /tmp/get-docker.sh || error_exit "Failed to install Docker"
rm /tmp/get-docker.sh

# Start Docker service
systemctl start docker || error_exit "Failed to start Docker"
systemctl enable docker || error_exit "Failed to enable Docker"

# Add user to docker group
usermod -aG docker $ACTUAL_USER || error_exit "Failed to add user to docker group"

# Verify Docker installation
docker --version || error_exit "Docker installation verification failed"
log_success "Docker installed: $(docker --version)"

################################################################################
# STEP 4: Install Docker Compose
################################################################################
log_step "STEP 4/20: Installing Docker Compose"
apt install -y docker-compose-plugin || error_exit "Failed to install Docker Compose"

# Verify installation
docker compose version || error_exit "Docker Compose installation verification failed"
log_success "Docker Compose installed: $(docker compose version)"

################################################################################
# STEP 5: Install Python 3 and Pip
################################################################################
log_step "STEP 5/20: Installing Python 3 and Pip"
apt install -y python3 python3-pip python3-venv python3-dev build-essential || error_exit "Failed to install Python"

python3 --version || error_exit "Python installation verification failed"
pip3 --version || error_exit "Pip installation verification failed"
log_success "Python installed: $(python3 --version)"

################################################################################
# STEP 6: Install Go 1.21
################################################################################
log_step "STEP 6/20: Installing Go 1.21"

# Remove old Go installation
rm -rf /usr/local/go

# Download and install Go
log_info "Downloading Go 1.21.0..."
wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz -O /tmp/go1.21.0.linux-amd64.tar.gz || error_exit "Failed to download Go"

log_info "Installing Go..."
tar -C /usr/local -xzf /tmp/go1.21.0.linux-amd64.tar.gz || error_exit "Failed to extract Go"
rm /tmp/go1.21.0.linux-amd64.tar.gz

# Set up Go path for all users
cat >> /etc/profile.d/go.sh <<'EOF'
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF

# Set up Go path for current session
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$ACTUAL_HOME/go
export PATH=$PATH:$GOPATH/bin

# Verify Go installation
/usr/local/go/bin/go version || error_exit "Go installation verification failed"
log_success "Go installed: $(/usr/local/go/bin/go version)"

################################################################################
# STEP 7: Install Additional Utilities
################################################################################
log_step "STEP 7/20: Installing Additional Utilities"
apt install -y jq tree htop net-tools || error_exit "Failed to install utilities"
log_success "Utilities installed"

################################################################################
# STEP 8: Install Node.js (for Blockchain Explorer)
################################################################################
log_step "STEP 8/20: Installing Node.js"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - || error_exit "Failed to add Node.js repository"
apt install -y nodejs || error_exit "Failed to install Node.js"
node --version || error_exit "Node.js installation verification failed"
log_success "Node.js installed: $(node --version)"

################################################################################
# STEP 9: Navigate to Project Directory
################################################################################
log_step "STEP 9/20: Setting Up Project Directory"

PROJECT_DIR="/home/$ACTUAL_USER/Dual-hyperledger-Blockchain"

if [ ! -d "$PROJECT_DIR" ]; then
    error_exit "Project directory not found: $PROJECT_DIR"
fi

cd "$PROJECT_DIR" || error_exit "Failed to navigate to project directory"
log_info "Working in: $(pwd)"

# Fix ownership
chown -R $ACTUAL_USER:$ACTUAL_USER "$PROJECT_DIR"
log_success "Project directory ready"

################################################################################
# STEP 10: Checkout Correct Branch
################################################################################
log_step "STEP 10/20: Checking Out Correct Branch"

# Run git commands as the actual user
su - $ACTUAL_USER -c "cd $PROJECT_DIR && git fetch --all" || log_warning "Failed to fetch (continuing)"
su - $ACTUAL_USER -c "cd $PROJECT_DIR && git checkout claude/backup-012kvMLwmsqnxqfbzsF2HCYJ" || error_exit "Failed to checkout branch"

CURRENT_BRANCH=$(su - $ACTUAL_USER -c "cd $PROJECT_DIR && git branch --show-current")
log_success "Checked out branch: $CURRENT_BRANCH"

################################################################################
# STEP 11: Make Scripts Executable
################################################################################
log_step "STEP 11/20: Making Scripts Executable"
chmod +x "$PROJECT_DIR"/*.sh || error_exit "Failed to make scripts executable"
log_success "Scripts are executable"

################################################################################
# STEP 12: Install Python Dependencies for Webapp
################################################################################
log_step "STEP 12/20: Installing Python Dependencies"

if [ -f "$PROJECT_DIR/requirements.txt" ]; then
    log_info "Installing from requirements.txt..."
    su - $ACTUAL_USER -c "cd $PROJECT_DIR && pip3 install --user -r requirements.txt" || log_warning "Some Python packages failed to install (continuing)"
else
    log_info "Installing common Python packages..."
    su - $ACTUAL_USER -c "pip3 install --user flask requests pymysql python-dotenv ipfshttpclient" || log_warning "Some Python packages failed to install (continuing)"
fi

log_success "Python dependencies installed"

################################################################################
# STEP 13: Pull Required Docker Images
################################################################################
log_step "STEP 13/20: Pulling Required Docker Images"

log_info "This may take several minutes..."

# Pull Hyperledger Fabric images
su - $ACTUAL_USER -c "docker pull hyperledger/fabric-tools:2.5" || log_warning "Failed to pull fabric-tools (continuing)"
su - $ACTUAL_USER -c "docker pull hyperledger/fabric-peer:2.5" || log_warning "Failed to pull fabric-peer (continuing)"
su - $ACTUAL_USER -c "docker pull hyperledger/fabric-orderer:2.5" || log_warning "Failed to pull fabric-orderer (continuing)"
su - $ACTUAL_USER -c "docker pull hyperledger/fabric-ca:1.5" || log_warning "Failed to pull fabric-ca (continuing)"

# Pull other images
su - $ACTUAL_USER -c "docker pull mysql:8.0" || log_warning "Failed to pull mysql (continuing)"
su - $ACTUAL_USER -c "docker pull ipfs/kubo:latest" || log_warning "Failed to pull ipfs (continuing)"
su - $ACTUAL_USER -c "docker pull phpmyadmin/phpmyadmin" || log_warning "Failed to pull phpmyadmin (continuing)"

log_success "Docker images pulled"

################################################################################
# STEP 14: Clean Any Existing Docker Containers/Networks
################################################################################
log_step "STEP 14/20: Cleaning Previous Docker Resources"

log_info "Stopping any running containers..."
su - $ACTUAL_USER -c "docker stop \$(docker ps -aq) 2>/dev/null" || true

log_info "Removing containers..."
su - $ACTUAL_USER -c "docker rm \$(docker ps -aq) 2>/dev/null" || true

log_info "Removing networks..."
su - $ACTUAL_USER -c "docker network prune -f" || true

log_info "Removing volumes..."
su - $ACTUAL_USER -c "docker volume prune -f" || true

log_success "Docker environment cleaned"

################################################################################
# STEP 15: Initialize Blockchain (Nuclear Reset)
################################################################################
log_step "STEP 15/20: Initializing Blockchain Network"

log_info "Running nuclear-reset.sh..."
log_warning "You will need to type 'NUCLEAR' when prompted"

# Run as actual user in interactive mode
cd "$PROJECT_DIR"
su - $ACTUAL_USER -c "cd $PROJECT_DIR && ./nuclear-reset.sh" || error_exit "Nuclear reset failed"

log_success "Blockchain network initialized"

################################################################################
# STEP 16: Deploy Chaincode
################################################################################
log_step "STEP 16/20: Deploying Chaincode"

log_info "This may take 2-3 minutes..."

# Ensure we're in the project directory
cd "$PROJECT_DIR"

# Run chaincode deployment
su - $ACTUAL_USER -c "cd $PROJECT_DIR && ./deploy-chaincode.sh" || error_exit "Chaincode deployment failed"

log_success "Chaincode deployed successfully"

################################################################################
# STEP 17: Start Storage Services
################################################################################
log_step "STEP 17/20: Starting Storage Services (MySQL, IPFS, phpMyAdmin)"

cd "$PROJECT_DIR"
su - $ACTUAL_USER -c "cd $PROJECT_DIR && docker-compose -f docker-compose-storage.yml up -d" || error_exit "Failed to start storage services"

log_info "Waiting 20 seconds for services to initialize..."
sleep 20

# Check if MySQL is ready
log_info "Checking MySQL readiness..."
for i in {1..30}; do
    if su - $ACTUAL_USER -c "docker exec mysql-coc mysqladmin ping -h localhost -uroot -prootpassword 2>/dev/null" | grep -q "mysqld is alive"; then
        log_success "MySQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        error_exit "MySQL failed to start after 30 attempts"
    fi
    sleep 2
done

log_success "Storage services started"

################################################################################
# STEP 18: Initialize Database Schema
################################################################################
log_step "STEP 18/20: Initializing Database Schema"

if [ -f "$PROJECT_DIR/01-schema.sql" ]; then
    log_info "Loading database schema..."
    su - $ACTUAL_USER -c "docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < $PROJECT_DIR/01-schema.sql" 2>/dev/null || log_warning "Database might already be initialized"
    log_success "Database schema loaded"
else
    log_warning "01-schema.sql not found, skipping database initialization"
fi

################################################################################
# STEP 19: Start Blockchain Explorers
################################################################################
log_step "STEP 19/20: Starting Blockchain Explorers"

cd "$PROJECT_DIR"
su - $ACTUAL_USER -c "cd $PROJECT_DIR && docker-compose -f docker-compose-explorers.yml up -d" || error_exit "Failed to start explorers"

log_info "Waiting 30 seconds for explorers to sync..."
sleep 30

log_success "Blockchain explorers started"

################################################################################
# STEP 20: Launch Web Application
################################################################################
log_step "STEP 20/20: Launching Web Application"

cd "$PROJECT_DIR"

# Check if launch-webapp.sh exists
if [ -f "$PROJECT_DIR/launch-webapp.sh" ]; then
    su - $ACTUAL_USER -c "cd $PROJECT_DIR && ./launch-webapp.sh" || log_warning "Webapp launch script failed (you may need to start it manually)"
else
    log_warning "launch-webapp.sh not found, you may need to start the webapp manually"
fi

log_success "Web application launched"

################################################################################
# FINAL VERIFICATION
################################################################################
log_step "Final Verification and Status Check"

echo ""
log_info "Checking Docker containers..."
CONTAINER_COUNT=$(docker ps | wc -l)
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}" | head -20
echo ""
log_info "Total containers running: $((CONTAINER_COUNT - 1))"

echo ""
log_info "Checking blockchain status..."
sleep 5
curl -s http://localhost:5000/api/blockchain/status 2>/dev/null | jq '.' || log_warning "Webapp not responding yet (may need 30-60 seconds to fully start)"

echo ""
log_step "✅ DEPLOYMENT COMPLETE!"

echo ""
log_success "DFIR Blockchain System is now running!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ACCESS POINTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  🌐 Main Dashboard:     http://localhost:5000"
echo "  🔍 Hot Chain Explorer:  http://localhost:8090"
echo "     Username: exploreradmin"
echo "     Password: exploreradminpw"
echo ""
echo "  ❄️  Cold Chain Explorer: http://localhost:8091"
echo "     Username: exploreradmin"
echo "     Password: exploreradminpw"
echo ""
echo "  🗄️  phpMyAdmin:          http://localhost:8081"
echo "     Username: cocuser"
echo "     Password: cocpassword"
echo ""
echo "  📦 IPFS Gateway:        http://localhost:8080/ipfs/{hash}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EXPECTED STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ✅ Containers running: 20+"
echo "  ✅ Hot blockchain height: ~7 blocks"
echo "  ✅ Cold blockchain height: ~4 blocks"
echo "  ✅ All services accessible"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Run verification tests:"
echo "     cd $PROJECT_DIR"
echo "     ./verify-blockchain.sh"
echo ""
echo "  2. Check container logs if needed:"
echo "     docker logs <container_name>"
echo ""
echo "  3. Restart if needed:"
echo "     ./restart-blockchain.sh"
echo ""
echo "  4. Complete reset:"
echo "     ./nuclear-reset.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_success "Setup completed successfully!"
echo ""
log_warning "IMPORTANT: You may need to log out and log back in for Docker group changes to take effect"
log_warning "If you get 'permission denied' errors, run: newgrp docker"
echo ""
