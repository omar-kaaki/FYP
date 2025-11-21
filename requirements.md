# FYP Blockchain Requirements

This document specifies all system requirements, dependencies, and versions needed to deploy and run the FYP blockchain network based on Hyperledger Fabric v2.5.14 LTS.

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
| Docker Engine | 24.x or 25.x (latest stable) | [Official Docker docs](https://docs.docker.com/engine/install/) | Container runtime for all Fabric components |
| Docker Compose Plugin | v2.x (latest stable) | Included with Docker Engine | Orchestrate multi-container deployments |

**Post-install:** Add current user to docker group to run Docker without sudo:
```bash
sudo usermod -aG docker $USER
```

### Language Runtimes

| Name | Recommended Version | Install Method | Why |
|------|---------------------|----------------|-----|
| Go | ≥ 1.25.x (tested with 1.25.2) | [Official Go downloads](https://go.dev/dl/) | Required for Fabric binaries and Go chaincode |
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
| CouchDB | 3.x (latest stable) | Docker: `docker pull couchdb:3` | Enables rich JSON queries on world state |

**Configuration:** Each peer requires its own CouchDB container.

**Reference:** [Fabric CouchDB as State Database](https://hyperledger-fabric.readthedocs.io/en/release-2.5/couchdb_as_state_database.html)

### Distributed Storage

| Name | Recommended Version | Install Method | Why |
|------|---------------------|----------------|-----|
| IPFS (Kubo) | 0.38.x (latest stable) | Docker: `docker pull ipfs/kubo:v0.38.0` OR Native: [Kubo releases](https://github.com/ipfs/kubo/releases) | Decentralized storage for large files/evidence |

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
| **Hyperledger Fabric** | 2.5.14 |
| **Fabric CA** | 1.5.15 |
| **Go** | ≥ 1.25.2 |
| **Node.js** | 20.x LTS |
| **Python** | ≥ 3.11 |
| **Docker Engine** | 24.x or 25.x |
| **Docker Compose** | v2.x |
| **CouchDB** | 3.x |
| **IPFS (Kubo)** | 0.38.x |
| **Casbin** | v2 |

---

## Installation Quick Reference

### 1. Install Docker
```bash
# Follow official Docker installation for your distro
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### 2. Install Go
```bash
# Download and install Go 1.25.2
wget https://go.dev/dl/go1.25.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.25.2.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### 3. Install Node.js (via nvm)
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
```

### 4. Install Fabric Binaries and Docker Images
```bash
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- 2.5.14 1.5.15 docker binary
export PATH=$PATH:$(pwd)/fabric-samples/bin
```

### 5. Pull Additional Docker Images
```bash
docker pull couchdb:3
docker pull ipfs/kubo:v0.38.0
```

---

## Notes

- This requirements file will be updated as new dependencies are added during development
- All versions listed are tested and compatible with Hyperledger Fabric v2.5.14 LTS
- For production deployments, pin all Docker images and dependencies to specific versions
- Regular security updates should be applied to all system components

---

**Last Updated:** 2025-11-21
**Fabric Version:** 2.5.14 LTS
**Fabric CA Version:** 1.5.15
