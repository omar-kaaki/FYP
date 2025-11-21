# Troubleshooting Guide - Common Issues & Solutions

Quick reference for resolving common deployment and runtime issues.

---

## 🚨 Chaincode Deployment Errors

### Error: "failed to normalize chaincode path"

```
Error: failed to normalize chaincode path: 'go list' failed with: go: inconsistent vendoring
```

**Solution:**
```bash
cd hot-blockchain/chaincode
go mod tidy && go mod vendor
cd ../../cold-blockchain/chaincode
go mod tidy && go mod vendor
cd ../..

# Retry deployment
./deploy-chaincode.sh
```

---

### Error: "requested sequence is 1, but new definition must be sequence 2"

```
Error: requested sequence is 1, but new definition must be sequence 2
```

**Cause:** Chaincode was already deployed. Sequence must increment.

**Solution 1 - Fresh Start (Recommended):**
```bash
./nuclear-reset.sh
./deploy-chaincode.sh  # Will use sequence 1
```

**Solution 2 - Upgrade Existing:**
```bash
# Edit deploy-chaincode.sh
nano deploy-chaincode.sh

# Change line 20:
CC_SEQUENCE=2  # or 3, 4, etc.

# Redeploy
./deploy-chaincode.sh
```

---

### Error: "ENDORSEMENT_POLICY_FAILURE"

```
Error: transaction invalidated with status (ENDORSEMENT_POLICY_FAILURE)
```

**Cause:** Organization without peers is in channel definition.

**Solution:**
```bash
# Check hot-blockchain/configtx.yaml
# Under HotChainChannel -> Application -> Organizations
# Should ONLY have:
#   - *LawEnforcement
#   - *ForensicLab
# NOT Court or Auditor (they're client-only)

# Check cold-blockchain/configtx.yaml
# Under ColdChainChannel -> Application -> Organizations
# Should ONLY have:
#   - *Auditor
# NOT Court

# If wrong, fix and run:
./nuclear-reset.sh
./deploy-chaincode.sh
```

---

### Error: "attestation check failed: insufficient verifiers"

```
Error: endorsement failure during invoke. response: status:500 message:"attestation check failed: insufficient verifiers: 0 < 2"
```

**Solution:**

Both chaincode files should have verifier requirement set to 0 for development.

**Check hot-blockchain/chaincode/chaincode.go around line 300:**
```go
// Should be:
if len(config.VerifiedBy) < 0 {  // 0 for development
    return fmt.Errorf("insufficient verifiers: %d < 0", len(config.VerifiedBy))
}
```

**Check cold-blockchain/chaincode/chaincode.go around line 271:**
```go
// Should be:
if len(config.VerifiedBy) < 0 {  // 0 for development
    return fmt.Errorf("insufficient verifiers: %d < 0", len(config.VerifiedBy))
}
```

If set to 2, change to 0, then redeploy:
```bash
./deploy-chaincode.sh  # Increment sequence in script first
```

---

### Error: "chaincode install failed"

```
Error: chaincode install failed with status: 500
```

**Check these:**

1. **Go modules are clean:**
```bash
cd hot-blockchain/chaincode
go mod tidy && go mod vendor
cd ../../cold-blockchain/chaincode
go mod tidy && go mod vendor
```

2. **Peers are running:**
```bash
docker ps | grep peer
# Should see peer0.lawenforcement, peer0.forensiclab, peer0.auditor
```

3. **Peer logs:**
```bash
docker logs peer0.lawenforcement.hot.coc.com
docker logs peer0.forensiclab.hot.coc.com
docker logs peer0.auditor.cold.coc.com
```

---

## 🔴 Docker Issues

### Error: "permission denied" (Docker socket)

```
Got permission denied while trying to connect to Docker daemon socket
```

**Solution:**
```bash
# Add user to docker group (if not done)
sudo usermod -aG docker $USER

# Option 1: Start new shell
newgrp docker

# Option 2: Log out and back in
logout
# Then log back in

# Verify
docker ps
```

---

### Error: "port is already allocated"

```
Error: Bind for 0.0.0.0:7050 failed: port is already allocated
```

