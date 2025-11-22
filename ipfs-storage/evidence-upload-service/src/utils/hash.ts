/**
 * File hashing utilities
 */

import * as crypto from 'crypto';
import * as fs from 'fs/promises';
import { createReadStream } from 'fs';

/**
 * Compute SHA256 hash of a file
 * @param filePath Path to file
 * @returns SHA256 hash in hexadecimal format
 */
export async function computeSHA256(filePath: string): Promise<string> {
    return new Promise((resolve, reject) => {
        const hash = crypto.createHash('sha256');
        const stream = createReadStream(filePath);

        stream.on('data', (chunk) => {
            hash.update(chunk);
        });

        stream.on('end', () => {
            resolve(hash.digest('hex'));
        });

        stream.on('error', (error) => {
            reject(error);
        });
    });
}

/**
 * Compute SHA256 hash of a buffer
 * @param buffer Buffer data
 * @returns SHA256 hash in hexadecimal format
 */
export function computeSHA256FromBuffer(buffer: Buffer): string {
    return crypto.createHash('sha256').update(buffer).digest('hex');
}
