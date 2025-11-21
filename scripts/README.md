# FYP Blockchain Scripts

This directory contains operational scripts for managing the Hyperledger Fabric v2.5.14 network.

## Scripts Overview

### generate-crypto.sh

**Purpose:** Generate all cryptographic material for the blockchain network

**What it does:**
1. Starts all 6 Certificate Authority (CA) containers
2. Enrolls CA admin users for each organization
3. Registers all node and user identities
4. Enrolls all identities to generate certificates
5. Generates TLS certificates for secure communication
6. Organizes all certificates into proper MSP directory structure

**Usage:**
```bash
cd /home/user/FYPBcoc
./scripts/generate-crypto.sh
```

**Prerequisites:**
- Docker and Docker Compose installed
- Fabric CA client binaries in PATH
- CA containers defined in `docker-compose-ca.yaml`

**Output:**
- Complete `crypto-config/` directory with all MSP materials
- Certificates for 3 organizations (OrdererOrg, LabOrg, CourtOrg)
- Identity and TLS certificates for all nodes and users

**Identities Generated:**

| Organization | Identity | Type | OU |
|--------------|----------|------|----|
| OrdererOrg | orderer1.ordererorg.example.com | Orderer | orderer |
| OrdererOrg | orderer-admin@ordererorg.example.com | Admin | admin |
| LabOrg | peer0.laborg.example.com | Peer | peer |
| LabOrg | lab-admin@laborg.example.com | Admin | admin |
| LabOrg | lab-gw@laborg.example.com | Client | client |
| CourtOrg | peer0.courtorg.example.com | Peer | peer |
| CourtOrg | court-admin@courtorg.example.com | Admin | admin |

---

## Execution Order

For initial network setup, run scripts in this order:

1. **generate-crypto.sh** - Generate all crypto material (this script)
2. **generate-genesis.sh** - Create channel genesis blocks (to be created)
3. **start-network.sh** - Start all network containers (to be created)
4. **create-channels.sh** - Create and join channels (to be created)
5. **deploy-chaincode.sh** - Package and deploy chaincode (to be created)

---

## Troubleshooting

### CA containers fail to start
```bash
# Check CA logs
docker logs ca.laborg.example.com

# Restart CA containers
docker-compose -f docker-compose-ca.yaml restart
```

### Certificate enrollment fails
```bash
# Verify CA is responsive
curl -k https://localhost:7055/cainfo

# Check CA admin enrollment
export FABRIC_CA_CLIENT_HOME=/home/user/FYPBcoc/crypto-config/peerOrganizations/laborg.example.com
fabric-ca-client getcainfo -u https://localhost:7055
```

### Missing directories
The script will create all required directories. If you see permission errors:
```bash
sudo chown -R $USER:$USER /home/user/FYPBcoc/crypto-config
```

---

## Directory Structure Created

```
crypto-config/
├── ordererOrganizations/
│   └── ordererorg.example.com/
│       ├── ca/                    # Identity CA files
│       ├── tlsca/                 # TLS CA files
│       ├── msp/                   # Org MSP definition
│       ├── orderers/
│       │   └── orderer1.ordererorg.example.com/
│       │       ├── msp/           # Node identity
│       │       └── tls/           # Node TLS certs
│       └── users/
│           └── orderer-admin@ordererorg.example.com/
│               └── msp/
├── peerOrganizations/
│   ├── laborg.example.com/
│   │   ├── ca/
│   │   ├── tlsca/
│   │   ├── msp/
│   │   ├── peers/
│   │   │   └── peer0.laborg.example.com/
│   │   │       ├── msp/
│   │   │       └── tls/
│   │   └── users/
│   │       ├── lab-admin@laborg.example.com/
│   │       │   └── msp/
│   │       └── lab-gw@laborg.example.com/
│   │           ├── msp/
│   │           └── tls/
│   └── courtorg.example.com/
│       ├── ca/
│       ├── tlsca/
│       ├── msp/
│       ├── peers/
│       │   └── peer0.courtorg.example.com/
│       │       ├── msp/
│       │       └── tls/
│       └── users/
│           └── court-admin@courtorg.example.com/
│               └── msp/
```

---

## Notes

- All passwords are currently set to default values for development
- For production, use secure password management and rotate credentials regularly
- TLS is enabled for all communications
- NodeOUs are enabled for role-based access control

---

**Last Updated:** 2025-11-21
**Fabric Version:** 2.5.14 LTS
