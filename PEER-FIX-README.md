# Peer Container Crash Fix

## Problem Identified

Your peer containers were starting but immediately crashing. This was caused by a **timing issue** with CouchDB:

```
Peer Container Starts → Tries to connect to CouchDB → CouchDB not ready yet → Connection refused → Peer crashes
```

## Root Cause

The `depends_on` directive in docker-compose only waits for containers to **START**, not for services to be **READY**. CouchDB takes a few seconds to initialize after the container starts, but the peers were trying to connect immediately.

## Solution Applied

Added **health checks** to all CouchDB containers and updated peer containers to wait for CouchDB to be healthy:

### 1. CouchDB Health Checks
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5984/_up"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### 2. Peer Wait Conditions
```yaml
depends_on:
  couchdb0:
    condition: service_healthy  # Wait until CouchDB passes health check
```

### 3. Removed Obsolete Version
Removed `version: '3.7'` from all docker-compose files to eliminate warnings.

---

## Testing the Fix

### Step 1: Pull Latest Changes
```bash
cd ~/Documents/Dual-hyperledger-Blockchain
git pull origin claude/fix-docker-network-peers-011CUpbTaJYAg44GzT1B28gq
```

### Step 2: Restart System
```bash
./restart-blockchain.sh
```

**What to expect:**
- CouchDB containers will start first
- You'll see health checks running
- Peers will wait ~10-30 seconds for CouchDB to be healthy
- Then peers will start successfully
- All containers should remain running

### Step 3: Verify Peer Status
```bash
# Check all containers are running
docker ps

# Should see:
# ✅ peer0.lawenforcement.hot.coc.com  (Up X seconds)
# ✅ peer0.forensiclab.hot.coc.com     (Up X seconds)
# ✅ peer0.archive.cold.coc.com        (Up X seconds)
```

### Step 4: Run Diagnostic (if issues persist)
```bash
./diagnose-peers.sh
```

This will show:
- Peer container status
- Exit codes if crashed
- Last 30 lines of logs
- Network connectivity
- Crypto-config verification

### Step 5: Deploy Chaincode
Once all peers are running:
```bash
./deploy-chaincode.sh
```

### Step 6: Verify Everything
```bash
./verify-blockchain.sh
```

Expected: **20/20 tests passing**

---

## Troubleshooting

### If peers still crash:

**1. Check health status:**
```bash
docker ps -a | grep couchdb
# Should show (healthy) in status
```

**2. Check peer logs:**
```bash
docker logs peer0.lawenforcement.hot.coc.com
docker logs peer0.forensiclab.hot.coc.com
docker logs peer0.archive.cold.coc.com
```

**3. Run diagnostics:**
```bash
./diagnose-peers.sh
```

**4. Common issues:**

| Symptom | Cause | Fix |
|---------|-------|-----|
| "connection refused" | CouchDB not ready | Health checks should fix this |
| "no such host" | Network issue | Run `docker network inspect coc-network` |
| "permission denied" | Volume mount issue | Check crypto-config directories exist |
| "exit code 1" | Configuration error | Check peer logs for specific error |

### If CouchDB won't become healthy:

```bash
# Check CouchDB logs
docker logs couchdb0
docker logs couchdb1
docker logs couchdb2

# Test CouchDB manually
curl http://localhost:5984/_up
curl http://localhost:6984/_up
curl http://localhost:7984/_up
```

---

## Technical Details

### Health Check Process
1. Container starts
2. Docker waits 10 seconds (first interval)
3. Runs: `curl -f http://localhost:5984/_up`
4. If fails, waits 10s and retries (up to 5 times)
5. Once succeeds, marks container as "healthy"
6. Dependent peers can now start

### Startup Order
```
1. CouchDB containers start
   ├─ couchdb0 (for Law Enforcement peer)
   ├─ couchdb1 (for Forensic Lab peer)
   └─ couchdb2 (for Archive peer)

2. CouchDB health checks run (10-50 seconds)

3. Peers start (after CouchDB healthy)
   ├─ peer0.lawenforcement.hot.coc.com
   ├─ peer0.forensiclab.hot.coc.com
   └─ peer0.archive.cold.coc.com

4. CLIs start (after peers)
   ├─ cli
   └─ cli-cold
```

---

## Expected Timeline

```
T+0s:   docker-compose up -d
T+5s:   CouchDB containers running
T+10s:  First health check
T+15-30s: CouchDB marked healthy
T+30s:  Peers start
T+45s:  All containers running
```

---

## Success Criteria

When working correctly, you should see:

### Container List:
```
peer0.lawenforcement.hot.coc.com  Up 2 minutes
peer0.forensiclab.hot.coc.com     Up 2 minutes
peer0.archive.cold.coc.com        Up 2 minutes
couchdb0                          Up 3 minutes (healthy)
couchdb1                          Up 3 minutes (healthy)
couchdb2                          Up 3 minutes (healthy)
orderer.hot.coc.com               Up 2 minutes
orderer.cold.coc.com              Up 2 minutes
cli                               Up 2 minutes
cli-cold                          Up 2 minutes
mysql-coc                         Up 3 minutes
ipfs-node                         Up 3 minutes (healthy)
```

### Blockchain Status:
```
✅ Hot Blockchain: Running on hotchannel
✅ Cold Blockchain: Running on coldchannel
```

### No Warnings:
- ✅ No "version is obsolete" warnings
- ✅ No "orphan containers" warnings
- ✅ No "connection refused" errors
- ✅ No DNS resolution errors

---

## Summary of All Fixes in This Branch

1. **Network Isolation** - Created shared `coc-network` for all containers
2. **MySQL SSL** - Disabled SSL for local development
3. **Port 5000** - Added availability check for webapp
4. **Peer Crashes** - Added CouchDB health checks ← **NEW FIX**
5. **Version Warnings** - Removed obsolete version attribute ← **NEW FIX**

All issues should now be resolved! 🎉
