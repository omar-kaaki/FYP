#!/bin/bash

echo "========================================"
echo "Starting Hyperledger Explorers"
echo "========================================"
echo ""

# Check if blockchains are running
if ! docker ps | grep -q "peer0.lawenforcement.hot.coc.com"; then
    echo "❌ Error: Hot blockchain is not running!"
    echo "   Please run ./restart-blockchain.sh first"
    exit 1
fi

if ! docker ps | grep -q "peer0.archive.cold.coc.com"; then
    echo "❌ Error: Cold blockchain is not running!"
    echo "   Please run ./restart-blockchain.sh first"
    exit 1
fi

echo "✓ Blockchains are running"
echo ""

# Start explorers
echo "Starting explorer services..."
docker-compose -f docker-compose-explorers.yml up -d

echo ""
echo "Waiting for explorer databases to initialize (30 seconds)..."
sleep 30

echo ""
echo "========================================"
echo "✅ Explorers Started Successfully!"
echo "========================================"
echo ""
echo "Access the explorers at:"
echo ""
echo "  🔥 Hot Chain Explorer:  http://localhost:8090"
echo "  ❄️  Cold Chain Explorer: http://localhost:8091"
echo ""
echo "Login credentials:"
echo "  Username: exploreradmin"
echo "  Password: exploreradminpw"
echo ""
echo "Note: First-time startup may take 1-2 minutes to sync"
echo "========================================"
