# Orderer Keys - Complete Summary

## Hot Orderer (orderer.hot.coc.com)

### Private Key
**Location:** `hot-blockchain/crypto-config/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/msp/keystore/priv_sk`

```
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgNdg0x/xbVHRuP6pK
fuXm1/azavwgX3Lj4tLwIJd4hdGhRANCAARNe+S/vZ9cn078UgejLA8AQ3F14xub
PT27hP9fd6vnntH/ILtrKSEQrTEzif2pj3yPKK3KEeXg+gfJvBdjyYIj
-----END PRIVATE KEY-----
```

**Algorithm:** ECDSA (Elliptic Curve Digital Signature Algorithm)
**Curve:** secp256r1 (P-256, prime256v1)
**Key Size:** 256 bits
**Format:** PKCS#8 PEM

### Public Certificate
**Location:** `hot-blockchain/crypto-config/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/msp/signcerts/orderer.hot.coc.com-cert.pem`

```
-----BEGIN CERTIFICATE-----
MIICHTCCAcSgAwIBAgIQG6lTo9czIoXBkDuuY+lFBjAKBggqhkjOPQQDAjBpMQsw
CQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQGA1UEBxMNU2FuIEZy
YW5jaXNjbzEUMBIGA1UEChMLaG90LmNvYy5jb20xFzAVBgNVBAMTDmNhLmhvdC5j
b2MuY29tMB4XDTI1MTEwMTE5MjcwMFoXDTM1MTAzMDE5MjcwMFowajELMAkGA1UE
BhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcTDVNhbiBGcmFuY2lz
Y28xEDAOBgNVBAsTB29yZGVyZXIxHDAaBgNVBAMTE29yZGVyZXIuaG90LmNvYy5j
b20wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARNe+S/vZ9cn078UgejLA8AQ3F1
4xubPT27hP9fd6vnntH/ILtrKSEQrTEzif2pj3yPKK3KEeXg+gfJvBdjyYIjo00w
SzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADArBgNVHSMEJDAigCCphN+p
h3ICaOAAWtJqSQU5fszpGBR1wOf/c1u9+so7MTAKBggqhkjOPQQDAgNHADBEAiBZ
FZsyWNru+TOQVofdfnex5P5BM+qtd2xWYtJu5E/gKgIgAR6PfCE3tMZ+gJ8q5GZ7
bYO2cWWR3rI09G38SYjHx98=
-----END CERTIFICATE-----
```

**Subject:** CN=orderer.hot.coc.com, OU=orderer, L=San Francisco, ST=California, C=US
**Issuer:** CN=ca.hot.coc.com, O=hot.coc.com, L=San Francisco, ST=California, C=US
**Valid From:** Nov 01, 2025 19:27:00 GMT
**Valid Until:** Oct 30, 2035 19:27:00 GMT (10 years)
**Signature Algorithm:** ecdsa-with-SHA256

### Public Key (Extracted)
```
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAETXvkv72fXJ9O/FIHoywPAENxdeMb
mz09u4T/X3er557R/yC7aykhEK0xM4n9qY98jyityhHl4PoHybwXY8mCIw==
-----END PUBLIC KEY-----
```

**Coordinates:**
- X: 4d7be4bfbd9f5c9f4efc5207a32c0f007371…
- Y: 9b3d3dbb84ff5f77abe79ed1ff20bb6b292…

---

## Cold Orderer (orderer.cold.coc.com)

### Private Key
**Location:** `cold-blockchain/crypto-config/ordererOrganizations/cold.coc.com/orderers/orderer.cold.coc.com/msp/keystore/priv_sk`

```
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgq1aZaYMfRYOxurfB
insFg6Unr7uHcQaP+p4E+3oVQGOhRANCAATsMUgqeSMgf5HzK6h3ca2yYgmk4Ydm
jcMaQAto3vDO1FLDfvE0wvWcBQSVkBmXxyz7mZoBfztcpcKr3+P5S3Rl
-----END PRIVATE KEY-----
```

**Algorithm:** ECDSA (Elliptic Curve Digital Signature Algorithm)
**Curve:** secp256r1 (P-256, prime256v1)
**Key Size:** 256 bits
**Format:** PKCS#8 PEM

### Public Certificate
**Location:** `cold-blockchain/crypto-config/ordererOrganizations/cold.coc.com/orderers/orderer.cold.coc.com/msp/signcerts/orderer.cold.coc.com-cert.pem`

