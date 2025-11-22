# Evidence Upload Service Dockerfile
FROM node:20-alpine

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates

# Create app directory
WORKDIR /app

# Create log directory
RUN mkdir -p /var/log/evidence-upload-service

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY src/ ./src/

# Build TypeScript
RUN npm run build

# Create uploads directory
RUN mkdir -p /tmp/uploads

# Expose service port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Run service
CMD ["node", "dist/index.js"]
