#!/bin/bash

# Complete cleanup and restart script
# Removes all volumes, containers, and networks for fresh start

echo "==========================================="
echo "   Complete Blockchain System Cleanup"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}WARNING: This will delete all blockchain data and volumes!${NC}"
echo -e "${YELLOW}Press Ctrl+C within 5 seconds to cancel...${NC}"
sleep 5

echo ""
echo -e "${YELLOW}[1/7] Stopping all containers...${NC}"
docker-compose -f docker-compose-storage.yml down
docker-compose -f docker-compose-hot.yml down
docker-compose -f docker-compose-cold.yml down

echo -e "${YELLOW}[2/7] Removing all containers and orphans...${NC}"
docker-compose -f docker-compose-storage.yml down --remove-orphans 2>/dev/null
docker-compose -f docker-compose-hot.yml down --remove-orphans 2>/dev/null
docker-compose -f docker-compose-cold.yml down --remove-orphans 2>/dev/null

echo -e "${YELLOW}[3/7] Removing all volumes (including chaincode data)...${NC}"
docker-compose -f docker-compose-storage.yml down -v 2>/dev/null
docker-compose -f docker-compose-hot.yml down -v 2>/dev/null
docker-compose -f docker-compose-cold.yml down -v 2>/dev/null

echo -e "${YELLOW}[4/7] Removing chaincode containers...${NC}"
docker rm -f $(docker ps -aq --filter "name=dev-peer") 2>/dev/null || echo "No chaincode containers to remove"

echo -e "${YELLOW}[5/7] Removing chaincode images...${NC}"
docker rmi -f $(docker images -q --filter "reference=dev-peer*") 2>/dev/null || echo "No chaincode images to remove"

echo -e "${YELLOW}[6/7] Removing any leftover networks...${NC}"
docker network rm hot-chain-network cold-chain-network storage-network 2>/dev/null || echo "Networks already removed"

echo -e "${YELLOW}[7/7] Waiting for cleanup to complete...${NC}"
sleep 5

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Cleanup Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Run ./restart-blockchain.sh to start fresh"
echo "  2. Run ./deploy-chaincode.sh to deploy chaincode"
echo "  3. Run ./verify-blockchain.sh to verify"
echo ""