```
-----BEGIN CERTIFICATE-----
MIICITCCAcigAwIBAgIRAN2cWvu23EoADFTrliCxoIUwCgYIKoZIzj0EAwIwazEL
MAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcTDVNhbiBG
cmFuY2lzY28xFTATBgNVBAoTDGNvbGQuY29jLmNvbTEYMBYGA1UEAxMPY2EuY29s
ZC5jb2MuY29tMB4XDTI1MTEwMTE5MjcwMFoXDTM1MTAzMDE5MjcwMFowazELMAkG
A1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcTDVNhbiBGcmFu
Y2lzY28xEDAOBgNVBAsTB29yZGVyZXIxHTAbBgNVBAMTFG9yZGVyZXIuY29sZC5j
b2MuY29tMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE7DFIKnkjIH+R8yuod3Gt
smIJpOGHZo3DGkALaN7wztRSw37xNML1nAUElZAZl8cs+5maAX87XKXCq9/j+Ut0
ZaNNMEswDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwKwYDVR0jBCQwIoAg
lT+dxr0nWbjFnLmc09QsqOM5ZphtqSAyugkqpCj7X0owCgYIKoZIzj0EAwIDRwAw
RAIgUwzksYkZkLNhCSkvB4pigmhJlRkKNSOpBBK5Mr63epoCIHgkk7NoZQxRVIJT
VkL5xaDBkYZe/BwzSxrgLTeesA2d
-----END CERTIFICATE-----
```

**Subject:** CN=orderer.cold.coc.com, OU=orderer, L=San Francisco, ST=California, C=US
**Issuer:** CN=ca.cold.coc.com, O=cold.coc.com, L=San Francisco, ST=California, C=US
**Valid From:** Nov 01, 2025 19:27:00 GMT
**Valid Until:** Oct 30, 2035 19:27:00 GMT (10 years)
**Signature Algorithm:** ecdsa-with-SHA256

### Public Key (Extracted)
```
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE7DFIKnkjIH+R8yuod3GtsmIJpOGH
Zo3DGkALaN7wztRSw37xNML1nAUElZAZl8cs+5maAX87XKXCq9/j+Ut0ZQ==
-----END PUBLIC KEY-----
```

**Coordinates:**
- X: ec31482a792320f791f32ba87771adb262…
- Y: 09a4e18766…

---

## Key Comparison

| Aspect | Hot Orderer | Cold Orderer |
|--------|-------------|--------------|
| **Algorithm** | ECDSA P-256 | ECDSA P-256 |
| **Key Size** | 256 bits | 256 bits |
| **Curve** | secp256r1 | secp256r1 |
| **Validity** | 10 years | 10 years |
| **Certificate Issuer** | ca.hot.coc.com | ca.cold.coc.com |
| **Common Name** | orderer.hot.coc.com | orderer.cold.coc.com |

---

## Security Notes

⚠️ **CRITICAL SECURITY WARNINGS:**

1. **Private Keys Exposed Above**
   - These private keys are now visible in this document
   - Anyone with this file can impersonate the orderers
   - Can sign fake blocks
   - Can compromise your entire blockchain

2. **Current Storage: INSECURE**
   - Keys stored as plain files on disk
   - File permissions: 644 (world-readable)
   - No encryption
   - No HSM or enclave protection

3. **Immediate Actions Required:**
   ```bash
   # 1. Change file permissions NOW
   chmod 600 hot-blockchain/crypto-config/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/msp/keystore/priv_sk
   chmod 600 cold-blockchain/crypto-config/ordererOrganizations/cold.coc.com/orderers/orderer.cold.coc.com/msp/keystore/priv_sk

   # 2. Delete this file after viewing
   rm ORDERER-KEYS-SUMMARY.md

   # 3. Regenerate keys if this is production
   # (Use cryptogen or fabric-ca to generate new keys)

   # 4. Implement SGX enclave or HSM protection
   # (See docs/ORDERER-KEY-SECURITY-COMPARISON.md)
   ```

4. **For Production:**
   - ❌ NEVER store private keys in plain files
   - ❌ NEVER commit private keys to git
   - ❌ NEVER share private keys via email/chat
   - ✅ Use HSM or SGX enclave
   - ✅ Implement proper key management
   - ✅ Regular key rotation policy

