/**
 * Evidence Upload Service - Main Entry Point
 *
 * This microservice provides a REST API for uploading evidence files to IPFS
 * and recording metadata on the Hyperledger Fabric blockchain.
 *
 * Workflow:
 * 1. Receive file upload from client (or JumpServer)
 * 2. Compute SHA256 hash
 * 3. Upload to IPFS and get CID
 * 4. Invoke Fabric chaincode (AddEvidence) via Gateway
 * 5. Return result to caller
 */

import express, { Express, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import path from 'path';
import { logger } from './utils/logger';
import { config } from './config';
import { uploadToIPFS, getFromIPFS } from './services/ipfs';
import { addEvidenceToFabric, getEvidenceFromFabric } from './services/fabric';
import { computeSHA256 } from './utils/hash';
import { v4 as uuidv4 } from 'uuid';

const app: Express = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Configure multer for file uploads
const upload = multer({
    dest: '/tmp/uploads',
    limits: {
        fileSize: 500 * 1024 * 1024, // 500MB max file size
    },
});

// Request logging middleware
app.use((req: Request, res: Response, next: NextFunction) => {
    logger.info(`${req.method} ${req.path}`, {
        ip: req.ip,
        userAgent: req.get('user-agent'),
    });
    next();
});

/**
 * Health check endpoint
 */
app.get('/health', (req: Request, res: Response) => {
    res.json({
        status: 'healthy',
        service: 'evidence-upload-service',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
    });
});

/**
 * Upload evidence file
 *
 * POST /api/evidence/upload
 *
 * Request body (multipart/form-data):
 * - file: Evidence file (required)
 * - investigationId: Investigation ID (required)
 * - description: Evidence description (required)
 * - userId: User ID (required)
 * - userRole: User role (required)
 * - chain: Target chain ('hot' or 'cold', default: 'hot')
 * - metadata: Additional JSON metadata (optional)
 *
 * Response:
 * {
 *   "success": true,
 *   "evidenceId": "uuid",
 *   "cid": "ipfs-cid",
 *   "sha256": "file-hash",
 *   "txId": "fabric-tx-id",
 *   "chain": "hot"
 * }
 */
app.post('/api/evidence/upload', upload.single('file'), async (req: Request, res: Response) => {
    try {
        // Validate file upload
        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: 'No file uploaded',
            });
        }

        // Extract form data
        const {
            investigationId,
            description,
            userId,
            userRole,
            chain = 'hot',
            metadata,
        } = req.body;

        // Validate required fields
        if (!investigationId || !description || !userId || !userRole) {
            return res.status(400).json({
                success: false,
                error: 'Missing required fields: investigationId, description, userId, userRole',
            });
        }

        // Validate chain
        if (chain !== 'hot' && chain !== 'cold') {
            return res.status(400).json({
                success: false,
                error: 'Invalid chain. Must be "hot" or "cold"',
            });
        }

        const file = req.file;
        const evidenceId = uuidv4();

        logger.info('Processing evidence upload', {
            evidenceId,
            investigationId,
            filename: file.originalname,
            size: file.size,
            userId,
            userRole,
            chain,
        });

        // Step 1: Compute SHA256 hash
        logger.info('Computing SHA256 hash...');
        const sha256 = await computeSHA256(file.path);
        logger.info('SHA256 computed', { sha256 });

        // Step 2: Upload to IPFS
        logger.info('Uploading to IPFS...');
        const cid = await uploadToIPFS(file.path);
        logger.info('Uploaded to IPFS', { cid });

        // Step 3: Prepare evidence metadata
        const evidenceMetadata = {
            fileName: file.originalname,
            fileSize: file.size,
            mimeType: file.mimetype,
            uploadedAt: new Date().toISOString(),
            ...(metadata ? JSON.parse(metadata) : {}),
        };

        // Step 4: Record on Fabric blockchain
        logger.info('Recording on Fabric blockchain...', { chain });
        const txId = await addEvidenceToFabric({
            chain,
            evidenceId,
            investigationId,
            description,
            cid,
            sha256,
            metadata: evidenceMetadata,
            userId,
            userRole,
        });
        logger.info('Recorded on blockchain', { txId });

        // Success response
        res.json({
            success: true,
            evidenceId,
            cid,
            sha256,
            txId,
            chain,
            message: 'Evidence uploaded and recorded successfully',
        });

        logger.info('Evidence upload completed', {
            evidenceId,
            investigationId,
            cid,
            txId,
        });

    } catch (error: any) {
        logger.error('Evidence upload failed', {
            error: error.message,
            stack: error.stack,
        });

        res.status(500).json({
            success: false,
            error: error.message || 'Internal server error',
        });
    }
});

