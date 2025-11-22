# Database Configuration - Chain of Custody System

**Last Updated:** 2025-11-22

---

## Overview

Hyperledger Fabric uses **two separate databases** for each peer:

1. **Block Storage** (Immutable Blockchain) - Always LevelDB
2. **World State Database** (Current State) - LevelDB OR CouchDB

---

## 1. Block Storage (LevelDB) - ALWAYS USED

### What It Stores
- **Immutable blockchain blocks** containing all transactions
- **Transaction history** (complete audit trail)
- **Block metadata** (block numbers, hashes, timestamps)

### Configuration
- **Database:** LevelDB (embedded, no external container needed)
- **Location:** `/var/hyperledger/production/ledgersData/` inside peer container
- **Always enabled** - No configuration required

### For Your Project
- Both **HOT** and **COLD** chains use LevelDB for block storage
- Provides complete tamper-proof audit trail for forensic evidence
- No external database container needed for block storage

---

## 2. World State Database - CURRENT CONFIGURATION: CouchDB

### What We're Using: CouchDB

**Why CouchDB Instead of LevelDB?**

For forensic evidence management, CouchDB provides critical advantages:

| Feature | LevelDB | CouchDB | Our Need |
|---------|---------|---------|----------|
| Rich Queries | ❌ No | ✅ Yes | **Required** for evidence search |
| JSON Indexing | ❌ No | ✅ Yes | **Required** for metadata queries |
| Complex Filters | ❌ Limited | ✅ Full | **Required** for investigation queries |
| Key-only queries | ✅ Yes | ✅ Yes | Basic operations |
| Performance | ✅ Faster | ⚠️ Slower | Acceptable for our use case |

### CouchDB Use Cases in Our System

1. **Evidence Search:**
   ```javascript
   // Find all evidence for an investigation
   SELECT * WHERE investigationId = 'inv-12345'

   // Find evidence by date range
   SELECT * WHERE timestamp >= '2025-01-01' AND timestamp <= '2025-12-31'

   // Find evidence by hash
   SELECT * WHERE sha256 = 'abc123...'
   ```

2. **Investigation Queries:**
   ```javascript
   // Find open investigations
   SELECT * WHERE status = 'open'

   // Find investigations by case number
   SELECT * WHERE caseNumber = 'CASE-2025-001'
   ```

3. **GUID Mapping (Cold Chain):**
   ```javascript
   // Resolve GUID to evidence ID for court anonymization
   SELECT * WHERE guid = 'GUID-xyz...'
   ```

### Current Configuration

**HOT Blockchain:**
- Peer: `peer0.laborg.hot.coc.com`
- CouchDB: `couchdb.peer0.laborg.hot.coc.com:5984`
- Credentials: `admin:adminpw`

**COLD Blockchain:**
- Peer: `peer0.laborg.cold.coc.com`
  - CouchDB: `couchdb.peer0.laborg.cold.coc.com:6984`
- Peer: `peer0.courtorg.cold.coc.com`
  - CouchDB: `couchdb.peer0.courtorg.cold.coc.com:7984`

### Environment Variables (Already Configured)

In `docker-compose-network.yaml`:

```yaml
peer0.laborg.hot.coc.com:
  environment:
    - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
    - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb.peer0.laborg.hot.coc.com:5984
    - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
    - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw
```

---

## 3. Alternative: Switching to LevelDB (If Needed)

### When to Use LevelDB

Use LevelDB if:
- You only need simple key-based queries (GetState, PutState)
- Performance is critical (LevelDB is faster)
- You don't need complex JSON queries
- You want to avoid external database containers

### How to Switch to LevelDB

**For HOT Blockchain:**

1. Edit `hot-blockchain/docker-compose-network.yaml`:
   ```yaml
   peer0.laborg.hot.coc.com:
     environment:
       # Remove or comment out CouchDB settings:
       # - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
       # - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=...
       # - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=...
       # - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=...

       # Optional: Explicitly set to goleveldb (default if not specified)
       - CORE_LEDGER_STATE_STATEDATABASE=goleveldb
   ```

2. Remove CouchDB service:
   ```yaml
   # Comment out or remove couchdb service
   # couchdb.peer0.laborg.hot.coc.com:
   #   ...
   ```

3. Update chaincode queries:
   - Remove CouchDB-specific rich queries
   - Use only GetState, PutState, GetStateByRange, GetQueryResult

**For COLD Blockchain:**

Same process for both peers (LabOrg and CourtOrg).

### LevelDB Storage Location

World state will be stored in:
- `/var/hyperledger/production/stateLeveldb/` inside peer container
- Automatically created by Fabric
- No external database needed

---

## 4. Database Architecture Summary

### Current Setup (CouchDB)

