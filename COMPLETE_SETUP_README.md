# Complete Setup Script - Usage Guide

This guide covers the **complete-setup.sh** script that installs everything from scratch on a fresh Ubuntu VM/laptop.

---

## 🎯 What This Script Does

This single script handles **EVERYTHING**:

✅ **System Dependencies**
- Docker & Docker Compose
- Python 3 + pip
- Go 1.21
- Node.js 18
- All utilities (curl, jq, git, etc.)

✅ **Blockchain Network**
- Hot blockchain (2 organizations)
- Cold blockchain (1 organization)
- Certificate authorities
- Orderers and peers
- Channel creation

✅ **Chaincode Deployment**
- Advanced DFIR chaincode (1,861 lines)
- RBAC policies
- mTLS security
- Sequence 1 deployment

✅ **Supporting Services**
- MySQL database
- IPFS distributed storage
- phpMyAdmin
- Blockchain explorers
- Flask web dashboard

---

## 📋 Prerequisites

**System Requirements:**
- Fresh Ubuntu 20.04/22.04 VM or laptop
- Minimum 4 CPU cores
- Minimum 8GB RAM
- Minimum 50GB disk space
- Internet connection

**Required:**
- Project code copied to: `/home/user/Dual-hyperledger-Blockchain`
- User must have sudo privileges

---

## 🚀 Usage

### Step 1: Copy Project Code to VM

```bash
# If using git:
cd /home/user
git clone <your-repo-url> Dual-hyperledger-Blockchain
cd Dual-hyperledger-Blockchain
git checkout claude/backup-012kvMLwmsqnxqfbzsF2HCYJ

# Or copy files directly via scp/rsync
```

### Step 2: Run the Complete Setup Script

```bash
cd /home/user/Dual-hyperledger-Blockchain
sudo bash complete-setup.sh
```

**What Happens:**
1. Script asks for confirmation ✓
2. Installs all dependencies (5-10 minutes)
3. Initializes blockchain - **YOU MUST TYPE 'NUCLEAR'** when prompted
4. Deploys chaincode (2-3 minutes)
5. Starts all services (2-3 minutes)
6. Shows access points and status

**Total Time:** 15-25 minutes

---

## ⚠️ Important Notes

### During Execution

**Nuclear Reset Prompt:**
```
WARNING: This will destroy all blockchain data and start fresh.
Type 'NUCLEAR' to confirm:
```
👉 **Type:** `NUCLEAR` (in caps) and press Enter

**Do NOT interrupt the script** while it's running. Let it complete all 20 steps.

### After Completion

**Docker Group Issue:**

If you see "permission denied" errors when running Docker commands:

```bash
# Option 1: Start new shell with docker group
newgrp docker

# Option 2: Log out and log back in
logout
# Then log back in
```

---

## 🌐 Access Points After Setup

| Service | URL | Credentials |
|---------|-----|-------------|
| **Main Dashboard** | http://localhost:5000 | None |
| **Hot Explorer** | http://localhost:8090 | exploreradmin / exploreradminpw |
| **Cold Explorer** | http://localhost:8091 | exploreradmin / exploreradminpw |
| **phpMyAdmin** | http://localhost:8081 | cocuser / cocpassword |
| **IPFS** | http://localhost:8080/ipfs/{hash} | None |

---

## ✅ Verification

### Check Container Status

```bash
docker ps
# Should show 20+ containers running
```

### Check Blockchain Status

```bash
curl http://localhost:5000/api/blockchain/status | jq
```

**Expected Output:**
```json
{
  "hot_chain": {
    "height": 7,
    "channel": "hotchannel"
  },
  "cold_chain": {
    "height": 4,
    "channel": "coldchannel"
  }
}
```

### Run Verification Tests

```bash
cd /home/user/Dual-hyperledger-Blockchain
./verify-blockchain.sh
```

**Expected:** 17+ tests passing

---

## 🔧 Troubleshooting

### Script Fails at Step X

**Check the error message** - the script will show exactly what failed in RED.

Common issues:

#### 1. "Failed to update package list"
```bash
# Fix DNS or network connectivity
ping google.com

# Update sources manually
sudo apt update
```

#### 2. "Docker installation verification failed"
```bash
# Check Docker service
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker
```

#### 3. "Nuclear reset failed"
```bash
# Make sure you typed 'NUCLEAR' correctly (all caps)
# Try manual reset:
cd /home/user/Dual-hyperledger-Blockchain
./nuclear-reset.sh
```

