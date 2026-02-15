# Tailscale Serve Setup for ChangeDetection.io

This guide explains how to set up Tailscale Serve for HTTPS access, matching your existing Immich configuration.

---

## Current Setup (Immich)

You're already using Tailscale Serve for Immich:

```bash
# Immich on port 8443 (HTTPS via Tailscale Serve)
sudo tailscale serve --bg --https=8443 2283
```

**Access:**
- Direct: `http://[TAILSCALE_IP]:2283`
- HTTPS: `https://[TAILSCALE_IP]:8443` (via Tailscale Serve)

---

## Recommended Setup for ChangeDetection.io

Use port **8444** for ChangeDetection.io HTTPS (next sequential port after Immich's 8443).

### Option A: Direct Access Only (Simplest)

**No Tailscale Serve needed** - just use direct port access:

```bash
# Access ChangeDetection.io directly
http://[TAILSCALE_IP]:5000
```

**Pros:**
- Simplest setup
- No additional configuration
- Still encrypted via Tailscale's WireGuard tunnel

**Cons:**
- HTTP only (but traffic is encrypted by Tailscale)
- No custom domain support

---

### Option B: HTTPS via Tailscale Serve (Recommended)

**Matches your Immich setup** - adds HTTPS layer:

```bash
# On your Ubuntu server, run:
sudo tailscale serve --bg --https=8444 5000
```

**Access:**
- Direct: `http://[TAILSCALE_IP]:5000`
- HTTPS: `https://[TAILSCALE_IP]:8444` (via Tailscale Serve)

**Pros:**
- HTTPS in browser (no security warnings)
- Consistent with Immich setup
- Can use Tailscale MagicDNS names
- Better for mobile apps that require HTTPS

**Cons:**
- Slightly more complex
- One more service to manage

---

## Complete Port Mapping

| Service | Container Port | Direct Access | Tailscale Serve (HTTPS) | Purpose |
|---------|---------------|---------------|------------------------|---------|
| **Immich** | 2283 | `http://IP:2283` | `https://IP:8443` | Photo library |
| **ChangeDetection** | 5000 | `http://IP:5000` | `https://IP:8444` | Price tracking |
| **EduXul** | 80/443 | N/A | Via Cloudflare Tunnel | Public web app |

---

## Setup Instructions (Option B - HTTPS)

### Step 1: Deploy ChangeDetection.io

Follow the main [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) to deploy the Docker containers first.

### Step 2: Verify Container is Running

```bash
# Check ChangeDetection.io is running on port 5000
curl http://localhost:5000

# Should return HTML (not "connection refused")
```

### Step 3: Set Up Tailscale Serve

```bash
# On your Ubuntu server
sudo tailscale serve --bg --https=8444 5000
```

**Explanation:**
- `--bg`: Run in background
- `--https=8444`: Serve over HTTPS on port 8444
- `5000`: Forward to local port 5000 (ChangeDetection.io)

### Step 4: Verify Tailscale Serve

```bash
# Check Tailscale Serve status
tailscale serve status

# Expected output:
# https://[TAILSCALE-NAME]:8443 proxy http://127.0.0.1:2283  (Immich)
# https://[TAILSCALE-NAME]:8444 proxy http://127.0.0.1:5000  (ChangeDetection)
```

### Step 5: Test Access

**From any device on your Tailscale network:**

```bash
# Get your Tailscale IP
tailscale ip -4

# Test HTTPS access
curl -k https://[TAILSCALE_IP]:8444

# Open in browser
https://[TAILSCALE_IP]:8444
```

### Step 6: Update BASE_URL (Optional)

If you want ChangeDetection.io to generate HTTPS links:

```bash
# Edit docker-compose.yml
nano ~/changedetection/docker-compose.yml

# Change:
# - BASE_URL=http://YOUR_TAILSCALE_IP:5000
# To:
# - BASE_URL=https://YOUR_TAILSCALE_IP:8444

# Restart container
cd ~/changedetection
docker-compose restart
```

---

## Managing Tailscale Serve

### View Active Serves

```bash
tailscale serve status
```

### Remove a Serve

```bash
# Remove ChangeDetection.io serve
sudo tailscale serve --https=8444 off

# Remove Immich serve (if needed)
sudo tailscale serve --https=8443 off
```

### Make Serve Persistent

Tailscale Serve persists automatically with `--bg` flag, but to ensure it survives reboots:

```bash
# Check if tailscaled is enabled
sudo systemctl status tailscaled

# Should show: Loaded: loaded (/lib/systemd/system/tailscaled.service; enabled)
# If not enabled:
sudo systemctl enable tailscaled
```

**Note:** Tailscale Serve configurations are automatically restored on Tailscale daemon restart.

---

## Using MagicDNS Names (Optional)

If you have MagicDNS enabled in Tailscale, you can use hostnames instead of IPs:

### Enable MagicDNS

1. Go to https://login.tailscale.com/admin/dns
2. Enable "MagicDNS"
3. Your server will be accessible via: `[hostname].[tailnet-name].ts.net`

### Access via Hostname

```bash
# Instead of:
https://100.86.89.19:8444

# Use:
https://ubuntu-server.tail-scale.ts.net:8444
```

**Benefits:**
- No need to remember IP addresses
- Works even if Tailscale IP changes
- Easier to share with family/friends on your tailnet

---

## Troubleshooting

### HTTPS Certificate Warning

**Problem:** Browser shows "Not Secure" or certificate warning

**Solution:** This is expected with Tailscale Serve using self-signed certs. You can:
1. Click "Advanced" → "Proceed anyway" (safe within Tailscale)
2. Use Tailscale's built-in HTTPS (requires MagicDNS + HTTPS enabled in admin panel)

### Tailscale Serve Not Working

```bash
# Check if Tailscale is running
sudo systemctl status tailscaled

# Restart Tailscale
sudo systemctl restart tailscaled

# Re-add serve
sudo tailscale serve --bg --https=8444 5000

# Check status
tailscale serve status
```

### Port Already in Use

```bash
# Check what's using port 8444
sudo ss -tulpn | grep 8444

# If occupied, use a different port (e.g., 8445)
sudo tailscale serve --bg --https=8445 5000
```

### Can't Access from Another Device

```bash
# Verify other device is on Tailscale network
tailscale status

# Should show the device in the list

# Check firewall (should allow Tailscale interface)
sudo ufw status
```

---

## Recommended Configuration Summary

**For best compatibility with your existing setup:**

1. **Deploy ChangeDetection.io** on port 5000 (container)
2. **Set up Tailscale Serve** on port 8444 (HTTPS)
3. **Access via:**
   - `https://[TAILSCALE_IP]:8444` (primary, HTTPS)
   - `http://[TAILSCALE_IP]:5000` (backup, direct)

**Commands to run on Ubuntu server:**

```bash
# After deploying ChangeDetection.io container
cd ~/changedetection
docker-compose up -d

# Set up Tailscale Serve (matches Immich pattern)
sudo tailscale serve --bg --https=8444 5000

# Verify
tailscale serve status
curl -k https://localhost:8444
```

---

## Quick Reference

### All Services Access

| Service | HTTPS (Recommended) | Direct HTTP | Cloudflare |
|---------|-------------------|-------------|------------|
| **Immich** | `https://IP:8443` | `http://IP:2283` | N/A |
| **ChangeDetection** | `https://IP:8444` | `http://IP:5000` | N/A |
| **EduXul** | N/A | N/A | Via tunnel |

### Commands

```bash
# Start ChangeDetection.io
cd ~/changedetection && docker-compose up -d

# Set up HTTPS via Tailscale Serve
sudo tailscale serve --bg --https=8444 5000

# Check status
tailscale serve status
docker ps

# View logs
docker-compose logs -f

# Restart
docker-compose restart
```

---

**Last Updated:** 2026-02-15
**Your Setup:** Immich (8443) + ChangeDetection (8444) via Tailscale Serve
