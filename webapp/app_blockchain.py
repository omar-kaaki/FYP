#!/usr/bin/env python3
"""
DFIR Blockchain Web Dashboard
Main application for interacting with Hot and Cold blockchains
"""

from flask import Flask, render_template, request, jsonify, send_file
import subprocess
import json
import requests
import mysql.connector
import hashlib
import os
from datetime import datetime
import time

app = Flask(__name__)

# Configuration
HOT_PEER = "peer0.lawenforcement.hot.coc.com:7051"
COLD_PEER = "peer0.archive.cold.coc.com:9051"
CHAINCODE_NAME = "dfir"

# MySQL connection
def get_db():
    """Connect to MySQL database"""
    try:
        return mysql.connector.connect(
            host="localhost",
            port=3306,
            user="cocuser",
            password="cocpassword",
            database="coc_evidence"
        )
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def exec_chaincode(command_type, channel, chaincode, function, args):
    """Execute chaincode command via CLI container"""
    cli_container = "cli" if channel == "hotchannel" else "cli-cold"
    peer_address = HOT_PEER if channel == "hotchannel" else COLD_PEER

    cmd = [
        "docker", "exec", cli_container,
        "peer", "chaincode", command_type,
        "-C", channel,
        "-n", chaincode,
        "-c", json.dumps({"function": function, "Args": args})
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            return {"success": True, "data": result.stdout}
        else:
            return {"success": False, "error": result.stderr}
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.route('/')
def index():
    """Main dashboard"""
    return render_template('dashboard.html')

@app.route('/api/blockchain/status')
def blockchain_status():
    """Get blockchain status"""
    try:
        # Check Hot blockchain
        hot_result = subprocess.run([
            "docker", "exec", "cli",
            "peer", "channel", "getinfo", "-c", "hotchannel"
        ], capture_output=True, text=True, timeout=10)

        # Check Cold blockchain
        cold_result = subprocess.run([
            "docker", "exec", "cli-cold",
            "peer", "channel", "getinfo", "-c", "coldchannel"
        ], capture_output=True, text=True, timeout=10)

        return jsonify({
            "hot_blockchain": {
                "status": "running" if hot_result.returncode == 0 else "error",
                "info": hot_result.stdout if hot_result.returncode == 0 else hot_result.stderr
            },
            "cold_blockchain": {
                "status": "running" if cold_result.returncode == 0 else "error",
                "info": cold_result.stdout if cold_result.returncode == 0 else cold_result.stderr
            }
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/evidence/create', methods=['POST'])
def create_evidence():
    """Create new evidence on blockchain"""
    try:
        data = request.json

        # Validate required fields
        required = ['id', 'case_id', 'type', 'description', 'hash', 'location']
        if not all(k in data for k in required):
            return jsonify({"error": "Missing required fields"}), 400

        # Create evidence on Hot blockchain
        result = exec_chaincode(
            "invoke",
            "hotchannel",
            CHAINCODE_NAME,
            "CreateEvidenceSimple",
            [
                data['id'],
                data['case_id'],
                data['type'],
                data['description'],
                data['hash'],
                data['location'],
                data.get('metadata', '{}')
            ]
        )

        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/evidence/<evidence_id>')
def get_evidence(evidence_id):
    """Query evidence from blockchain"""
    try:
        # Try Hot blockchain first
        result = exec_chaincode(
            "query",
            "hotchannel",
            CHAINCODE_NAME,
            "ReadEvidenceSimple",
            [evidence_id]
        )

        if result['success']:
            return jsonify(json.loads(result['data']))

        # Try Cold blockchain if not found in Hot
        result = exec_chaincode(
            "query",
            "coldchannel",
            CHAINCODE_NAME,
            "ReadEvidenceSimple",
            [evidence_id]
        )

        if result['success']:
            return jsonify(json.loads(result['data']))

        return jsonify({"error": "Evidence not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/evidence/list')
def list_evidence():
    """List all evidence from MySQL metadata database"""
    try:
        db = get_db()
        if not db:
            return jsonify({"error": "Database connection failed"}), 500

        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT * FROM evidence_metadata ORDER BY collected_timestamp DESC LIMIT 100")
        evidence = cursor.fetchall()

        # Convert datetime objects to strings
        for e in evidence:
            if e.get('collected_timestamp'):
                e['collected_timestamp'] = str(e['collected_timestamp'])
            if e.get('created_at'):
                e['created_at'] = str(e['created_at'])
            if e.get('updated_at'):
                e['updated_at'] = str(e['updated_at'])

        cursor.close()
        db.close()
        return jsonify(evidence)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/containers/status')
def containers_status():
    """Get Docker containers status"""
    try:
        result = subprocess.run(
            ["docker", "ps", "--format", "{{.Names}}\t{{.Status}}"],
            capture_output=True,
            text=True,
            timeout=5
        )

        if result.returncode == 0:
            containers = []
            for line in result.stdout.strip().split('\n'):
                if '\t' in line:
                    name, status = line.split('\t', 1)
                    containers.append({"name": name, "status": status})
            return jsonify(containers)
        else:
            return jsonify({"error": result.stderr}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/ipfs/status')
def ipfs_status():
    """Get IPFS node status"""
    try:
        # Try docker exec since IPFS is in container
        result = subprocess.run(
            ["docker", "exec", "ipfs-node", "ipfs", "version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            version = result.stdout.strip().split()[-1] if result.stdout else "unknown"
            return jsonify({"status": "running", "Version": version})
        else:
            return jsonify({"status": "error", "error": result.stderr}), 500
    except Exception as e:
        return jsonify({"status": "offline", "error": str(e)}), 500

@app.route('/api/ipfs/upload', methods=['POST'])
def ipfs_upload():
    """Upload file to IPFS"""
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file provided"}), 400

        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "Empty filename"}), 400

        # Create temporary directory for uploads
        upload_dir = '/tmp/ipfs-uploads'
        os.makedirs(upload_dir, exist_ok=True)

        # Save file temporarily
        temp_path = os.path.join(upload_dir, file.filename)
        file.save(temp_path)

        try:
            # Calculate SHA-256 hash of the file
            sha256_hash = hashlib.sha256()
            with open(temp_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b''):
                    sha256_hash.update(chunk)
            file_hash = sha256_hash.hexdigest()

            # Copy file to IPFS container
            copy_result = subprocess.run(
                ["docker", "cp", temp_path, f"ipfs-node:/tmp/{file.filename}"],
                capture_output=True,
                text=True,
                timeout=30
            )

            if copy_result.returncode != 0:
                return jsonify({
                    "error": f"Failed to copy file to IPFS container: {copy_result.stderr}"
                }), 500

            # Add file to IPFS
            ipfs_result = subprocess.run(
                ["docker", "exec", "ipfs-node", "ipfs", "add", "-Q", f"/tmp/{file.filename}"],
                capture_output=True,
                text=True,
                timeout=60
            )

            if ipfs_result.returncode == 0:
                ipfs_hash = ipfs_result.stdout.strip()

                # Clean up temp files
                try:
                    os.remove(temp_path)
                    subprocess.run(
                        ["docker", "exec", "ipfs-node", "rm", f"/tmp/{file.filename}"],
                        capture_output=True,
                        timeout=10
                    )
                except:
                    pass

                return jsonify({
                    "success": True,
                    "ipfs_hash": ipfs_hash,
                    "file_hash": file_hash,
                    "filename": file.filename,
                    "gateway_url": f"http://localhost:8080/ipfs/{ipfs_hash}"
                })
            else:
                return jsonify({
                    "error": f"IPFS add failed: {ipfs_result.stderr}"
                }), 500

        finally:
            # Clean up temp file if still exists
            if os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except:
                    pass

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "DFIR Blockchain Dashboard"
    })

if __name__ == '__main__':
    print()
    print("=" * 70)
    print("       DFIR BLOCKCHAIN EVIDENCE MANAGEMENT SYSTEM")
    print("=" * 70)
    print()
    print("📍 SERVICE URLS:")
    print()
    print("  🌐 Main Dashboard:        http://localhost:5000")
    print("  📁 IPFS Web UI:           https://webui.ipfs.io")
    print("  🔗 IPFS Gateway:          http://localhost:8080")
    print("  🗄️  MySQL phpMyAdmin:      http://localhost:8081")
    print()
    print("  Credentials for phpMyAdmin:")
    print("    Username: cocuser")
    print("    Password: cocpassword")
    print("    Database: coc_evidence")
    print()
    print("=" * 70)
    print()
    print("🔧 API ENDPOINTS:")
    print()
    print("  GET  /api/blockchain/status    - Blockchain health status")
    print("  POST /api/evidence/create      - Create new evidence")
    print("  GET  /api/evidence/<id>        - Query evidence by ID")
    print("  GET  /api/evidence/list        - List all evidence")
    print("  POST /api/ipfs/upload          - Upload file to IPFS")
    print("  GET  /api/ipfs/status          - IPFS node status")
    print("  GET  /api/containers/status    - Docker containers status")
    print()
    print("=" * 70)
    print()
    print("✅ System Ready - Press Ctrl+C to stop")
    print()

    app.run(host='0.0.0.0', port=5000, debug=True)
