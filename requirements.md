# FYP Blockchain Requirements

This document specifies all system requirements, dependencies, and versions needed to deploy and run the FYP blockchain network based on **Hyperledger Fabric v2.5.14 LTS** - the latest stable release of Hyperledger Fabric as of October 2025.

**Important:** All versions listed below are tested and verified compatible with Fabric v2.5.14.

---

## 0.1 System & Tooling (Host Machine)

### Operating System

**Name:** Linux (64-bit)
**Recommended version:** Kali Linux (Debian-based) or any modern 64-bit Linux distribution
**Install method:** N/A (base OS)
**Why:** Fabric requires a 64-bit Linux environment for production deployments.

### Core Tools

| Name | Recommended Version | Install Method | Why |
|------|---------------------|----------------|-----|
| git | Latest stable (≥ 2.x) | `apt install git` | Version control for codebase management |
| curl | Latest stable | `apt install curl` | Download binaries and make HTTP requests |
| wget | Latest stable | `apt install wget` | Alternative download tool |
| tar | Latest stable | `apt install tar` | Extract compressed archives |
| unzip | Latest stable | `apt install unzip` | Extract ZIP archives |
| jq | Latest stable (≥ 1.6) | `apt install jq` | Parse and manipulate JSON data in scripts |
| openssl | Latest stable | `apt install openssl` | PKI tool for debugging certificates |

### Container Stack

