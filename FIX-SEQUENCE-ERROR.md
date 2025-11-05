# Fix for Sequence Error and Transaction Failures

## Problems Identified

From your output, I found **3 issues**:

### 1. ❌ Sequence Conflict
```
Error: requested sequence is 1, but new definition must be sequence 2
```
**Cause:** Chaincode already deployed with sequence 1. Can't redeploy with same sequence.

### 2. ❌ Wrong Function Names in Verify Script
```
Transaction failed - Function CreateEvidence not found
```
**Cause:** Verify script called `CreateEvidence` (8 args) but chaincode has `CreateEvidenceSimple` (7 args)

### 3. ⚠️  MySQL Missing from Container List
MySQL container not showing in `docker ps` output, suggesting it's crashing/restarting.

---

## SOLUTION: Clean Restart

The best solution is a **complete clean restart** that removes all volumes and chaincode state.

### Step 1: Pull Latest Fixes

```bash
cd ~/Documents/block/Dual-hyperledger-Blockchain
git pull origin claude/fix-docker-network-peers-011CUpbTaJYAg44GzT1B28gq
```

**What's new:**
- `clean-restart.sh` - Complete cleanup script
- Fixed `verify-blockchain.sh` - Uses correct function names

### Step 2: Complete Cleanup

```bash
./clean-restart.sh
```

**What this does:**
- Stops all containers
- **Removes ALL volumes** (including chaincode data)
- Removes chaincode containers (`dev-peer*`)
- Removes chaincode images
- Removes networks
- Clean slate for fresh deployment

**⚠️ WARNING:** This deletes all blockchain data! You'll need to redeploy everything.

### Step 3: Fresh Start

```bash
./restart-blockchain.sh
```

**Expected output:**
```
Starting Storage Services...
Starting Hot Blockchain...
Starting Cold Blockchain...
Joining orderers to channels...
  ✓ Hot orderer joined
  ✓ Cold orderer joined
✓ Orderer channel participation complete

📦 Running Containers:
...all containers including mysql-coc...

Hot Blockchain: ✅ Running
Cold Blockchain: ✅ Running
```

### Step 4: Deploy Chaincode Fresh

```bash
./deploy-chaincode.sh
```

**Expected - ALL 10 STEPS SHOULD PASS:**
```
[Step 1/10] Checking blockchain containers... ✅
[Step 2/10] Packaging Hot blockchain chaincode... ✅
[Step 3/10] Installing chaincode on Law Enforcement peer... ✅
[Step 4/10] Installing chaincode on Forensic Lab peer... ✅
[Step 5/10] Querying Hot blockchain package ID... ✅
[Step 6/10] Approving chaincode for Law Enforcement... ✅
[Step 7/10] Approving chaincode for Forensic Lab... ✅
[Step 8/10] Committing chaincode to Hot blockchain... ✅
[Step 9/10] Deploying to Cold blockchain... ✅
[Step 10/10] Initializing chaincode... ✅
  Note: Using placeholder PRV config
  ✓ Hot blockchain initialized
  ✓ Cold blockchain initialized

Chaincode Deployment Complete!
```

### Step 5: Verify Everything Works

```bash
./verify-blockchain.sh
```

**Expected - 19-20/20 PASSING:**
```
========================================
SECTION 1: Container Health Checks
========================================
✅ 9/9 containers running (including mysql-coc)

========================================
SECTION 2: Channel Connectivity
========================================
✅ Hot blockchain - channel list
✅ Cold blockchain - channel list

========================================
SECTION 3: Chaincode Deployment
========================================
✅ Hot blockchain - chaincode installed
✅ Cold blockchain - chaincode installed
✅ Hot blockchain - chaincode committed
✅ Cold blockchain - chaincode committed

========================================
SECTION 4: Blockchain Transaction Test
========================================
✅ Creating test evidence on Hot blockchain
✅ Verifying new block was created
✅ Querying test evidence from blockchain

========================================
SECTION 5: Storage Services
========================================
✅ IPFS API is responding
✅ MySQL database is accessible

========================================
Total Tests: 20
Passed: 19-20
Failed: 0-1
========================================
```

---

## What Was Fixed

### Fix #1: Created `clean-restart.sh`

Complete cleanup script that removes:
- All containers
- All volumes (chaincode state, CouchDB data, MySQL data)
- Chaincode containers (`dev-peer*`)
- Chaincode images
- Networks

**Why needed:** Prevents sequence conflicts when redeploying

### Fix #2: Fixed `verify-blockchain.sh`

**Before (WRONG):**
```bash
-c '{"function":"CreateEvidence","Args":[...8 args including verifier...]}'
-c '{"function":"QueryEvidence","Args":[...]}'
```

**After (CORRECT):**
```bash
-c '{"function":"CreateEvidenceSimple","Args":[...7 args, no verifier...]}'
-c '{"function":"ReadEvidenceSimple","Args":[...]}'
```

**Why:** Chaincode only has `CreateEvidenceSimple` and `ReadEvidenceSimple` functions.

---

## Understanding the Errors

### ENDORSEMENT_POLICY_FAILURE

This happened because you tried to approve chaincode definition that was already approved with sequence 1. Fabric rejected it because:
- Sequence 1 already exists
- New approval must use sequence 2 (upgrade)
- But you can't upgrade to same version with same code

**Solution:** Clean volumes and redeploy fresh with sequence 1.

