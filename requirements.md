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