**Solution:**
```bash
# Find what's using the port
sudo lsof -i :7050

# Kill the process
sudo kill -9 <PID>

# Or stop all containers
docker stop $(docker ps -aq)

# Restart
./restart-blockchain.sh
```

---

### Error: Containers keep restarting

**Check logs:**
```bash
docker ps -a  # See which container is restarting

docker logs <container_name>
```

**Common causes:**

1. **Port conflict** - Another service using the port
2. **Volume permission** - Wrong ownership on crypto-config
3. **Configuration error** - Wrong paths in docker-compose files

**Quick fix:**
```bash
# Complete reset
./stop-all.sh
docker system prune -af
docker volume prune -f
./nuclear-reset.sh
```

---

## 🗄️ Database Issues

### Error: "Can't connect to MySQL server"

```
ERROR 2003 (HY000): Can't connect to MySQL server on 'localhost'
```

**Solution:**
```bash
# Check if MySQL container is running
docker ps | grep mysql

# If not running, start it
docker-compose -f docker-compose-storage.yml up -d

# Wait for it to be ready
for i in {1..30}; do
    if docker exec mysql-coc mysqladmin ping -h localhost -uroot -prootpassword 2>/dev/null | grep -q "mysqld is alive"; then
        echo "MySQL is ready"
        break
    fi
    sleep 2
done

# Initialize schema if needed
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql
```

---

### Error: "Access denied for user"

```
ERROR 1045 (28000): Access denied for user 'root'@'localhost'
```

**Solution:**
```bash
# Check credentials in docker-compose-storage.yml
# Should be:
#   MYSQL_ROOT_PASSWORD: rootpassword
#   MYSQL_DATABASE: coc_evidence
#   MYSQL_USER: cocuser
#   MYSQL_PASSWORD: cocpassword

# Restart MySQL
docker-compose -f docker-compose-storage.yml down
docker volume rm $(docker volume ls -q | grep mysql) 2>/dev/null || true
docker-compose -f docker-compose-storage.yml up -d

# Wait and reinitialize
sleep 20
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql
```

---

## 📦 IPFS Issues

### IPFS not starting

```bash
# Check IPFS container
docker ps | grep ipfs

# If not running
docker-compose -f docker-compose-storage.yml up -d

# Check logs
docker logs ipfs-coc

# Test IPFS
curl http://localhost:8080/ipfs/QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG
# Should return IPFS welcome page
```

---

## 🌐 Web Application Issues

### Webapp not responding on port 5000

**Solution:**
```bash
# Check if running
ps aux | grep python | grep app.py

# Check logs
tail -f /tmp/webapp.log

# Restart webapp
pkill -f "python3.*app.py"
./launch-webapp.sh

# Wait 30 seconds
sleep 30

# Test
curl http://localhost:5000/api/blockchain/status
```

---

### Error: "Module not found" (Python)

```
ModuleNotFoundError: No module named 'flask'
```

**Solution:**
```bash
# Install Python dependencies
pip3 install flask requests pymysql python-dotenv ipfshttpclient

# Or from requirements.txt if exists
pip3 install -r requirements.txt

# Restart webapp
./launch-webapp.sh
```

---

## 🔍 Explorer Issues

### Explorers not accessible

**Check containers:**
```bash
docker ps | grep explorer

# Should see:
# explorer.hot.coc.com
# explorer-db-hot
# explorer.cold.coc.com
# explorer-db-cold
```

**Restart explorers:**
```bash
docker-compose -f docker-compose-explorers.yml down
docker-compose -f docker-compose-explorers.yml up -d

# Wait for sync
sleep 30

# Access:
# Hot: http://localhost:8090
# Cold: http://localhost:8091
```

---

### Explorer shows wrong blockchain height

**This is normal** after a restart. Explorers sync from genesis block.

**Wait for sync:**
```bash
# Check explorer logs
docker logs explorer.hot.coc.com

# Should eventually show current height
```

---

## 🧪 Verification Issues

### verify-blockchain.sh fails

**Common causes:**

1. **Peers not ready:**
```bash
docker ps | grep peer
# All should be "Up" and healthy
```

2. **Channels not created:**
```bash
docker exec cli peer channel list
# Should show: hotchannel

docker exec cli-cold peer channel list
# Should show: coldchannel
```

