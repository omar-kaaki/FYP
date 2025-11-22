/**
 * IPFS Service - Upload and retrieve files from IPFS
 */

import { create, IPFSHTTPClient } from 'ipfs-http-client';
import * as fs from 'fs/promises';
import { config } from '../config';
import { logger } from '../utils/logger';

let ipfsClient: IPFSHTTPClient | null = null;

/**
 * Get IPFS client (singleton)
 */
function getIPFSClient(): IPFSHTTPClient {
    if (!ipfsClient) {
        logger.info('Initializing IPFS client', { url: config.ipfs.apiUrl });
        ipfsClient = create({ url: config.ipfs.apiUrl });
    }
    return ipfsClient;
}

/**
 * Upload file to IPFS
 * @param filePath Path to file
 * @returns IPFS CID (Content Identifier)
 */
export async function uploadToIPFS(filePath: string): Promise<string> {
    try {
        const client = getIPFSClient();

        // Read file content
        const fileContent = await fs.readFile(filePath);

        // Upload to IPFS
        const result = await client.add(fileContent, {
            pin: true, // Pin the file to ensure it's retained
            cidVersion: 1, // Use CIDv1 for better compatibility
        });

        const cid = result.cid.toString();
        logger.info('File uploaded to IPFS', { cid, size: fileContent.length });

        return cid;

    } catch (error: any) {
        logger.error('Failed to upload to IPFS', {
            error: error.message,
            filePath,
        });
        throw new Error(`IPFS upload failed: ${error.message}`);
    }
}

/**
 * Get file from IPFS
 * @param cid IPFS Content Identifier
 * @returns File content as Buffer
 */
export async function getFromIPFS(cid: string): Promise<Buffer> {
    try {
        const client = getIPFSClient();

        logger.info('Retrieving file from IPFS', { cid });

        // Fetch content from IPFS
        const chunks: Uint8Array[] = [];
        for await (const chunk of client.cat(cid)) {
            chunks.push(chunk);
        }

        // Concatenate all chunks
        const totalLength = chunks.reduce((acc, chunk) => acc + chunk.length, 0);
        const buffer = Buffer.concat(chunks, totalLength);

        logger.info('File retrieved from IPFS', { cid, size: buffer.length });

        return buffer;

    } catch (error: any) {
        logger.error('Failed to retrieve from IPFS', {
            error: error.message,
            cid,
        });
        throw new Error(`IPFS retrieval failed: ${error.message}`);
    }
}

/**
 * Check if IPFS daemon is reachable
 * @returns true if IPFS is accessible
 */
export async function checkIPFS(): Promise<boolean> {
    try {
        const client = getIPFSClient();
        const version = await client.version();
        logger.info('IPFS daemon is reachable', { version: version.version });
        return true;
    } catch (error: any) {
        logger.error('IPFS daemon is not reachable', { error: error.message });
        return false;
    }
}
