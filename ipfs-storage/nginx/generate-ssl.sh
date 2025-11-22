#!/bin/bash
#
# generate-ssl.sh - Generate self-signed SSL certificates for IPFS proxy
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSL_DIR="${SCRIPT_DIR}/ssl"

echo "=================================="
echo "  Generating SSL Certificates"
echo "  for IPFS HTTPS Proxy"
echo "=================================="
echo ""

# Create SSL directory
mkdir -p "${SSL_DIR}"

# Generate private key
echo "Generating private key..."
openssl genrsa -out "${SSL_DIR}/server.key" 4096

# Generate certificate signing request
echo "Generating certificate signing request..."
openssl req -new \
    -key "${SSL_DIR}/server.key" \
    -out "${SSL_DIR}/server.csr" \
    -subj "/C=MY/ST=KualaLumpur/L=KualaLumpur/O=CoC/OU=IPFS/CN=ipfs-api.coc.local"

# Generate self-signed certificate (valid for 10 years)
echo "Generating self-signed certificate..."
openssl x509 -req \
    -days 3650 \
    -in "${SSL_DIR}/server.csr" \
    -signkey "${SSL_DIR}/server.key" \
    -out "${SSL_DIR}/server.crt" \
    -extensions v3_req \
    -extfile <(cat <<EOF
[v3_req]
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ipfs-api.coc.local
DNS.2 = ipfs-gateway.coc.local
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF
)

# Set permissions
chmod 600 "${SSL_DIR}/server.key"
chmod 644 "${SSL_DIR}/server.crt"

echo ""
echo "✓ SSL certificates generated successfully"
echo ""
echo "Certificate details:"
openssl x509 -in "${SSL_DIR}/server.crt" -noout -text | grep -E "Subject:|Issuer:|Not Before|Not After|DNS:"
echo ""
echo "Files created:"
echo "  Private Key: ${SSL_DIR}/server.key"
echo "  Certificate: ${SSL_DIR}/server.crt"
echo "  CSR:         ${SSL_DIR}/server.csr"
echo ""
echo "Note: For production, replace with certificates signed by a trusted CA"
echo ""