3. **Chaincode not deployed:**
```bash
docker exec cli peer chaincode list --installed
docker exec cli peer chaincode list --instantiated -C hotchannel
```

**Fix:**
```bash
./nuclear-reset.sh
./deploy-chaincode.sh
./verify-blockchain.sh
```

---

## 🔧 Network Issues

### Containers can't communicate

```
Error: Failed to connect to peer0.lawenforcement.hot.coc.com:7051
```

**Check Docker networks:**
```bash
docker network ls
# Should see:
#   dual-hyperledger-blockchain_hot
#   dual-hyperledger-blockchain_cold

# Inspect network
docker network inspect dual-hyperledger-blockchain_hot
```

**Recreate networks:**
```bash
./stop-all.sh
docker network prune -f
./nuclear-reset.sh
```

---

## 💾 Disk Space Issues

### Error: "no space left on device"

**Check Docker disk usage:**
```bash
docker system df

# Clean up
docker system prune -a
docker volume prune
```

**Check system disk:**
```bash
df -h
# Ensure at least 10GB free
```

---

## 📊 Performance Issues

### System running slow

**Check resources:**
```bash
# CPU/Memory usage
docker stats

# System resources
htop
```

**Common fixes:**

1. **Reduce container count** - Stop explorers if not needed:
```bash
docker-compose -f docker-compose-explorers.yml down
```

2. **Increase VM resources** - Add more CPU/RAM to VM

3. **Clean Docker** - Remove unused images:
```bash
docker image prune -a
```

---

## 🔄 Complete Reset Procedure

When all else fails:

```bash
cd /home/user/Dual-hyperledger-Blockchain

# Stop everything
./stop-all.sh

# Kill any remaining processes
pkill -f "python3.*app.py"

# Clean Docker completely
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
docker network prune -f
docker volume prune -f
docker system prune -af

# Fresh start
./nuclear-reset.sh
./deploy-chaincode.sh
docker-compose -f docker-compose-storage.yml up -d
sleep 20
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql
docker-compose -f docker-compose-explorers.yml up -d
sleep 30
./launch-webapp.sh
./verify-blockchain.sh
```

---

## 📞 Debug Commands Cheat Sheet

```bash
# Container status
docker ps -a

# Container logs
docker logs <container_name>

# Container shell
docker exec -it <container_name> bash

# Network inspection
docker network ls
docker network inspect <network_name>

# Volume inspection
docker volume ls
docker volume inspect <volume_name>

# Resource usage
docker stats

# Blockchain query (hot chain)
docker exec cli peer chaincode query -C hotchannel -n dfir -c '{"Args":["<function>"]}'

# Blockchain invoke (hot chain)
docker exec cli peer chaincode invoke -C hotchannel -n dfir -c '{"Args":["<function>"]}' -o orderer.hot.coc.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/tls/ca.crt

# Check peers on channel
docker exec cli peer channel list

# Check chaincode on channel
docker exec cli peer chaincode list --instantiated -C hotchannel
```

---

## ✅ Verification Checklist

Use this to verify everything is working:

- [ ] 20+ containers running: `docker ps | wc -l`
- [ ] No containers restarting: `docker ps` (check STATUS)
- [ ] Hot orderer running: `docker logs orderer.hot.coc.com`
- [ ] Cold orderer running: `docker logs orderer.cold.coc.com`
- [ ] Hot peers running: `docker ps | grep peer.*hot`
- [ ] Cold peer running: `docker ps | grep peer.*cold`
- [ ] MySQL accessible: `docker exec mysql-coc mysqladmin ping -h localhost -uroot -prootpassword`
- [ ] IPFS accessible: `curl http://localhost:8080/ipfs/QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG`
- [ ] Hot explorer accessible: `curl http://localhost:8090`
- [ ] Cold explorer accessible: `curl http://localhost:8091`
- [ ] Webapp accessible: `curl http://localhost:5000/api/blockchain/status`
- [ ] Hot blockchain height > 5: Check via API or explorer
- [ ] Cold blockchain height > 3: Check via API or explorer
- [ ] Verification tests pass: `./verify-blockchain.sh`

---

**Last Updated:** 2025-11-17
**Covers:** All common deployment and runtime issues
