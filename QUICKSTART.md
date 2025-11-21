# DFIR Blockchain - Quick Start Guide

**Get the system running in under 10 minutes.**

---

## ⚡ Prerequisites

You need:
- Linux/macOS
- Docker & Docker Compose
- Git
- 8GB+ RAM

**Install Docker:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

---

## 🚀 Deploy

```bash
# 1. Clone repository
git clone https://github.com/omar-kaaki/Dual-hyperledger-Blockchain.git
cd Dual-hyperledger-Blockchain
git checkout claude/backup-012kvMLwmsqnxqfbzsF2HCYJ
chmod +x *.sh

# 2. Initialize blockchain
./nuclear-reset.sh
# Type 'NUCLEAR' when prompted

# 3. Deploy chaincode
./deploy-chaincode.sh

# 4. Start services
docker-compose -f docker-compose-storage.yml up -d
sleep 15
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql 2>/dev/null
docker-compose -f docker-compose-explorers.yml up -d
sleep 30
./launch-webapp.sh
```

---

## 🌐 Access

| Service | URL | Login |
|---------|-----|-------|
| **Dashboard** | http://localhost:5000 | - |
| **Hot Explorer** | http://localhost:8090 | exploreradmin / exploreradminpw |
| **Cold Explorer** | http://localhost:8091 | exploreradmin / exploreradminpw |
| **phpMyAdmin** | http://localhost:8081 | cocuser / cocpassword |

---

## ✅ Verify

```bash
./verify-blockchain.sh
```

**Should show:** 17+ tests passing

---

## 🧪 Test

```bash
# Create investigation
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

**Success:** JSON output with investigation details

---

## 🔧 Troubleshooting

**Everything broken?**
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

**Restart:**
```bash
./restart-blockchain.sh
```

---

## 📖 Full Documentation

See **[SETUP.md](SETUP.md)** for complete instructions including:
- Detailed prerequisite installation
- System architecture explanation
- Advanced troubleshooting
- All available commands

---

**System Check:**
```bash
docker ps | wc -l
# Should show 20+ containers running
```

✅ **You're ready to go!**
