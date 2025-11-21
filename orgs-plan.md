# FYP Blockchain - Organizations & MSP Architecture

This document defines the complete organization structure, MSP identities, peer topology, and endorsement policies for the Hyperledger Fabric v2.5.14 network.

---

## 1. Organizations Overview

| Organization | MSP ID | Nodes | Primary Role | Channels |
|--------------|--------|-------|--------------|----------|
| **OrdererOrg** | `OrdererOrgMSP` | `orderer1.ordererorg` | Ordering service (Raft consensus) | System channel, hot-chain, cold-chain |
| **LabOrg** | `LabOrgMSP` | `peer0.laborg` | DFIR/CoC owner, endorses on both chains | hot-chain, cold-chain |
| **CourtOrg** | `CourtOrgMSP` | `peer0.courtorg` | Court validator, endorses on cold-chain | hot-chain, cold-chain |

**Note:** JumpServer roles (Investigator, Auditor, Court, SystemAdmin) are **application-level only** and map to Fabric Gateway client identities, NOT separate Fabric organizations.

---

## 2. Certificate Authorities (CAs) per Organization

Each organization runs **two CAs**:
1. **Identity CA** - Issues enrollment certificates (ECerts) for identities
2. **TLS CA** - Issues TLS certificates for secure communication

### 2.1 OrdererOrg CAs

| CA Type | Hostname | Port | Purpose |
|---------|----------|------|---------|
| Identity CA | `ca.ordererorg.example.com` | 7054 | Issues enrollment certs for orderer nodes and admins |
| TLS CA | `tlsca.ordererorg.example.com` | 8054 | Issues TLS certs for orderer nodes |

**Identities issued:**
- `orderer1.ordererorg.example.com` (orderer node, OU=orderer)
- `orderer-admin@ordererorg.example.com` (admin, OU=admin)

### 2.2 LabOrg CAs

| CA Type | Hostname | Port | Purpose |
|---------|----------|------|---------|
| Identity CA | `ca.laborg.example.com` | 7055 | Issues enrollment certs for peer, admins, gateway clients |
| TLS CA | `tlsca.laborg.example.com` | 8055 | Issues TLS certs for peer and clients |

**Identities issued:**
- `peer0.laborg.example.com` (peer node, OU=peer)
- `lab-admin@laborg.example.com` (admin, OU=admin)
- `lab-gw@laborg.example.com` (Fabric Gateway client for JumpServer, OU=client)

### 2.3 CourtOrg CAs

| CA Type | Hostname | Port | Purpose |
|---------|----------|------|---------|
| Identity CA | `ca.courtorg.example.com` | 7056 | Issues enrollment certs for peer and admins |
| TLS CA | `tlsca.courtorg.example.com` | 8056 | Issues TLS certs for peer |

**Identities issued:**
- `peer0.courtorg.example.com` (peer node, OU=peer)
- `court-admin@courtorg.example.com` (admin, OU=admin)

---

## 3. Directory Structure (crypto-config)

**Base path:** `/home/user/FYPBcoc/crypto-config`

