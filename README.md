# DFIR Blockchain - Digital Forensics & Incident Response Chain of Custody System

A dual-blockchain architecture for managing digital evidence chain of custody using Hyperledger Fabric, IPFS, and MySQL.

## 🚀 Quick Links

### For New Users (Fresh VM/Laptop)
- **[⚡ 5-Minute Quick Start](QUICK_START.md)** - One-command deployment for fresh Ubuntu systems
- **[🤖 Complete Setup Script](COMPLETE_SETUP_README.md)** - Automated A-Z installation (installs everything)
- **[🔧 Troubleshooting Guide](TROUBLESHOOTING.md)** - Fix common deployment and runtime issues

### For Existing Setups
- **[📖 Detailed Setup Guide](SETUP.md)** - Manual step-by-step installation
- **[⚡ Quick Deploy](QUICKSTART.md)** - Fast deployment with prerequisites installed
- **[🌐 API Integration](API_INTEGRATION.md)** - Connect external systems via REST API

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [System Architecture](#system-architecture)
- [Features](#features)
- [Quick Start](#quick-start)
- [Usage Guide](#usage-guide)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)

---

## 🎯 Project Overview

**DFIR Blockchain** is a comprehensive evidence management system designed for digital forensics and incident response. It uses a **dual-blockchain architecture** to ensure evidence integrity, traceability, and compliance with legal standards.

### Purpose

- **Hot Blockchain**: Handles frequent investigative metadata, custody events, and active case management
- **Cold Blockchain**: Provides immutable archival storage for completed cases and evidence files
- **IPFS**: Distributed storage for large evidence files (images, logs, disk dumps)
- **MySQL**: Off-chain database for fast querying and reporting

### Key Benefits

✅ **Immutability** - Evidence records cannot be altered or deleted
✅ **Transparency** - Complete audit trail of custody transfers
✅ **Compliance** - Meets NIST, ISO/IEC 27037, and legal evidence standards
✅ **Scalability** - Handles large files (100MB - 5GB) via IPFS
✅ **Multi-Organization** - Law Enforcement, Forensic Labs, Court, Auditor
✅ **Advanced RBAC** - Role-based access control with 4 roles and 50+ permission rules
✅ **mTLS Security** - All communications encrypted with mutual TLS

---

## 🏗️ System Architecture

### Hot Blockchain (Law Enforcement Chain)
```
┌─────────────────────────────────────────────────────┐
│  Hot Blockchain - Active Investigations            │
├─────────────────────────────────────────────────────┤
│  • Orderer: orderer.hot.coc.com:7050               │
│  • Peer (Law Enforcement): :7051                    │
│  • Peer (Forensic Lab): :8051                       │
│  • Channel: hotchannel                              │
│  • Explorer: http://localhost:8090                  │
└─────────────────────────────────────────────────────┘
```

### Cold Blockchain (Archive Chain)
```
┌─────────────────────────────────────────────────────┐
│  Cold Blockchain - Immutable Archive               │
├─────────────────────────────────────────────────────┤
│  • Orderer: orderer.cold.coc.com:8050              │
│  • Peer (Law Enforcement): :9051                    │
│  • Peer (Forensic Lab): :10051                      │
│  • Channel: coldchannel                             │
│  • Explorer: http://localhost:8091                  │
└─────────────────────────────────────────────────────┘
```

### Supporting Services
```
┌─────────────────────────────────────────────────────┐
│  Shared Infrastructure                              │
├─────────────────────────────────────────────────────┤
│  • IPFS: localhost:5001 (API), :8080 (Gateway)     │
│  • MySQL: localhost:3306                            │
│  • phpMyAdmin: http://localhost:8081                │
│  • Flask Webapp: http://localhost:5000              │
└─────────────────────────────────────────────────────┘
```

---

## ✨ Features

### Evidence Management
- 📁 Upload evidence files to IPFS with automatic hash generation
- 🔗 Store evidence metadata on blockchain (immutable)
- 📝 Track custody transfers and access logs
- 🔍 Search and query evidence by ID, case, type, or date
- 📊 Case management with full evidence lifecycle

### Security
- 🔐 TLS-enabled communications between all nodes
- 🔑 X.509 certificate-based authentication
- 🛡️ Multi-signature endorsement policies
- 📜 Complete audit trail of all operations

### User Interface
- 🌙 Professional dark theme (VS Code-inspired)
- 📤 Drag-and-drop file upload
- 📋 Case creation and management
- 🔍 Real-time blockchain status monitoring
- 📊 Blockchain explorers for both chains

---

## ⚡ Quick Start

### For New Users (Complete Setup)

See **[SETUP.md](SETUP.md)** for complete installation including:
- Installing Docker, Git, Python, Go
- Cloning the repository
- Deploying the blockchain
- Testing the system

### For Users with Prerequisites Installed

See **[QUICKSTART.md](QUICKSTART.md)** for rapid deployment:

```bash
git clone https://github.com/omar-kaaki/Dual-hyperledger-Blockchain.git
cd Dual-hyperledger-Blockchain
git checkout claude/backup-012kvMLwmsqnxqfbzsF2HCYJ
chmod +x *.sh
./nuclear-reset.sh              # Type 'NUCLEAR'
./deploy-chaincode.sh
docker-compose -f docker-compose-storage.yml up -d && sleep 15
docker exec -i mysql-coc mysql -uroot -prootpassword coc_evidence < 01-schema.sql
docker-compose -f docker-compose-explorers.yml up -d && sleep 30
./launch-webapp.sh
```

**Access:** http://localhost:5000

---

## 📦 Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04+ / Debian 11+ / macOS / Windows WSL2
- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 20GB free space
- **CPU**: 4 cores minimum

### Required Software

See [SETUP.md](SETUP.md) for detailed installation instructions.

#### 1. Docker & Docker Compose
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker-compose --version

# Add user to docker group (optional)
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. Python 3.8+
```bash
# Check Python version
python3 --version

# Install pip
sudo apt-get install -y python3-pip
```

#### 3. Git
```bash
sudo apt-get install -y git
```

---

## 🚀 Installation & Setup

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/omar-kaaki/Dual-hyperledger-Blockchain.git
cd Dual-hyperledger-Blockchain

# Checkout the clean setup branch
git checkout clean-setup-guide
```

### Step 2: Install Python Dependencies

```bash
# Install required Python packages
pip3 install --break-system-packages --ignore-installed flask mysql-connector-python
```

### Step 3: Initialize the Blockchain System

```bash
# Navigate to scripts directory
cd scripts

# Make script executable
chmod +x nuclear-reset.sh

# Run the nuclear reset (regenerates everything from scratch)
./nuclear-reset.sh
```

**What `nuclear-reset.sh` does:**

1. ✅ Stops all running containers
2. ✅ Cleans all volumes and networks
3. ✅ Regenerates cryptographic material (certificates, keys)
4. ✅ Creates channel configuration blocks
5. ✅ Starts all Docker containers (peers, orderers, IPFS, MySQL)
6. ✅ Joins orderers to channels using osnadmin API
7. ✅ Joins peers to channels
8. ✅ Updates anchor peers

**Expected Duration**: 5-10 minutes

### Step 4: Deploy Chaincode (Smart Contracts)

```bash
# Deploy chaincode to both hot and cold blockchains
./deploy-chaincode.sh
```

**What `deploy-chaincode.sh` does:**

1. ✅ Packages chaincode for both hot and cold chains
2. ✅ Installs chaincode on all peers
3. ✅ Approves chaincode for each organization
4. ✅ Commits chaincode to channels
5. ✅ Initializes chaincode (if required)

**Expected Duration**: 2-3 minutes

### Step 5: Start the Web Application

```bash
# Navigate to webapp directory
cd ../webapp

# Start webapp in background
nohup python3 app_blockchain.py > webapp.log 2>&1 &

# Monitor logs
tail -f webapp.log
```

**Webapp will start on**: http://localhost:5000

---

## 🎮 Running the System

### Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| **Main Dashboard** | http://localhost:5000 | N/A |
| **phpMyAdmin** | http://localhost:8081 | User: `cocuser`<br>Pass: `cocpassword` |
| **Hot Chain Explorer** | http://localhost:8090 | User: `exploreradmin`<br>Pass: `exploreradminpw` |
| **Cold Chain Explorer** | http://localhost:8091 | User: `exploreradmin`<br>Pass: `exploreradminpw` |
| **IPFS Gateway** | http://localhost:8080 | N/A |
| **IPFS Web UI** | https://webui.ipfs.io | N/A |

### Verify System Health

```bash
# Check all containers are running
docker ps

# Expected containers (13 total):
# - orderer.hot.coc.com
# - orderer.cold.coc.com
# - peer0.lawenforcement.hot.coc.com
# - peer0.forensiclab.hot.coc.com
# - peer0.lawenforcement.cold.coc.com
# - peer0.forensiclab.cold.coc.com
# - cli (hot chain CLI)
# - cli.cold (cold chain CLI)
# - ipfs-node
# - mysql-coc
# - phpmyadmin
# - explorer.hot.coc.com
# - explorer.cold.coc.com
```

```bash
# Check blockchain status via API
curl http://localhost:5000/api/blockchain/status | python3 -m json.tool

# Check IPFS status
curl http://localhost:5000/api/ipfs/status | python3 -m json.tool

# Check container status
curl http://localhost:5000/api/containers/status | python3 -m json.tool
```

---

## 📖 Usage Guide

### Creating a Case

1. Open http://localhost:5000 in your browser
2. Click **"➕ Create New Case"** button
3. Fill in case details:
   - **Case ID**: Unique identifier (e.g., CASE-001)
   - **Case Name**: Descriptive name
   - **Case Number**: Official case number
   - **Case Type**: Digital Forensics, Cybercrime, etc.
   - **Investigating Agency**: FBI, Local Police, etc.
   - **Lead Investigator**: Agent name
   - **Opened Date**: Case start date
   - **Description**: Brief case summary
4. Click **"Create Case"**

### Uploading Evidence

1. **Select Case**: Choose case from dropdown
2. **Evidence ID**: Enter unique ID (e.g., EVD-001)
3. **Evidence Type**: Digital Evidence, Physical Evidence, etc.
4. **Description**: Describe the evidence
5. **Collected By**: Name of collector
6. **Blockchain**: Select Hot Chain or Cold Chain
7. **Upload File**:
   - Click "Choose File" or drag-and-drop
   - File automatically uploads to IPFS
   - Hash is calculated (SHA-256)
8. Click **"Submit Evidence"**

### Viewing Evidence

```bash
# Query MySQL database for all evidence
docker exec mysql-coc mysql -ucocuser -pcocpassword -e "SELECT evidence_id, case_id, description FROM coc_evidence.evidence_metadata;"

# Query blockchain directly
docker exec cli peer chaincode query -C hotchannel -n dfir_chaincode -c '{"Args":["ReadEvidenceSimple","EVD-001"]}'
```

### Monitoring Blockchain

Visit the explorers to see:
- Block heights
- Transaction history
- Chaincode installed
- Network topology

---

## 🔌 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Endpoints

#### GET `/blockchain/status`
Get blockchain health status
```bash
curl http://localhost:5000/api/blockchain/status
```

**Response:**
```json
{
  "hot_blockchain": {
    "height": 15,
    "channel": "hotchannel",
    "chaincode": "dfir_chaincode"
  },
  "cold_blockchain": {
    "height": 9,
    "channel": "coldchannel",
    "chaincode": "dfir_chaincode"
  }
}
```

#### POST `/evidence/create`
Create new evidence record
```bash
curl -X POST http://localhost:5000/api/evidence/create \
  -H "Content-Type: application/json" \
  -d '{
    "id": "EVD-001",
    "case_id": "CASE-001",
    "type": "Digital Evidence",
    "description": "Laptop hard drive",
    "hash": "sha256:abc123...",
    "location": "ipfs://QmXyz...",
    "blockchain": "hot",
    "metadata": "{\"collected_by\":\"Agent Smith\"}"
  }'
```

#### GET `/evidence/<id>`
Query evidence by ID
```bash
curl http://localhost:5000/api/evidence/EVD-001
```

#### GET `/evidence/list`
List all evidence
```bash
curl http://localhost:5000/api/evidence/list
```

#### POST `/ipfs/upload`
Upload file to IPFS
```bash
curl -X POST http://localhost:5000/api/ipfs/upload \
  -F "file=@/path/to/evidence.img"
```

#### GET `/ipfs/status`
Get IPFS node status
```bash
curl http://localhost:5000/api/ipfs/status
```

#### GET `/cases/list`
List all cases
```bash
curl http://localhost:5000/api/cases/list
```

#### POST `/cases/create`
Create new case
```bash
curl -X POST http://localhost:5000/api/cases/create \
  -H "Content-Type: application/json" \
  -d '{
    "case_id": "CASE-002",
    "case_name": "Cybercrime Investigation",
    "case_number": "INV-2025-002",
    "case_type": "Cybercrime",
    "investigating_agency": "FBI",
    "lead_investigator": "Agent Johnson",
    "opened_date": "2025-01-15"
  }'
```

---

## 🔧 Troubleshooting

### Issue: Containers Won't Start

**Symptoms**: `docker ps` shows no containers or some missing

**Solution**:
```bash
# Check Docker is running
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Re-run nuclear reset
cd scripts
./nuclear-reset.sh
```

### Issue: Port Already in Use

**Symptoms**: Error like "port 5000 is already allocated"

**Solution**:
```bash
# Find process using port
lsof -i :5000

# Kill the process
kill -9 <PID>

# Or restart webapp
pkill -9 -f app_blockchain.py
cd webapp
nohup python3 app_blockchain.py > webapp.log 2>&1 &
```

### Issue: Peer Crashes with "Config File 'core' Not Found"

**Symptoms**: Peer containers exit immediately

**Solution**: This is already fixed in `nuclear-reset.sh`. Run:
```bash
cd scripts
./nuclear-reset.sh
```

### Issue: Chaincode Sequence Error

**Symptoms**: "requested sequence is 1, but new definition must be sequence 2"

**Solution**: Already fixed - chaincode uses sequence 2. Redeploy:
```bash
cd scripts
./deploy-chaincode.sh
```

### Issue: Evidence Not Appearing in MySQL

**Symptoms**: Evidence on blockchain but not in phpMyAdmin

**Solution**: This is fixed in the latest version. Pull latest changes:
```bash
git pull origin clean-setup-guide
cd webapp
pkill -9 -f app_blockchain.py
nohup python3 app_blockchain.py > webapp.log 2>&1 &
```

### Issue: "No such file or directory" for configtx

**Symptoms**: Channel creation fails

**Solution**: Already fixed - uses Fabric 2.x `outputBlock` method

### Issue: Webapp Shows Black Screen

**Symptoms**: Browser loads but shows nothing

**Solution**:
```bash
# Check webapp logs
tail -50 ~/Documents/block/Dual-hyperledger-Blockchain/webapp/webapp.log

# Restart webapp
pkill -9 -f app_blockchain.py
cd webapp
nohup python3 app_blockchain.py > webapp.log 2>&1 &
```

### Viewing Logs

```bash
# Webapp logs
tail -f webapp/webapp.log

# Hot blockchain peer
docker logs -f peer0.lawenforcement.hot.coc.com

# Hot orderer
docker logs -f orderer.hot.coc.com

# Cold blockchain peer
docker logs -f peer0.lawenforcement.cold.coc.com

# IPFS
docker logs -f ipfs-node

# MySQL
docker logs -f mysql-coc
```

### Complete System Reset

If everything is broken, do a complete reset:
```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all volumes
docker volume rm $(docker volume ls -q)

# Remove all networks
docker network prune -f

# Start fresh
cd scripts
./nuclear-reset.sh
./deploy-chaincode.sh

cd ../webapp
nohup python3 app_blockchain.py > webapp.log 2>&1 &
```

---

## 📁 Project Structure

```
Dual-hyperledger-Blockchain/
│
├── docker-compose.yml              # Main Docker Compose file
│
├── scripts/
│   ├── nuclear-reset.sh           # Complete system reset & initialization
│   ├── deploy-chaincode.sh        # Deploy chaincode to both chains
│   └── launch_webapp.sh           # Start Flask webapp
│
├── hot-blockchain/
│   ├── configtx.yaml              # Hot chain configuration
│   ├── crypto-config.yaml         # Crypto material specification
│   ├── crypto-config/             # Generated certificates & keys
│   ├── channel-artifacts/         # Channel blocks & transactions
│   └── chaincode/
│       └── chaincode.go           # Hot chain smart contract
│
├── cold-blockchain/
│   ├── configtx.yaml              # Cold chain configuration
│   ├── crypto-config.yaml         # Crypto material specification
│   ├── crypto-config/             # Generated certificates & keys
│   ├── channel-artifacts/         # Channel blocks & transactions
│   └── chaincode/
│       └── chaincode.go           # Cold chain smart contract
│
├── config/
│   └── core.yaml                  # Peer configuration template
│
├── webapp/
│   ├── app_blockchain.py          # Flask REST API application
│   ├── templates/
│   │   └── dashboard.html         # Web UI (dark theme)
│   └── webapp.log                 # Application logs
│
├── database/
│   └── init.sql                   # MySQL schema initialization
│
├── explorer/                      # Hot chain explorer config
├── explorer-cold/                 # Cold chain explorer config
│
├── fabric-samples/                # Hyperledger Fabric binaries
│
└── README.md                      # This file
```

---

## 🛠️ Development & Customization

### Modifying Chaincode

1. Edit chaincode:
   - Hot chain: `hot-blockchain/chaincode/chaincode.go`
   - Cold chain: `cold-blockchain/chaincode/chaincode.go`

2. Increment sequence in `deploy-chaincode.sh`:
   ```bash
   CC_SEQUENCE=3  # Change from 2 to 3
   ```

3. Redeploy:
   ```bash
   cd scripts
   ./deploy-chaincode.sh
   ```

### Adding New API Endpoints

1. Edit `webapp/app_blockchain.py`
2. Add new Flask route:
   ```python
   @app.route('/api/my-endpoint')
   def my_endpoint():
       # Your code here
       return jsonify({"status": "success"})
   ```
3. Restart webapp:
   ```bash
   pkill -9 -f app_blockchain.py
   cd webapp
   nohup python3 app_blockchain.py > webapp.log 2>&1 &
   ```

### Customizing UI Theme

1. Edit `webapp/templates/dashboard.html`
2. Modify CSS in `<style>` section
3. Refresh browser (Ctrl+Shift+R)

---

## 📚 Technical Details

### Blockchain Specifications

| Component | Hot Chain | Cold Chain |
|-----------|-----------|------------|
| **Consensus** | Raft | Raft |
| **Channel** | hotchannel | coldchannel |
| **Organizations** | Law Enforcement, Forensic Lab | Law Enforcement, Forensic Lab |
| **Endorsement Policy** | AND('LawEnforcement.member', 'ForensicLab.member') | Same |
| **Block Timeout** | 2 seconds | 2 seconds |
| **Max Message Count** | 10 | 10 |
| **Absolute Max Bytes** | 99 MB | 99 MB |

### Chaincode Functions

**CreateEvidenceSimple**(id, caseID, type, description, hash, location, metadata, timestamp)
- Creates new evidence record on blockchain

**ReadEvidenceSimple**(id)
- Retrieves evidence by ID

**UpdateEvidenceStatus**(id, newStatus)
- Updates evidence status (e.g., "collected" → "analyzed")

**TransferCustody**(id, newCustodian)
- Transfers evidence custody to new custodian

**GetEvidenceHistory**(id)
- Returns complete history of evidence modifications

### MySQL Schema

```sql
-- Evidence metadata table
CREATE TABLE evidence_metadata (
    id INT AUTO_INCREMENT PRIMARY KEY,
    evidence_id VARCHAR(100) UNIQUE NOT NULL,
    case_id VARCHAR(100) NOT NULL,
    evidence_type VARCHAR(100),
    description TEXT,
    sha256_hash VARCHAR(64),
    ipfs_hash VARCHAR(100),
    collected_by VARCHAR(100),
    blockchain_type ENUM('hot', 'cold') DEFAULT 'hot',
    collected_timestamp DATETIME,
    location VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (case_id) REFERENCES cases(case_id)
);

-- Cases table
CREATE TABLE cases (
    case_id VARCHAR(100) PRIMARY KEY,
    case_name VARCHAR(255) NOT NULL,
    case_number VARCHAR(100),
    case_type VARCHAR(100),
    investigating_agency VARCHAR(255),
    lead_investigator VARCHAR(255),
    opened_date DATE,
    closed_date DATE,
    status ENUM('open', 'closed', 'archived') DEFAULT 'open',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🔐 Security Considerations

### Production Deployment

⚠️ **This is a development/demonstration system. For production:**

1. **Enable TLS for all communications** ✅ (Already enabled)
2. **Use hardware security modules (HSM)** for key storage
3. **Implement proper RBAC** (Role-Based Access Control)
4. **Enable Fabric CA** for dynamic certificate management
5. **Set up monitoring** (Prometheus + Grafana)
6. **Configure backups** for blockchain data and IPFS
7. **Harden webapp** with authentication (OAuth2, JWT)
8. **Use HTTPS** instead of HTTP
9. **Implement rate limiting** on APIs
10. **Set up log aggregation** (ELK stack)

---

## 📄 License & Legal

This system is designed to comply with:
- **NIST SP 800-61**: Computer Security Incident Handling Guide
- **ISO/IEC 27037:2012**: Guidelines for identification, collection, acquisition, and preservation of digital evidence
- **Federal Rules of Evidence** (Rules 901, 902): Authentication requirements
- **IEEE 2418.2-2020**: Standard for blockchain data format

---

## 👥 Support & Contributing

### Getting Help

- Check the [Troubleshooting](#troubleshooting) section
- Review logs: `docker logs <container-name>`
- Check Hyperledger Fabric docs: https://hyperledger-fabric.readthedocs.io/

### Reporting Issues

Please include:
1. Output of `docker ps`
2. Relevant log files
3. Steps to reproduce
4. Error messages

---

## 🎉 Quick Reference

### Essential Commands

```bash
# Start everything from scratch
cd scripts && ./nuclear-reset.sh && ./deploy-chaincode.sh

# Start webapp
cd webapp && nohup python3 app_blockchain.py > webapp.log 2>&1 &

# Stop all containers
docker stop $(docker ps -aq)

# View logs
tail -f webapp/webapp.log
docker logs -f <container-name>

# Check blockchain height
docker exec cli peer channel getinfo -c hotchannel
docker exec cli.cold peer channel getinfo -c coldchannel

# Query evidence
docker exec cli peer chaincode query -C hotchannel -n dfir_chaincode -c '{"Args":["ReadEvidenceSimple","EVD-001"]}'

# MySQL query
docker exec mysql-coc mysql -ucocuser -pcocpassword -e "SELECT * FROM coc_evidence.evidence_metadata;"
```

---

**Built with**: Hyperledger Fabric 2.5 • IPFS 0.38.2 • MySQL 8.0 • Flask 3.0 • Docker

**Last Updated**: November 2025
