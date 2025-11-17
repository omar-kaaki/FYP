#!/bin/bash

# ============================================
# DFIR Blockchain - Complete VM Setup Script
# ============================================
# Run this on a fresh VM with the codebase already copied
# Usage: bash vm-setup.sh

set -e  # Exit on any error

echo "=========================================="
echo "DFIR Blockchain - VM Setup Starting"
echo "=========================================="

# Step 1: Update system
echo "[1/17] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install Docker
echo "[2/17] Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

echo "Docker installed. Version:"
docker --version

# Step 3: Install Docker Compose
echo "[3/17] Installing Docker Compose..."
sudo apt install docker-compose-plugin -y
docker compose version

# Step 4: Install Git
echo "[4/17] Installing Git..."
sudo apt install git -y

# Step 5: Install Python 3 and Pip
echo "[5/17] Installing Python 3 and Pip..."
sudo apt install python3 python3-pip -y

# Step 6: Install Go 1.21
echo "[6/17] Installing Go 1.21..."
wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin
go version

# Step 7: Install additional utilities
echo "[7/17] Installing additional utilities..."
sudo apt install curl jq tree -y

# Step 8: Checkout correct branch
echo "[8/17] Checking out correct branch..."
git checkout claude/backup-012kvMLwmsqnxqfbzsF2HCYJ

# Step 9: Make scripts executable
echo "[9/17] Making scripts executable..."
chmod +x *.sh

# Step 10: Initialize blockchain
echo "[10/17] Initializing blockchain (nuclear reset)..."
echo "You will be prompted to type 'NUCLEAR' to confirm..."
./nuclear-reset.sh

# Step 11: Deploy chaincode
echo "[11/17] Deploying chaincode..."
./deploy-chaincode.sh

# Step 12: Start storage services
echo "[12/17] Starting storage services (MySQL, IPFS, phpMyAdmin)..."
docker-compose -f docker-compose-storage.yml up -d
echo "Waiting 15 seconds for services to initialize..."
sleep 15

# Step 13: Initialize database
echo "[13/17] Initializing database schema..."
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql 2>/dev/null || echo "Database already initialized"

# Step 14: Start explorers
echo "[14/17] Starting blockchain explorers..."
docker-compose -f docker-compose-explorers.yml up -d
echo "Waiting 30 seconds for explorers to sync..."
sleep 30

# Step 15: Launch webapp
echo "[15/17] Launching web application..."
./launch-webapp.sh

# Step 16: Verify deployment
echo "[16/17] Running verification tests..."
./verify-blockchain.sh

# Step 17: Display status
echo "[17/17] Checking system status..."
echo ""
echo "=========================================="
echo "Container Status:"
echo "=========================================="
docker ps --format "table {{.Names}}\t{{.Status}}" | head -15
echo ""
echo "Total containers running:"
docker ps | wc -l

echo ""
echo "=========================================="
echo "Blockchain Status:"
echo "=========================================="
curl -s http://localhost:5000/api/blockchain/status 2>/dev/null | jq '.' || echo "Webapp not responding yet, wait 30 seconds and check http://localhost:5000"

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "Access Points:"
echo "  Main Dashboard:     http://localhost:5000"
echo "  Hot Explorer:       http://localhost:8090 (exploreradmin/exploreradminpw)"
echo "  Cold Explorer:      http://localhost:8091 (exploreradmin/exploreradminpw)"
echo "  phpMyAdmin:         http://localhost:8081 (cocuser/cocpassword)"
echo "  IPFS Gateway:       http://localhost:8080/ipfs/{hash}"
echo ""
echo "Expected Status:"
echo "  - 20+ containers running"
echo "  - Hot blockchain: ~7 blocks"
echo "  - Cold blockchain: ~4 blocks"
echo "  - 17+ tests passing"
echo ""
echo "If you see errors, check logs with:"
echo "  docker logs <container_name>"
echo ""
