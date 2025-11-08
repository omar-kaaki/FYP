#!/bin/bash

###############################################################################
# Web Application Launch Script
# Chain of Custody Management Dashboard
###############################################################################

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Chain of Custody Web Dashboard       ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if storage services are running
echo -e "${YELLOW}Checking required services...${NC}"

if ! docker ps | grep -q "ipfs-node"; then
    echo -e "${YELLOW}⚠  IPFS not running. Starting storage services...${NC}"
    docker-compose -f docker-compose-storage.yml up -d
    echo -e "${GREEN}✓ Storage services started${NC}"
    sleep 5
fi

if ! docker ps | grep -q "mysql-coc"; then
    echo -e "${YELLOW}⚠  MySQL not running. Starting storage services...${NC}"
    docker-compose -f docker-compose-storage.yml up -d
    echo -e "${GREEN}✓ Storage services started${NC}"
    sleep 5
fi

echo -e "${GREEN}✓ All required services are running${NC}"
echo ""

# Check if webapp is already running
if pgrep -f "python.*app_blockchain.py" > /dev/null; then
    echo -e "${YELLOW}⚠  Webapp is already running. Stopping it...${NC}"
    pkill -f "python.*app_blockchain.py"
    sleep 2
fi

# Start the Flask webapp
echo -e "${GREEN}Starting Flask web application...${NC}"
cd "$PROJECT_ROOT/webapp"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating Python virtual environment...${NC}"
    python3 -m venv venv
    source venv/bin/activate
    pip install -q flask mysql-connector-python
else
    source venv/bin/activate
fi

# Set environment variables
export FLASK_APP=app_blockchain.py
export FLASK_ENV=development

# Start the app in background
nohup python3 app_blockchain.py > flask.log 2>&1 &
WEBAPP_PID=$!

echo -e "${GREEN}✓ Webapp started (PID: $WEBAPP_PID)${NC}"
echo ""

# Wait for webapp to be ready
echo -e "${YELLOW}Waiting for webapp to initialize...${NC}"
sleep 3

# Check if webapp is responding
if curl -s http://localhost:5000 > /dev/null; then
    echo -e "${GREEN}✓ Webapp is responding${NC}"
else
    echo -e "${YELLOW}⚠  Webapp may still be initializing...${NC}"
fi

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}      Access Your Services              ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${GREEN}📊 Main Dashboard:${NC}"
echo -e "   http://localhost:5000"
echo ""
echo -e "${GREEN}🔍 Blockchain Explorers:${NC}"
echo -e "   Hot Chain:  http://localhost:8090"
echo -e "   Cold Chain: http://localhost:8091"
echo -e "   ${YELLOW}Login - Username: exploreradmin${NC}"
echo -e "   ${YELLOW}Login - Password: exploreradminpw${NC}"
echo ""
echo -e "${GREEN}💾 Storage Services:${NC}"
echo -e "   IPFS Gateway:  http://localhost:8080"
echo -e "   IPFS API:      http://localhost:5001"
echo -e "   phpMyAdmin:    http://localhost:8081"
echo -e "   ${YELLOW}MySQL User: cocuser${NC}"
echo -e "   ${YELLOW}MySQL Pass: cocpassword${NC}"
echo ""
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}To stop the webapp:${NC}"
echo -e "  kill $WEBAPP_PID"
echo -e "  or: pkill -f 'python.*app_blockchain.py'"
echo ""
echo -e "${YELLOW}To view webapp logs:${NC}"
echo -e "  tail -f webapp/flask.log"
echo ""
echo -e "${GREEN}✓ All services ready!${NC}"
echo ""
