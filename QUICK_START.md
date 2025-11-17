# ⚡ Quick Start - 5 Minute Deployment

The absolute fastest way to get DFIR Blockchain running on a fresh VM.

---

## 📋 Requirements

- Fresh Ubuntu 20.04/22.04 VM
- Minimum 4 CPU, 8GB RAM, 50GB disk
- Internet connection
- Sudo privileges

---

## 🚀 One-Command Deployment

```bash
cd /home/user/Dual-hyperledger-Blockchain
sudo bash complete-setup.sh
```

**That's it!**

When prompted, type: `NUCLEAR` (all caps)

**Time:** 15-25 minutes

---

## ✅ Quick Verification

```bash
# Check containers (should be 20+)
docker ps | wc -l

# Check status
curl http://localhost:5000/api/blockchain/status | jq
```

---

## 🌐 Access Your System

| What | Where |
|------|-------|
| **Dashboard** | http://localhost:5000 |
| **Hot Explorer** | http://localhost:8090 (exploreradmin/exploreradminpw) |
| **Cold Explorer** | http://localhost:8091 (exploreradmin/exploreradminpw) |

---

## 🔧 If Something Goes Wrong

```bash
# Check logs
docker logs orderer.hot.coc.com

# Complete reset
./stop-all.sh
docker system prune -af
sudo bash complete-setup.sh
```

---

## 📚 Need More Details?

- **Full Setup Instructions:** See [COMPLETE_SETUP_README.md](COMPLETE_SETUP_README.md)
- **Troubleshooting:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **API Integration:** See [API_INTEGRATION.md](API_INTEGRATION.md)

---

## 🎯 What You Get

After successful deployment:

✅ **2 Blockchain Networks**
   - Hot chain (active investigations)
   - Cold chain (immutable archive)

✅ **4 Organizations**
   - LawEnforcement (hot chain peer)
   - ForensicLab (hot chain peer)
   - Auditor (cold chain peer)
   - Court (client-only)

✅ **Advanced Features**
   - Role-based access control (RBAC)
   - Mutual TLS (mTLS) security
   - IPFS distributed storage
   - MySQL database caching
   - Real-time blockchain explorers

✅ **Full REST API**
   - Create/read investigations
   - Manage evidence
   - Transfer custody
   - Archive to cold chain
   - Verify integrity

---

## 🧪 Test Your Deployment

```bash
./verify-blockchain.sh
# Should show 17+ tests passing
```

---

## 🔄 Daily Operations

**Start all services:**
```bash
./restart-blockchain.sh
```

**Stop all services:**
```bash
./stop-all.sh
```

**Fresh blockchain (data reset):**
```bash
./nuclear-reset.sh
./deploy-chaincode.sh
```

---

## 💡 Pro Tips

1. **First time?** Let the script run completely. Don't interrupt it.

2. **Docker permission error?** Run: `newgrp docker`

3. **Webapp not responding?** Wait 60 seconds after setup, then check again.

4. **Need to restart?** Use `./restart-blockchain.sh` instead of rebooting.

5. **Containers not talking?** Reset: `./nuclear-reset.sh`

---

## 📊 Expected Results

When everything is working:

```bash
$ docker ps | wc -l
21  # 20+ containers

$ curl http://localhost:5000/api/blockchain/status
{
  "hot_chain": {"height": 7},
  "cold_chain": {"height": 4}
}

$ ./verify-blockchain.sh
✓ 17 tests passed
```

---

## 🆘 Emergency Reset

If everything breaks:

```bash
cd /home/user/Dual-hyperledger-Blockchain
./stop-all.sh
docker system prune -af
sudo bash complete-setup.sh
```

---

**Total Time from Zero to Working System:** 15-25 minutes

**Next Steps:** Open http://localhost:5000 and explore the dashboard!

---

**See also:**
- [Complete Setup Guide](COMPLETE_SETUP_README.md) - Detailed installation docs
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Fix common issues
- [API Integration](API_INTEGRATION.md) - Connect external systems
