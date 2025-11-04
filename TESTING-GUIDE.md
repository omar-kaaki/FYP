# TESTING & VERIFICATION GUIDE
## Blockchain Chain of Custody System

## Quick Health Check

After running `./start-all.sh`, use these commands to verify everything is working.

## 1. Container Status Check

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Expected**: All 12-13 containers should show "Up" status.

## 2. Test Each Component

### A. Test Hot Blockchain

```bash
# Enter Hot Blockchain CLI
docker exec -it cli bash

# Inside the container, run these tests:
peer version
peer channel list
exit
```

**Expected output**: 
- Peer version: 2.5.x
- Channel list may be empty initially (normal)

### B. Test Cold Blockchain

```bash
# Enter Cold Blockchain CLI
docker exec -it cli-cold bash

# Inside the container, run these tests:
peer version
peer channel list
exit
```

**Expected output**: Same as hot blockchain

### C. Test IPFS

```bash
# Check IPFS version
curl -X POST http://localhost:5001/api/v0/version

# Check IPFS ID
curl -X POST http://localhost:5001/api/v0/id

# Test file upload
echo "Test evidence file" > test-evidence.txt
curl -F file=@test-evidence.txt http://localhost:5001/api/v0/add
```

**Expected**: JSON responses with IPFS version, peer ID, and file hash

### D. Test MySQL

```bash
# Connect to MySQL
docker exec -it mysql-coc mysql -ucocuser -pcocpassword coc_evidence

# Inside MySQL, run:
SHOW TABLES;
SELECT * FROM cases;
SELECT COUNT(*) FROM evidence_metadata;
exit
```

**Expected**: 
- 6 tables listed
- 2 sample cases
- Empty or populated evidence_metadata

**Or use phpMyAdmin**: http://localhost:8081
- Server: mysql
- Username: cocuser
- Password: cocpassword

## 3. Port Connectivity Tests

```bash
# Test Hot Blockchain Orderer
nc -zv localhost 7050

# Test Hot Blockchain Peers
nc -zv localhost 7051  # Law Enforcement
nc -zv localhost 8051  # Forensic Lab

# Test Cold Blockchain
nc -zv localhost 7150  # Orderer
nc -zv localhost 9051  # Archive Peer

# Test IPFS
nc -zv localhost 5001  # API
nc -zv localhost 8080  # Gateway

# Test MySQL
nc -zv localhost 3306
```

**Expected**: All should show "succeeded!"

## 4. View Logs

### Hot Blockchain Logs
```bash
# All Hot Blockchain services
docker-compose -f docker-compose-hot.yml logs -f

# Specific services
docker logs orderer.hot.coc.com
docker logs peer0.lawenforcement.hot.coc.com
docker logs peer0.forensiclab.hot.coc.com
```

### Cold Blockchain Logs
```bash
# All Cold Blockchain services
docker-compose -f docker-compose-cold.yml logs -f

# Specific services
docker logs orderer.cold.coc.com
docker logs peer0.archive.cold.coc.com
```

### Storage Services Logs
```bash
# All storage services
docker-compose -f docker-compose-storage.yml logs -f

# Specific services
docker logs ipfs-node
docker logs mysql-coc
```

## 5. Network Inspection

```bash
# List all Docker networks
docker network ls

# Inspect Hot Blockchain network
docker network inspect hot-chain-network

# Inspect Cold Blockchain network
docker network inspect cold-chain-network

# Inspect Storage network
docker network inspect storage-network
```

**Expected**: 3 networks with correct container assignments

## 6. Storage Volume Check

```bash
# List volumes
docker volume ls | grep coc

# Inspect specific volumes
docker volume inspect blockchain-coc_orderer.hot.coc.com
docker volume inspect blockchain-coc_peer0.lawenforcement.hot.coc.com
docker volume inspect blockchain-coc_ipfs-data
docker volume inspect blockchain-coc_mysql-data
```

**Expected**: Multiple volumes for blockchain data persistence

## 7. Resource Usage

```bash
# Check CPU and memory usage
docker stats --no-stream

# Check disk usage
docker system df
```

**Expected**: 
- Reasonable CPU/memory usage (depends on your system)
- Blockchain images ~500MB-1GB each

## 8. Advanced Testing

### Test IPFS File Storage and Retrieval

```bash
# Add a test evidence file
echo "This is test evidence for Case-001" > evidence-test.txt

# Upload to IPFS
HASH=$(curl -F file=@evidence-test.txt http://localhost:5001/api/v0/add | jq -r '.Hash')

echo "File uploaded with hash: $HASH"

# Retrieve from IPFS
curl "http://localhost:8080/ipfs/$HASH"

# Or via API
curl -X POST "http://localhost:5001/api/v0/cat?arg=$HASH"
```

### Test MySQL Evidence Insert

