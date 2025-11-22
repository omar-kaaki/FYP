#!/bin/bash
#
# fix-and-setup.sh - Reliable setup script that handles permissions properly
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  FYP Blockchain - Clean Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Get current user
CURRENT_USER=$(whoami)
echo -e "${YELLOW}Running as user: ${CURRENT_USER}${NC}"

# Step 1: Stop all containers
echo -e "${YELLOW}>>> Step 1: Stopping all Docker containers...${NC}"
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
echo -e "${GREEN}✓ Containers stopped${NC}"

# Step 2: Remove old crypto materials
echo -e "${YELLOW}>>> Step 2: Removing old crypto materials...${NC}"
sudo rm -rf "${SCRIPT_DIR}/hot-blockchain/crypto-config"
sudo rm -rf "${SCRIPT_DIR}/cold-blockchain/crypto-config"
sudo rm -rf "${SCRIPT_DIR}/hot-blockchain/.fabric-ca-client"
sudo rm -rf "${SCRIPT_DIR}/cold-blockchain/.fabric-ca-client"
sudo rm -rf "${SCRIPT_DIR}/hot-blockchain/channel-artifacts"
sudo rm -rf "${SCRIPT_DIR}/cold-blockchain/channel-artifacts"
echo -e "${GREEN}✓ Old crypto materials removed${NC}"

# Step 3: Prune Docker volumes
echo -e "${YELLOW}>>> Step 3: Pruning Docker volumes...${NC}"
docker volume prune -f
echo -e "${GREEN}✓ Docker volumes pruned${NC}"

# Step 4: Create directories with correct ownership
echo -e "${YELLOW}>>> Step 4: Creating directories with correct ownership...${NC}"
mkdir -p "${SCRIPT_DIR}/hot-blockchain/crypto-config"
mkdir -p "${SCRIPT_DIR}/cold-blockchain/crypto-config"
mkdir -p "${SCRIPT_DIR}/hot-blockchain/.fabric-ca-client"
mkdir -p "${SCRIPT_DIR}/cold-blockchain/.fabric-ca-client"
echo -e "${GREEN}✓ Directories created${NC}"

# Step 5: Run setup with automatic permission fixes
echo -e "${YELLOW}>>> Step 5: Running setup with permission fixes...${NC}"
echo ""

# Run setup.sh but wrap it to fix permissions after each docker cp
# We'll run setup in background and monitor/fix permissions

# First, let's run setup.sh with sudo to avoid permission issues entirely
echo -e "${YELLOW}Running setup.sh with sudo to handle Docker file permissions...${NC}"
echo ""

sudo -E ./setup.sh --skip-prereq

# Step 6: Fix ownership of all generated files
echo -e "${YELLOW}>>> Step 6: Fixing ownership of generated files...${NC}"
sudo chown -R ${CURRENT_USER}:${CURRENT_USER} "${SCRIPT_DIR}/hot-blockchain/crypto-config" 2>/dev/null || true
sudo chown -R ${CURRENT_USER}:${CURRENT_USER} "${SCRIPT_DIR}/cold-blockchain/crypto-config" 2>/dev/null || true
sudo chown -R ${CURRENT_USER}:${CURRENT_USER} "${SCRIPT_DIR}/hot-blockchain/.fabric-ca-client" 2>/dev/null || true
sudo chown -R ${CURRENT_USER}:${CURRENT_USER} "${SCRIPT_DIR}/cold-blockchain/.fabric-ca-client" 2>/dev/null || true
sudo chown -R ${CURRENT_USER}:${CURRENT_USER} "${SCRIPT_DIR}/hot-blockchain/channel-artifacts" 2>/dev/null || true
sudo chown -R ${CURRENT_USER}:${CURRENT_USER} "${SCRIPT_DIR}/cold-blockchain/channel-artifacts" 2>/dev/null || true
echo -e "${GREEN}✓ Ownership fixed${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "You can now run: ${BLUE}./test-all.sh${NC}"
