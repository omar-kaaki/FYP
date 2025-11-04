# QUICK START GUIDE
## Blockchain Chain of Custody System - AUB Project 68

## 🚀 Running Your System in 3 Steps

### Step 1: Navigate to Project Directory
```bash
cd /home/claude/blockchain-coc
```

### Step 2: Start Everything
```bash
./start-all.sh
```

Wait 5-10 minutes for first-time setup. The script will:
- Download Hyperledger Fabric (first time only)
- Generate all cryptographic materials
- Create blockchain networks
- Start IPFS and MySQL
- Launch both Hot and Cold blockchains

### Step 3: Verify It's Running
```bash
docker ps
```

You should see ~12 containers running.

## ✅ What You Now Have Running

### 🔥 HOT BLOCKCHAIN (Active Investigations)
- **Orderer**: localhost:7050
- **Law Enforcement Peer**: localhost:7051  
- **Forensic Lab Peer**: localhost:8051
- **Purpose**: Real-time custody tracking, metadata updates

### ❄️ COLD BLOCKCHAIN (Immutable Archive)
- **Orderer**: localhost:7150
- **Archive Peer**: localhost:9051
- **Purpose**: Long-term evidence storage, IPFS references

### 📦 IPFS (File Storage)
- **API**: http://localhost:5001
- **Gateway**: http://localhost:8080
- **Purpose**: Distributed evidence file storage

### 🗄️ MySQL Database
- **Host**: localhost:3306
- **Database**: coc_evidence
- **Username**: cocuser
- **Password**: cocpassword
- **Web UI**: http://localhost:8081 (phpMyAdmin)

## 🔍 Quick Tests

### Test IPFS
```bash
curl http://localhost:5001/api/v0/version
```

### Test MySQL
Open http://localhost:8081 in browser
- Server: mysql
- Username: cocuser  
- Password: cocpassword

### Access Hot Blockchain CLI
```bash
docker exec -it cli bash
# Inside container:
peer version
peer channel list
```

### Access Cold Blockchain CLI
```bash
docker exec -it cli-cold bash
# Inside container:
peer version
peer channel list
```

## 📊 View Logs

```bash
# Hot Blockchain
docker-compose -f docker-compose-hot.yml logs -f

# Cold Blockchain  
docker-compose -f docker-compose-cold.yml logs -f

# Storage (IPFS + MySQL)
docker-compose -f docker-compose-storage.yml logs -f
```

## 🛑 Stop Everything

```bash
./stop-all.sh
```

## 🎯 Architecture Summary

```
┌─────────────────────────────────────────────────┐
│            USER INTERACTIONS                     │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│  🔥 HOT BLOCKCHAIN (Metadata & Custody Events)  │
│  • Law Enforcement Org                          │
│  • Forensic Lab Org                             │
│  • CouchDB for Rich Queries                     │
└─────────────────────────────────────────────────┘
                      │
                      │ Archive Completed Cases
                      ▼
┌─────────────────────────────────────────────────┐
│  ❄️ COLD BLOCKCHAIN (Immutable Archive)         │
│  • Archive Org                                  │
│  • IPFS Hash References                         │
│  • Long-term Storage                            │
└─────────────────────────────────────────────────┘
        │                           │
        ▼                           ▼
┌──────────────┐          ┌────────────────┐
│ 📦 IPFS      │          │ 🗄️ MySQL DB    │
│ Evidence     │          │ Metadata Cache │
│ Files        │          │ Fast Queries   │
└──────────────┘          └────────────────┘
```

## 📁 Project Files

All your files are in: `/home/claude/blockchain-coc/`

Key files:
- `README.md` - Full documentation
- `start-all.sh` - Start everything
- `stop-all.sh` - Stop everything
- `docker-compose-hot.yml` - Hot blockchain config
- `docker-compose-cold.yml` - Cold blockchain config
- `docker-compose-storage.yml` - IPFS + MySQL config

## 💡 Next Steps

1. **Create Smart Contracts** - Write chaincode for evidence management
2. **Build Jump Server** - Implement gateway with DNSSEC, mTLS, RBAC
3. **Develop REST APIs** - Build API layer for system interaction
4. **Create GUI** - Build user interface for evidence management
5. **Add Path Analyzer** - Implement Dijkstra's algorithm for custody trails

## 🆘 Common Issues

**Docker not running?**
```bash
sudo systemctl start docker
```

**Port conflicts?**
```bash
# Stop conflicting services
./stop-all.sh
# Or edit port numbers in docker-compose files
```

**Out of disk space?**
```bash
docker system prune -a --volumes
```

**Need to reset everything?**
```bash
./stop-all.sh
rm -rf hot-blockchain/crypto-config hot-blockchain/channel-artifacts
rm -rf cold-blockchain/crypto-config cold-blockchain/channel-artifacts
./start-all.sh
```

## ✨ Features Implemented

✅ Dual Blockchain (Hot & Cold) as per project spec
✅ Multi-organization setup (Law Enforcement, Forensic Lab, Archive)
✅ IPFS integration for distributed file storage
✅ MySQL database for metadata caching
✅ TLS-enabled secure communications
✅ CouchDB for rich queries
✅ Separate channels for Hot and Cold chains
✅ Docker-based deployment for easy setup

## 📖 For More Details

See `README.md` for complete documentation including:
- Detailed architecture explanation
- Troubleshooting guide
- Standards compliance information
- Performance specifications
- Security considerations

---

**Your system is ready! Both blockchains are running and connected to IPFS and MySQL.**
