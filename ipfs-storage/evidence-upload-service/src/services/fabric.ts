/**
 * Fabric Gateway Service - Interact with Hyperledger Fabric blockchain
 */

import * as grpc from '@grpc/grpc-js';
import { connect, Contract, Gateway, Identity, Signer, signers } from '@hyperledger/fabric-gateway';
import * as crypto from 'crypto';
import * as fs from 'fs/promises';
import { config } from '../config';
import { logger } from '../utils/logger';

interface AddEvidenceParams {
    chain: string;
    evidenceId: string;
    investigationId: string;
    description: string;
    cid: string;
    sha256: string;
    metadata: any;
    userId: string;
    userRole: string;
}

/**
 * Create gRPC connection to Fabric peer
 */
async function createGrpcConnection(chain: 'hot' | 'cold'): Promise<grpc.Client> {
    const chainConfig = chain === 'hot' ? config.fabric.hot : config.fabric.cold;

    if (chainConfig.tlsEnabled) {
        const tlsCaCert = await fs.readFile(chainConfig.tlsCaCert);
        const tlsCredentials = grpc.credentials.createSsl(tlsCaCert);
        return new grpc.Client(chainConfig.gatewayPeer, tlsCredentials, {
            'grpc.ssl_target_name_override': chainConfig.gatewayPeer.split(':')[0],
        });
    } else {
        return new grpc.Client(chainConfig.gatewayPeer, grpc.credentials.createInsecure());
    }
}

/**
 * Create Fabric Gateway identity
 */
async function createIdentity(chain: 'hot' | 'cold'): Promise<Identity> {
    const chainConfig = chain === 'hot' ? config.fabric.hot : config.fabric.cold;
    const certPath = `${chainConfig.mspPath}/signcerts/${chainConfig.gatewayIdentity}@laborg.${chain}.coc.com-cert.pem`;

    const credentials = await fs.readFile(certPath);

    return {
        mspId: chainConfig.mspId,
        credentials,
    };
}

/**
 * Create Fabric Gateway signer
 */
async function createSigner(chain: 'hot' | 'cold'): Promise<Signer> {
    const chainConfig = chain === 'hot' ? config.fabric.hot : config.fabric.cold;
    const keyPath = `${chainConfig.mspPath}/keystore/priv_sk`;

    const privateKeyPem = await fs.readFile(keyPath);
    const privateKey = crypto.createPrivateKey(privateKeyPem);

    return signers.newPrivateKeySigner(privateKey);
}

/**
 * Get Fabric Gateway contract
 */
async function getContract(chain: 'hot' | 'cold'): Promise<{ gateway: Gateway; contract: Contract }> {
    const chainConfig = chain === 'hot' ? config.fabric.hot : config.fabric.cold;

    logger.info('Connecting to Fabric Gateway', {
        chain,
        peer: chainConfig.gatewayPeer,
        channel: chainConfig.channel,
        chaincode: chainConfig.chaincode,
    });

    // Create gRPC connection
    const client = await createGrpcConnection(chain);

    // Create identity and signer
    const identity = await createIdentity(chain);
    const signer = await createSigner(chain);

    // Connect to gateway
    const gateway = connect({
        client,
        identity,
        signer,
        evaluateOptions: () => ({ deadline: Date.now() + 30000 }), // 30 seconds
        endorseOptions: () => ({ deadline: Date.now() + 60000 }), // 60 seconds
        submitOptions: () => ({ deadline: Date.now() + 60000 }), // 60 seconds
        commitStatusOptions: () => ({ deadline: Date.now() + 120000 }), // 120 seconds
    });

    const network = gateway.getNetwork(chainConfig.channel);
    const contract = network.getContract(chainConfig.chaincode);

    return { gateway, contract };
}

/**
 * Add evidence to Fabric blockchain
 */
export async function addEvidenceToFabric(params: AddEvidenceParams): Promise<string> {
    const chain = params.chain as 'hot' | 'cold';
    let gateway: Gateway | null = null;

    try {
        // Get contract
        const { gateway: gw, contract } = await getContract(chain);
        gateway = gw;

        // Prepare transient data (user context)
        const transientData = {
            userId: Buffer.from(params.userId),
            role: Buffer.from(params.userRole),
        };

        // Invoke AddEvidence chaincode function
        logger.info('Invoking AddEvidence chaincode function', {
            chain,
            evidenceId: params.evidenceId,
            investigationId: params.investigationId,
        });

        const result = await contract.submit('AddEvidence', {
            arguments: [
                params.evidenceId,
                params.investigationId,
                params.description,
                params.cid,
                params.sha256,
                JSON.stringify(params.metadata),
            ],
            transientData,
        });

        const txId = result.toString('utf8');
        logger.info('Evidence added to blockchain', {
            chain,
            evidenceId: params.evidenceId,
            txId,
        });

        return txId;

    } catch (error: any) {
        logger.error('Failed to add evidence to Fabric', {
            chain,
            error: error.message,
            details: error.details || error.toString(),
        });
        throw new Error(`Fabric transaction failed: ${error.message}`);

    } finally {
        if (gateway) {
            gateway.close();
        }
    }
}

/**
 * Get evidence from Fabric blockchain
 */
export async function getEvidenceFromFabric(chain: string, evidenceId: string): Promise<any> {
    const chainType = chain as 'hot' | 'cold';
    let gateway: Gateway | null = null;

    try {
        // Get contract
        const { gateway: gw, contract } = await getContract(chainType);
        gateway = gw;

        // Query GetEvidence chaincode function
        logger.info('Querying GetEvidence chaincode function', {
            chain,
            evidenceId,
        });

        const result = await contract.evaluateTransaction('GetEvidence', evidenceId);
        const evidence = JSON.parse(result.toString('utf8'));

        logger.info('Evidence retrieved from blockchain', {
            chain,
            evidenceId,
        });

        return evidence;

    } catch (error: any) {
        logger.error('Failed to get evidence from Fabric', {
            chain,
            evidenceId,
            error: error.message,
        });
        throw new Error(`Fabric query failed: ${error.message}`);

    } finally {
        if (gateway) {
            gateway.close();
        }
    }
}
