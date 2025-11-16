# DFIR Blockchain - Complete Setup Guide

**Digital Forensics & Incident Response - Dual Hyperledger Blockchain System**

This guide will walk you through setting up the complete system from scratch, even if you have nothing installed.

---

## 📋 Table of Contents

1. [System Requirements](#system-requirements)
2. [Install Prerequisites](#install-prerequisites)
3. [Clone the Repository](#clone-the-repository)
4. [Deploy the Blockchain](#deploy-the-blockchain)
5. [Access the System](#access-the-system)
6. [Test the System](#test-the-system)
7. [Troubleshooting](#troubleshooting)

---

## 💻 System Requirements

**Minimum Hardware:**
- CPU: 4 cores
- RAM: 8 GB
- Storage: 20 GB free space
- OS: Linux (Ubuntu 20.04+, Debian, Kali) or macOS

**Recommended:**
- CPU: 8+ cores
- RAM: 16 GB
- Storage: 50 GB SSD

---

## 🛠️ Install Prerequisites

### Step 1: Update Your System

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (avoid using sudo)
sudo usermod -aG docker $USER

# Apply group changes (or logout/login)
newgrp docker

# Verify Docker installation
docker --version
```

**Expected output:** `Docker version 24.0.0 or higher`

### Step 3: Install Docker Compose

```bash
# Docker Compose v2 comes with Docker Desktop
# For standalone installation:
sudo apt install docker-compose-plugin -y

# Verify installation
docker compose version
```

**Expected output:** `Docker Compose version v2.20.0 or higher`

### Step 4: Install Git

```bash
sudo apt install git -y
git --version
```

### Step 5: Install Python 3 and Pip

```bash
sudo apt install python3 python3-pip -y
python3 --version
pip3 --version
```

### Step 6: Install Go (for chaincode compilation)

```bash
# Download and install Go 1.21
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
go version
```

**Expected output:** `go version go1.21.0 linux/amd64`

### Step 7: Install Additional Tools

```bash
# Install curl, jq, and other utilities
sudo apt install curl jq tree -y
```

---

## 📦 Clone the Repository

### Step 1: Clone the Project

```bash
# Clone from GitHub
git clone https://github.com/omar-kaaki/Dual-hyperledger-Blockchain.git

# Navigate to project directory
cd Dual-hyperledger-Blockchain

# Checkout the correct branch
git checkout claude/backup-012kvMLwmsqnxqfbzsF2HCYJ
```

### Step 2: Make Scripts Executable

```bash
# Make all shell scripts executable
chmod +x *.sh
```

---

## 🚀 Deploy the Blockchain

### Step 1: Complete System Reset and Initialization

This will generate all cryptographic material, create channels, and start the blockchains.

```bash
./nuclear-reset.sh
```

**When prompted, type:** `NUCLEAR`

**This script will:**
- ✅ Stop all existing services
- ✅ Clear old blockchain data
- ✅ Generate fresh TLS certificates for all organizations
- ✅ Create genesis blocks for both chains
- ✅ Start hot and cold blockchain networks
- ✅ Join orderers and peers to channels

**Expected time:** 5-10 minutes

**Success indicators:**
```
✓ Hot blockchain started
✓ Cold blockchain started
✓ Hot orderer joined channel
✓ Cold orderer joined channel
✓ Hot channel created
✓ Cold channel created
```

### Step 2: Deploy Chaincode

Deploy the advanced DFIR chaincode (1,861 lines) to both blockchains.

```bash
./deploy-chaincode.sh
```

**This script will:**
- ✅ Package chaincode for hot and cold chains
- ✅ Install on all peers (LawEnforcement, ForensicLab, Auditor)
- ✅ Approve for each organization
- ✅ Commit to channels
- ✅ Initialize ledger with PRV configuration

**Expected time:** 2-3 minutes

**Success indicators:**
```
✓ Installed on Law Enforcement peer
✓ Installed on Forensic Lab peer
✓ Approved for Law Enforcement
✓ Approved for Forensic Lab
✓ Committed to Hot blockchain
✓ Installed on Auditor peer
✓ Approved for Auditor organization
✓ Committed to Cold blockchain
✓ Hot blockchain initialized
✓ Cold blockchain initialized
```

### Step 3: Start Storage Services

Start MySQL, IPFS, and phpMyAdmin.

```bash
# Start storage services
docker-compose -f docker-compose-storage.yml up -d

# Wait for services to initialize
sleep 15

# Initialize the database schema
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql 2>/dev/null || echo "Database already initialized"
```

### Step 4: Start Blockchain Explorers

Start the web-based blockchain explorers.

```bash
# Start explorers
docker-compose -f docker-compose-explorers.yml up -d

# Wait for explorers to sync
sleep 30
```

### Step 5: Launch Web Application

Start the Flask web dashboard.

```bash
./launch-webapp.sh
```

**Success indicator:**
```
✓ Webapp started (PID: xxxxx)
✓ Webapp is responding

📊 Main Dashboard:
   http://localhost:5000
```

---

## 🌐 Access the System

Once all services are running, you can access:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Main Dashboard** | http://localhost:5000 | None |
| **Hot Chain Explorer** | http://localhost:8090 | exploreradmin / exploreradminpw |
| **Cold Chain Explorer** | http://localhost:8091 | exploreradmin / exploreradminpw |
| **phpMyAdmin** | http://localhost:8081 | cocuser / cocpassword |
| **IPFS Gateway** | http://localhost:8080/ipfs/{hash} | None |

---

## 🧪 Test the System

### Test 1: Check All Containers Are Running

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

**Expected containers (20+):**
- orderer.hot.coc.com
- orderer.cold.coc.com
- peer0.lawenforcement.hot.coc.com
- peer0.forensiclab.hot.coc.com
- peer0.auditor.cold.coc.com
- couchdb0, couchdb1, couchdb2
- cli, cli-cold
- mysql-coc
- ipfs-node
- phpmyadmin-coc
- explorer-hot, explorer-cold
- explorerdb-hot, explorerdb-cold
- Chaincode containers (3)

### Test 2: Create an Investigation

```bash
docker exec cli peer chaincode invoke \
  -C hotchannel -n dfir \
  -c '{"Args":["CreateInvestigation","INV-001","CASE-2025-001","Financial Fraud Case","LawEnforcement","Detective Smith","open","","Investigation into financial fraud",""]}' \
  -o orderer.hot.coc.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/tls/ca.crt \
  --peerAddresses peer0.lawenforcement.hot.coc.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/lawenforcement.hot.coc.com/peers/peer0.lawenforcement.hot.coc.com/tls/ca.crt \
  --peerAddresses peer0.forensiclab.hot.coc.com:8051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/forensiclab.hot.coc.com/peers/peer0.forensiclab.hot.coc.com/tls/ca.crt
```

**Success:** `Chaincode invoke successful. result: status:200`

### Test 3: Query the Investigation

```bash
docker exec cli peer chaincode query \
  -C hotchannel -n dfir \
  -c '{"Args":["ReadInvestigation","INV-001"]}'
```

**Expected output:** JSON with investigation details
```json
{
  "ID": "INV-001",
  "CaseNumber": "CASE-2025-001",
  "CaseName": "Financial Fraud Case",
  "InvestigatingOrg": "LawEnforcement",
  "LeadInvestigator": "Detective Smith",
  "Status": "open",
  "Description": "Investigation into financial fraud",
  "EvidenceCount": 0,
  ...
}
```

### Test 4: Create Evidence

```bash
docker exec cli peer chaincode invoke \
  -C hotchannel -n dfir \
  -c '{"Args":["CreateEvidence","EVD-001","INV-001","Digital Evidence","Forensic disk image","abc123hash456","QmTestIPFSHash123","Evidence Room A","Laptop hard drive","1048576"]}' \
  -o orderer.hot.coc.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/tls/ca.crt \
  --peerAddresses peer0.lawenforcement.hot.coc.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/lawenforcement.hot.coc.com/peers/peer0.lawenforcement.hot.coc.com/tls/ca.crt \
  --peerAddresses peer0.forensiclab.hot.coc.com:8051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/forensiclab.hot.coc.com/peers/peer0.forensiclab.hot.coc.com/tls/ca.crt
```

### Test 5: Run Comprehensive Verification

```bash
./verify-blockchain.sh
```

**Expected:** 17+ tests passing

---

## 🔧 Troubleshooting

### Issue: Containers Not Starting

**Check logs:**
```bash
docker logs orderer.hot.coc.com --tail 50
docker logs peer0.lawenforcement.hot.coc.com --tail 50
```

**Restart containers:**
```bash
./restart-blockchain.sh
```

### Issue: Chaincode Errors

**Check chaincode logs:**
```bash
docker logs $(docker ps -q --filter name=dev-peer0.lawenforcement) --tail 50
```

**Redeploy chaincode:**
```bash
./deploy-chaincode.sh
```

### Issue: Permission Denied Errors

**Fix Docker permissions:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Issue: Port Already in Use

**Find and kill process using port:**
```bash
sudo lsof -i :5000
sudo kill -9 <PID>
```

### Issue: Database Connection Errors

**Restart MySQL:**
```bash
docker restart mysql-coc
sleep 10
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql
```

### Complete Reset (Nuclear Option)

If everything is broken, start fresh:

```bash
# Stop everything
./stop-all.sh

# Clean up Docker
docker system prune -af
docker volume prune -f

# Start from Step 1 of deployment
./nuclear-reset.sh
```

---

## 📚 System Architecture

### Hot Blockchain (Active Investigations)
- **Organizations:** LawEnforcement, ForensicLab
- **Peers:** 2 endorsing peers
- **Purpose:** Active case management, evidence collection, custody transfers
- **Consensus:** Both peers must endorse transactions

### Cold Blockchain (Immutable Archive)
- **Organizations:** Auditor
- **Peers:** 1 peer
- **Purpose:** Long-term immutable storage of closed cases
- **Consensus:** Single peer (Auditor)

### Key Features
- ✅ **1,861 lines of production chaincode** with RBAC
- ✅ **4 organizations:** LawEnforcement, ForensicLab, Court, Auditor
- ✅ **mTLS security** on all communications
- ✅ **IPFS integration** for large file storage
- ✅ **MySQL caching** for fast queries
- ✅ **Web dashboard** for easy access
- ✅ **Blockchain explorers** for transparency

---

## 🎯 Quick Start (All-in-One)

If you have all prerequisites installed:

```bash
# Clone and setup
git clone https://github.com/omar-kaaki/Dual-hyperledger-Blockchain.git
cd Dual-hyperledger-Blockchain
git checkout claude/backup-012kvMLwmsqnxqfbzsF2HCYJ
chmod +x *.sh

# Deploy everything
./nuclear-reset.sh              # Type 'NUCLEAR' when prompted
./deploy-chaincode.sh
docker-compose -f docker-compose-storage.yml up -d
sleep 15
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql 2>/dev/null
docker-compose -f docker-compose-explorers.yml up -d
sleep 30
./launch-webapp.sh

# Verify
./verify-blockchain.sh

# Access dashboard
echo "Open http://localhost:5000 in your browser"
```

**Total time:** ~10 minutes

---

## 📞 Support

**Common Commands:**

```bash
# Check all containers
docker ps

# Check logs
docker logs <container_name>

# Restart blockchain
./restart-blockchain.sh

# Stop everything
./stop-all.sh

# Start everything
./start-all.sh

# Verify system
./verify-blockchain.sh
```

**Blockchain Heights:**
- Fresh deployment: Hot chain ~7 blocks, Cold chain ~4 blocks
- This is normal (includes genesis, chaincode deployment, initialization)

---

## 🎓 Learning Resources

- **Hyperledger Fabric Docs:** https://hyperledger-fabric.readthedocs.io/
- **IPFS Docs:** https://docs.ipfs.tech/
- **Docker Docs:** https://docs.docker.com/

---

## 📄 License

Proprietary - Omar Kaaki. All rights reserved.

---

**System Status Check:**
```bash
curl http://localhost:5000/api/blockchain/status 2>/dev/null | jq
```

✅ **If you see blockchain status data, your system is fully operational!**