```
┌─────────────────────────────────────────────────────────────┐
│  HOT Blockchain                                             │
├─────────────────────────────────────────────────────────────┤
│  peer0.laborg.hot.coc.com                                   │
│    ├── Block Storage (LevelDB)     → Immutable blocks      │
│    └── World State (CouchDB)       → Current state + queries│
│         └── couchdb:5984                                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  COLD Blockchain                                            │
├─────────────────────────────────────────────────────────────┤
│  peer0.laborg.cold.coc.com                                  │
│    ├── Block Storage (LevelDB)     → Immutable blocks      │
│    └── World State (CouchDB)       → Current state + queries│
│         └── couchdb:6984                                    │
│                                                             │
│  peer0.courtorg.cold.coc.com                                │
│    ├── Block Storage (LevelDB)     → Immutable blocks      │
│    └── World State (CouchDB)       → Current state + queries│
│         └── couchdb:7984                                    │
└─────────────────────────────────────────────────────────────┘
```

### With LevelDB (Alternative)

```
┌─────────────────────────────────────────────────────────────┐
│  HOT Blockchain                                             │
├─────────────────────────────────────────────────────────────┤
│  peer0.laborg.hot.coc.com                                   │
│    ├── Block Storage (LevelDB)     → Immutable blocks      │
│    └── World State (LevelDB)       → Current state (embedded)│
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Recommendations

### For Development / FYP Demo

**Use CouchDB** because:
- ✅ Better for demonstrating evidence search capabilities
- ✅ Better for showing investigation management
- ✅ More realistic for production forensic systems
- ✅ Already configured and tested
- ⚠️ Slight performance overhead acceptable for demo

### For Production Deployment

**Evaluate based on requirements:**

| If you need... | Use |
|----------------|-----|
| Complex evidence queries, search by metadata | **CouchDB** |
| Maximum performance, simple key lookups only | **LevelDB** |
| Both performance AND rich queries | **CouchDB + optimization** |

### For Your FYP

**Recommendation: Keep CouchDB** (current configuration)

This demonstrates:
- Real-world forensic evidence management
- Complex query capabilities
- Integration with IPFS metadata
- Investigation tracking across multiple evidence items
- GUID-based court anonymization (cold chain)

---

## 6. Testing Database Configuration

### Test CouchDB Connectivity

**HOT Chain:**
```bash
# Check CouchDB is running
curl http://admin:adminpw@localhost:5984/_up

# List databases (channels)
curl http://admin:adminpw@localhost:5984/_all_dbs

# View hot-chain database
curl http://admin:adminpw@localhost:5984/hot-chain/_all_docs
```

**COLD Chain:**
```bash
# LabOrg CouchDB
curl http://admin:adminpw@localhost:6984/_up

# CourtOrg CouchDB
curl http://admin:adminpw@localhost:7984/_up
```

### Test Rich Queries (CouchDB Only)

Create an index in chaincode:
```go
// In Evidence.go
func createEvidenceIndex(ctx contractapi.TransactionContextInterface) error {
    index := `{
        "index": {
            "fields": ["investigationId", "timestamp"]
        },
        "ddoc": "indexInvestigationDoc",
        "name": "indexInvestigation",
        "type": "json"
    }`

    return ctx.GetStub().CreateIndex("indexInvestigation", index)
}
```

Query using rich query:
```go
query := `{
    "selector": {
        "investigationId": "inv-12345"
    }
}`
iterator, err := ctx.GetStub().GetQueryResult(query)
```

---

## 7. Performance Considerations

### CouchDB Optimization

1. **Create indexes** for frequently queried fields
2. **Limit result sets** with pagination
3. **Use appropriate query filters** to reduce data transfer
4. **Monitor CouchDB performance** via operations endpoint

### LevelDB Performance

- Faster for simple key-value operations
- Better for high-throughput scenarios
- No external network latency (embedded)

---

## 8. Backup and Recovery

### CouchDB Backup

```bash
# Backup CouchDB databases
docker exec couchdb.peer0.laborg.hot.coc.com \
  curl -X GET http://admin:adminpw@localhost:5984/hot-chain/_all_docs?include_docs=true \
  > hot-chain-backup.json
```

### LevelDB Backup

```bash
# Backup peer data directory (includes LevelDB)
docker exec peer0.laborg.hot.coc.com \
  tar czf /tmp/ledger-backup.tar.gz /var/hyperledger/production/

docker cp peer0.laborg.hot.coc.com:/tmp/ledger-backup.tar.gz ./ledger-backup.tar.gz
```

---

## Summary

**Current Configuration:**
- ✅ Block Storage: LevelDB (always, automatic)
- ✅ World State: CouchDB (configured for rich queries)
- ✅ Best for forensic evidence management
- ✅ Already deployed in docker-compose-network.yaml

**No changes needed** - your current setup is optimal for the Chain of Custody system!

For documentation: "World state uses CouchDB for rich queries; block storage uses LevelDB (default)."
