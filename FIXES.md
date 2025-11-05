# Blockchain System Fixes

## Issues Identified and Fixed

### 1. Docker Network Isolation (PRIMARY ISSUE)
**Problem:** The three docker-compose files created separate isolated networks:
- `storage-network` for IPFS and MySQL
- `hot-chain-network` for Hot blockchain
- `cold-chain-network` for Cold blockchain

This caused DNS resolution failures:
```
Error: lookup peer0.lawenforcement.hot.coc.com on 127.0.0.11:53: no such host
```

**Root Cause:** Containers from different compose files couldn't communicate because they were on separate networks.

**Solution:** Created a shared network `coc-network` that all containers join:
- Updated all three docker-compose files to define and use `coc-network`
- Each container now joins both its local network AND the shared network
- Updated `startup-blockchain.sh` to create the network before starting containers

**Files Modified:**
- `docker-compose-storage.yml` - Added `coc-network` to all services
- `docker-compose-hot.yml` - Added `coc-network` to all services
- `docker-compose-cold.yml` - Added `coc-network` to all services
- `startup-blockchain.sh` - Added network creation step

---

### 2. MySQL SSL Certificate Error
**Problem:**
```
ERROR 2026 (HY000): TLS/SSL error: Certificate verification failure
```

**Solution:**
- Added `--ssl-mode=DISABLED` to MySQL command in `docker-compose-storage.yml`
- Created `update-mysql.sh` helper script for database updates with SSL disabled

**Files Modified:**
- `docker-compose-storage.yml` - Line 53
- Created `update-mysql.sh` helper script

---

### 3. Port 5000 Conflict
**Problem:** Flask webapp couldn't start because port 5000 was already in use.

**Solution:**
- Updated `startup-blockchain.sh` to check if port 5000 is available
- If port is in use, script skips webapp auto-start with clear instructions
- User can manually start webapp later after freeing the port

**Files Modified:**
- `startup-blockchain.sh` - Lines 61-70

---

## New Helper Scripts

### 1. `restart-blockchain.sh`
Complete system restart with proper cleanup:
- Stops all containers
- Removes orphan containers
- Creates shared network
- Starts all services in correct order
- Configures channels
- Shows system status

**Usage:**
```bash
./restart-blockchain.sh
```

### 2. `update-mysql.sh`
Safely updates MySQL database without SSL issues:
- Checks for update-database.sql
- Executes with `--ssl-mode=DISABLED`
- Shows success/failure status

**Usage:**
```bash
./update-mysql.sh
```

---

## How to Use (Step-by-Step)

### Step 1: Clean Restart
```bash
# Stop everything and restart properly
./restart-blockchain.sh
```

### Step 2: Deploy Chaincode
```bash
# Deploy the DFIR chaincode to both blockchains
./deploy-chaincode.sh
```

### Step 3: Update Database (if needed)
```bash
# Update MySQL schema
./update-mysql.sh
```

### Step 4: Start Web Application
```bash
# If port 5000 was in use, kill the process first:
sudo lsof -ti:5000 | xargs kill -9  # Kill process on port 5000

# Then start the webapp
cd webapp
python3 app_blockchain.py
```

### Step 5: Verify Everything
```bash
# Run verification script
./verify-blockchain.sh
```

---

## What Was Changed

### Network Architecture
**Before:**
```
Storage Containers (storage-network) ← ISOLATED
Hot Blockchain (hot-chain-network)   ← ISOLATED
Cold Blockchain (cold-chain-network) ← ISOLATED
```

**After:**
```
All Containers (coc-network) ← SHARED
├── Storage Containers (also on storage-network)
├── Hot Blockchain (also on hot-chain-network)
└── Cold Blockchain (also on cold-chain-network)
```

Each container is now on TWO networks:
1. Their local network (for backwards compatibility)
2. The shared `coc-network` (for cross-compose communication)

---

## Expected Results After Fixes

### Container Status
All containers should be running:
```
✅ cli
✅ cli-cold
✅ peer0.lawenforcement.hot.coc.com
✅ peer0.forensiclab.hot.coc.com
✅ peer0.archive.cold.coc.com
✅ orderer.hot.coc.com
✅ orderer.cold.coc.com
✅ couchdb0, couchdb1, couchdb2
✅ mysql-coc
✅ ipfs-node
✅ phpmyadmin-coc
```

### Blockchain Status
```
✅ Hot Blockchain: Running on hotchannel
✅ Cold Blockchain: Running on coldchannel
```

### Chaincode Deployment
```
✅ dfir chaincode installed on all peers
✅ dfir chaincode committed on both channels
```

### Verification Script Results
```
Total Tests: 20
Passed: 20
Failed: 0
```

---

## Troubleshooting

### If containers still can't communicate:
```bash
# Check network exists
docker network inspect coc-network

# Check containers are on the network
docker network inspect coc-network | grep -A 5 "Containers"
```

### If peer containers still failing:
```bash
# Check peer logs
docker logs peer0.lawenforcement.hot.coc.com
docker logs peer0.forensiclab.hot.coc.com
docker logs peer0.archive.cold.coc.com
```

### If chaincode deployment fails:
```bash
# Check CLI can reach peers
docker exec cli peer lifecycle chaincode queryinstalled
docker exec cli-cold peer lifecycle chaincode queryinstalled
```

### If MySQL connection fails:
```bash
# Test MySQL connection
mysql -h localhost -P 3306 -u cocuser -pcocpassword --ssl-mode=DISABLED -e "SHOW DATABASES;"
```

---

## Technical Details

### Why This Approach?
1. **External Network**: The `coc-network` is defined as external so it persists across compose up/down
2. **Dual Networks**: Containers join both local and shared networks for maximum compatibility
3. **DNS Resolution**: Docker's embedded DNS server (127.0.0.11) now has all hostnames registered
4. **No Code Changes**: Only configuration changes, no modifications to chaincode or application logic

### Network Flow
```
CLI Container (hot) → peer0.lawenforcement.hot.coc.com
                   ↓
              coc-network (DNS: 127.0.0.11)
                   ↓
              Resolves hostname ✓
                   ↓
              Connects successfully ✓
```

---

## Files Summary

### Modified Files
1. `docker-compose-storage.yml` - Network + MySQL SSL fix
2. `docker-compose-hot.yml` - Network configuration
3. `docker-compose-cold.yml` - Network configuration
4. `startup-blockchain.sh` - Network creation + port check

### New Files
1. `restart-blockchain.sh` - Complete system restart
2. `update-mysql.sh` - MySQL update helper
3. `FIXES.md` - This documentation

---

## Next Steps After Applying Fixes

1. Run `./restart-blockchain.sh` to restart everything cleanly
2. Run `./deploy-chaincode.sh` to deploy chaincode
3. Run `./verify-blockchain.sh` to verify all tests pass
4. Start the webapp and test the full system

All issues should now be resolved! 🎉