| Name | Recommended Version | Install Method | Why |
|------|---------------------|----------------|-----|
| Docker Engine | ≥ 24.0.x (latest stable: 25.x) | [Official Docker docs](https://docs.docker.com/engine/install/) | Container runtime for all Fabric components |
| Docker Compose Plugin | ≥ v2.20.x (latest v2.x stable) | Included with Docker Engine | Orchestrate multi-container deployments |

**Post-install:** Add current user to docker group to run Docker without sudo:
```bash
sudo usermod -aG docker $USER
```

### Language Runtimes

| Name | Recommended Version | Install Method | Why |
|------|---------------------|----------------|-----|
| Go | ≥ 1.22.x (latest stable: 1.25.4) | [Official Go downloads](https://go.dev/dl/) | Required for Fabric binaries and Go chaincode |
| Node.js | LTS 20.x | [NodeSource repository](https://github.com/nodesource/distributions) or [nvm](https://github.com/nvm-sh/nvm) | Fabric Gateway client SDK (if using Node.js) |
| Python | 3.11+ | `apt install python3.11` or pyenv | Helper scripts and automation tooling |

---

## 0.2 Fabric & CA Components

### Hyperledger Fabric Core

| Component | Version | Install Method | Why |
|-----------|---------|----------------|-----|
| Fabric Docker Images | 2.5.14 | `curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh \| bash -s -- docker binary` | Core peer, orderer, and tools images |
| Fabric CA Docker Images | 1.5.15 | Same script as above | Certificate Authority for MSP management |

**Binaries included:**
- `peer` - Peer node management
- `orderer` - Orderer node management
- `configtxgen` - Generate channel configuration
- `configtxlator` - Translate config between formats
- `osnadmin` - Orderer admin operations
- `fabric-ca-server` - CA server
- `fabric-ca-client` - CA client for enrollment

**Download location:**
Official script downloads to `./fabric-samples/bin/` and Docker images tagged as:
- `hyperledger/fabric-peer:2.5.14`
- `hyperledger/fabric-orderer:2.5.14`
- `hyperledger/fabric-ca:1.5.15`
- `hyperledger/fabric-tools:2.5.14`

**Reference:** [Fabric v2.5.14 Release](https://hyperledger-fabric.readthedocs.io/en/release-2.5/)

### Fabric Gateway SDK

Choose **one** client SDK for backend integration:

| Option | Version | Install Method | Why |
|--------|---------|----------------|-----|
| **Node.js Gateway Client** (Recommended) | Compatible with Fabric 2.5.x | `npm install @hyperledger/fabric-gateway` | Best integration with Django/JumpServer via Node microservice |
| Go Gateway Client | Compatible with Fabric 2.5.x | `go get github.com/hyperledger/fabric-gateway` | Alternative if using Go microservice |

**Reference:** [Fabric Gateway Documentation](https://hyperledger.github.io/fabric-gateway/)

---

## 0.3 Chaincode Dependencies

### Authorization Library

| Name | Version | Install Method | Why |
|------|---------|----------------|-----|
| Casbin for Go | v2 (latest) | Add to chaincode `go.mod`: `github.com/casbin/casbin/v2` | Role-based access control (RBAC) in chaincode |

**Note:** Chaincode needs Casbin model & policy files bundled or generated at build-time.

**Reference:** [Casbin Go Documentation](https://casbin.org/docs/en/get-started)

---

## 0.4 Storage & Database

### State Database (for Rich Queries)

| Name | Recommended Version | Install Method | Why |
|------|---------------------|----------------|-----|
| CouchDB | 3.3.x (latest 3.x stable) | Docker: `docker pull couchdb:3.3` | Enables rich JSON queries on world state |

**Configuration:** Each peer requires its own CouchDB container.

**Reference:** [Fabric CouchDB as State Database](https://hyperledger-fabric.readthedocs.io/en/release-2.5/couchdb_as_state_database.html)

### Distributed Storage

| Name | Recommended Version | Install Method | Why |
|------|---------------------|----------------|-----|
| IPFS (Kubo) | ≥ 0.29.x (latest stable) | Docker: `docker pull ipfs/kubo:latest` OR Native: [Kubo releases](https://github.com/ipfs/kubo/releases) | Decentralized storage for large files/evidence |

**Reference:** [IPFS Kubo Documentation](https://docs.ipfs.tech/install/command-line/)

---

## 0.5 Development & Testing Tools

| Name | Recommended Version | Install Method | Why |
|------|---------------------|----------------|-----|
| make | Latest stable | `apt install build-essential` | Build automation for chaincode and scripts |
| tree | Latest stable | `apt install tree` | Visualize directory structures |
| htop | Latest stable | `apt install htop` | Monitor system resources |

---

## Version Summary

| Component | Version |
|-----------|---------|
| **Hyperledger Fabric** | 2.5.14 (latest LTS) |
| **Fabric CA** | 1.5.15 |
| **Go** | ≥ 1.22.x (latest: 1.25.4) |
| **Node.js** | 20.x LTS |
| **Python** | ≥ 3.11 |
| **Docker Engine** | ≥ 24.0.x (latest: 25.x) |
| **Docker Compose** | ≥ v2.20.x |
| **CouchDB** | 3.3.x |
| **IPFS (Kubo)** | ≥ 0.29.x |
| **Casbin** | v2 (latest) |

---

## Complete Installation Guide

### Prerequisites Check

Before starting, ensure you have:
- 64-bit Linux system (Kali Linux recommended)
- At least 4GB RAM (8GB+ recommended)
- 20GB free disk space
- Internet connection
- sudo/root access

### Step-by-Step Installation (Kali Linux / Debian-based)

#### 1. Update System and Install Core Tools

```bash
# Update package index
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y \
    git \
    curl \
    wget \
    tar \
    unzip \
    jq \
    openssl \
    build-essential \
    tree \
    htop \
    python3 \
    python3-pip
```

#### 2. Install Docker and Docker Compose

```bash
# Install Docker
sudo apt install -y docker.io

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
sudo apt install -y docker-compose

# Add current user to docker group (IMPORTANT)
sudo usermod -aG docker $USER

# Verify Docker installation
docker --version
docker-compose --version

# IMPORTANT: Log out and log back in for group changes to take effect
# Or run: newgrp docker
```

#### 3. Install Go 1.25.4

```bash
# Download Go 1.25.4 (latest stable as of November 5, 2025)
cd ~
wget https://go.dev/dl/go1.25.4.linux-amd64.tar.gz

# Remove old Go installation (if exists)
sudo rm -rf /usr/local/go

# Extract and install
sudo tar -C /usr/local -xzf go1.25.4.linux-amd64.tar.gz

# Add to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
go version
# Should output: go version go1.25.4 linux/amd64

# Clean up
rm go1.25.4.linux-amd64.tar.gz
```

#### 4. Install Node.js 20.x LTS (Optional - for Gateway SDK)

```bash
# Install via nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc

# Install Node.js 20.x LTS
nvm install 20
nvm use 20
nvm alias default 20

# Verify installation
node --version
npm --version
```

#### 5. Install Hyperledger Fabric Binaries v2.5.14

```bash
# Navigate to your project directory
cd ~/FYPBcoc

# Download Fabric binaries and Docker images
# This downloads: peer, orderer, configtxgen, configtxlator, osnadmin,
# fabric-ca-server, fabric-ca-client
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- binary 2.5.14 1.5.15

# The binaries will be downloaded to ./bin directory
# Add them to PATH permanently
echo 'export PATH=$PATH:~/FYPBcoc/bin' >> ~/.bashrc
source ~/.bashrc

# OR copy binaries to /usr/local/bin for system-wide access
sudo cp bin/* /usr/local/bin/

# Verify installations
fabric-ca-client version
# Should output: fabric-ca-client: Version: 1.5.15...

configtxgen --version
# Should output: configtxgen: Version: 2.5.14...

peer version
# Should output: peer: Version: 2.5.14...
```

#### 6. Pull Hyperledger Fabric Docker Images

```bash
# Pull Fabric Docker images (peer, orderer, tools)
docker pull hyperledger/fabric-peer:2.5.14
docker pull hyperledger/fabric-orderer:2.5.14
docker pull hyperledger/fabric-ca:1.5.15
docker pull hyperledger/fabric-tools:2.5.14

# Tag as 'latest' for convenience (optional)
docker tag hyperledger/fabric-peer:2.5.14 hyperledger/fabric-peer:latest
docker tag hyperledger/fabric-orderer:2.5.14 hyperledger/fabric-orderer:latest
docker tag hyperledger/fabric-ca:1.5.15 hyperledger/fabric-ca:latest
docker tag hyperledger/fabric-tools:2.5.14 hyperledger/fabric-tools:latest

# Verify images
docker images | grep hyperledger
```

#### 7. Pull Additional Docker Images

```bash
# Pull CouchDB for state database
docker pull couchdb:3.3

# Pull IPFS for distributed storage (optional for now)
docker pull ipfs/kubo:latest

# Verify all images
docker images
```

#### 8. Clone and Setup FYP Repository

```bash
# Clone the repository
cd ~
git clone https://github.com/rae81/FYPBcoc.git
cd FYPBcoc

# Checkout the development branch
git checkout claude/clone-fyp-repo-01GcQmZnMbvkNkxehnggLCs3

# Pull latest changes
git pull origin claude/clone-fyp-repo-01GcQmZnMbvkNkxehnggLCs3

# Verify directory structure
ls -la
```

### Post-Installation Verification

Run these commands to verify all tools are properly installed:

```bash
# Check Docker
docker --version
docker-compose --version
docker ps

# Check Go
go version

# Check Node.js (if installed)
node --version
npm --version

# Check Fabric tools
fabric-ca-client version
configtxgen --version
peer version

# Check Docker images
docker images | grep hyperledger

# Check project files
cd ~/FYPBcoc
ls -la scripts/
ls -la ca-config/
```

Expected output:
- Docker version ≥ 24.0
- Docker Compose version ≥ 2.20
- Go version 1.25.4
- fabric-ca-client version 1.5.15
- configtxgen version 2.5.14
- peer version 2.5.14

---

## Testing the CA Infrastructure

After installation, test the Certificate Authority setup for both blockchains:

### Testing HOT Blockchain (Active Investigation Chain)

#### Option 1: Quick Validation (No Crypto Generation)

```bash
cd ~/FYPBcoc/hot-blockchain

# Run test script without generating crypto material
./scripts/test-ca-setup.sh --skip-crypto
```

This will verify:
- All required tools are installed
- Configuration files exist and are valid
- Docker Compose syntax is correct
- Docker network setup

#### Option 2: Full Test (Generate Crypto Material)

```bash
cd ~/FYPBcoc/hot-blockchain

# Run full test including crypto generation
# This will start CA containers and generate all certificates
./scripts/test-ca-setup.sh
```

This will:
1. Start all 4 CA containers (OrdererOrg + LabOrg)
2. Verify CA API health
3. Generate crypto material for all identities
4. Validate certificate structure
5. Test configtx.yaml

#### Manual Crypto Generation

```bash
cd ~/FYPBcoc/hot-blockchain

# Start CA containers
docker-compose -f docker-compose-ca.yaml up -d

# Wait for CAs to be ready (10-15 seconds)
sleep 15

# Generate all crypto material
./scripts/generate-crypto.sh

# Verify crypto-config directory
tree -L 4 crypto-config/
```

### Testing COLD Blockchain (Archival Chain)

#### Option 1: Quick Validation (No Crypto Generation)

```bash
cd ~/FYPBcoc/cold-blockchain

# Run test script without generating crypto material
./scripts/test-ca-setup.sh --skip-crypto
```

#### Option 2: Full Test (Generate Crypto Material)

```bash
cd ~/FYPBcoc/cold-blockchain

# Run full test including crypto generation
# This will start CA containers and generate all certificates
./scripts/test-ca-setup.sh
```

This will:
1. Start all 6 CA containers (OrdererOrg + LabOrg + CourtOrg)
2. Verify CA API health
3. Generate crypto material for all identities
4. Validate certificate structure
5. Test configtx.yaml

#### Manual Crypto Generation

```bash
cd ~/FYPBcoc/cold-blockchain

# Start CA containers
docker-compose -f docker-compose-ca.yaml up -d

# Wait for CAs to be ready (10-15 seconds)
sleep 15

# Generate all crypto material
./scripts/generate-crypto.sh

# Verify crypto-config directory
tree -L 4 crypto-config/
```

### Cleanup

To stop CA containers and clean up:

```bash
# Stop HOT chain CA containers
cd ~/FYPBcoc/hot-blockchain
docker-compose -f docker-compose-ca.yaml down

# Stop COLD chain CA containers
cd ~/FYPBcoc/cold-blockchain
docker-compose -f docker-compose-ca.yaml down

# Remove generated crypto material (optional)
cd ~/FYPBcoc
rm -rf hot-blockchain/crypto-config/*
rm -rf cold-blockchain/crypto-config/*
rm -rf .fabric-ca-client/
```

---

## 5. Chaincode Development and Deployment

### 5.1 Chaincode Overview

The Chain of Custody system uses a single Go chaincode (`coc_chaincode`) deployed as:
- **hot_chaincode** on `hot-chain` (Active Investigation)
- **cold_chaincode** on `cold-chain` (Archival)

**Architecture:**
- Language: Go 1.21+
- RBAC Framework: Casbin v2.97.0 with domain support
- Gateway Identity: `lab-gw@LabOrgMSP` (JumpServer integration)
- Access Control: On-chain role mapping + Casbin policy enforcement
- Security: TLS, transient user context, admin NodeOU validation

### 5.2 Chaincode Structure

```
coc_chaincode/
├── access/                    # Casbin RBAC configuration
│   ├── casbin_model.conf     # Domain-based RBAC model (hot/cold)
│   └── casbin_policy.csv     # Permission policies for 4 roles
├── rbac/                      # Gateway and user management
│   ├── gateway.go            # Identity validation (MSP ID + CN)
│   └── userroles.go          # On-chain user role mapping
├── domain/                    # Business logic
│   ├── investigation.go      # CRUD + archive/reopen operations
│   ├── evidence.go           # CRUD + chain of custody tracking
│   └── guidmap.go            # GUID↔Evidence mapping (cold-chain)
├── utils/
│   └── json.go               # JSON marshaling helpers
├── main.go                    # Chaincode entry point with routing
├── go.mod                     # Go module definition
├── build.sh                   # Build and package script
└── README.md                  # Comprehensive documentation
```

### 5.3 RBAC Roles and Permissions

**Casbin Domain-Based Policies:**

| Role | Hot Chain | Cold Chain |
|------|-----------|------------|
| **BlockchainInvestigator** | Full CRUD on investigations and evidence | Read-only access |
| **BlockchainAuditor** | Read-only access to all data | Read-only access to all data |
| **BlockchainCourt** | No access | View, archive, reopen, GUID management |
| **SystemAdmin** | User role management | User role management |

**Access Control Flow:**
1. JumpServer connects with `lab-gw` gateway identity
2. Transient map contains `userId` and `role` (privacy - not on ledger)
3. Chaincode validates gateway identity (MSPID + CN)
4. Extracts user context from transient
5. Builds principal ID: `LabOrgMSP|lab-gw|user:<userId>`
6. Validates user has claimed role in on-chain mapping
7. Enforces Casbin policy: (role, domain, object, action)
8. Executes business logic if permitted

### 5.4 Data Models

**Investigation** (Key: `INVESTIGATION:<id>`):
```json
{
  "id": "INV-2025-0001",
  "title": "Investigation title",
  "description": "Detailed description",
  "status": "open" | "archived",
  "createdBy": "userId",
  "createdAt": "RFC3339 timestamp",
  "updatedAt": "RFC3339 timestamp",
  "channel": "hot" | "cold"
}
```

**Evidence** (Key: `EVIDENCE:<id>`):
```json
{
  "id": "EVID-0001",
  "investigationId": "INV-2025-0001",
  "hash": "sha256:...",
  "ipfsCid": "bafy...",
  "createdBy": "userId",
  "createdAt": "RFC3339 timestamp",
  "channel": "hot" | "cold",
  "meta": {
    "type": "disk image",
    "sizeBytes": 123456789,
    "fileName": "evidence.img",
    "notes": "Optional notes"
  },
  "chainOfCustody": [
    {
      "timestamp": "RFC3339",
      "action": "collected",
      "custodian": "userId",
      "location": "Lab A",
      "description": "Evidence collected from scene"
    }
  ]
}
```

**GUID Mapping** (Key: `GUIDMAP:<guid>`) - Cold-chain only:
```json
{
  "guid": "GUID-XYZ-123",
  "internalEvidenceId": "EVID-0001",
  "createdBy": "court-user-id",
  "createdAt": "RFC3339 timestamp",
  "description": "Court case reference"
}
```

**User Role** (Key: `USERROLE:<principalId>`):
```json
{
  "principalId": "LabOrgMSP|lab-gw|user:investigator1",
  "roles": ["BlockchainInvestigator", "BlockchainAuditor"],
  "updatedBy": "admin-id",
  "updatedAt": "RFC3339 timestamp"
}
```

### 5.5 Chaincode Functions

**Admin Functions** (require admin NodeOU):
- `SetUserRoles(principalID, rolesCsv)` - Assign roles to user
- `GetUserRoles(principalID)` - Query user's roles
- `ListUserRoles()` - List all user role mappings
- `DeleteUserRole(principalID)` - Remove user role mapping

**Investigation Functions** (require gateway + user context):
- `CreateInvestigation(id, title, description)` - Create new investigation
- `GetInvestigation(id)` - Retrieve investigation by ID
- `UpdateInvestigation(id, title, description)` - Update investigation
- `ListInvestigations()` - List all investigations
- `ArchiveInvestigation(id)` - Archive investigation (cold-chain only)
- `ReopenInvestigation(id)` - Reopen archived investigation (cold-chain only)

**Evidence Functions** (require gateway + user context):
- `AddEvidence(id, investigationId, hash, ipfsCid, metaJSON)` - Add evidence
- `GetEvidence(id)` - Retrieve evidence by ID
- `ListEvidence()` - List all evidence
- `ListEvidenceByInvestigation(investigationId)` - Filter by investigation
- `AddCustodyEvent(evidenceId, action, custodian, location, description)` - Add custody event
- `VerifyEvidenceHash(evidenceId, hash)` - Verify hash integrity

**GUID Mapping Functions** (require gateway + user context, cold-chain only):
- `CreateGUIDMapping(guid, internalEvidenceId, description)` - Create mapping
- `ResolveGUID(guid)` - Resolve GUID to evidence ID
- `GetEvidenceByGUID(guid)` - Retrieve evidence by GUID
- `ListGUIDMappings()` - List all GUID mappings

### 5.6 Building the Chaincode

```bash
cd ~/FYPBcoc/coc_chaincode

# Build and package chaincode
./build.sh
```

**Build process:**
1. Downloads Go dependencies
2. Vendors dependencies (creates `vendor/` directory)
3. Builds chaincode binary
4. Creates `coc_chaincode.tar.gz` package

**Build output:**
- `coc_chaincode` - Binary (for testing)
- `coc_chaincode.tar.gz` - Package for deployment
- `vendor/` - Vendored dependencies

### 5.7 Deploying Chaincode

#### Deploy to Hot Blockchain

```bash
cd ~/FYPBcoc/hot-blockchain
./scripts/deploy-chaincode.sh
```

**Deployment details:**
- Chaincode name: `hot_chaincode`
- Version: 1.0
- Sequence: 1
- Channel: `hot-chain`
- Endorsement policy: `OR('LabOrgMSP.peer')`
- Installed on: `peer0.laborg.hot.coc.com`

**Deployment steps:**
1. Builds chaincode package
2. Packages for Fabric lifecycle
3. Installs on LabOrg peer
4. Approves for LabOrg
5. Commits chaincode definition
6. Initializes chaincode

#### Deploy to Cold Blockchain

```bash
cd ~/FYPBcoc/cold-blockchain
./scripts/deploy-chaincode.sh
```

**Deployment details:**
- Chaincode name: `cold_chaincode`
- Version: 1.0
- Sequence: 1
- Channel: `cold-chain`
- Endorsement policy: `AND('LabOrgMSP.peer','CourtOrgMSP.peer')`
- Installed on: `peer0.laborg.cold.coc.com`, `peer0.courtorg.cold.coc.com`

**Deployment steps:**
1. Builds chaincode package
2. Packages for Fabric lifecycle
3. Installs on both LabOrg and CourtOrg peers
4. Approves for both organizations
5. Commits chaincode definition (requires both endorsements)
6. Initializes chaincode

### 5.8 Testing Chaincode

#### Set User Roles (Admin Function)

```bash
# Set environment for LabOrg admin
export CORE_PEER_LOCALMSPID="LabOrgMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_ADDRESS="localhost:7051"
export CORE_PEER_TLS_ROOTCERT_FILE=/home/user/FYPBcoc/hot-blockchain/crypto-config/peerOrganizations/laborg.hot.coc.com/peers/peer0.laborg.hot.coc.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/user/FYPBcoc/hot-blockchain/crypto-config/peerOrganizations/laborg.hot.coc.com/users/Admin@laborg.hot.coc.com/msp

# Assign BlockchainInvestigator role to user
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.hot.coc.com \
  --tls \
  --cafile /home/user/FYPBcoc/hot-blockchain/crypto-config/ordererOrganizations/ordererorg.hot.coc.com/tlsca/tlsca.ordererorg.hot.coc.com-cert.pem \
  -C hot-chain \
  -n hot_chaincode \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles /home/user/FYPBcoc/hot-blockchain/crypto-config/peerOrganizations/laborg.hot.coc.com/peers/peer0.laborg.hot.coc.com/tls/ca.crt \
  -c '{"function":"SetUserRoles","Args":["LabOrgMSP|lab-gw|user:investigator1","BlockchainInvestigator"]}'

# Query user roles
peer chaincode query \
  -C hot-chain \
  -n hot_chaincode \
  -c '{"function":"GetUserRoles","Args":["LabOrgMSP|lab-gw|user:investigator1"]}'
```

#### Create Investigation (Gateway Function with Transient)

**Note:** In production, JumpServer will provide the transient map. For testing:

```bash
# Transient map values must be base64 encoded
# userId: investigator1 -> aW52ZXN0aWdhdG9yMQ==
# role: BlockchainInvestigator -> QmxvY2tjaGFpbkludmVzdGlnYXRvcg==

peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.hot.coc.com \
  --tls \
  --cafile /home/user/FYPBcoc/hot-blockchain/crypto-config/ordererOrganizations/ordererorg.hot.coc.com/tlsca/tlsca.ordererorg.hot.coc.com-cert.pem \
  -C hot-chain \
  -n hot_chaincode \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles /home/user/FYPBcoc/hot-blockchain/crypto-config/peerOrganizations/laborg.hot.coc.com/peers/peer0.laborg.hot.coc.com/tls/ca.crt \
  --transient '{"userId":"aW52ZXN0aWdhdG9yMQ==","role":"QmxvY2tjaGFpbkludmVzdGlnYXRvcg=="}' \
  -c '{"function":"CreateInvestigation","Args":["INV-2025-001","Test Investigation","Initial test investigation"]}'
```

#### Query Investigation

```bash
peer chaincode invoke \
  -C hot-chain \
  -n hot_chaincode \
  --transient '{"userId":"aW52ZXN0aWdhdG9yMQ==","role":"QmxvY2tjaGFpbkludmVzdGlnYXRvcg=="}' \
  -c '{"function":"GetInvestigation","Args":["INV-2025-001"]}'
```

### 5.9 Security Considerations

**Gateway Enforcement:**
- Only `lab-gw@LabOrgMSP` identity can invoke business functions
- Chaincode validates MSP ID and CN on every invocation
- Non-gateway identities are immediately rejected

**User Context Privacy:**
- User ID and role passed via transient map
- Transient data not written to ledger
- Only principal ID stored in role mapping (no sensitive data)

**On-Chain Role Mapping:**
- Provides audit trail of role assignments
- Admin-only modification (NodeOU validation)
- Principal ID format prevents impersonation

**Casbin Policy Enforcement:**
- Fine-grained permissions per function
- Domain separation (hot vs cold)
- Object-level access control

**TLS Security:**
- All peer-to-peer communication uses TLS
- Certificate validation on all connections
- Mutual TLS (mTLS) between components

**Admin Functions:**
- Require admin NodeOU in certificate
- Separate from gateway path
- LabOrg and CourtOrg admins supported

### 5.10 Chaincode Upgrade Process

When upgrading chaincode to a new version:

```bash
# 1. Update chaincode source code
cd ~/FYPBcoc/coc_chaincode
# ... make changes ...

# 2. Rebuild
./build.sh

# 3. Update deployment scripts with new version and sequence
# Edit hot-blockchain/scripts/deploy-chaincode.sh
# Change: CHAINCODE_VERSION="1.1"
# Change: CHAINCODE_SEQUENCE=2

# 4. Redeploy
cd ~/FYPBcoc/hot-blockchain
./scripts/deploy-chaincode.sh

# Repeat for cold-chain
cd ~/FYPBcoc/cold-blockchain
./scripts/deploy-chaincode.sh
```

**Important:** On cold-chain, both LabOrg and CourtOrg must approve the upgrade.

### 5.11 Troubleshooting

**Issue:** Chaincode build fails with missing dependencies

**Fix:**
```bash
cd coc_chaincode
go mod tidy
go mod vendor
./build.sh
```

**Issue:** Chaincode installation fails

**Fix:**
```bash
# Check peer is running
docker ps | grep peer

# Check peer logs
docker logs peer0.laborg.hot.coc.com

# Verify package exists
ls -lh hot-blockchain/hot_chaincode_1.0.tar.gz
```

**Issue:** Permission denied on chaincode invocation

**Fix:**
- Verify user role is set: `GetUserRoles`
- Check transient map is base64 encoded correctly
- Verify gateway identity is lab-gw
- Check Casbin policy allows the action

**Issue:** Endorsement policy not satisfied on cold-chain

**Fix:**
- Ensure both LabOrg and CourtOrg peers are running
- Verify chaincode installed on both peers
- Check both peer addresses in invocation

---

## 6. Network Deployment

### 6.1 Docker Network Architecture

The system uses separate Docker networks for isolation:

- **hot-network**: HOT blockchain components
- **cold-network**: COLD blockchain components
- **ipfs-network**: IPFS and evidence upload service
- Cross-network connectivity for evidence upload service to both blockchains

### 6.2 Network Components

#### HOT Blockchain Network (`docker-compose-network.yaml`)

| Component | Container Name | Ports | Purpose |
|-----------|---------------|-------|---------|
| Orderer | orderer.hot.coc.com | 7050, 7053, 8443 | Transaction ordering |
| Peer | peer0.laborg.hot.coc.com | 7051, 7052, 9443 | Ledger + chaincode |
| CouchDB | couchdb.peer0.laborg.hot.coc.com | 5984 | State database |
| CLI | cli.hot | N/A | Admin tool |

**Features:**
- mTLS enabled on orderer and peer
- Fabric Gateway enabled on peer (for JumpServer)
- Prometheus metrics enabled
- TLS client authentication required

#### COLD Blockchain Network (`docker-compose-network.yaml`)

| Component | Container Name | Ports | Purpose |
|-----------|---------------|-------|---------|
| Orderer | orderer.cold.coc.com | 7150, 7153, 8543 | Transaction ordering |
| Peer (LabOrg) | peer0.laborg.cold.coc.com | 8051, 8052, 9543 | Ledger + chaincode |
| Peer (CourtOrg) | peer0.courtorg.cold.coc.com | 9051, 9052, 9643 | Ledger + chaincode |
| CouchDB (LabOrg) | couchdb.peer0.laborg.cold.coc.com | 6984 | State database |
| CouchDB (CourtOrg) | couchdb.peer0.courtorg.cold.coc.com | 7984 | State database |
| CLI | cli.cold | N/A | Admin tool |

**Features:**
- mTLS enabled on all components
- Dual-peer endorsement (LabOrg + CourtOrg)
- Gateway enabled on LabOrg peer only
- Separate operations endpoints for monitoring

### 6.3 Starting the Networks

**Prerequisites:**
1. CA infrastructure running
2. Crypto materials generated
3. Channel artifacts created

**Start HOT Blockchain:**
```bash
cd hot-blockchain
./scripts/start-network.sh
```

**Start COLD Blockchain:**
```bash
cd cold-blockchain
./scripts/start-network.sh
```

The scripts automatically:
- Stop existing containers
- Start network components
- Wait for containers to be healthy
- Test connectivity
- Create channel (if not already created)
- Display network status and endpoints

### 6.4 Stopping the Networks

```bash
# Stop HOT blockchain
cd hot-blockchain && ./scripts/stop-network.sh

# Stop COLD blockchain
cd cold-blockchain && ./scripts/stop-network.sh
```

You will be prompted to remove data volumes (ledger data).

### 6.5 Network Health Checks

**Check running containers:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Check peer health (Prometheus endpoint):**
```bash
# HOT peer
curl http://localhost:9443/healthz

# COLD LabOrg peer
curl http://localhost:9543/healthz

# COLD CourtOrg peer
curl http://localhost:9643/healthz
```

**Check CouchDB:**
```bash
# HOT CouchDB
curl http://admin:adminpw@localhost:5984/_up

# COLD LabOrg CouchDB
curl http://admin:adminpw@localhost:6984/_up

# COLD CourtOrg CouchDB
curl http://admin:adminpw@localhost:7984/_up
```

**View logs:**
```bash
# HOT peer
docker logs -f peer0.laborg.hot.coc.com

# COLD LabOrg peer
docker logs -f peer0.laborg.cold.coc.com

# COLD CourtOrg peer
docker logs -f peer0.courtorg.cold.coc.com
```

---

## 7. IPFS Integration and Evidence Upload

### 7.1 IPFS Infrastructure

The system uses IPFS (InterPlanetary File System) for decentralized storage of evidence files. Only metadata (CID, hash, description) is stored on-chain.

#### IPFS Components (`docker-compose-ipfs.yaml`)

| Component | Container Name | Ports | Purpose |
|-----------|---------------|-------|---------|
| IPFS Node | ipfs.coc | 4001, 5001, 8080 | Decentralized storage |
| Nginx Proxy | ipfs-proxy.coc | 5443, 8443 | HTTPS reverse proxy |
| Upload Service | evidence-upload.coc | 3000 | REST API for uploads |

**IPFS Kubo:** Version 0.24.0
**Storage:** Persistent volumes for IPFS data and staging
**Network:** Connected to hot-network, cold-network, ipfs-network

### 7.2 Evidence Upload Service

A Node.js/TypeScript microservice that handles:
1. File uploads (multipart/form-data)
2. SHA256 hash computation
3. IPFS upload (get CID)
4. Fabric chaincode invocation (via Gateway SDK)
5. Response to caller

**Technology Stack:**
- Node.js 20 LTS
- TypeScript 5.3
- Express 4.18 (REST API)
- Multer 1.4 (file uploads)
- @hyperledger/fabric-gateway 1.5 (blockchain integration)
- ipfs-http-client 60.0 (IPFS integration)

**Source Structure:**
```
evidence-upload-service/
├── src/
│   ├── index.ts                 # Main REST API server
│   ├── config.ts                # Environment configuration
│   ├── utils/
│   │   ├── logger.ts            # Winston logger
│   │   └── hash.ts              # SHA256 computation
│   └── services/
│       ├── ipfs.ts              # IPFS upload/retrieval
│       └── fabric.ts            # Fabric Gateway integration
├── package.json                 # Dependencies
├── tsconfig.json                # TypeScript config
├── Dockerfile                   # Container image
└── .env.example                 # Environment template
```

### 7.3 Evidence Upload Workflow

```
┌─────────────┐
│  JumpServer │  (or direct upload)
│   (Client)  │
└──────┬──────┘
       │ POST /api/evidence/upload
       │ (file + metadata)
       ▼
┌─────────────────────────┐
│ Evidence Upload Service │
└───┬─────────────────┬───┘
    │                 │
    │ 1. Compute      │ 3. Invoke chaincode
    │    SHA256       │    via Gateway
    │                 │
    │ 2. Upload to    │
    │    IPFS (CID)   │
    ▼                 ▼
┌────────┐      ┌──────────────┐
│  IPFS  │      │   Fabric     │
│  Node  │      │ Peer (LabOrg)│
└────────┘      └──────────────┘
```

**Steps:**
1. Client uploads file with metadata
2. Service computes SHA256 hash of file
3. Service uploads file to IPFS, receives CID
4. Service invokes `AddEvidence` chaincode function:
   - Gateway identity: lab-gw@LabOrgMSP
   - Transient data: userId + role
   - Arguments: evidenceId, investigationId, description, CID, SHA256, metadata
5. Chaincode validates permissions (Casbin RBAC)
6. Chaincode writes on-chain record
7. Service returns response to client

### 7.4 API Endpoints

#### Upload Evidence

**Endpoint:** `POST /api/evidence/upload`

**Content-Type:** `multipart/form-data`

**Parameters:**
- `file` (required): Evidence file (max 500MB)
- `investigationId` (required): Investigation ID
- `description` (required): Evidence description
- `userId` (required): User ID (format: `user:<username>`)
- `userRole` (required): Blockchain role
- `chain` (optional): Target chain (`hot` or `cold`, default: `hot`)
- `metadata` (optional): Additional JSON metadata

**Response:**
```json
{
  "success": true,
  "evidenceId": "uuid",
  "cid": "bafybeigdyrzt...",
  "sha256": "e3b0c44298fc...",
  "txId": "fabric-tx-id",
  "chain": "hot"
}
```

#### Get Evidence Metadata

**Endpoint:** `GET /api/evidence/:evidenceId?chain=hot`

**Response:**
```json
{
  "success": true,
  "evidence": {
    "evidenceId": "uuid",
    "investigationId": "inv-id",
    "description": "...",
    "cid": "bafybeigdyrzt...",
    "sha256": "e3b0c44298fc...",
    "metadata": "{...}",
    "recordedAt": "timestamp",
    "recordedBy": "user:investigator1"
  }
}
```

#### Retrieve Evidence File

**Endpoint:** `GET /api/evidence/:evidenceId/file?chain=hot&verify=true`

**Response:** Binary file content with proper headers

#### Health Check

**Endpoint:** `GET /health`

**Response:**
```json
{
  "status": "healthy",
  "service": "evidence-upload-service",
  "version": "1.0.0",
  "timestamp": "2025-11-22T10:30:00Z"
}
```

### 7.5 Starting IPFS Infrastructure

**Prerequisites:**
1. Both blockchain networks running
2. Chaincode deployed on both chains
3. lab-gw user identity created

**Start IPFS:**
```bash
cd ipfs-storage
./start-ipfs.sh
```

The script:
- Checks blockchain networks are running
- Generates SSL certificates for Nginx
- Starts IPFS node, proxy, and upload service
- Tests connectivity
- Displays endpoints and API documentation

**Stop IPFS:**
```bash
cd ipfs-storage
./stop-ipfs.sh
```

### 7.6 Testing Evidence Upload

**Create test file:**
```bash
echo "Test evidence data" > test-evidence.txt
```

**Upload to HOT chain:**
```bash
curl -X POST http://localhost:3000/api/evidence/upload \
  -F 'file=@test-evidence.txt' \
  -F 'investigationId=inv-test-001' \
  -F 'description=Test evidence file' \
  -F 'userId=user:investigator1' \
  -F 'userRole=BlockchainInvestigator' \
  -F 'chain=hot'
```

**Retrieve metadata:**
```bash
curl http://localhost:3000/api/evidence/<evidenceId>?chain=hot
```

**Retrieve file:**
```bash
curl http://localhost:3000/api/evidence/<evidenceId>/file?chain=hot \
  --output retrieved-evidence.txt
```

### 7.7 IPFS Security

**HTTPS Reverse Proxy:**
- IPFS API exposed via Nginx on HTTPS (port 5443)
- Self-signed certificates generated automatically
- For production: Replace with CA-signed certificates

**mTLS (Optional):**
Nginx configuration supports client certificate authentication:
```nginx
ssl_client_certificate /etc/nginx/ssl/ca.crt;
ssl_verify_client optional;
```

**File Integrity:**
- SHA256 hash computed before upload
- Hash stored on blockchain (immutable)
- Hash verified during retrieval
- Tampered files detected automatically

---

## 8. JumpServer Integration

### 8.1 Integration Overview

JumpServer (external web application) integrates with the blockchain infrastructure to enable forensic investigators to upload evidence with immutable audit trails.

**Integration Document:** See `INTEGRATION_JUMPSERVER.md` for complete details

### 8.2 Authentication Flow

1. **User Authentication:** JumpServer authenticates user
2. **Role Mapping:** JumpServer maps user to blockchain role
3. **API Call:** JumpServer calls Evidence Upload Service REST API
4. **Gateway Identity:** Service uses lab-gw identity for Fabric
5. **User Context:** Actual user passed via transient data
6. **Chaincode Validation:** Chaincode validates permissions via Casbin

### 8.3 Required Integration Points

**Endpoint:** `http://evidence-upload.coc:3000` (or configured URL)

**User Role Mapping:**

| JumpServer Role | Blockchain Role | Hot Chain Access | Cold Chain Access |
|----------------|-----------------|------------------|-------------------|
| Administrator | BlockchainAdmin | Full CRUD | Full CRUD |
| Investigator | BlockchainInvestigator | Full CRUD | Read-only |
| Analyst | BlockchainAnalyst | Read-only | Read-only |
| Court | BlockchainCourt | No access | Archive only |

**Sample Integration Code (JavaScript):**
```javascript
const FormData = require('form-data');
const axios = require('axios');

async function uploadEvidence(file, metadata) {
    const form = new FormData();
    form.append('file', file);
    form.append('investigationId', metadata.investigationId);
    form.append('description', metadata.description);
    form.append('userId', `user:${currentUser.username}`);
    form.append('userRole', currentUser.blockchainRole);
    form.append('chain', 'hot'); // or 'cold'

    const response = await axios.post(
        'http://evidence-upload.coc:3000/api/evidence/upload',
        form,
        { headers: form.getHeaders() }
    );

    return response.data; // { evidenceId, cid, sha256, txId }
}
```

### 8.4 Security Considerations

**Gateway Identity:**
- Only lab-gw@LabOrgMSP can invoke chaincode
- JumpServer never has blockchain credentials
- Evidence Upload Service acts as trusted intermediary

**Transient Data:**
- User context passed via transient data (never on ledger)
- Chaincode validates user permissions
- Prevents impersonation attacks

**TLS/mTLS:**
- All Fabric connections use mTLS
- IPFS API behind HTTPS proxy
- Optional: Client certificates for JumpServer → Evidence Upload Service

### 8.5 Troubleshooting

See `INTEGRATION_JUMPSERVER.md` section "Troubleshooting" for:
- IPFS connection issues
- Fabric Gateway errors
- Permission denied errors
- Hash verification failures
- Gateway identity validation errors

---

## Notes

- **Project Architecture**: Split into `hot-blockchain/` (active investigation) and `cold-blockchain/` (archival)
- **Hot Chain**: Uses `*.hot.coc.com` domains, includes OrdererOrg + LabOrg only
- **Cold Chain**: Uses `*.cold.coc.com` domains, includes OrdererOrg + LabOrg + CourtOrg
- **Dynamic Certificates**: Using Fabric CA v1.5.15 for dynamic certificate issuance
- This requirements file will be updated as new dependencies are added during development
- All versions listed are tested and compatible with Hyperledger Fabric v2.5.14 LTS
- For production deployments, pin all Docker images and dependencies to specific versions
- Regular security updates should be applied to all system components
- **Fabric 2.5.14 is the latest stable LTS release** as of October 2025
- Minimum versions specified with ≥ symbol; latest stable versions recommended

---

**Last Updated:** 2025-11-22
**Fabric Version:** 2.5.14 LTS (latest stable)
**Fabric CA Version:** 1.5.15
**Go Version:** ≥ 1.22.x (latest stable: 1.25.4, released November 5, 2025)
**Branch:** claude/clone-fyp-repo-01GcQmZnMbvkNkxehnggLCs3