```bash
docker exec -it mysql-coc mysql -ucocuser -pcocpassword coc_evidence << EOF
INSERT INTO evidence_metadata (
    evidence_id, 
    case_id, 
    evidence_type, 
    sha256_hash, 
    collected_timestamp, 
    collected_by,
    blockchain_type
) VALUES (
    'TEST-EVIDENCE-001',
    'CASE-001',
    'Document',
    SHA2('test data', 256),
    NOW(),
    'Test User',
    'hot'
);

SELECT * FROM evidence_metadata WHERE evidence_id = 'TEST-EVIDENCE-001';
EOF
```

### Test Blockchain Peer Communication

```bash
# From Hot Blockchain CLI
docker exec cli peer node status

# From Cold Blockchain CLI
docker exec cli-cold peer node status
```

## 9. Common Issues & Solutions

### Issue: Container exits immediately
```bash
# Check logs for the problematic container
docker logs <container-name>

# Common fix: regenerate crypto material
cd /mnt/user-data/outputs/blockchain-coc
./stop-all.sh
rm -rf hot-blockchain/crypto-config cold-blockchain/crypto-config
./start-all.sh
```

### Issue: Port already in use
```bash
# Find what's using the port
sudo lsof -i :7050  # Example for orderer port

# Stop the conflicting service or change port in docker-compose file
```

### Issue: IPFS not responding
```bash
# Restart IPFS
docker restart ipfs-node

# Check IPFS logs
docker logs ipfs-node -f
```

### Issue: MySQL connection refused
```bash
# Check MySQL is running
docker ps | grep mysql

# Restart MySQL
docker restart mysql-coc

# Check MySQL logs
docker logs mysql-coc -f
```

### Issue: Blockchain peers can't connect to orderer
```bash
# Check orderer is running
docker logs orderer.hot.coc.com

# Verify network connectivity
docker exec cli ping orderer.hot.coc.com
```

## 10. Performance Benchmarking

### Measure IPFS Upload Speed
```bash
# Create a 100MB test file
dd if=/dev/urandom of=test-100mb.bin bs=1M count=100

# Time the upload
time curl -F file=@test-100mb.bin http://localhost:5001/api/v0/add
```

### Check Blockchain Transaction Rate
```bash
# View hot blockchain metrics
curl http://localhost:9443/metrics

# View cold blockchain metrics  
curl http://localhost:9543/metrics
```

### Monitor Database Query Performance
```bash
docker exec mysql-coc mysql -ucocuser -pcocpassword coc_evidence << EOF
-- Show slow query log status
SHOW VARIABLES LIKE 'slow_query_log%';

-- Show current connections
SHOW PROCESSLIST;

-- Check table sizes
SELECT 
    table_name,
    table_rows,
    ROUND(data_length / 1024 / 1024, 2) AS 'Data Size (MB)'
FROM information_schema.tables
WHERE table_schema = 'coc_evidence'
ORDER BY data_length DESC;
EOF
```

## 11. Integration Testing

### Test Hot → Cold Blockchain Flow (Manual)

1. **Create evidence in Hot Blockchain**
   - Use CLI to add evidence metadata
   
2. **Archive to Cold Blockchain**
   - Move completed case to Cold chain
   
3. **Store files in IPFS**
   - Upload evidence files
   - Store IPFS hash in Cold blockchain

4. **Update MySQL**
   - Log evidence metadata
   - Record custody events

### Test Full Stack
```bash
# 1. Upload file to IPFS
IPFS_HASH=$(curl -F file=@test-evidence.txt http://localhost:5001/api/v0/add | jq -r '.Hash')

# 2. Calculate SHA256
SHA256=$(sha256sum test-evidence.txt | awk '{print $1}')

# 3. Insert into MySQL
docker exec mysql-coc mysql -ucocuser -pcocpassword coc_evidence << EOF
INSERT INTO evidence_metadata 
VALUES ('TEST-001', 'CASE-001', 'Document', 12345, '$IPFS_HASH', '$SHA256', 
        NOW(), 'Test User', 'Test Lab', 'Test evidence', 'hot', 'tx-001', NOW(), NOW());
EOF

# 4. Verify storage
echo "IPFS Hash: $IPFS_HASH"
echo "SHA256: $SHA256"
curl "http://localhost:8080/ipfs/$IPFS_HASH"
```

## 12. Cleanup and Reset

### Soft Reset (Keep data)
```bash
./stop-all.sh
./start-all.sh
```

### Hard Reset (Delete everything)
```bash
./stop-all.sh
rm -rf hot-blockchain/crypto-config hot-blockchain/channel-artifacts
rm -rf cold-blockchain/crypto-config cold-blockchain/channel-artifacts
docker system prune -af --volumes
./start-all.sh
```

## Summary Checklist

After setup, verify these work:

- [ ] All 12-13 containers running
- [ ] Hot Blockchain peers responsive
- [ ] Cold Blockchain peers responsive
- [ ] IPFS accepts file uploads
- [ ] IPFS serves files via gateway
- [ ] MySQL accepts connections
- [ ] phpMyAdmin accessible
- [ ] All ports open and listening
- [ ] Blockchain logs show no errors
- [ ] Can add/retrieve IPFS files
- [ ] Can query MySQL database
- [ ] Peer-to-peer communication working

---

**If all checks pass, your system is fully operational! ✅**
