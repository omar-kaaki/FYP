# Complete VM Setup Commands

**Quick deployment on a fresh VM with codebase already copied.**

---

## Option 1: Automated Script (Recommended)

```bash
cd /home/user/Dual-hyperledger-Blockchain
bash vm-setup.sh
```

**Note:** You will be prompted to type `NUCLEAR` during blockchain initialization.

---

## Option 2: Manual Step-by-Step Commands

### Prerequisites Installation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Install Git
sudo apt install git -y

# Install Python 3 and Pip
sudo apt install python3 python3-pip -y

# Install Go 1.21
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install utilities
sudo apt install curl jq tree -y
```

### Blockchain Deployment

```bash
# Navigate to project
cd /home/user/Dual-hyperledger-Blockchain

# Checkout branch
git checkout claude/backup-012kvMLwmsqnxqfbzsF2HCYJ

# Make scripts executable
chmod +x *.sh

# Initialize blockchain (will prompt for 'NUCLEAR')
./nuclear-reset.sh

# Deploy chaincode
./deploy-chaincode.sh

# Start storage services
docker-compose -f docker-compose-storage.yml up -d
sleep 15

# Initialize database
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql 2>/dev/null

# Start explorers
docker-compose -f docker-compose-explorers.yml up -d
sleep 30

# Launch webapp
./launch-webapp.sh

# Verify deployment
./verify-blockchain.sh
```

---

## Verify Installation

```bash
# Check containers (should show 20+)
docker ps | wc -l

# Check webapp status
curl http://localhost:5000/api/blockchain/status | jq

# Check blockchain heights
# Hot: ~7 blocks, Cold: ~4 blocks
```

---

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| **Dashboard** | http://localhost:5000 | None |
| **Hot Explorer** | http://localhost:8090 | exploreradmin / exploreradminpw |
| **Cold Explorer** | http://localhost:8091 | exploreradmin / exploreradminpw |
| **phpMyAdmin** | http://localhost:8081 | cocuser / cocpassword |
| **IPFS Gateway** | http://localhost:8080/ipfs/{hash} | None |

---

## Troubleshooting

**Docker permission denied:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Port already in use:**
```bash
sudo lsof -i :5000
sudo kill -9 <PID>
```

**Complete reset:**
```bash
./stop-all.sh
docker system prune -af
./nuclear-reset.sh
```

**Check logs:**
```bash
docker logs orderer.hot.coc.com
docker logs peer0.lawenforcement.hot.coc.com
```

---

## Expected Timeline

- Prerequisites installation: 5-10 minutes
- Blockchain initialization: 5-10 minutes
- Chaincode deployment: 2-3 minutes
- Storage services startup: 1-2 minutes
- Explorer startup: 1-2 minutes
- **Total: 15-25 minutes**

---

## Post-Installation Test

```bash
# Create test investigation
docker exec cli peer chaincode invoke \
  -C hotchannel -n dfir \
  -c '{"Args":["CreateInvestigation","TEST-001","CASE-001","Test Case","LawEnforcement","Detective","open","","Test investigation",""]}' \
  -o orderer.hot.coc.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/tls/ca.crt \
  --peerAddresses peer0.lawenforcement.hot.coc.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/lawenforcement.hot.coc.com/peers/peer0.lawenforcement.hot.coc.com/tls/ca.crt \
  --peerAddresses peer0.forensiclab.hot.coc.com:8051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/forensiclab.hot.coc.com/peers/peer0.forensiclab.hot.coc.com/tls/ca.crt

# Query investigation
docker exec cli peer chaincode query \
  -C hotchannel -n dfir \
  -c '{"Args":["ReadInvestigation","TEST-001"]}'
```

**Success:** Should return JSON with investigation details.

---

✅ **System is fully operational when all checks pass!**
