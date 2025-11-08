# Complete System Reset and Fresh Start Guide

## Problems You Were Experiencing

### 1. Evidence Upload Error
```
Error: evidence 1 already exists
```
**Cause**: Evidence with ID "1" was already submitted to the blockchain in previous tests.
**Solution**: Either use a different evidence ID (2, 3, 4, etc.) OR reset the blockchain to start fresh.

### 2. No Evidence Records Showing
**Cause**: MySQL `evidence_metadata` table was not created or data wasn't inserted properly.
**Solution**: MySQL schema needs to be reloaded after reset.

### 3. Explorer Blocks Tab Empty
**Cause**: Hyperledger Explorer database needs to sync with blockchain after data changes.
**Solution**: Reset explorer databases when resetting blockchains.

### 4. Can't See All Blocks from Beginning
**Cause**: Explorer UI pagination or sync issues.
**Solution**: Fresh explorer start with clean database ensures all blocks are indexed from block 0.

## Solution: Complete Reset

We've created comprehensive reset scripts that will:
- ✅ Stop all services (blockchains, explorers, webapp)
- ✅ Remove all blockchain ledger data
- ✅ Clear MySQL evidence records
- ✅ Reset explorer databases
- ✅ Remove chaincode containers
- ✅ Restart everything fresh from block 0 (genesis)

## Step-by-Step Reset Process

### Step 1: Pull Latest Changes
```bash
git pull origin claude/fix-docker-network-peers-011CUpbTaJYAg44GzT1B28gq
```

### Step 2: Run Complete Reset
```bash
./complete-reset.sh
```

**You will be prompted to type 'RESET' to confirm.**

This script will:
1. Stop webapp
2. Stop explorers (removes databases)
3. Stop blockchains (removes volumes)
4. Remove all chaincode containers and images
5. Clear MySQL evidence database
6. Reload MySQL schema from `shared/database/init/01-schema.sql`
7. Start Hot blockchain fresh
8. Start Cold blockchain fresh
9. Create channels (hotchannel, coldchannel)
10. Join peers to channels
11. Verify both blockchains are at height 1 (genesis block only)

**Result**: Both blockchains at height 1 with NO evidence data.

### Step 3: Deploy Chaincode
```bash
./deploy-chaincode.sh
```

This will:
- Package the DFIR chaincode
- Install on all peers (Hot: LawEnforcement + ForensicLab, Cold: Archive)
- Approve chaincode definition for all organizations
- Commit chaincode to both channels
- Initialize chaincode (creates sample evidence for testing)

**Time**: ~5-7 minutes

### Step 4: Start Explorers
```bash
./start-explorers.sh
```

This will:
- Start PostgreSQL databases for both explorers
- Wait for databases to be healthy
- Start Hot Explorer on port 8090
- Start Cold Explorer on port 8091
- Sync with blockchain from genesis

**Login Credentials**:
- Username: `exploreradmin`
- Password: `exploreradminpw`

### Step 5: Start Webapp
```bash
./launch-webapp.sh
```

This will:
- Check storage services (MySQL, IPFS)
- Install Python dependencies if needed
- Start Flask webapp on port 5000
- Display all service URLs

## Accessing Services After Reset

| Service | URL | Credentials |
|---------|-----|-------------|
| 📊 Main Dashboard | http://localhost:5000 | None |
| 🔥 Hot Explorer | http://localhost:8090 | exploreradmin / exploreradminpw |
| ❄️ Cold Explorer | http://localhost:8091 | exploreradmin / exploreradminpw |
| 💾 phpMyAdmin | http://localhost:8081 | cocuser / cocpassword |
| 📁 IPFS Gateway | http://localhost:8080 | None |

## Testing Evidence Upload After Reset

### First Evidence Upload
1. Go to http://localhost:5000
2. Upload a test file
3. Fill in the form:
   - **Evidence ID**: `1` (starts fresh from 1)
   - **Case ID**: `CASE-001` (sample case exists in DB)
   - **Evidence Type**: `digital`
   - **Description**: `Test evidence after reset`
   - **Collected By**: `Your Name`
   - **Blockchain**: Choose `Hot` or `Cold`
4. Click "Submit Evidence"