---

## What These Keys Are Used For

### Private Keys (priv_sk):
1. **Sign every block** before broadcasting to peers
2. **Authenticate orderer** to peers (mutual TLS)
3. **Participate in Raft consensus** (leader election, heartbeats)
4. **Sign channel operations** (create, update channels)

### Public Keys (in certificates):
1. **Distributed to all peers** for signature verification
2. **Verify blocks** signed by orderer
3. **Establish TLS connections** to orderer
4. **Identify orderer** in the network

---

## Cryptographic Details

### ECDSA P-256 (secp256r1)
- **Security Level:** 128-bit (equivalent to 3072-bit RSA)
- **NIST Standard:** FIPS 186-4
- **Also Known As:** prime256v1, NIST P-256
- **Used By:** Bitcoin, TLS 1.3, many cryptocurrencies

### Why ECDSA for Blockchain?
- ✅ Smaller key sizes (256 bits vs 3072 bits RSA)
- ✅ Faster signatures
- ✅ Smaller signatures (64 bytes vs 384 bytes)
- ✅ Better performance for blockchain
- ✅ Industry standard for distributed ledgers

---

## File Locations Summary

```
hot-blockchain/crypto-config/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/
├── msp/
│   ├── keystore/
│   │   └── priv_sk                     ← HOT PRIVATE KEY
│   ├── signcerts/
│   │   └── orderer.hot.coc.com-cert.pem  ← HOT PUBLIC CERT
│   ├── cacerts/
│   │   └── ca.hot.coc.com-cert.pem     (CA certificate)
│   └── tlscacerts/
│       └── tlsca.hot.coc.com-cert.pem  (TLS CA certificate)
└── tls/
    ├── server.key                       (TLS private key - different from signing key)
    └── server.crt                       (TLS certificate)

cold-blockchain/crypto-config/ordererOrganizations/cold.coc.com/orderers/orderer.cold.coc.com/
├── msp/
│   ├── keystore/
│   │   └── priv_sk                      ← COLD PRIVATE KEY
│   ├── signcerts/
│   │   └── orderer.cold.coc.com-cert.pem ← COLD PUBLIC CERT
│   ├── cacerts/
│   │   └── ca.cold.coc.com-cert.pem
│   └── tlscacerts/
│       └── tlsca.cold.coc.com-cert.pem
└── tls/
    ├── server.key
    └── server.crt
```

---

## Verification Commands

```bash
# Verify private key matches public certificate (Hot)
openssl ec -in hot-blockchain/crypto-config/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/msp/keystore/priv_sk -pubout | openssl md5
openssl x509 -in hot-blockchain/crypto-config/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/msp/signcerts/orderer.hot.coc.com-cert.pem -pubkey -noout | openssl md5
# Hashes should match!

# View certificate details (Hot)
openssl x509 -in hot-blockchain/crypto-config/ordererOrganizations/hot.coc.com/orderers/orderer.hot.coc.com/msp/signcerts/orderer.hot.coc.com-cert.pem -text -noout

# Verify private key matches public certificate (Cold)
openssl ec -in cold-blockchain/crypto-config/ordererOrganizations/cold.coc.com/orderers/orderer.cold.coc.com/msp/keystore/priv_sk -pubout | openssl md5
openssl x509 -in cold-blockchain/crypto-config/ordererOrganizations/cold.coc.com/orderers/orderer.cold.coc.com/msp/signcerts/orderer.cold.coc.com-cert.pem -pubkey -noout | openssl md5
# Hashes should match!

# View certificate details (Cold)
openssl x509 -in cold-blockchain/crypto-config/ordererOrganizations/cold.coc.com/orderers/orderer.cold.coc.com/msp/signcerts/orderer.cold.coc.com-cert.pem -text -noout
```

---

## Recommendation

**🔴 URGENT: These keys are now exposed in this document!**

For a production DFIR system handling legal evidence, you MUST:

1. **Regenerate these keys** if this will be used in production
2. **Implement SGX enclave protection** (recommended for your setup)
3. **Or use HSM** (if budget allows)
4. **Never expose private keys** like this again
5. **Delete this document** after reading

See `docs/ORDERER-KEY-SECURITY-COMPARISON.md` for implementation guide.

---

**Generated:** 2025-11-05
**Status:** 🔴 DEVELOPMENT KEYS ONLY - NOT FOR PRODUCTION
