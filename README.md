<<<<<<< HEAD
# Dual-hyperledger-Blockchain
Hot-Chain &amp; Cold Chain
=======
# Blockchain-Based Chain of Custody System
## AUB Project 68 - Hot & Cold Blockchain Implementation

This system implements a dual-blockchain architecture for managing digital evidence chain of custody, exactly as described in your project report.

## System Architecture

### Hot Blockchain
- **Purpose**: Handles frequent investigative metadata and custody events
- **Organizations**: Law Enforcement, Forensic Lab
- **Ports**: 
  - Orderer: 7050, 7053
  - Peer0 (Law Enforcement): 7051
  - Peer0 (Forensic Lab): 8051
  - CouchDB instances: 5984, 6984

### Cold Blockchain
- **Purpose**: Stores immutable evidence records and IPFS references
- **Organizations**: Archive
- **Ports**:
  - Orderer: 7150, 7153
  - Peer0 (Archive): 9051
  - CouchDB: 7984

### Supporting Services
- **IPFS**: Distributed file storage
  - API: http://localhost:5001
  - Gateway: http://localhost:8080
  
- **MySQL Database**: Off-chain evidence metadata
  - Host: localhost:3306
  - Database: coc_evidence
  - Username: cocuser
  - Password: cocpassword
  - phpMyAdmin: http://localhost:8081

## Prerequisites

1. **Docker** (version 20.10+)
   ```bash
   docker --version
   ```

2. **Docker Compose** (version 1.29+)
   ```bash
   docker-compose --version
   ```

3. **At least 8GB RAM and 20GB free disk space**

## Quick Start

### Step 1: Make scripts executable
```bash
cd /home/claude/blockchain-coc
chmod +x setup-blockchains.sh start-all.sh stop-all.sh
```

### Step 2: Run the complete setup
```bash
./start-all.sh
```

This single command will:
1. Download Hyperledger Fabric binaries (if needed)
2. Generate cryptographic materials for both blockchains
3. Create genesis blocks and channel configurations
4. Start IPFS and MySQL services
5. Launch Hot Blockchain network
6. Launch Cold Blockchain network

**Total setup time**: Approximately 5-10 minutes (first run)

### Step 3: Verify the system is running

Check Docker containers:
```bash
docker ps
```

You should see approximately 12 containers running:
- Hot Blockchain: orderer, 2 peers, 2 CouchDB instances, CLI
- Cold Blockchain: orderer, 1 peer, 1 CouchDB, CLI
- Storage: IPFS, MySQL, phpMyAdmin

## Verifying Each Component

### 1. Hot Blockchain
```bash
# Access Hot Blockchain CLI
docker exec -it cli bash

# Inside the container, check peer status
peer channel list

# Check installed chaincodes
peer lifecycle chaincode queryinstalled
```

### 2. Cold Blockchain
```bash
# Access Cold Blockchain CLI
docker exec -it cli-cold bash

# Inside the container, check peer status
peer channel list
```

### 3. IPFS
```bash
# Check IPFS status
curl http://localhost:5001/api/v0/version

# Or visit IPFS Gateway
open http://localhost:8080
```

### 4. MySQL Database
Visit phpMyAdmin at http://localhost:8081

Login credentials:
- Server: mysql
- Username: cocuser
- Password: cocpassword

You should see the `coc_evidence` database with the following tables:
- `evidence_metadata`
- `custody_events`
- `access_logs`
- `ipfs_pins`
- `cases`
- `blockchain_sync`

## System Architecture Details

### Hot Blockchain Flow
1. Evidence submitted by investigator
2. Metadata recorded on Hot Blockchain
3. Custody transfer events logged
4. Frequent queries for active investigations

### Cold Blockchain Flow
1. Completed cases archived from Hot Blockchain
2. IPFS hash references stored on Cold Blockchain
3. Long-term immutable storage
4. Minimal modification operations

### Integration Points
- **Hot ↔ Cold**: Cases moved to Cold Blockchain when closed
- **Blockchain ↔ IPFS**: Evidence files stored in IPFS, hashes on blockchain
- **Blockchain ↔ MySQL**: Metadata cached for fast queries

