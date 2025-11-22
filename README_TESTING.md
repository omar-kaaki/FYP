# FYP Blockchain - Installation and Testing Guide

## Quick Start

### 1. Install All Prerequisites

Run the automated installation script:

```bash
cd ~/FYPBcoc
./install-prerequisites.sh
```

**This installs:**
- Docker & Docker Compose
- Go 1.25.4
- Node.js 20.x (via NVM)
- Hyperledger Fabric binaries v2.5.14
- Fabric CA binaries v1.5.15
- All required tools (jq, tree, curl, wget, git, etc.)

**System Requirements:**
- OS: Debian/Ubuntu/Kali Linux (x86_64)
- RAM: 8GB minimum (16GB recommended)
- Disk: 20GB free space minimum
- Permissions: sudo/root access required

---

### 2. Run Comprehensive Tests

After installation, test everything:

```bash
cd ~/FYPBcoc

# Quick validation (recommended first - no crypto generation)
./test-all.sh --skip-crypto

# Full test (includes crypto generation - takes longer)
./test-all.sh
```

**The master test validates:**
1. All prerequisites and tools
2. Project directory structure
3. Hot blockchain configuration (4 CAs, 2 orgs)
4. Cold blockchain configuration (6 CAs, 3 orgs)
5. MSP structures (org-level and node-level)
6. NodeOUs configuration
7. Docker Compose files
8. CA container health
9. Domain names (.hot.coc.com / .cold.coc.com)
10. Individual blockchain tests

---

## Individual Blockchain Tests

### Hot Blockchain (Active Investigation Chain)

```bash
cd ~/FYPBcoc/hot-blockchain

# Quick test (no crypto)
./scripts/test-ca-setup.sh --skip-crypto

# Full test with crypto generation
./scripts/test-ca-setup.sh
```

**What it tests:**
- 4 CA containers (OrdererOrg + LabOrg)
- MSP structures for 2 organizations
- 1 orderer node + 1 peer node
- TLS configuration
- NodeOUs setup

---

### Cold Blockchain (Archival Chain)

```bash
cd ~/FYPBcoc/cold-blockchain

# Quick test (no crypto)
./scripts/test-ca-setup.sh --skip-crypto

# Full test with crypto generation
./scripts/test-ca-setup.sh
```

**What it tests:**
- 6 CA containers (OrdererOrg + LabOrg + CourtOrg)
- MSP structures for 3 organizations
- 1 orderer node + 2 peer nodes
- TLS configuration
- NodeOUs setup

---

## Test Hierarchy

```
test-all.sh (Master Test)
├── Prerequisites Validation
├── Project Structure Check
├── Hot Blockchain Tests
│   └── scripts/test-ca-setup.sh
└── Cold Blockchain Tests
    └── scripts/test-ca-setup.sh
```

---

## Scripts Overview

### Installation Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `install-prerequisites.sh` | Install all dependencies | `./install-prerequisites.sh` |

### Testing Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `test-all.sh` | Master test for everything | `./test-all.sh [--skip-crypto]` |
| `hot-blockchain/scripts/test-ca-setup.sh` | Hot blockchain tests | `./test-ca-setup.sh [--skip-crypto]` |
| `cold-blockchain/scripts/test-ca-setup.sh` | Cold blockchain tests | `./test-ca-setup.sh [--skip-crypto]` |

### Crypto Generation Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `hot-blockchain/scripts/generate-crypto.sh` | Generate hot chain crypto | `./generate-crypto.sh` |
| `cold-blockchain/scripts/generate-crypto.sh` | Generate cold chain crypto | `./generate-crypto.sh` |

---

## What Gets Installed

### Core Tools
- Docker Engine 24.0+
- Docker Compose 2.20+
- Git
- curl, wget
- jq (JSON processor - required for CA API)
- tree (directory viewer)
- OpenSSL
- build-essential
- Python 3.11+

### Hyperledger Fabric
- Fabric binaries v2.5.14 LTS
  - peer
  - orderer
  - configtxgen
  - configtxlator
  - osnadmin
- Fabric CA binaries v1.5.15
  - fabric-ca-server
  - fabric-ca-client

### Programming Languages
- Go 1.25.4
- Node.js 20.x (via NVM)

### Docker Images
- hyperledger/fabric-peer:2.5.14
- hyperledger/fabric-orderer:2.5.14
- hyperledger/fabric-ca:1.5.15
- hyperledger/fabric-tools:2.5.14

---

## Test Output Examples

### Successful Test
```
╔════════════════════════════════════════════════════════════════╗
║  ✓ SUCCESS: All tests passed!                                 ║
║  Both hot and cold blockchain configurations are ready.       ║
╚════════════════════════════════════════════════════════════════╝

Next Steps:
  1. Start hot blockchain CAs:
     cd hot-blockchain && docker-compose -f docker-compose-ca.yaml up -d

  2. Start cold blockchain CAs:
     cd cold-blockchain && docker-compose -f docker-compose-ca.yaml up -d

  3. Generate crypto material:
     cd hot-blockchain && ./scripts/generate-crypto.sh
     cd cold-blockchain && ./scripts/generate-crypto.sh
```

