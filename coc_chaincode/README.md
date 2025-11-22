# Chain of Custody Chaincode

Complete Go chaincode implementation for the FYP Chain of Custody system with JumpServer RBAC integration and Casbin policy enforcement.

## Architecture

This chaincode is deployed on both blockchains:
- **hot_chaincode** on `hot-chain` (Active Investigation)
- **cold_chaincode** on `cold-chain` (Archival)

## Directory Structure

```
coc_chaincode/
├── access/                    # Casbin RBAC configuration
│   ├── casbin_model.conf     # RBAC domain model
│   └── casbin_policy.csv     # Permission policies
├── rbac/                      # Gateway and user role management
│   ├── gateway.go            # Identity validation
│   └── userroles.go          # On-chain user role mapping
├── domain/                    # Business logic
│   ├── investigation.go      # Investigation CRUD + archive/reopen
│   ├── evidence.go           # Evidence CRUD + chain of custody
│   └── guidmap.go            # GUID mapping (cold-chain only)
├── utils/                     # Helper utilities
│   └── json.go               # JSON marshaling helpers
├── main.go                    # Chaincode entry point
├── go.mod                     # Go module definition
├── build.sh                   # Build and package script
└── README.md                  # This file
```

## Key Features

### 1. Gateway Identity Validation
- All business operations must come through the trusted gateway (`lab-gw` from `LabOrgMSP`)
- User context passed via transient map (`userId`, `role`)
- On-chain principal ID format: `LabOrgMSP|lab-gw|user:<userId>`

### 2. Casbin RBAC Enforcement
- **Domain-based**: Separate policies for `hot` and `cold` blockchains
- **Roles**:
  - `BlockchainInvestigator`: Create/modify on hot, read-only on cold
  - `BlockchainAuditor`: Read-only on both chains
  - `BlockchainCourt`: Archive/reopen/GUID management on cold
  - `SystemAdmin`: User role management

### 3. Data Models

#### Investigation
```json
{
  "id": "INV-2025-0001",
  "title": "Investigation title",
  "description": "Description",
  "status": "open|archived",
  "createdBy": "userId",
  "createdAt": "RFC3339",
  "updatedAt": "RFC3339",
  "channel": "hot|cold"
}
```

#### Evidence
```json
{
  "id": "EVID-0001",
  "investigationId": "INV-2025-0001",
  "hash": "sha256:...",
  "ipfsCid": "bafy...",
  "createdBy": "userId",
  "createdAt": "RFC3339",
  "channel": "hot|cold",
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
      "description": "Evidence collected"
    }
  ]
}
```

#### GUID Mapping (cold-chain only)
```json
{
  "guid": "GUID-XYZ",
  "internalEvidenceId": "EVID-0001",
  "createdBy": "userId",
  "createdAt": "RFC3339",
  "description": "Court case reference"
}
```

## Chaincode Functions

### Admin Functions (require admin identity)
- `SetUserRoles(principalID, rolesCsv)` - Assign roles to user
- `GetUserRoles(principalID)` - Query user roles
- `ListUserRoles()` - List all user role mappings
- `DeleteUserRole(principalID)` - Remove user role mapping

### Investigation Functions (require gateway + user context)
- `CreateInvestigation(id, title, description)` - Create investigation
- `GetInvestigation(id)` - Retrieve investigation
- `UpdateInvestigation(id, title, description)` - Update investigation
- `ListInvestigations()` - List all investigations
- `ArchiveInvestigation(id)` - Archive (cold-chain only)
- `ReopenInvestigation(id)` - Reopen archived (cold-chain only)

### Evidence Functions (require gateway + user context)
- `AddEvidence(id, investigationId, hash, ipfsCid, metaJSON)` - Add evidence
- `GetEvidence(id)` - Retrieve evidence
- `ListEvidence()` - List all evidence
- `ListEvidenceByInvestigation(investigationId)` - Filter by investigation
- `AddCustodyEvent(evidenceId, action, custodian, location, description)` - Add custody event
- `VerifyEvidenceHash(evidenceId, hash)` - Verify hash integrity

