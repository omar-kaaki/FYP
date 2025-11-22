# JumpServer Integration Guide

**Chain of Custody (CoC) Digital Forensics System - Blockchain Integration**

Version: 1.0
Date: 2025-11-22

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Integration Requirements](#integration-requirements)
4. [Evidence Upload Workflow](#evidence-upload-workflow)
5. [API Endpoints](#api-endpoints)
6. [Authentication and Security](#authentication-and-security)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

---

## Overview

This document describes how to integrate JumpServer with the Chain of Custody blockchain infrastructure. The integration enables forensic investigators to upload digital evidence to IPFS and record immutable metadata on the Hyperledger Fabric blockchain.

### System Components

- **JumpServer**: Web application for forensic case management
- **Evidence Upload Service**: Microservice for file handling and blockchain integration
- **IPFS**: Decentralized storage for evidence files
- **Hyperledger Fabric**: Blockchain for immutable audit trails
  - **HOT Chain**: Active investigation data
  - **COLD Chain**: Archival/court presentation data

---

## Architecture

```
┌─────────────┐
│  JumpServer │
│   (Web UI)  │
└──────┬──────┘
       │ HTTPS
       │ POST /api/evidence/upload
       ▼
┌─────────────────────────┐
│ Evidence Upload Service │
│  (Port 3000)            │
└───┬─────────────────┬───┘
    │                 │
    │ HTTP            │ gRPC + mTLS
    │ IPFS API        │ Fabric Gateway
    ▼                 ▼
┌────────┐      ┌──────────────┐
│  IPFS  │      │   Fabric     │
│  Node  │      │ Peer (LabOrg)│
└────────┘      └──────────────┘
```

### Evidence Upload Flow

1. **User uploads file** via JumpServer UI
2. **JumpServer calls** Evidence Upload Service REST API
3. **Service computes** SHA256 hash of file
4. **Service uploads** file to IPFS (gets CID)
5. **Service invokes** Fabric chaincode via Gateway
6. **Chaincode validates** access permissions (Casbin RBAC)
7. **Chaincode records** metadata on blockchain
8. **Service returns** evidenceId, CID, txId to JumpServer

---

## Integration Requirements

### Network Requirements

- JumpServer must be able to reach Evidence Upload Service on `http://localhost:3000` (or configured endpoint)
- For production, use HTTPS with TLS certificates
- Firewall rules to allow outbound connections from JumpServer to Evidence Upload Service

### Blockchain Networks

The system supports two blockchain networks:

| Network | Purpose | Channel | Chaincode | Endorsement |
|---------|---------|---------|-----------|-------------|
| **HOT**  | Active investigation | `hot-chain` | `hot_chaincode` | LabOrg only |
| **COLD** | Archival/court | `cold-chain` | `cold_chaincode` | LabOrg + CourtOrg |

### User Roles

JumpServer must map users to one of these blockchain roles:

| Role | Permissions | Hot Chain | Cold Chain |
|------|-------------|-----------|------------|
| **BlockchainAdmin** | Full admin access | ✓ Create/Read/Update | ✓ Create/Read/Update |
| **BlockchainInvestigator** | Create evidence, investigations | ✓ Create/Read/Update | ✗ Read-only |
| **BlockchainAnalyst** | Read-only analysis | ✓ Read-only | ✗ Read-only |
| **BlockchainCourt** | Archive to cold chain | ✗ No access | ✓ Create/Archive |

---

## Evidence Upload Workflow

### Step 1: User Authentication in JumpServer

JumpServer authenticates the user and determines their blockchain role:

```javascript
// Example: JumpServer user mapping
const userMapping = {
    "investigator@lab.com": {
        userId: "user:investigator1",
        role: "BlockchainInvestigator"
    },
    "court@justice.gov": {
        userId: "user:court1",
        role: "BlockchainCourt"
    }
};
```

### Step 2: File Upload via REST API

JumpServer makes a `multipart/form-data` POST request to the Evidence Upload Service:

```javascript
// Example: JavaScript/Node.js
const FormData = require('form-data');
const fs = require('fs');
const axios = require('axios');

const form = new FormData();
form.append('file', fs.createReadStream('/path/to/evidence.zip'));
form.append('investigationId', 'inv-12345');
form.append('description', 'Disk image from suspect laptop');
form.append('userId', 'user:investigator1');
form.append('userRole', 'BlockchainInvestigator');
form.append('chain', 'hot'); // or 'cold'
form.append('metadata', JSON.stringify({
    caseNumber: 'CASE-2025-001',
    deviceSerial: 'ABC123',
    acquisitionDate: '2025-11-22T10:30:00Z'
}));

try {
    const response = await axios.post('http://localhost:3000/api/evidence/upload', form, {
        headers: form.getHeaders(),
        maxContentLength: Infinity,
        maxBodyLength: Infinity
    });

    console.log('Evidence uploaded:', response.data);
    // {
    //   "success": true,
    //   "evidenceId": "uuid-here",
    //   "cid": "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
    //   "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    //   "txId": "fabric-transaction-id",
    //   "chain": "hot"
    // }
} catch (error) {
    console.error('Upload failed:', error.response.data);
}
```

### Step 3: Service Processes Upload

The Evidence Upload Service:

1. Saves uploaded file temporarily
2. Computes SHA256 hash
3. Uploads to IPFS (gets CID)
4. Invokes `AddEvidence` chaincode function
5. Returns result to JumpServer

### Step 4: Store evidenceId in JumpServer Database

JumpServer should store the returned `evidenceId`, `cid`, and `sha256` in its database for future reference.

```sql
-- Example: JumpServer database schema
CREATE TABLE evidence_blockchain (
    id SERIAL PRIMARY KEY,
    case_id VARCHAR(255),
    evidence_id UUID NOT NULL,           -- From blockchain
    cid VARCHAR(255) NOT NULL,           -- IPFS Content ID
    sha256 VARCHAR(64) NOT NULL,         -- File hash
    tx_id VARCHAR(255),                  -- Fabric transaction ID
    chain VARCHAR(10),                   -- 'hot' or 'cold'
    uploaded_at TIMESTAMP DEFAULT NOW(),
    uploaded_by VARCHAR(255)
);
```

---

## API Endpoints

### 1. Upload Evidence File

**Endpoint:** `POST /api/evidence/upload`

**Content-Type:** `multipart/form-data`

**Request Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | File | Yes | Evidence file (max 500MB) |
| `investigationId` | String | Yes | Investigation ID |
| `description` | String | Yes | Evidence description |
| `userId` | String | Yes | User ID (format: `user:<username>`) |
| `userRole` | String | Yes | User role (see table above) |
| `chain` | String | No | Target chain: `hot` (default) or `cold` |
| `metadata` | JSON String | No | Additional metadata |

**Response (Success):**

```json
{
  "success": true,
  "evidenceId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "cid": "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
  "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "txId": "abc123def456",
  "chain": "hot",
  "message": "Evidence uploaded and recorded successfully"
}
```

**Response (Error):**

```json
{
  "success": false,
  "error": "Permission denied: user does not have required role"
}
```

### 2. Get Evidence Metadata

**Endpoint:** `GET /api/evidence/:evidenceId?chain=hot`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `chain` | String | No | `hot` | Target chain: `hot` or `cold` |

**Response:**

```json
{
  "success": true,
  "evidence": {
    "evidenceId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "investigationId": "inv-12345",
    "description": "Disk image from suspect laptop",
    "cid": "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
    "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "metadata": "{\"caseNumber\":\"CASE-2025-001\"}",
    "recordedAt": "2025-11-22T10:35:12Z",
    "recordedBy": "user:investigator1"
  }
}
```

### 3. Retrieve Evidence File

**Endpoint:** `GET /api/evidence/:evidenceId/file?chain=hot&verify=true`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `chain` | String | No | `hot` | Target chain: `hot` or `cold` |
| `verify` | Boolean | No | `true` | Verify SHA256 hash |

**Response:**

Binary file content with headers:
- `Content-Type`: Original file MIME type
- `Content-Disposition`: `attachment; filename="original-filename.ext"`
- `Content-Length`: File size in bytes

### 4. Health Check

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

---

## Authentication and Security

### Fabric Gateway Identity

The Evidence Upload Service uses the **lab-gw** gateway identity to communicate with the blockchain. This identity:

- Has MSP ID: `LabOrgMSP`
- Has Common Name: `lab-gw`
- Is the ONLY identity allowed to invoke chaincode functions (enforced by gateway validation)

### User Context via Transient Data

The actual user identity and role are passed to the chaincode via **transient data**:

```javascript
// In fabric.ts service
const transientData = {
    userId: Buffer.from('user:investigator1'),
    role: Buffer.from('BlockchainInvestigator')
};

await contract.submit('AddEvidence', {
    arguments: [evidenceId, investigationId, ...],
    transientData: transientData
});
```

The chaincode extracts this information and validates permissions using Casbin RBAC.

### mTLS Configuration

All Fabric Gateway connections use mutual TLS (mTLS):

**Required Files:**

1. **TLS CA Certificate**: Peer's TLS CA certificate
   - Hot: `/fabric/hot/tls/ca.crt`
   - Cold: `/fabric/cold/tls/ca.crt`

2. **Gateway MSP**: Lab-gw identity credentials
   - Certificate: `/fabric/{hot|cold}/gateway/msp/signcerts/lab-gw@laborg.{hot|cold}.coc.com-cert.pem`
   - Private Key: `/fabric/{hot|cold}/gateway/msp/keystore/priv_sk`

These files are mounted into the Evidence Upload Service container via docker-compose volumes.

### IPFS Security

IPFS API is proxied through Nginx with HTTPS:

- **Internal**: `http://ipfs:5001` (container network only)
- **External**: `https://localhost:5443` (HTTPS reverse proxy)

For production with JumpServer:
- Enable mTLS client authentication in Nginx
- Issue client certificates for JumpServer
- Configure `ssl_client_certificate` and `ssl_verify_client` in nginx.conf

---

## Testing

### Prerequisites

1. Start blockchain networks:
   ```bash
   cd hot-blockchain && ./scripts/start-network.sh
   cd cold-blockchain && ./scripts/start-network.sh
   ```

2. Deploy chaincode:
   ```bash
   cd hot-blockchain && ./scripts/deploy-chaincode.sh
   cd cold-blockchain && ./scripts/deploy-chaincode.sh
   ```

3. Start IPFS infrastructure:
   ```bash
   cd ipfs-storage && ./start-ipfs.sh
   ```

### Test 1: Upload Evidence (cURL)

```bash
# Create test file
echo "This is test evidence" > test-evidence.txt

# Upload to hot chain
curl -X POST http://localhost:3000/api/evidence/upload \
  -F 'file=@test-evidence.txt' \
  -F 'investigationId=inv-test-001' \
  -F 'description=Test evidence file' \
  -F 'userId=user:tester1' \
  -F 'userRole=BlockchainInvestigator' \
  -F 'chain=hot' \
  -F 'metadata={"testField":"testValue"}'
```

**Expected Response:**
```json
{
  "success": true,
  "evidenceId": "uuid-here",
  "cid": "Qm...",
  "sha256": "sha256-hash",
  "txId": "tx-id",
  "chain": "hot"
}
```

### Test 2: Retrieve Metadata

```bash
# Use evidenceId from Test 1
curl http://localhost:3000/api/evidence/uuid-here?chain=hot
```

### Test 3: Retrieve File

```bash
curl http://localhost:3000/api/evidence/uuid-here/file?chain=hot \
  --output retrieved-evidence.txt

# Verify content
cat retrieved-evidence.txt
```

### Test 4: Python Integration Example

```python
import requests

# Upload evidence
url = 'http://localhost:3000/api/evidence/upload'
files = {'file': open('evidence.zip', 'rb')}
data = {
    'investigationId': 'inv-12345',
    'description': 'Test evidence',
    'userId': 'user:investigator1',
    'userRole': 'BlockchainInvestigator',
    'chain': 'hot'
}

response = requests.post(url, files=files, data=data)
result = response.json()

if result['success']:
    evidence_id = result['evidenceId']
    print(f"Evidence uploaded: {evidence_id}")
    print(f"IPFS CID: {result['cid']}")
    print(f"SHA256: {result['sha256']}")
    print(f"Blockchain TX: {result['txId']}")
else:
    print(f"Upload failed: {result['error']}")
```

---

## Troubleshooting

### Issue: "IPFS upload failed"

**Cause:** IPFS node is not reachable

**Solution:**
1. Check IPFS container status: `docker ps | grep ipfs`
2. View IPFS logs: `docker logs ipfs.coc`
3. Test IPFS API: `curl -X POST http://localhost:5001/api/v0/version`

### Issue: "Fabric transaction failed: permission denied"

**Cause:** User role not set or invalid role

**Solution:**
1. Ensure user roles are set in chaincode:
   ```bash
   docker exec cli.hot peer chaincode invoke \
     -C hot-chain -n hot_chaincode \
     -c '{"function":"SetUserRoles","Args":["LabOrgMSP|lab-gw|user:investigator1","BlockchainInvestigator"]}'
   ```

2. Verify role:
   ```bash
   docker exec cli.hot peer chaincode query \
     -C hot-chain -n hot_chaincode \
     -c '{"function":"GetUserRoles","Args":["LabOrgMSP|lab-gw|user:investigator1"]}'
   ```

### Issue: "Failed to connect to Fabric Gateway"

**Cause:** mTLS certificates not found or invalid

**Solution:**
1. Verify crypto materials exist:
   ```bash
   ls -la hot-blockchain/crypto-config/peerOrganizations/laborg.hot.coc.com/users/lab-gw@laborg.hot.coc.com/msp/
   ```

2. Check Evidence Upload Service logs:
   ```bash
   docker logs evidence-upload.coc
   ```

3. Verify peer is running:
   ```bash
   docker ps | grep peer0.laborg.hot.coc.com
   ```

### Issue: "File integrity verification failed"

**Cause:** File corrupted during IPFS retrieval

**Solution:**
1. Re-upload the file
2. Check IPFS node health
3. Verify IPFS data is not corrupted

### Issue: "Gateway identity validation failed"

**Cause:** Service not using lab-gw identity

**Solution:**
1. Verify docker-compose mounts correct MSP path
2. Check certificate CN matches "lab-gw":
   ```bash
   openssl x509 -in hot-blockchain/crypto-config/.../lab-gw@laborg.hot.coc.com-cert.pem \
     -noout -subject
   ```

---

## Service Configuration

The Evidence Upload Service is configured via environment variables in `docker-compose-ipfs.yaml`. Key settings:

```yaml
environment:
  # IPFS Configuration
  - IPFS_API_URL=http://ipfs:5001

  # Fabric Hot Chain
  - FABRIC_HOT_GATEWAY_PEER=peer0.laborg.hot.coc.com:7051
  - FABRIC_HOT_CHANNEL=hot-chain
  - FABRIC_HOT_CHAINCODE=hot_chaincode
  - FABRIC_HOT_MSP_ID=LabOrgMSP
  - FABRIC_HOT_GATEWAY_IDENTITY=lab-gw

  # Fabric Cold Chain
  - FABRIC_COLD_GATEWAY_PEER=peer0.laborg.cold.coc.com:8051
  - FABRIC_COLD_CHANNEL=cold-chain
  - FABRIC_COLD_CHAINCODE=cold_chaincode
  - FABRIC_COLD_MSP_ID=LabOrgMSP
  - FABRIC_COLD_GATEWAY_IDENTITY=lab-gw

  # TLS
  - FABRIC_TLS_ENABLED=true
```

---

## Production Deployment Considerations

### High Availability

- Deploy multiple Evidence Upload Service instances behind a load balancer
- Use distributed IPFS cluster for redundancy
- Ensure Fabric peers are highly available

### Monitoring

- Enable Prometheus metrics on Fabric peers (port 9443/9543/9643)
- Monitor Evidence Upload Service health endpoint
- Set up alerts for IPFS disk usage

### Backup

- Regularly backup IPFS data volume
- Export chaincode data periodically
- Back up Fabric ledger data

### Performance

- For large files (>100MB), consider chunking
- Use IPFS pinning service for critical evidence
- Optimize Docker resource limits based on load

---

## Contact and Support

For technical support:
- Blockchain Team: blockchain@lab.com
- Documentation: See `requirements.md` for detailed system architecture
- Issue Tracker: (Add your issue tracker URL)

---

**Last Updated:** 2025-11-22
**Version:** 1.0
**Author:** CoC Blockchain Team