## Viewing Logs

### All services
```bash
docker-compose -f docker-compose-hot.yml logs -f
docker-compose -f docker-compose-cold.yml logs -f
docker-compose -f docker-compose-storage.yml logs -f
```

### Specific service
```bash
docker logs -f orderer.hot.coc.com
docker logs -f peer0.lawenforcement.hot.coc.com
docker logs -f ipfs-node
docker logs -f mysql-coc
```

## Stopping the System

To stop all services:
```bash
./stop-all.sh
```

This will stop and remove all containers and volumes.

## Troubleshooting

### Issue: "Cannot connect to Docker daemon"
**Solution**: Make sure Docker is running
```bash
sudo systemctl start docker
```

### Issue: "Port already in use"
**Solution**: Stop conflicting services or change ports in docker-compose files

### Issue: "No space left on device"
**Solution**: Clean up Docker resources
```bash
docker system prune -a --volumes
```

### Issue: Fabric binaries not found
**Solution**: Re-run the setup
```bash
cd /home/claude/blockchain-coc
rm -rf fabric-samples
./start-all.sh
```

## Project Structure

```
blockchain-coc/
├── docker-compose-hot.yml          # Hot Blockchain configuration
├── docker-compose-cold.yml         # Cold Blockchain configuration  
├── docker-compose-storage.yml      # IPFS + MySQL configuration
├── start-all.sh                    # Complete setup script
├── stop-all.sh                     # Stop all services
├── hot-blockchain/
│   ├── crypto-config.yaml          # Crypto material definition
│   ├── configtx.yaml               # Channel configuration
│   ├── crypto-config/              # Generated certificates
│   ├── channel-artifacts/          # Genesis block, channel tx
│   ├── chaincode/                  # Smart contracts
│   └── scripts/                    # Utility scripts
├── cold-blockchain/
│   ├── crypto-config.yaml
│   ├── configtx.yaml
│   ├── crypto-config/
│   ├── channel-artifacts/
│   ├── chaincode/
│   └── scripts/
└── shared/
    ├── ipfs/                       # IPFS data directory
    │   ├── export/
    │   └── staging/
    └── database/
        └── init/
            └── 01-schema.sql       # Database initialization
```

## Next Steps

1. **Deploy Chaincode**: Install and instantiate smart contracts on both blockchains
2. **Build Jump Server**: Implement the gateway with DNSSEC, mTLS, and RBAC
3. **Create APIs**: Build REST APIs to interact with the system
4. **Develop GUI**: Create user interface for evidence management
5. **Implement Path Analyzer**: Add Dijkstra's algorithm for custody trail analysis

## Key Features (As per Project Report)

✅ **Hot Blockchain**: Frequent metadata updates, custody tracking
✅ **Cold Blockchain**: Immutable archive, long-term storage  
✅ **IPFS Integration**: Distributed evidence file storage
✅ **MySQL Database**: Off-chain metadata caching
✅ **Multi-Organization**: Law Enforcement, Forensic Lab, Archive
✅ **TLS Enabled**: Secure communications
✅ **CouchDB**: Rich query capabilities for evidence search

## Performance Specifications

Based on your project report:
- **Hot Blockchain**: Target 70+ TPS for metadata updates
- **Cold Blockchain**: Optimized for archival (lower TPS acceptable)
- **IPFS**: Handles large files (100MB - 5GB) efficiently
- **Storage Growth**: Plan for 1TB per 100 cases retained

## Standards Compliance

This implementation follows:
- NIST SP 800-61: Incident handling phases
- ISO/IEC 27037: Digital evidence guidelines
- Federal Rules of Evidence (Rules 901, 902)
- IEEE 2418.2-2020: Blockchain data format

## Support

For issues or questions about this implementation, refer to:
- Project Report: FYP_Template__1___1_.pdf
- Hyperledger Fabric Docs: https://hyperledger-fabric.readthedocs.io/
- IPFS Docs: https://docs.ipfs.tech/

---

**Note**: This is a development/demonstration system. For production use, additional security hardening, monitoring, and backup procedures must be implemented.
>>>>>>> eb3a507 (Initial upload of full folder structure)
