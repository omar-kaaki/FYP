# Professional Web Interface with IPFS Integration

## Overview

The webapp has been completely redesigned with a professional corporate UI and full IPFS file upload integration as requested.

## Changes Implemented

### 1. Professional UI Design

**Removed:**
- ❌ Colorful gradients
- ❌ Bright colors
- ❌ Flashy design elements

**Added:**
- ✅ Professional corporate color scheme (gray/white/blue)
- ✅ Clean card-based layout
- ✅ Minimal, business-appropriate design
- ✅ Professional typography
- ✅ Proper spacing and alignment

### 2. IPFS File Upload Integration

**Frontend Features (`webapp/templates/dashboard.html`):**
- Drag-and-drop file upload area
- File browser with click-to-upload
- Real-time upload progress
- SHA-256 hash calculation in browser
- Automatic blockchain submission after IPFS upload
- Display of IPFS hash (CID) and gateway link
- Evidence metadata form pre-filled with file information

**Backend Features (`webapp/app_blockchain.py`):**
- New endpoint: `POST /api/ipfs/upload`
- File upload handling via Flask
- Temporary file storage and management
- SHA-256 hash calculation
- Docker-based IPFS file addition
- Returns:
  - IPFS hash (CID)
  - File SHA-256 hash
  - Gateway URL for accessing file
  - Filename

### 3. Enhanced Startup Display

When you run the webapp, you now see:

```
======================================================================
       DFIR BLOCKCHAIN EVIDENCE MANAGEMENT SYSTEM
======================================================================

📍 SERVICE URLS:

  🌐 Main Dashboard:        http://localhost:5000
  📁 IPFS Web UI:           https://webui.ipfs.io
  🔗 IPFS Gateway:          http://localhost:8080
  🗄️  MySQL phpMyAdmin:      http://localhost:8081

  Credentials for phpMyAdmin:
    Username: cocuser
    Password: cocpassword
    Database: coc_evidence

======================================================================

🔧 API ENDPOINTS:

  GET  /api/blockchain/status    - Blockchain health status
  POST /api/evidence/create      - Create new evidence
  GET  /api/evidence/<id>        - Query evidence by ID
  GET  /api/evidence/list        - List all evidence
  POST /api/ipfs/upload          - Upload file to IPFS
  GET  /api/ipfs/status          - IPFS node status
  GET  /api/containers/status    - Docker containers status

======================================================================

✅ System Ready - Press Ctrl+C to stop
```

## How to Use

### Starting the System

```bash
# 1. Start all blockchain services
./restart-blockchain.sh

# 2. Deploy chaincode (if not already deployed)
./deploy-chaincode.sh

# 3. Start the web dashboard
cd webapp
python3 app_blockchain.py
```

The startup display will show you all the service URLs you need.

### Uploading Evidence with Files

**Method 1: Using the Web Interface**

1. Open http://localhost:5000 in your browser
2. Go to the "Create Evidence" section
3. Drag a file to the upload area or click to browse
4. The file will automatically:
   - Upload to IPFS
   - Calculate SHA-256 hash
   - Display IPFS hash (CID)
   - Pre-fill the evidence form
5. Fill in remaining fields:
   - Evidence ID (unique identifier)
   - Case ID
   - Evidence Type
   - Description
   - Collected By
6. Click "Submit Evidence"
7. The evidence record (with IPFS reference) is stored on blockchain

**Method 2: Using the API**

```bash
# Step 1: Upload file to IPFS
curl -X POST -F "file=@/path/to/evidence.jpg" \
  http://localhost:5000/api/ipfs/upload

# Response:
{
  "success": true,
  "ipfs_hash": "QmXyz123...",
  "file_hash": "abc123def456...",
  "filename": "evidence.jpg",
  "gateway_url": "http://localhost:8080/ipfs/QmXyz123..."
}

# Step 2: Create evidence on blockchain
curl -X POST http://localhost:5000/api/evidence/create \
  -H "Content-Type: application/json" \
  -d '{
    "id": "EVD-2024-001",
    "case_id": "CASE-123",
    "type": "digital",
    "description": "Surveillance footage",
    "hash": "abc123def456...",
    "location": "ipfs://QmXyz123...",
    "metadata": "{\"filename\":\"evidence.jpg\"}"
  }'
```

## File Upload Workflow

```
User selects file
      ↓
Frontend: Calculate SHA-256 hash
      ↓
POST /api/ipfs/upload
      ↓
Backend: Save file temporarily
      ↓
Backend: Copy to IPFS container
      ↓
Backend: docker exec ipfs-node ipfs add <file>
      ↓
Backend: Return IPFS hash (CID)
      ↓
Frontend: Display IPFS hash and gateway link
      ↓
Frontend: Pre-fill evidence form
      ↓
User fills remaining fields
      ↓
POST /api/evidence/create
      ↓
Backend: Submit to blockchain
      ↓
Evidence stored with:
  - File hash (integrity)
  - IPFS location (storage)
  - Metadata (case info)
```

## Accessing Services

### Main Dashboard
**URL:** http://localhost:5000