```
crypto-config/
├── ordererOrganizations/
│   └── ordererorg.example.com/
│       ├── ca/                          # Identity CA root cert + key
│       ├── tlsca/                       # TLS CA root cert + key
│       ├── msp/                         # Organization MSP definition
│       │   ├── cacerts/                 # ca-cert.pem (identity CA root)
│       │   ├── tlscacerts/              # tlsca-cert.pem (TLS CA root)
│       │   ├── admincerts/              # orderer-admin cert
│       │   └── config.yaml              # NodeOUs configuration
│       ├── orderers/
│       │   └── orderer1.ordererorg.example.com/
│       │       ├── msp/                 # Node MSP (identity cert, private key)
│       │       │   ├── cacerts/
│       │       │   ├── keystore/        # orderer1 private key
│       │       │   ├── signcerts/       # orderer1 enrollment cert
│       │       │   └── config.yaml
│       │       └── tls/                 # TLS cert, key, CA cert
│       │           ├── server.crt
│       │           ├── server.key
│       │           └── ca.crt
│       └── users/
│           └── orderer-admin@ordererorg.example.com/
│               └── msp/
│                   ├── cacerts/
│                   ├── keystore/
│                   ├── signcerts/
│                   └── config.yaml
│
├── peerOrganizations/
│   ├── laborg.example.com/
│   │   ├── ca/                          # Identity CA root cert + key
│   │   ├── tlsca/                       # TLS CA root cert + key
│   │   ├── msp/                         # Organization MSP definition
│   │   │   ├── cacerts/
│   │   │   ├── tlscacerts/
│   │   │   ├── admincerts/
│   │   │   └── config.yaml
│   │   ├── peers/
│   │   │   └── peer0.laborg.example.com/
│   │   │       ├── msp/
│   │   │       │   ├── cacerts/
│   │   │       │   ├── keystore/
│   │   │       │   ├── signcerts/
│   │   │       │   └── config.yaml
│   │   │       └── tls/
│   │   │           ├── server.crt
│   │   │           ├── server.key
│   │   │           └── ca.crt
│   │   └── users/
│   │       ├── lab-admin@laborg.example.com/
│   │       │   └── msp/
│   │       └── lab-gw@laborg.example.com/
│   │           ├── msp/
│   │           └── tls/ (optional, for client mTLS)
│   │
│   └── courtorg.example.com/
│       ├── ca/
│       ├── tlsca/
│       ├── msp/
│       │   ├── cacerts/
│       │   ├── tlscacerts/
│       │   ├── admincerts/
│       │   └── config.yaml
│       ├── peers/
│       │   └── peer0.courtorg.example.com/
│       │       ├── msp/
│       │       └── tls/
│       └── users/
│           └── court-admin@courtorg.example.com/
│               └── msp/
```

---

## 4. NodeOUs Configuration

Each organization MSP requires a `config.yaml` file enabling **NodeOUs** for role-based access control.

**Location:** `<org-msp-path>/config.yaml`

**Template:**

```yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-<orgname>-example-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-<orgname>-example-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-<orgname>-example-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-<orgname>-example-com.pem
    OrganizationalUnitIdentifier: orderer
```

**Organizational Unit (OU) Assignments:**

| Organization | Identity | OU | Role |
|--------------|----------|----|----|
| OrdererOrg | orderer1.ordererorg.example.com | `orderer` | Orderer node |
| OrdererOrg | orderer-admin@ordererorg.example.com | `admin` | Orderer admin |
| LabOrg | peer0.laborg.example.com | `peer` | Peer node |
| LabOrg | lab-admin@laborg.example.com | `admin` | Org admin |
| LabOrg | lab-gw@laborg.example.com | `client` | Gateway client |
| CourtOrg | peer0.courtorg.example.com | `peer` | Peer node |
| CourtOrg | court-admin@courtorg.example.com | `admin` | Org admin |

---

## 5. Peers & Channel Membership

### 5.1 peer0.laborg.example.com

**Configuration:**
- **Hostname:** `peer0.laborg.example.com`
- **Listen Address:** `0.0.0.0:7051`
- **Chaincode Address:** `peer0.laborg.example.com:7052`
- **Operations Address:** `0.0.0.0:9443`
- **MSP ID:** `LabOrgMSP`
- **MSP Path:** `/home/user/FYPBcoc/crypto-config/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/msp`
- **TLS Path:** `/home/user/FYPBcoc/crypto-config/peerOrganizations/laborg.example.com/peers/peer0.laborg.example.com/tls`
- **State Database:** CouchDB (`couchdb0.laborg`)

**Channel Membership:**
- `hot-chain` - **Endorser** and **Anchor Peer**
- `cold-chain` - **Endorser** and **Anchor Peer**

**Endorsement Role:**
- **hot-chain:** Sole endorser (policy: `OR('LabOrgMSP.peer')`)
- **cold-chain:** Co-endorser with CourtOrg (policy: `AND('LabOrgMSP.peer','CourtOrgMSP.peer')`)

**Gateway Endpoint:**
- JumpServer connects to this peer via Fabric Gateway SDK
- Uses identity: `lab-gw@laborg.example.com`

### 5.2 peer0.courtorg.example.com