### GUID Mapping Functions (require gateway + user context, cold-chain only)
- `CreateGUIDMapping(guid, internalEvidenceId, description)` - Create mapping
- `ResolveGUID(guid)` - Resolve GUID to evidence ID
- `GetEvidenceByGUID(guid)` - Retrieve evidence by GUID
- `ListGUIDMappings()` - List all mappings

## Building the Chaincode

```bash
cd /home/user/FYPBcoc/coc_chaincode
./build.sh
```

This will:
1. Download Go dependencies
2. Vendor dependencies
3. Build the chaincode binary
4. Create `coc_chaincode.tar.gz` package

## Deploying the Chaincode

### Hot Blockchain
```bash
cd /home/user/FYPBcoc/hot-blockchain
./scripts/deploy-chaincode.sh
```

This deploys as `hot_chaincode` with:
- Endorsement policy: `OR('LabOrgMSP.peer')`
- Installed on: `peer0.laborg.hot.coc.com`

### Cold Blockchain
```bash
cd /home/user/FYPBcoc/cold-blockchain
./scripts/deploy-chaincode.sh
```

This deploys as `cold_chaincode` with:
- Endorsement policy: `AND('LabOrgMSP.peer','CourtOrgMSP.peer')`
- Installed on: `peer0.laborg.cold.coc.com` and `peer0.courtorg.cold.coc.com`

## Testing the Chaincode

### Set User Roles (admin function)
```bash
# As LabOrg admin
export CORE_PEER_MSPCONFIGPATH=/home/user/FYPBcoc/hot-blockchain/crypto-config/peerOrganizations/laborg.hot.coc.com/users/Admin@laborg.hot.coc.com/msp

peer chaincode invoke \
  -C hot-chain \
  -n hot_chaincode \
  -c '{"function":"SetUserRoles","Args":["LabOrgMSP|lab-gw|user:investigator1","BlockchainInvestigator"]}'
```

### Create Investigation (gateway function with transient)
```bash
# Via JumpServer with lab-gw identity
# Transient map: {"userId": "investigator1", "role": "BlockchainInvestigator"}

peer chaincode invoke \
  -C hot-chain \
  -n hot_chaincode \
  --transient '{"userId":"aW52ZXN0aWdhdG9yMQ==","role":"QmxvY2tjaGFpbkludmVzdGlnYXRvcg=="}' \
  -c '{"function":"CreateInvestigation","Args":["INV-001","Test Investigation","Initial investigation"]}'
```

Note: Transient values must be base64 encoded.

## Access Control Flow

1. **Request arrives** from JumpServer via `lab-gw` gateway identity
2. **Gateway validation**: Verify MSP ID and CN match trusted gateway
3. **User context extraction**: Get `userId` and `role` from transient map
4. **Principal construction**: Build `LabOrgMSP|lab-gw|user:<userId>`
5. **Role validation**: Verify user has claimed role in on-chain mapping
6. **Casbin enforcement**: Check permission for (role, domain, object, action)
7. **Business logic execution**: If permitted, execute function

## Security Considerations

- Private keys never exposed in chaincode
- All access via trusted gateway identity
- User context in transient map (not on ledger)
- On-chain role mapping provides audit trail
- Casbin policies embedded in chaincode binary
- Domain separation (hot vs cold) enforced
- TLS for all peer-to-peer communication

## Development

To modify the chaincode:
1. Edit source files in appropriate module (domain/, rbac/, etc.)
2. Update Casbin policies in `access/` if needed
3. Rebuild: `./build.sh`
4. Upgrade chaincode with new sequence number in deploy scripts

## Dependencies

- Hyperledger Fabric Chaincode Go v0.0.0-20240618150331-c5e787a1b0cf
- Hyperledger Fabric Protos Go v0.3.3
- Casbin v2.97.0
- Go 1.21+

## License

Part of FYP Chain of Custody project.