Features:
- System status overview
- Evidence submission with IPFS upload
- Evidence search and verification
- Container health monitoring

### IPFS Web UI
**URL:** https://webui.ipfs.io

Connect to your local node:
- Click "Settings"
- Enter API: http://localhost:5001
- Explore files in your IPFS node

### IPFS Gateway
**URL:** http://localhost:8080/ipfs/{CID}

Access any file by its IPFS hash:
```
http://localhost:8080/ipfs/QmXyz123...
```

### MySQL phpMyAdmin
**URL:** http://localhost:8081

Credentials:
- Username: `cocuser`
- Password: `cocpassword`
- Database: `coc_evidence`

View and manage:
- Evidence metadata
- Custody transfers
- System logs

## New API Endpoints

### Upload File to IPFS

```http
POST /api/ipfs/upload
Content-Type: multipart/form-data

file: <binary file data>
```

**Response:**
```json
{
  "success": true,
  "ipfs_hash": "QmXyz123...",
  "file_hash": "sha256_hash_here",
  "filename": "evidence.jpg",
  "gateway_url": "http://localhost:8080/ipfs/QmXyz123..."
}
```

### Create Evidence (Enhanced)

```http
POST /api/evidence/create
Content-Type: application/json

{
  "id": "EVD-2024-001",
  "case_id": "CASE-123",
  "type": "digital",
  "description": "Evidence description",
  "hash": "sha256_file_hash",
  "location": "ipfs://QmXyz123...",
  "metadata": "{\"filename\":\"evidence.jpg\",\"size\":1024}"
}
```

## Security Considerations

### File Integrity
- SHA-256 hash calculated before IPFS upload
- Hash stored on blockchain
- Verify file integrity by comparing hashes

### Immutable Storage
- Files stored on IPFS (content-addressed)
- Blockchain records cannot be altered
- Complete chain of custody preserved

### Access Control
- Blockchain uses mTLS authentication
- IPFS local node (not exposed to internet)
- MySQL credentials for authorized users only

## Troubleshooting

### IPFS Upload Fails

**Error:** "Failed to copy file to IPFS container"

**Solution:**
```bash
# Check IPFS container is running
docker ps | grep ipfs-node

# Restart if needed
docker restart ipfs-node
```

### File Not Accessible via Gateway

**Error:** Gateway returns 404

**Solution:**
```bash
# Check if file is in IPFS
docker exec ipfs-node ipfs pin ls | grep <IPFS_HASH>

# Re-add file if missing
docker exec ipfs-node ipfs add /path/to/file
```

### Evidence Creation Fails

**Error:** "Transaction timeout"

**Solution:**
```bash
# Verify blockchain is running
./verify-blockchain.sh

# Check orderers are in channels
./verify-orderers.sh
```

## File Storage Best Practices

### Evidence File Management

1. **Upload to IPFS First**
   - Store original files on IPFS
   - Get IPFS hash (CID)
   - Use CID as permanent reference

2. **Store Reference on Blockchain**
   - Record IPFS hash on blockchain
   - Include file metadata
   - Add case information

3. **Maintain Metadata in MySQL**
   - Store searchable information
   - Enable fast queries
   - Link to blockchain records

### Example Complete Workflow

```python
# 1. Upload evidence file
file_path = "evidence.jpg"
upload_response = upload_to_ipfs(file_path)
ipfs_hash = upload_response['ipfs_hash']
file_hash = upload_response['file_hash']

# 2. Create blockchain record
evidence = {
    "id": "EVD-2024-001",
    "case_id": "CASE-123",
    "type": "digital",
    "description": "Surveillance footage",
    "hash": file_hash,
    "location": f"ipfs://{ipfs_hash}",
    "metadata": json.dumps({
        "filename": "evidence.jpg",
        "collected_by": "Officer Smith",
        "timestamp": datetime.now().isoformat()
    })
}
create_evidence(evidence)

# 3. Verify later
retrieved = query_evidence("EVD-2024-001")
assert retrieved['hash'] == file_hash
assert retrieved['location'] == f"ipfs://{ipfs_hash}"

# 4. Access file
gateway_url = f"http://localhost:8080/ipfs/{ipfs_hash}"
```

## Summary

Your DFIR blockchain system now has:

✅ Professional corporate web interface
✅ Integrated IPFS file upload (drag & drop)
✅ Automatic blockchain submission
✅ Complete file upload workflow
✅ All service URLs displayed on startup
✅ Clean, business-appropriate design

All changes have been committed and pushed to:
```
Branch: claude/fix-docker-network-peers-011CUpbTaJYAg44GzT1B28gq
```

## Next Steps

1. **Pull the latest changes:**
   ```bash
   git pull origin claude/fix-docker-network-peers-011CUpbTaJYAg44GzT1B28gq
   ```

2. **Start the system:**
   ```bash
   ./restart-blockchain.sh
   cd webapp && python3 app_blockchain.py
   ```

3. **Test file upload:**
   - Open http://localhost:5000
   - Drag a file to upload area
   - Submit evidence to blockchain
   - Verify via search

Your dual Hyperledger Fabric blockchain system with professional web interface and IPFS integration is ready for use!