### Transaction Test Failures

The verify script was calling functions that don't exist in the chaincode:
- `CreateEvidence` → doesn't exist
- `QueryEvidence` → doesn't exist

**Actual functions:**
- `CreateEvidenceSimple(id, caseID, type, description, hash, location, metadata)` - 7 args
- `ReadEvidenceSimple(id)` - 1 arg
- `InitLedger(publicKey, mrEnclave, mrSigner)` - 3 args (already fixed)

---

## If MySQL Still Fails

If mysql-coc container keeps restarting after clean restart:

### Check MySQL Logs
```bash
docker logs mysql-coc
```

### Common Issues and Fixes

**Issue 1: Init script error**
```bash
# Remove problematic init scripts
rm -rf shared/database/init/*
./clean-restart.sh
./restart-blockchain.sh
```

**Issue 2: Volume permission error**
```bash
# Fix volume permissions
sudo chown -R $USER:$USER .
./clean-restart.sh
./restart-blockchain.sh
```

**Issue 3: Port 3306 already in use**
```bash
# Check if MySQL running on host
sudo lsof -i :3306
# Kill process if needed, then restart
./restart-blockchain.sh
```

**Issue 4: MySQL container unhealthy**
```bash
# Check container status
docker inspect mysql-coc | grep -A 10 Health

# Try removing just MySQL volume
docker volume rm dual-hyperledger-blockchain_mysql-data
./restart-blockchain.sh
```

---

## Test Your Blockchain

After successful deployment, test evidence creation:

### Create Evidence
```bash
docker exec cli peer chaincode invoke \
    -o orderer.hot.coc.com:7050 \
    --ordererTLSHostnameOverride orderer.hot.coc.com \
    --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/msp/tlscacerts/tlsca.hot.coc.com-cert.pem \
    -C hotchannel \
    -n dfir \
    --peerAddresses peer0.lawenforcement.hot.coc.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/lawenforcement.hot.coc.com/peers/peer0.lawenforcement.hot.coc.com/tls/ca.crt \
    -c '{"function":"CreateEvidenceSimple","Args":["EVIDENCE-001","CASE-ALPHA","digital","Laptop hard drive image","sha256:abc123...","ipfs://Qm...","Found at crime scene"]}'
```

### Query Evidence
```bash
docker exec cli peer chaincode query \
    -C hotchannel \
    -n dfir \
    -c '{"function":"ReadEvidenceSimple","Args":["EVIDENCE-001"]}'
```

**Expected output:**
```json
{
  "id": "EVIDENCE-001",
  "case_id": "CASE-ALPHA",
  "type": "digital",
  "description": "Laptop hard drive image",
  "hash": "sha256:abc123...",
  "location": "ipfs://Qm...",
  "custodian": "x509::CN=Admin@lawenforcement.hot.coc.com...",
  "timestamp": 1699123456,
  "status": "collected",
  "metadata": "Found at crime scene"
}
```

---

## Quick Reference

| Script | Purpose |
|--------|---------|
| `./clean-restart.sh` | Complete cleanup (removes volumes) |
| `./restart-blockchain.sh` | Start all containers + join orderers |
| `./deploy-chaincode.sh` | Deploy and initialize chaincode |
| `./verify-blockchain.sh` | Run 20 automated tests |
| `./diagnose-peers.sh` | Debug peer issues |
| `./join-orderers-to-channels.sh` | Manually join orderers (usually not needed) |

---

## Summary of ALL Fixes

Your system now has **11 complete fixes**:

1. ✅ Docker Network Isolation
2. ✅ MySQL SSL Errors
3. ✅ Port 5000 Conflicts
4. ✅ Missing Scripts
5. ✅ Peer Container Crashes
6. ✅ Missing core.yaml
7. ✅ Chaincode Timeouts
8. ✅ Compilation Errors
9. ✅ Orderer Channel Participation
10. ✅ Chaincode Initialization (InitLedger)
11. ✅ **Verify Script Function Names** ← JUST FIXED
12. ✅ **Clean Restart Script** ← JUST ADDED

---

## Expected Final Result

After running all steps:

```
✅ All 13 containers running (including mysql-coc)
✅ Hot blockchain operational on hotchannel
✅ Cold blockchain operational on coldchannel
✅ Orderers joined to channels
✅ Chaincode deployed, committed, and initialized
✅ Transactions working (CreateEvidenceSimple/ReadEvidenceSimple)
✅ 19-20/20 tests passing
✅ System fully operational
```

---

## Next Steps After Success

1. **Start Web Dashboard:**
   ```bash
   cd webapp
   python3 app_blockchain.py
   ```
   Access at: http://localhost:5000

2. **Access Services:**
   - IPFS WebUI: https://webui.ipfs.io/#/files
   - IPFS Gateway: http://localhost:8080
   - phpMyAdmin: http://localhost:8081

3. **Develop Your Application:**
   - Integrate `CreateEvidenceSimple` for evidence submission
   - Use `ReadEvidenceSimple` for evidence queries
   - Store files in IPFS, hashes on blockchain
   - Metadata in MySQL for fast search

---

**Run the clean restart now and everything should work!** 🚀

If you still encounter issues after the clean restart, share:
1. Output of `./clean-restart.sh`
2. Output of `./restart-blockchain.sh`
3. Output of `./deploy-chaincode.sh`
4. Output of `docker logs mysql-coc` (if MySQL still failing)
