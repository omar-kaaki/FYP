# Missing core.yaml Fix - CRITICAL

## The Problem

After running `./diagnose-peers.sh`, the issue was clear:

```
Fatal error when initializing core config : error when reading core config file:
Config File "core" Not Found in "[/etc/hyperledger/fabric]"
```

All three peer containers were crashing immediately after startup because they couldn't find their `core.yaml` configuration file.

---

## Root Cause

Hyperledger Fabric peer containers require a `core.yaml` configuration file that defines:
- Logging levels
- Network settings
- CouchDB connection details
- TLS configuration
- Chaincode settings
- And many other parameters

The peer directories only had:
```
peer0.lawenforcement.hot.coc.com/
├── msp/     ✓ (certificates)
├── tls/     ✓ (TLS certs)
└── core.yaml  ✗ (MISSING!)
```

---

## Solution Applied

### 1. Copied core.yaml to All Peers

Source file from: `fabric-samples/test-network/compose/docker/peercfg/core.yaml`

Copied to:
- ✅ `hot-blockchain/.../peer0.lawenforcement.hot.coc.com/core.yaml`
- ✅ `hot-blockchain/.../peer0.forensiclab.hot.coc.com/core.yaml`
- ✅ `cold-blockchain/.../peer0.archive.cold.coc.com/core.yaml`

### 2. Updated restart-blockchain.sh

Added automatic core.yaml copying at step 5, before starting blockchains:
```bash
# 5. Fix core.yaml files
echo "Ensuring core.yaml files are in place..."
cp fabric-samples/.../core.yaml hot-blockchain/.../peer0.lawenforcement.hot.coc.com/
cp fabric-samples/.../core.yaml hot-blockchain/.../peer0.forensiclab.hot.coc.com/
cp fabric-samples/.../core.yaml cold-blockchain/.../peer0.archive.cold.coc.com/
```

### 3. Created fix-core-yaml.sh Helper

A standalone script to manually fix core.yaml if needed:
```bash
./fix-core-yaml.sh
```

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

**What to watch for:**
- ✓ "Ensuring core.yaml files are in place..."
- ✓ "✓ core.yaml files copied"
- ✓ Peers wait for CouchDB health checks
- ✓ All containers start successfully

### Step 3: Verify Peers Are Running
```bash
docker ps | grep peer
```

**Expected output:**
```
peer0.lawenforcement.hot.coc.com  Up X seconds  0.0.0.0:7051->7051/tcp
peer0.forensiclab.hot.coc.com     Up X seconds  0.0.0.0:8051->8051/tcp
peer0.archive.cold.coc.com        Up X seconds  0.0.0.0:9051->9051/tcp
```

### Step 4: Check Blockchain Status
```bash
docker exec cli peer channel list
docker exec cli-cold peer channel list
```

**Expected:**
```
✅ Channels for peer:
   hotchannel

✅ Channels for peer:
   coldchannel
```

### Step 5: Deploy Chaincode
```bash
./deploy-chaincode.sh
```

Should now complete all 10 steps successfully!

### Step 6: Run Full Verification
```bash
./verify-blockchain.sh
```

**Expected: 20/20 tests passing** ✅

---

## Troubleshooting

### If peers still crash:

**1. Check if core.yaml exists:**
```bash
ls -la hot-blockchain/crypto-config/peerOrganizations/lawenforcement.hot.coc.com/peers/peer0.lawenforcement.hot.coc.com/core.yaml
ls -la hot-blockchain/crypto-config/peerOrganizations/forensiclab.hot.coc.com/peers/peer0.forensiclab.hot.coc.com/core.yaml
ls -la cold-blockchain/crypto-config/peerOrganizations/archive.cold.coc.com/peers/peer0.archive.cold.coc.com/core.yaml
```

**2. Manually fix if needed:**
```bash
./fix-core-yaml.sh
./restart-blockchain.sh
```

**3. Run diagnostics:**
```bash
./diagnose-peers.sh
```

**4. Check peer logs:**
```bash
docker logs peer0.lawenforcement.hot.coc.com 2>&1 | tail -20
docker logs peer0.forensiclab.hot.coc.com 2>&1 | tail -20
docker logs peer0.archive.cold.coc.com 2>&1 | tail -20
```

### Common Issues After Fix:

| Issue | Likely Cause | Solution |
|-------|-------------|----------|
| "core.yaml not found" | File not copied | Run `./fix-core-yaml.sh` |
| "permission denied" | File permissions | `sudo chmod 644 */core.yaml` |
| "connection refused" | CouchDB not ready | Wait 30s for health checks |
| "already joined" | Channels already setup | This is normal, continue |

---

## MySQL Restarting Issue

You may have noticed:
```
mysql-coc    Restarting (1)
```

This is likely due to one of:
1. Port 3306 already in use
2. Volume permission issues
3. Configuration error

**Quick fix:**
```bash
# Check what's using port 3306
sudo lsof -i:3306

# If nothing is using it, check MySQL logs
docker logs mysql-coc

# Restart just MySQL
docker-compose -f docker-compose-storage.yml restart mysql
```

However, the blockchain can still work without MySQL running (it's for off-chain metadata only).

---

## Summary of All Fixes

This branch now includes fixes for:

1. **Docker Network Isolation** ✅
   - Shared `coc-network` for all containers
   - DNS resolution working

2. **MySQL SSL Errors** ✅
   - SSL disabled for local development
   - `update-mysql.sh` helper added

3. **Port 5000 Conflicts** ✅
   - Availability check in startup script

4. **Missing Scripts** ✅
   - `deploy-chaincode.sh` created
   - `verify-blockchain.sh` created

5. **Peer Container Crashes** ✅
   - CouchDB health checks added
   - Peers wait for CouchDB to be ready

6. **Missing core.yaml** ✅ ← **LATEST FIX**
   - core.yaml copied to all peer directories
   - Auto-copy in restart script
   - Manual fix script available

7. **Version Warnings** ✅
   - Removed obsolete `version:` attribute

---

## Final Checklist

After pulling and restarting, verify:

- [ ] All 11 containers running (or 10 if MySQL is optional)
- [ ] All 3 peer containers running and healthy
- [ ] Both orderers running
- [ ] All 3 CouchDB containers showing (healthy)
- [ ] Hot blockchain: `hotchannel` accessible
- [ ] Cold blockchain: `coldchannel` accessible
- [ ] Chaincode deployment succeeds (10/10 steps)
- [ ] Verification passes (20/20 tests)
- [ ] Web dashboard starts without errors

---

## Next Steps

```bash
# 1. Pull fixes
git pull origin claude/fix-docker-network-peers-011CUpbTaJYAg44GzT1B28gq

# 2. Restart everything
./restart-blockchain.sh

# 3. Wait for startup (~60 seconds total)
#    - CouchDB health checks: ~30s
#    - Peer startup: ~15s
#    - Channel joining: ~10s

# 4. Verify peers are running
docker ps | grep peer

# 5. Deploy chaincode
./deploy-chaincode.sh

# 6. Update database
./update-mysql.sh

# 7. Start webapp
cd webapp
python3 app_blockchain.py

# 8. Verify everything
cd ..
./verify-blockchain.sh
```

---

## Success Indicators

When everything works, you'll see:

```
📦 All Containers: 11/11 running
🔥 Hot Blockchain: ✅ Running on hotchannel
❄️  Cold Blockchain: ✅ Running on coldchannel
📝 Chaincode: ✅ dfir v1.0 deployed
🧪 Tests: ✅ 20/20 passing
🌐 Dashboard: ✅ http://localhost:5000
```

All peer crashes should now be **completely resolved**! 🎉