### Failed Test
```
╔════════════════════════════════════════════════════════════════╗
║  ✗ FAILURE: Some tests failed                                 ║
║  Please review the errors above and fix before proceeding.    ║
╚════════════════════════════════════════════════════════════════╝

Troubleshooting:
  - Check log files in /tmp/ for detailed error messages
  - Ensure all prerequisites are installed: ./install-prerequisites.sh
  - Verify Docker is running: sudo systemctl status docker
  - Check file permissions: chmod +x scripts/*.sh
```

---

## Troubleshooting

### Prerequisites Not Installed
```bash
# Run installation script
./install-prerequisites.sh

# Verify installations
docker --version
docker-compose --version
go version
fabric-ca-client version
peer version
jq --version
```

### Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run
newgrp docker

# Verify
docker ps
```

### CA Containers Not Starting
```bash
# Check Docker logs
cd hot-blockchain
docker-compose -f docker-compose-ca.yaml logs

# Check port conflicts
netstat -tlnp | grep -E "7054|8054|7055|8055"

# Restart containers
docker-compose -f docker-compose-ca.yaml down
docker-compose -f docker-compose-ca.yaml up -d
```

### Crypto Generation Fails
```bash
# Check CA health
curl -k https://localhost:7054/cainfo

# Check logs
cat /tmp/crypto-gen-hot.log
cat /tmp/crypto-gen-cold.log

# Verify jq is installed
jq --version

# Clean and retry
rm -rf crypto-config/*
./scripts/generate-crypto.sh
```

---

## Network Architecture

### Hot Blockchain (*.hot.coc.com)
- **Purpose**: Active investigation chain
- **Organizations**: OrdererOrg, LabOrg
- **Nodes**: 1 orderer, 1 peer
- **CAs**: 4 (2 per org: Identity + TLS)
- **Ports**: 7054, 8054, 7055, 8055
- **Endorsement**: OR('LabOrgMSP.peer')

### Cold Blockchain (*.cold.coc.com)
- **Purpose**: Archival chain
- **Organizations**: OrdererOrg, LabOrg, CourtOrg
- **Nodes**: 1 orderer, 2 peers
- **CAs**: 6 (2 per org: Identity + TLS)
- **Ports**: 7154, 8154, 7155, 8155, 7156, 8156
- **Endorsement**: AND('LabOrgMSP.peer', 'CourtOrgMSP.peer')

---

## File Structure

```
FYPBcoc/
├── install-prerequisites.sh      # Install all dependencies
├── test-all.sh                   # Master test script
├── README_TESTING.md             # This file
├── requirements.txt              # Quick reference
├── requirements.md               # Detailed documentation
│
├── hot-blockchain/               # Active investigation chain
│   ├── ca-config/               # CA configurations (4 CAs)
│   ├── crypto-config/           # Generated certificates
│   ├── scripts/
│   │   ├── generate-crypto.sh  # Generate crypto material
│   │   └── test-ca-setup.sh    # Test hot blockchain
│   ├── configtx.yaml           # Channel configuration
│   └── docker-compose-ca.yaml  # CA containers
│
└── cold-blockchain/              # Archival chain
    ├── ca-config/               # CA configurations (6 CAs)
    ├── crypto-config/           # Generated certificates
    ├── scripts/
    │   ├── generate-crypto.sh  # Generate crypto material
    │   └── test-ca-setup.sh    # Test cold blockchain
    ├── configtx.yaml           # Channel configuration
    └── docker-compose-ca.yaml  # CA containers
```

---

## Quick Reference Commands

```bash
# Install everything
./install-prerequisites.sh

# Test everything (quick)
./test-all.sh --skip-crypto

# Test everything (full with crypto)
./test-all.sh

# Start hot blockchain CAs
cd hot-blockchain
docker-compose -f docker-compose-ca.yaml up -d
./scripts/generate-crypto.sh

# Start cold blockchain CAs
cd cold-blockchain
docker-compose -f docker-compose-ca.yaml up -d
./scripts/generate-crypto.sh

# View crypto structure
tree -L 4 hot-blockchain/crypto-config/
tree -L 4 cold-blockchain/crypto-config/

# Stop all containers
docker-compose -f hot-blockchain/docker-compose-ca.yaml down
docker-compose -f cold-blockchain/docker-compose-ca.yaml down

# Clean crypto material
rm -rf hot-blockchain/crypto-config/*
rm -rf cold-blockchain/crypto-config/*
```

---

## Support

For detailed documentation, see:
- `requirements.txt` - Quick reference guide
- `requirements.md` - Comprehensive documentation
- Hyperledger Fabric docs: https://hyperledger-fabric.readthedocs.io/
- Fabric CA docs: https://hyperledger-fabric-ca.readthedocs.io/