**Configuration:**
- **Hostname:** `peer0.courtorg.example.com`
- **Listen Address:** `0.0.0.0:9051`
- **Chaincode Address:** `peer0.courtorg.example.com:9052`
- **Operations Address:** `0.0.0.0:9444`
- **MSP ID:** `CourtOrgMSP`
- **MSP Path:** `/home/user/FYPBcoc/crypto-config/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/msp`
- **TLS Path:** `/home/user/FYPBcoc/crypto-config/peerOrganizations/courtorg.example.com/peers/peer0.courtorg.example.com/tls`
- **State Database:** CouchDB (`couchdb0.courtorg`)

**Channel Membership:**
- `hot-chain` - **Committer** and **Anchor Peer** (reads only, does NOT endorse)
- `cold-chain` - **Endorser** and **Anchor Peer**

**Endorsement Role:**
- **hot-chain:** No endorsement (CourtOrg not in endorsement policy)
- **cold-chain:** Required co-endorser for critical operations (policy: `AND('LabOrgMSP.peer','CourtOrgMSP.peer')`)

---

## 6. Orderer Configuration

### orderer1.ordererorg.example.com

**Configuration:**
- **Hostname:** `orderer1.ordererorg.example.com`
- **Listen Address:** `0.0.0.0:7050`
- **Operations Address:** `0.0.0.0:8443`
- **MSP ID:** `OrdererOrgMSP`
- **MSP Path:** `/home/user/FYPBcoc/crypto-config/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/msp`
- **TLS Path:** `/home/user/FYPBcoc/crypto-config/ordererOrganizations/ordererorg.example.com/orderers/orderer1.ordererorg.example.com/tls`
- **Consensus Type:** Raft (single-node initially, expandable)

**Channels Served:**
- System channel (for Fabric 2.3+: application channels only, no system channel)
- `hot-chain`
- `cold-chain`

---

## 7. Endorsement Policies

### 7.1 hot-chain Chaincode

**Default Policy:** `OR('LabOrgMSP.peer')`

**Rationale:**
- Hot chain handles frequent investigative operations (custody transfers, evidence updates)
- Only LabOrg (DFIR lab) needs to endorse
- CourtOrg can read/commit but does NOT participate in endorsement

**Implementation:**
```
peer lifecycle chaincode approveformyorg \
  --signature-policy "OR('LabOrgMSP.peer')" \
  ...
```

### 7.2 cold-chain Chaincode

**Default Policy:** `AND('LabOrgMSP.peer','CourtOrgMSP.peer')`

**Rationale:**
- Cold chain handles archival and court-critical operations
- Requires dual endorsement from both LabOrg and CourtOrg
- Ensures court validation before evidence archival

**Implementation:**
```
peer lifecycle chaincode approveformyorg \
  --signature-policy "AND('LabOrgMSP.peer','CourtOrgMSP.peer')" \
  ...
```

**Function-Specific Overrides:**
- Archive operations: `AND('LabOrgMSP.peer','CourtOrgMSP.peer')`
- Reopen operations: `AND('LabOrgMSP.peer','CourtOrgMSP.peer')`
- Read operations: No special endorsement (query only)

---

## 8. configtx.yaml Organization Definitions

Organizations defined in `configtx.yaml` must match exactly:

### OrdererOrg

```yaml
- &OrdererOrg
    Name: OrdererOrg
    ID: OrdererOrgMSP
    MSPDir: /home/user/FYPBcoc/crypto-config/ordererOrganizations/ordererorg.example.com/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('OrdererOrgMSP.member')"
      Writers:
        Type: Signature
        Rule: "OR('OrdererOrgMSP.member')"
      Admins:
        Type: Signature
        Rule: "OR('OrdererOrgMSP.admin')"
    OrdererEndpoints:
      - orderer1.ordererorg.example.com:7050
```

### LabOrg

```yaml
- &LabOrg
    Name: LabOrg
    ID: LabOrgMSP
    MSPDir: /home/user/FYPBcoc/crypto-config/peerOrganizations/laborg.example.com/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('LabOrgMSP.admin', 'LabOrgMSP.peer', 'LabOrgMSP.client')"
      Writers:
        Type: Signature
        Rule: "OR('LabOrgMSP.admin', 'LabOrgMSP.peer', 'LabOrgMSP.client')"
      Admins:
        Type: Signature
        Rule: "OR('LabOrgMSP.admin')"
      Endorsement:
        Type: Signature
        Rule: "OR('LabOrgMSP.peer')"
    AnchorPeers:
      - Host: peer0.laborg.example.com
        Port: 7051
```