/**
 * Get evidence metadata from blockchain
 *
 * GET /api/evidence/:evidenceId?chain=hot
 *
 * Query parameters:
 * - chain: Target chain ('hot' or 'cold', default: 'hot')
 *
 * Response:
 * {
 *   "success": true,
 *   "evidence": {
 *     "evidenceId": "uuid",
 *     "investigationId": "uuid",
 *     "description": "...",
 *     "cid": "ipfs-cid",
 *     "sha256": "file-hash",
 *     "metadata": {...},
 *     "recordedAt": "timestamp",
 *     "recordedBy": "user-id"
 *   }
 * }
 */
app.get('/api/evidence/:evidenceId', async (req: Request, res: Response) => {
    try {
        const { evidenceId } = req.params;
        const { chain = 'hot' } = req.query;

        if (chain !== 'hot' && chain !== 'cold') {
            return res.status(400).json({
                success: false,
                error: 'Invalid chain. Must be "hot" or "cold"',
            });
        }

        logger.info('Retrieving evidence metadata', { evidenceId, chain });

        const evidence = await getEvidenceFromFabric(chain as string, evidenceId);

        res.json({
            success: true,
            evidence,
        });

    } catch (error: any) {
        logger.error('Failed to retrieve evidence', {
            error: error.message,
            stack: error.stack,
        });

        res.status(500).json({
            success: false,
            error: error.message || 'Internal server error',
        });
    }
});

/**
 * Retrieve evidence file from IPFS
 *
 * GET /api/evidence/:evidenceId/file?chain=hot
 *
 * Query parameters:
 * - chain: Target chain ('hot' or 'cold', default: 'hot')
 * - verify: Verify SHA256 hash ('true' or 'false', default: 'true')
 *
 * Returns the file content with proper content-type headers
 */
app.get('/api/evidence/:evidenceId/file', async (req: Request, res: Response) => {
    try {
        const { evidenceId } = req.params;
        const { chain = 'hot', verify = 'true' } = req.query;

        if (chain !== 'hot' && chain !== 'cold') {
            return res.status(400).json({
                success: false,
                error: 'Invalid chain. Must be "hot" or "cold"',
            });
        }

        logger.info('Retrieving evidence file', { evidenceId, chain, verify });

        // Get metadata from blockchain
        const evidence = await getEvidenceFromFabric(chain as string, evidenceId);

        // Get file from IPFS
        const fileBuffer = await getFromIPFS(evidence.cid);

        // Verify hash if requested
        if (verify === 'true') {
            const tempPath = path.join('/tmp', `verify-${uuidv4()}`);
            const fs = await import('fs/promises');
            await fs.writeFile(tempPath, fileBuffer);
            const computedHash = await computeSHA256(tempPath);
            await fs.unlink(tempPath);

            if (computedHash !== evidence.sha256) {
                logger.error('Hash verification failed', {
                    evidenceId,
                    expected: evidence.sha256,
                    computed: computedHash,
                });
                return res.status(500).json({
                    success: false,
                    error: 'File integrity verification failed',
                });
            }
            logger.info('Hash verified successfully', { evidenceId });
        }

        // Set response headers
        const metadata = JSON.parse(evidence.metadata);
        res.setHeader('Content-Type', metadata.mimeType || 'application/octet-stream');
        res.setHeader('Content-Disposition', `attachment; filename="${metadata.fileName}"`);
        res.setHeader('Content-Length', fileBuffer.length);

        // Send file
        res.send(fileBuffer);

        logger.info('Evidence file retrieved', { evidenceId, size: fileBuffer.length });

    } catch (error: any) {
        logger.error('Failed to retrieve evidence file', {
            error: error.message,
            stack: error.stack,
        });

        res.status(500).json({
            success: false,
            error: error.message || 'Internal server error',
        });
    }
});

/**
 * Error handling middleware
 */
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    logger.error('Unhandled error', {
        error: err.message,
        stack: err.stack,
        path: req.path,
    });

    res.status(500).json({
        success: false,
        error: 'Internal server error',
    });
});

/**
 * Start server
 */
const PORT = config.servicePort;

app.listen(PORT, () => {
    logger.info(`Evidence Upload Service started`, {
        port: PORT,
        ipfsUrl: config.ipfs.apiUrl,
        hotChain: `${config.fabric.hot.gatewayPeer} (${config.fabric.hot.channel})`,
        coldChain: `${config.fabric.cold.gatewayPeer} (${config.fabric.cold.channel})`,
    });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, shutting down gracefully');
    process.exit(0);
});
