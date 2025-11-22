/**
 * Service Configuration
 */

import * as dotenv from 'dotenv';
import path from 'path';

dotenv.config();

export const config = {
    // Service configuration
    servicePort: parseInt(process.env.SERVICE_PORT || '3000', 10),
    logLevel: process.env.LOG_LEVEL || 'info',

    // IPFS configuration
    ipfs: {
        apiUrl: process.env.IPFS_API_URL || 'http://ipfs:5001',
    },

    // Fabric Hot Chain configuration
    fabric: {
        hot: {
            gatewayPeer: process.env.FABRIC_HOT_GATEWAY_PEER || 'peer0.laborg.hot.coc.com:7051',
            channel: process.env.FABRIC_HOT_CHANNEL || 'hot-chain',
            chaincode: process.env.FABRIC_HOT_CHAINCODE || 'hot_chaincode',
            mspId: process.env.FABRIC_HOT_MSP_ID || 'LabOrgMSP',
            gatewayIdentity: process.env.FABRIC_HOT_GATEWAY_IDENTITY || 'lab-gw',
            tlsEnabled: process.env.FABRIC_TLS_ENABLED === 'true',
            tlsCaCert: '/fabric/hot/tls/ca.crt',
            mspPath: '/fabric/hot/gateway/msp',
        },
        cold: {
            gatewayPeer: process.env.FABRIC_COLD_GATEWAY_PEER || 'peer0.laborg.cold.coc.com:8051',
            channel: process.env.FABRIC_COLD_CHANNEL || 'cold-chain',
            chaincode: process.env.FABRIC_COLD_CHAINCODE || 'cold_chaincode',
            mspId: process.env.FABRIC_COLD_MSP_ID || 'LabOrgMSP',
            gatewayIdentity: process.env.FABRIC_COLD_GATEWAY_IDENTITY || 'lab-gw',
            tlsEnabled: process.env.FABRIC_TLS_ENABLED === 'true',
            tlsCaCert: '/fabric/cold/tls/ca.crt',
            mspPath: '/fabric/cold/gateway/msp',
        },
    },
};