**Expected Result**:
- ✅ Success message
- ✅ Evidence appears in "Evidence Records" section
- ✅ File appears in "IPFS Files" section
- ✅ Transaction visible in appropriate explorer

### Subsequent Uploads
Use Evidence IDs: `2`, `3`, `4`, etc.
**Never reuse an Evidence ID on the same blockchain!**

## Verifying Everything Works

### Check Blockchain Heights
After reset and chaincode deployment:
- **Hot Blockchain**: Height should be 3-4 (genesis + chaincode deployment + init)
- **Cold Blockchain**: Height should be 3-4 (genesis + chaincode deployment + init)

### Check Explorer Blocks Tab
1. Go to http://localhost:8090 (Hot) or http://localhost:8091 (Cold)
2. Login with `exploreradmin` / `exploreradminpw`
3. Click "BLOCKS" tab
4. You should see ALL blocks from Block 0 (genesis) onwards

### Check MySQL Evidence Records
1. Go to http://localhost:8081
2. Login with `cocuser` / `cocpassword`
3. Navigate to `coc_evidence` database
4. Check `evidence_metadata` table
5. Should be empty after reset, will populate when you submit evidence

## Understanding Blockchain Heights

| Height | What It Means |
|--------|---------------|
| 1 | Genesis block only (fresh channel) |
| 2 | Genesis + 1 transaction (e.g., chaincode install) |
| 3+ | Genesis + chaincode deployment + your evidence |

**Note**: Both explorers and dashboard show the SAME blockchain data - they're just different views.

## What Gets Preserved During Reset

✅ **Preserved**:
- IPFS files (stored in IPFS volume)
- Crypto material (certificates, keys)
- Container images
- Code and configurations

❌ **Deleted**:
- All blockchain blocks and transactions
- All MySQL evidence records
- All explorer database contents
- All chaincode containers

## Troubleshooting After Reset

### If Explorers Don't Show Blocks
```bash
# Restart explorers
./stop-explorers.sh
./start-explorers.sh

# Wait 60 seconds for full sync
sleep 60
```

### If Evidence Records Don't Show
```bash
# Check MySQL table exists
docker exec mysql-coc mysql -ucocuser -pcocpassword -e "DESCRIBE evidence_metadata;" coc_evidence

# If table doesn't exist, reload schema
docker exec -i mysql-coc mysql -ucocuser -pcocpassword coc_evidence < shared/database/init/01-schema.sql
```

### If Webapp Won't Start
```bash
# Check logs
tail -f webapp/flask.log

# Restart webapp
pkill -f "python.*app_blockchain.py"
./launch-webapp.sh
```

## Quick Reset Commands Summary

```bash
# FULL RESET (recommended)
./complete-reset.sh
./deploy-chaincode.sh
./start-explorers.sh
./launch-webapp.sh

# Individual component resets
./reset-blockchains.sh     # Just blockchains
./stop-explorers.sh         # Just explorers
./fix-services.sh           # Fix running services

# Diagnostics
./diagnose-services.sh      # Check all services
./diagnose-explorers.sh     # Check explorers specifically
```

## Important Notes

1. **Evidence IDs must be unique per blockchain**
   - Hot blockchain: evidence IDs 1, 2, 3...
   - Cold blockchain: can reuse same IDs (separate ledger)

2. **Explorer sync takes time**
   - Wait 30-60 seconds after starting explorers
   - Refresh browser if blocks don't appear immediately

3. **MySQL is for indexing only**
   - Blockchain is the source of truth
   - MySQL makes listing faster
   - If MySQL fails, evidence is still on blockchain

4. **IPFS files persist**
   - Resetting blockchain doesn't delete IPFS files
   - Old evidence files remain in IPFS
   - Use new files for new evidence after reset

## Success Criteria

After complete reset and setup, you should see:

✅ Hot Blockchain: Height 3-4, all blocks visible in explorer
✅ Cold Blockchain: Height 3-4, all blocks visible in explorer
✅ MySQL: evidence_metadata table exists and is empty
✅ Webapp: Responds on http://localhost:5000
✅ First evidence upload with ID "1" succeeds
✅ Evidence appears in dashboard and explorer

---

**Now you have a clean slate to start testing evidence uploads!**
