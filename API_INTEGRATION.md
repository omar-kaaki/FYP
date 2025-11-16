# DFIR Blockchain API Integration Guide

**Connect your jumpserver or external application to the DFIR Blockchain REST API**

---

## 📋 Table of Contents

1. [API Overview](#api-overview)
2. [Authentication & Headers](#authentication--headers)
3. [API Endpoints](#api-endpoints)
4. [Request/Response Formats](#requestresponse-formats)
5. [Integration Examples](#integration-examples)
6. [Network Configuration](#network-configuration)
7. [Error Handling](#error-handling)

---

## 🌐 API Overview

**Base URL:** `http://your-server-ip:5000`

**Protocol:** HTTP REST API
**Format:** JSON
**Default Port:** 5000
**CORS:** Not enabled by default (see [Network Configuration](#network-configuration))

---

## 🔐 Authentication & Headers

### Standard Headers

All API requests should include:

```http
Content-Type: application/json
Accept: application/json
```

### Optional Headers

```http
User-Agent: YourJumpserver/1.0
X-Request-ID: unique-request-id
```

**Note:** The current API does not require authentication tokens. For production:
- Add JWT/API key authentication
- Enable HTTPS/TLS
- Implement rate limiting

---

## 📡 API Endpoints

### 1. Blockchain Status

**Get blockchain health and block height**

```http
GET /api/blockchain/status
```

**Headers:**
```
Accept: application/json
```

**Response:**
```json
{
  "hot_blockchain": {
    "status": "running",
    "height": 7,
    "currentBlockHash": "Z52b1xesICVv9/SxEC/+9sEtFa7p0+d1aiVpPR44CKg=",
    "previousBlockHash": "0gtpwMgCE1mOh+z0IUqhZ7KxcL/UDuLHq4mAgh/4LyE="
  },
  "cold_blockchain": {
    "status": "running",
    "height": 4,
    "currentBlockHash": "w9aJoJDKIfoO2UkOJNVGN1Y051c7GBB3pmuGshehm2o=",
    "previousBlockHash": "ySUe3FxYKqiHzlbtq2swqPk7/2SltP+T6qJO2S12xEo="
  }
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/blockchain/status \
  -H "Accept: application/json"
```

---

### 2. Create Evidence

**Submit new evidence to the blockchain**

```http
POST /api/evidence/create
```

**Headers:**
```
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "id": "EVD-001",
  "case_id": "CASE-2025-001",
  "type": "Digital Evidence",
  "description": "Forensic disk image from suspect laptop",
  "hash": "sha256:abc123def456...",
  "location": "ipfs://QmXXXXXXXXXXXXXXX",
  "blockchain": "hot",
  "metadata": {
    "collected_by": "Detective Smith",
    "timestamp": "2025-11-15T10:30:00Z",
    "location": "Evidence Room A",
    "file_size": "1048576"
  }
}
```

**Required Fields:**
- `id` - Unique evidence identifier
- `case_id` - Associated case/investigation ID
- `type` - Evidence type (Digital Evidence, Physical Evidence, etc.)
- `description` - Evidence description
- `hash` - SHA-256 hash of evidence file
- `location` - IPFS hash or storage location

**Optional Fields:**
- `blockchain` - Target chain: `"hot"` (default) or `"cold"`
- `metadata` - JSON object with additional metadata

**Response:**
```json
{
  "success": true,
  "data": "Transaction successful"
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:5000/api/evidence/create \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "id": "EVD-001",
    "case_id": "CASE-001",
    "type": "Digital Evidence",
    "description": "Laptop hard drive",
    "hash": "sha256:abc123",
    "location": "ipfs://QmTest123",
    "metadata": {
      "collected_by": "Officer Johnson",
      "timestamp": "2025-11-15T10:30:00Z"
    }
  }'
```

---

### 3. Query Evidence

**Retrieve evidence details from blockchain**

```http
GET /api/evidence/{evidence_id}
```

**Headers:**
```
Accept: application/json
```

**URL Parameters:**
- `evidence_id` - The unique evidence ID

**Response:**
```json
{
  "success": true,
  "data": {
    "ID": "EVD-001",
    "CaseID": "CASE-2025-001",
    "Type": "Digital Evidence",
    "Description": "Forensic disk image from suspect laptop",
    "Hash": "abc123def456",
    "Location": "ipfs://QmXXXXXXXXXXXXXXX",
    "Custodian": "x509::/C=US/ST=...",
    "Timestamp": 1700050200,
    "Status": "collected",
    "Metadata": "{\"collected_by\":\"Detective Smith\"}"
  }
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/evidence/EVD-001 \
  -H "Accept: application/json"
```

---

### 4. List All Evidence

**Get list of all evidence (from MySQL cache)**

```http
GET /api/evidence/list
```

**Headers:**
```
Accept: application/json
```

**Response:**
```json
{
  "success": true,
  "count": 5,
  "evidence": [
    {
      "evidence_id": "EVD-001",
      "case_id": "CASE-2025-001",
      "evidence_type": "Digital Evidence",
      "description": "Laptop hard drive",
      "sha256_hash": "abc123",
      "ipfs_hash": "QmXXXXXX",
      "collected_by": "Detective Smith",
      "blockchain_type": "hot",
      "collected_timestamp": "2025-11-15 10:30:00"
    }
  ]
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/evidence/list \
  -H "Accept: application/json"
```

---

### 5. Upload File to IPFS

**Upload evidence file to distributed storage**

```http
POST /api/ipfs/upload
```

**Headers:**
```
Content-Type: multipart/form-data
Accept: application/json
```

**Request Body:**
```
Form data with file field named 'file'
```

**Response:**
```json
{
  "success": true,
  "ipfs_hash": "QmXXXXXXXXXXXXXXX",
  "file_hash": "sha256:abc123def456...",
  "gateway_url": "http://localhost:8080/ipfs/QmXXXXXXXXXXXXXXX",
  "file_name": "evidence.img",
  "file_size": 1048576
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:5000/api/ipfs/upload \
  -H "Accept: application/json" \
  -F "file=@/path/to/evidence.img"
```

---

### 6. IPFS Status

**Check IPFS node health**

```http
GET /api/ipfs/status
```

**Headers:**
```
Accept: application/json
```

**Response:**
```json
{
  "status": "running",
  "version": "0.38.2"
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/ipfs/status \
  -H "Accept: application/json"
```

---

### 7. Create Case/Investigation

**Create a new investigation**

```http
POST /api/cases/create
```

**Headers:**
```
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "case_id": "CASE-2025-001",
  "case_name": "Financial Fraud Investigation",
  "case_number": "FR-2025-001",
  "case_type": "Financial Fraud",
  "investigating_agency": "FBI",
  "lead_investigator": "Agent Smith",
  "opened_date": "2025-11-15",
  "description": "Investigation into financial fraud allegations"
}
```

**Response:**
```json
{
  "success": true,
  "case_id": "CASE-2025-001"
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:5000/api/cases/create \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "case_id": "CASE-001",
    "case_name": "Test Investigation",
    "case_number": "INV-001",
    "case_type": "Fraud",
    "investigating_agency": "Local PD",
    "lead_investigator": "Detective Jones",
    "opened_date": "2025-11-15"
  }'
```

---

### 8. List Cases

**Get all cases**

```http
GET /api/cases/list
```

**Headers:**
```
Accept: application/json
```

**Response:**
```json
{
  "success": true,
  "count": 3,
  "cases": [
    {
      "case_id": "CASE-2025-001",
      "case_name": "Financial Fraud Investigation",
      "case_number": "FR-2025-001",
      "case_type": "Financial Fraud",
      "investigating_agency": "FBI",
      "lead_investigator": "Agent Smith",
      "status": "open",
      "opened_date": "2025-11-15",
      "evidence_count": 5,
      "total_evidence_size": 10485760
    }
  ]
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/cases/list \
  -H "Accept: application/json"
```

---

### 9. Container Status

**Get Docker container status**

```http
GET /api/containers/status
```

**Headers:**
```
Accept: application/json
```

**Response:**
```json
{
  "success": true,
  "containers": [
    {
      "name": "orderer.hot.coc.com",
      "status": "Up 2 hours",
      "ports": "7050/tcp, 7053/tcp"
    }
  ]
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/containers/status \
  -H "Accept: application/json"
```

---

### 10. Health Check

**Simple health endpoint**

```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-15T10:30:00Z"
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/health
```

---

## 🔗 Request/Response Formats

### Standard Request Format

```http
POST /api/endpoint
Content-Type: application/json
Accept: application/json

{
  "field1": "value1",
  "field2": "value2"
}
```

### Standard Success Response

```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

### Standard Error Response

```json
{
  "success": false,
  "error": "Error description",
  "code": 400
}
```

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid input/missing fields |
| 404 | Not Found | Resource not found |
| 500 | Internal Server Error | Server/blockchain error |

---

## 💻 Integration Examples

### Python Integration

```python
import requests
import json

class DFIRBlockchainClient:
    def __init__(self, base_url="http://localhost:5000"):
        self.base_url = base_url
        self.headers = {
            "Content-Type": "application/json",
            "Accept": "application/json"
        }

    def get_blockchain_status(self):
        """Get blockchain status"""
        response = requests.get(
            f"{self.base_url}/api/blockchain/status",
            headers={"Accept": "application/json"}
        )
        return response.json()

    def create_evidence(self, evidence_data):
        """Create new evidence on blockchain"""
        response = requests.post(
            f"{self.base_url}/api/evidence/create",
            headers=self.headers,
            json=evidence_data
        )
        return response.json()

    def get_evidence(self, evidence_id):
        """Query evidence from blockchain"""
        response = requests.get(
            f"{self.base_url}/api/evidence/{evidence_id}",
            headers={"Accept": "application/json"}
        )
        return response.json()

    def upload_file_to_ipfs(self, file_path):
        """Upload file to IPFS"""
        with open(file_path, 'rb') as f:
            files = {'file': f}
            response = requests.post(
                f"{self.base_url}/api/ipfs/upload",
                files=files
            )
        return response.json()

# Usage example
client = DFIRBlockchainClient("http://your-server-ip:5000")

# Check status
status = client.get_blockchain_status()
print(f"Hot chain height: {status['hot_blockchain']['height']}")

# Create evidence
evidence = {
    "id": "EVD-001",
    "case_id": "CASE-001",
    "type": "Digital Evidence",
    "description": "Disk image",
    "hash": "sha256:abc123",
    "location": "ipfs://QmTest",
    "metadata": {
        "collected_by": "Officer Smith",
        "timestamp": "2025-11-15T10:30:00Z"
    }
}
result = client.create_evidence(evidence)
print(f"Evidence created: {result['success']}")

# Upload file
upload_result = client.upload_file_to_ipfs("/path/to/file.img")
print(f"IPFS hash: {upload_result['ipfs_hash']}")
```

---

### JavaScript/Node.js Integration

```javascript
const axios = require('axios');

class DFIRBlockchainClient {
  constructor(baseURL = 'http://localhost:5000') {
    this.client = axios.create({
      baseURL: baseURL,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    });
  }

  async getBlockchainStatus() {
    const response = await this.client.get('/api/blockchain/status');
    return response.data;
  }

  async createEvidence(evidenceData) {
    const response = await this.client.post('/api/evidence/create', evidenceData);
    return response.data;
  }

  async getEvidence(evidenceId) {
    const response = await this.client.get(`/api/evidence/${evidenceId}`);
    return response.data;
  }

  async uploadFileToIPFS(fileBuffer, fileName) {
    const FormData = require('form-data');
    const formData = new FormData();
    formData.append('file', fileBuffer, fileName);

    const response = await this.client.post('/api/ipfs/upload', formData, {
      headers: formData.getHeaders()
    });
    return response.data;
  }
}

// Usage
const client = new DFIRBlockchainClient('http://your-server-ip:5000');

// Check status
client.getBlockchainStatus()
  .then(status => console.log('Hot chain height:', status.hot_blockchain.height));

// Create evidence
const evidence = {
  id: 'EVD-001',
  case_id: 'CASE-001',
  type: 'Digital Evidence',
  description: 'Disk image',
  hash: 'sha256:abc123',
  location: 'ipfs://QmTest',
  metadata: {
    collected_by: 'Officer Smith',
    timestamp: new Date().toISOString()
  }
};

client.createEvidence(evidence)
  .then(result => console.log('Evidence created:', result.success));
```

---

### Bash/Shell Integration

```bash
#!/bin/bash

# Configuration
API_BASE="http://localhost:5000"

# Get blockchain status
get_status() {
    curl -s -X GET "$API_BASE/api/blockchain/status" \
        -H "Accept: application/json" | jq
}

# Create evidence
create_evidence() {
    local evidence_id="$1"
    local case_id="$2"
    local description="$3"

    curl -s -X POST "$API_BASE/api/evidence/create" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "{
            \"id\": \"$evidence_id\",
            \"case_id\": \"$case_id\",
            \"type\": \"Digital Evidence\",
            \"description\": \"$description\",
            \"hash\": \"sha256:$(echo -n "$description" | sha256sum | cut -d' ' -f1)\",
            \"location\": \"ipfs://QmTest\",
            \"metadata\": {
                \"collected_by\": \"$USER\",
                \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
            }
        }" | jq
}

# Upload file to IPFS
upload_to_ipfs() {
    local file_path="$1"

    curl -s -X POST "$API_BASE/api/ipfs/upload" \
        -F "file=@$file_path" | jq
}

# Query evidence
get_evidence() {
    local evidence_id="$1"

    curl -s -X GET "$API_BASE/api/evidence/$evidence_id" \
        -H "Accept: application/json" | jq
}

# Usage
get_status
create_evidence "EVD-001" "CASE-001" "Test evidence"
upload_to_ipfs "/path/to/file.img"
get_evidence "EVD-001"
```

---

## 🌍 Network Configuration

### Expose API to Network

By default, Flask binds to `localhost` only. To allow external access:

**Option 1: Modify launch-webapp.sh**
```bash
# Edit launch-webapp.sh
# Change from:
python3 app_blockchain.py

# To:
python3 -c "from webapp.app_blockchain import app; app.run(host='0.0.0.0', port=5000)"
```

**Option 2: Use Environment Variable**
```bash
export FLASK_RUN_HOST=0.0.0.0
export FLASK_RUN_PORT=5000
python3 app_blockchain.py
```

**Option 3: Nginx Reverse Proxy**
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Enable CORS (for browser-based jumpservers)

Add to `app_blockchain.py`:

```python
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Or specific origins:
CORS(app, resources={r"/api/*": {"origins": "https://your-jumpserver.com"}})
```

### Firewall Configuration

```bash
# Allow port 5000 through firewall
sudo ufw allow 5000/tcp

# Or for specific IP:
sudo ufw allow from JUMPSERVER_IP to any port 5000
```

---

## ⚠️ Error Handling

### Common Errors

**1. Connection Refused**
```json
{
  "error": "Connection refused"
}
```
**Solution:** Ensure webapp is running and accessible on the network

**2. Missing Required Fields**
```json
{
  "error": "Missing required fields"
}
```
**Solution:** Check all required fields are present in request

**3. Blockchain Transaction Timeout**
```json
{
  "error": "Transaction timeout - orderer may not be responding"
}
```
**Solution:** Check blockchain containers are running (`docker ps`)

**4. Evidence Not Found**
```json
{
  "success": false,
  "error": "Evidence not found"
}
```
**Solution:** Verify evidence ID exists on the correct blockchain

### Retry Logic Example

```python
import time
import requests

def create_evidence_with_retry(evidence_data, max_retries=3):
    """Create evidence with automatic retry"""
    for attempt in range(max_retries):
        try:
            response = requests.post(
                "http://localhost:5000/api/evidence/create",
                json=evidence_data,
                timeout=30
            )
            if response.status_code == 200:
                return response.json()
        except requests.exceptions.RequestException as e:
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
                continue
            raise
    return {"error": "Max retries exceeded"}
```

---

## 🔒 Security Best Practices

### For Production Deployment:

1. **Enable HTTPS/TLS**
```bash
# Use nginx with SSL certificate
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

2. **Add API Authentication**
```python
# Example JWT authentication
from flask_jwt_extended import JWTManager, jwt_required

app.config['JWT_SECRET_KEY'] = 'your-secret-key'
jwt = JWTManager(app)

@app.route('/api/evidence/create', methods=['POST'])
@jwt_required()
def create_evidence():
    # Only accessible with valid JWT token
    pass
```

3. **Rate Limiting**
```python
from flask_limiter import Limiter

limiter = Limiter(app, key_func=lambda: request.remote_addr)

@app.route('/api/evidence/create', methods=['POST'])
@limiter.limit("10 per minute")
def create_evidence():
    pass
```

4. **Input Validation**
```python
from marshmallow import Schema, fields, validate

class EvidenceSchema(Schema):
    id = fields.Str(required=True, validate=validate.Length(min=1, max=64))
    case_id = fields.Str(required=True, validate=validate.Length(min=1, max=64))
    type = fields.Str(required=True)
    description = fields.Str(required=True)
    hash = fields.Str(required=True)
    location = fields.Str(required=True)
```

---

## 📊 Complete Integration Workflow

### Typical Evidence Submission Flow:

```
1. Jumpserver → GET /api/blockchain/status
   ↓ (verify system is healthy)

2. Jumpserver → POST /api/ipfs/upload (file)
   ↓ (get IPFS hash)

3. Jumpserver → POST /api/evidence/create
   {
     "id": "EVD-XXX",
     "case_id": "CASE-XXX",
     "hash": "<computed SHA-256>",
     "location": "ipfs://<ipfs-hash>",
     ...
   }
   ↓ (evidence recorded on blockchain)

4. Jumpserver → GET /api/evidence/EVD-XXX
   ↓ (verify evidence was stored)

5. Done ✓
```

---

## 📞 Support & Documentation

- **Full Setup Guide:** [SETUP.md](SETUP.md)
- **Quick Start:** [QUICKSTART.md](QUICKSTART.md)
- **Main README:** [README.md](README.md)

---

**API Version:** 1.0
**Last Updated:** November 2025
**License:** Proprietary - Omar Kaaki