#### 4. "Chaincode deployment failed"

**Most common issue:** Insufficient wait time or containers not ready

```bash
# Check if all containers are running
docker ps | grep peer
docker ps | grep orderer

# Check logs
docker logs peer0.lawenforcement.hot.coc.com
docker logs orderer.hot.coc.com

# Try manual deployment
cd /home/user/Dual-hyperledger-Blockchain
./deploy-chaincode.sh
```

#### 5. "MySQL failed to start"
```bash
# Check if port 3306 is already in use
sudo lsof -i :3306

# Stop conflicting service
sudo systemctl stop mysql

# Restart storage services
docker-compose -f docker-compose-storage.yml down
docker-compose -f docker-compose-storage.yml up -d
```

### Web Application Not Responding

```bash
# Wait 60 seconds after setup completes
sleep 60

# Check if Flask is running
ps aux | grep python

# Check webapp logs
docker logs webapp 2>/dev/null || tail -f /tmp/webapp.log

# Restart webapp
cd /home/user/Dual-hyperledger-Blockchain
./launch-webapp.sh
```

### Containers Exiting Immediately

```bash
# Check specific container logs
docker logs <container_name>

# Common issue: Port conflicts
sudo lsof -i :7050  # Orderer port
sudo lsof -i :7051  # Peer port
sudo lsof -i :3306  # MySQL port

# Complete cleanup and retry
cd /home/user/Dual-hyperledger-Blockchain
./stop-all.sh
docker system prune -af
sudo bash complete-setup.sh
```

---

## 🔄 Restart/Reset Commands

### Restart Everything
```bash
cd /home/user/Dual-hyperledger-Blockchain
./restart-blockchain.sh
```

### Complete Reset (Start Fresh)
```bash
cd /home/user/Dual-hyperledger-Blockchain
./nuclear-reset.sh
./deploy-chaincode.sh
docker-compose -f docker-compose-storage.yml up -d
docker-compose -f docker-compose-explorers.yml up -d
./launch-webapp.sh
```

### Stop All Services
```bash
cd /home/user/Dual-hyperledger-Blockchain
./stop-all.sh
```

---

## 📊 System Status Commands

```bash
# Container count
docker ps | wc -l

# Container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# Blockchain heights
curl http://localhost:5000/api/blockchain/status | jq

# Disk usage
docker system df

# Network status
docker network ls

# Volume status
docker volume ls
```

---

## 🐛 Debug Mode

Run the script with verbose output:

```bash
sudo bash -x complete-setup.sh 2>&1 | tee setup.log
```

This saves all output to `setup.log` for troubleshooting.

---

## 📝 Manual Installation Alternative

If the script fails, you can run commands manually from **VM_SETUP_COMMANDS.md**.

---

## ❓ Getting Help

**Check logs:**
```bash
# Docker logs
docker logs <container_name>

# All fabric logs
for container in $(docker ps --format '{{.Names}}' | grep -E 'peer|orderer|ca'); do
    echo "=== $container ==="
    docker logs $container 2>&1 | tail -20
done

# System logs
journalctl -u docker -n 50
```

**Common Log Locations:**
- Blockchain logs: `docker logs <container>`
- Webapp logs: `/tmp/webapp.log` or `docker logs webapp`
- Script output: Terminal or `setup.log` if redirected

---

## ✨ Success Indicators

When everything is working correctly:

✅ **20+ containers running** (docker ps)
✅ **No containers restarting** (check STATUS column)
✅ **Hot blockchain at ~7 blocks**
✅ **Cold blockchain at ~4 blocks**
✅ **Dashboard accessible** (http://localhost:5000)
✅ **Explorers accessible** (ports 8090, 8091)
✅ **17+ tests passing** (./verify-blockchain.sh)

---

## 🎓 Next Steps

Once setup is complete:

1. **Explore the Dashboard:** http://localhost:5000
2. **Create test investigation:** See API_INTEGRATION.md
3. **View blockchain data:** Use explorers on ports 8090/8091
4. **Integrate with external systems:** See API_INTEGRATION.md
5. **Read full documentation:** See SETUP.md and QUICKSTART.md

---

## 📞 Support

If you encounter issues:

1. Check this troubleshooting guide
2. Review container logs: `docker logs <container_name>`
3. Check the main documentation: SETUP.md
4. Run verification: `./verify-blockchain.sh`

---

**Script Version:** 1.0
**Last Updated:** 2025-11-17
**Compatible With:** Ubuntu 20.04/22.04, Debian 11+