### CourtOrg

```yaml
- &CourtOrg
    Name: CourtOrg
    ID: CourtOrgMSP
    MSPDir: /home/user/FYPBcoc/crypto-config/peerOrganizations/courtorg.example.com/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('CourtOrgMSP.admin', 'CourtOrgMSP.peer', 'CourtOrgMSP.client')"
      Writers:
        Type: Signature
        Rule: "OR('CourtOrgMSP.admin', 'CourtOrgMSP.peer', 'CourtOrgMSP.client')"
      Admins:
        Type: Signature
        Rule: "OR('CourtOrgMSP.admin')"
      Endorsement:
        Type: Signature
        Rule: "OR('CourtOrgMSP.peer')"
    AnchorPeers:
      - Host: peer0.courtorg.example.com
        Port: 9051
```

---

## 9. Implementation Checklist

### Phase 1: CA Setup
- [ ] Deploy Fabric CA containers for all 6 CAs (3 orgs × 2 CA types)
- [ ] Initialize CA root certificates
- [ ] Configure CA server configs with proper affiliations and OUs

### Phase 2: Crypto Material Generation
- [ ] Register and enroll all identities (orderers, peers, admins, clients)
- [ ] Generate TLS certificates for all nodes
- [ ] Organize certificates into crypto-config directory structure
- [ ] Create config.yaml for NodeOUs in each org MSP
- [ ] Copy admin certs to org MSP admincerts/

### Phase 3: configtx.yaml Creation
- [ ] Define all three organizations (OrdererOrg, LabOrg, CourtOrg)
- [ ] Create channel profiles for hot-chain and cold-chain
- [ ] Set proper endorsement policies
- [ ] Define orderer configuration (Raft consensus)
- [ ] Set application capabilities to V2_5

### Phase 4: Verification
- [ ] All org MSP directories exist with correct structure
- [ ] All node MSP directories exist with identity certs and private keys
- [ ] All TLS directories have server certs and keys
- [ ] config.yaml exists in all MSP paths
- [ ] configtx.yaml references correct absolute MSP paths

---

## 10. Network Topology Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     OrdererOrg (OrdererOrgMSP)                  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  orderer1.ordererorg.example.com:7050                    │  │
│  │  Consensus: Raft                                         │  │
│  │  Channels: hot-chain, cold-chain                         │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┴───────────────┐
                │                               │
┌───────────────▼──────────────┐   ┌────────────▼──────────────┐
│   LabOrg (LabOrgMSP)         │   │  CourtOrg (CourtOrgMSP)   │
│                              │   │                           │
│  ┌─────────────────────────┐ │   │  ┌──────────────────────┐ │
│  │ peer0.laborg:7051       │ │   │  │ peer0.courtorg:9051  │ │
│  │ CouchDB: couchdb0.laborg│ │   │  │ CouchDB: couchdb0.ct │ │
│  │                         │ │   │  │                      │ │
│  │ Channels:               │ │   │  │ Channels:            │ │
│  │  - hot-chain (endorser) │ │   │  │  - hot-chain (reader)│ │
│  │  - cold-chain (endorser)│ │   │  │  - cold-chain (endor)│ │
│  │                         │ │   │  │                      │ │
│  │ Gateway: lab-gw         │ │   │  │                      │ │
│  └─────────────────────────┘ │   │  └──────────────────────┘ │
└──────────────────────────────┘   └───────────────────────────┘
         │
         │ Fabric Gateway SDK
         ▼
┌────────────────────────────┐
│      JumpServer API        │
│  (Application Layer)       │
│  Roles: Investigator,      │
│  Auditor, Court, SysAdmin  │
└────────────────────────────┘
```

---

**Document Version:** 1.0
**Last Updated:** 2025-11-21
**Fabric Version:** 2.5.14 LTS
**Status:** Complete - Ready for Implementation
