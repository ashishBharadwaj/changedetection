# ChangeDetection.io Deployment Guide for Ubuntu Server

## Overview
This guide will help you deploy ChangeDetection.io on your Ubuntu server alongside Immich, accessible via Tailscale.

**Infrastructure:**
- **Immich**: Port 2283, accessible via Tailscale
- **ChangeDetection.io**: Port 5000, accessible via Tailscale
- **Access Pattern**: Both services use the same Tailscale IP but different ports

---

## Prerequisites (Already Set Up)
- ✅ Ubuntu Server running
- ✅ Docker and docker-compose installed
- ✅ Tailscale installed at host level
- ✅ Immich running on port 2283

---

## Deployment Steps

### Step 1: Transfer Files to Ubuntu Server

**On your Mac (local machine):**

```bash
# Navigate to the changedetection folder
cd /Users/ashishbharadwajj/Documents/git-repos/changedetection

# Option A: Use rsync over Tailscale (RECOMMENDED)
# Replace YOUR_TAILSCALE_IP with your server's Tailscale IP
rsync -avz --progress \
  ./ \
  axsys@YOUR_TAILSCALE_IP:/home/axsys/changedetection/

# Option B: Use scp over Tailscale
scp -r . axsys@YOUR_TAILSCALE_IP:/home/axsys/changedetection/

# Option C: Use git (if you have a private repo)
# Push to git, then pull on the server
```

---

### Step 2: SSH into Your Ubuntu Server

```bash
# Via Tailscale (secure, no port forwarding needed)
ssh axsys@YOUR_TAILSCALE_IP
```

---

### Step 3: Navigate to Deployment Directory

```bash
cd /home/axsys/changedetection
```

---

### Step 4: Get Your Tailscale IP

```bash
# Get the Tailscale IP of this server
tailscale ip -4

# Example output: 100.86.89.19
# Save this IP - you'll use it to access the services
```

---

### Step 5: Update docker-compose.yml with Tailscale IP

```bash
# Edit the docker-compose.yml file
nano docker-compose.yml

# Find this line:
# - BASE_URL=http://YOUR_TAILSCALE_IP:5000

# Replace YOUR_TAILSCALE_IP with your actual Tailscale IP
# Example:
# - BASE_URL=http://100.86.89.19:5000

# Save and exit (Ctrl+O, Enter, Ctrl+X)
```

---

### Step 6: Verify Port Availability

```bash
# Check if port 5000 is already in use
sudo ss -tulpn | grep 5000

# Should return nothing (port is free)
# Port 2283 should show Immich running
sudo ss -tulpn | grep 2283
```

---

### Step 7: Pull Docker Images

```bash
# Pull the required Docker images
docker-compose pull

# This will download:
# - changedetection.io (main app)
# - browserless/chrome (Playwright for JavaScript rendering)
```

---

### Step 8: Start ChangeDetection.io

```bash
# Start in detached mode
docker-compose up -d

# You should see:
# Creating changedetection-playwright ... done
# Creating changedetection           ... done
```

---

### Step 9: Verify Containers Are Running

```bash
# Check container status
docker ps

# You should see two containers:
# - changedetection (port 5000:5000)
# - changedetection-playwright (internal only)

# Both should show status: Up
```

---

### Step 10: Check Logs

```bash
# View logs for any errors
docker-compose logs -f

# Press Ctrl+C to exit log view

# Check for specific errors
docker-compose logs changedetection | grep -i error
```

---

### Step 11: Access ChangeDetection.io via Tailscale

**From any device connected to your Tailscale network:**

1. **Get your Tailscale IP** (from Step 4)
   - Example: `100.86.89.19`

2. **Open browser and navigate to:**
   - ChangeDetection.io: `http://100.86.89.19:5000`
   - Immich (verify still works): `http://100.86.89.19:2283`

3. **First-time setup:**
   - ChangeDetection.io will show the main interface
   - No initial login required (unless you set up authentication)

---

## Configuration for Price Tracking

### Step 12: Add Your First Product (Amazon Test)

1. **Click "Add New"** in ChangeDetection.io
2. **Enter URL:**
   - Test with Amazon product URL
   - Example: `https://www.amazon.in/dp/B0XXXXXXXXX`

3. **Configure monitoring:**
   - **Filters:** Click "CSS/XPath" filter
   - **For price only:** Add CSS selector (e.g., `.a-price-whole`)
   - **Enable JavaScript rendering:** Toggle "Use Chrome/Playwright"

4. **Set notification:**
   - Click "Notifications" tab
   - Select "Email" (via Apprise)
   - Enter email URL format (see Step 13)

5. **Save and test**

---

### Step 13: Configure Email Notifications (Apprise)

ChangeDetection.io uses Apprise for notifications. Email format:

```
mailto://smtp_username:smtp_password@smtp_server:smtp_port?to=recipient@email.com
```

**Example for Gmail:**
```
mailto://your-email@gmail.com:your-app-password@smtp.gmail.com:587?to=your-email@gmail.com
```

**Where to add:**
1. Settings → Notifications → "Notification URLs"
2. Add the mailto:// URL above
3. Test notification

---

### Step 14: Add Flipkart Product

1. **Add new watch**
2. **URL:** Flipkart product page
   - Example: `https://www.flipkart.com/product/p/itmXXXXXXX`

3. **Enable JavaScript rendering:**
   - Toggle "Use Chrome/Playwright" (REQUIRED for Flipkart)

4. **CSS selectors for Flipkart:**
   - Price: `._30jeq3._16Jk6d`
   - Title: `.B_NuCI`
   - Availability: `._16FRp0`

5. **Set check interval:**
   - Recommended: Every 6 hours
   - Avoid too frequent checks (rate limiting)

6. **Configure price change notification:**
   - Filters → "Trigger on price decrease"
   - Or use "Trigger on change" for any price change

---

### Step 15: Add Myntra Product

1. **Add new watch**
2. **URL:** Myntra product page
   - Example: `https://www.myntra.com/tshirts/brand/product-name/12345/buy`

3. **Enable JavaScript rendering:**
   - Toggle "Use Chrome/Playwright" (REQUIRED)

4. **CSS selectors for Myntra:**
   - Price: `.pdp-price strong`
   - Title: `.pdp-title`
   - Discount: `.pdp-discount`

5. **Set check interval:** Every 6 hours

---

## Verification & Testing

### Step 16: Test Notifications

```bash
# From ChangeDetection.io web interface:
1. Go to any watch
2. Click "Test notification"
3. Check your email inbox
4. Verify email received
```

---

### Step 17: Monitor Resources

```bash
# Check resource usage on Ubuntu server
docker stats

# You should see:
# - changedetection: ~50-150MB RAM
# - changedetection-playwright: ~200-400MB RAM
# - Total: ~250-550MB additional RAM usage
```

---

### Step 18: Verify No Conflicts with Immich

```bash
# Check both ports are accessible
curl http://localhost:5000  # ChangeDetection.io
curl http://localhost:2283  # Immich

# Both should return HTTP responses (not "connection refused")

# Verify via Tailscale from another device:
# - http://YOUR_TAILSCALE_IP:5000 (ChangeDetection)
# - http://YOUR_TAILSCALE_IP:2283 (Immich)
```

---

## Maintenance Commands

### Start/Stop Services

```bash
# Stop ChangeDetection.io
cd /home/axsys/changedetection
docker-compose down

# Start ChangeDetection.io
docker-compose up -d

# Restart ChangeDetection.io
docker-compose restart

# View logs
docker-compose logs -f
```

---

### Update ChangeDetection.io

```bash
cd /home/axsys/changedetection

# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d

# Check logs
docker-compose logs -f
```

---

### Backup Data

```bash
# Backup the datastore directory (contains all watches and settings)
cd /home/axsys
tar -czf changedetection-backup-$(date +%Y%m%d).tar.gz changedetection/datastore/

# Transfer backup to your Mac via Tailscale
scp changedetection-backup-*.tar.gz your-mac-user@YOUR_MAC_TAILSCALE_IP:~/backups/
```

---

### Restore from Backup

```bash
# Stop ChangeDetection.io
cd /home/axsys/changedetection
docker-compose down

# Restore datastore
cd /home/axsys
tar -xzf changedetection-backup-YYYYMMDD.tar.gz

# Start ChangeDetection.io
cd changedetection
docker-compose up -d
```

---

## Troubleshooting

### Port Already in Use

```bash
# Check what's using port 5000
sudo ss -tulpn | grep 5000

# If occupied, change port in docker-compose.yml:
# ports:
#   - 5001:5000  # Use 5001 instead
```

---

### Playwright/JavaScript Not Working

```bash
# Check if playwright-chrome is running
docker ps | grep playwright

# Check playwright logs
docker logs changedetection-playwright

# Restart playwright container
docker restart changedetection-playwright
```

---

### Email Notifications Not Sending

1. **Verify SMTP credentials** in Apprise URL
2. **Test with:**
   - Click "Test notification" in ChangeDetection.io
   - Check docker logs: `docker-compose logs -f`
3. **Common issues:**
   - Gmail: Use app-specific password (not regular password)
   - Port: Use 587 for TLS, 465 for SSL

---

### High Memory Usage

```bash
# Reduce concurrent browser sessions
# Edit docker-compose.yml:
# - MAX_CONCURRENT_SESSIONS=5  # Reduce from 10

# Restart
docker-compose restart
```

---

### Can't Access via Tailscale

```bash
# Verify Tailscale is running
sudo systemctl status tailscaled

# Restart Tailscale if needed
sudo systemctl restart tailscaled

# Check Tailscale IP
tailscale ip -4

# Verify firewall allows Tailscale
sudo ufw status
# Should show: Anywhere on tailscale0 ALLOW Anywhere
```

---

## Access Summary

**From any device on your Tailscale network:**

| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| **Immich** | `http://[TAILSCALE_IP]:2283` | 2283 | Photo library |
| **ChangeDetection.io** | `http://[TAILSCALE_IP]:5000` | 5000 | Price tracking |

**Example** (if Tailscale IP is `100.86.89.19`):
- Immich: `http://100.86.89.19:2283`
- ChangeDetection: `http://100.86.89.19:5000`

---

## Security Notes

1. **No public internet exposure** - Only accessible via Tailscale
2. **Encrypted traffic** - All Tailscale connections are WireGuard-encrypted
3. **Optional: Add password protection** in ChangeDetection.io settings
4. **Firewall**: No need to open ports - Tailscale handles networking

---

## Next Steps

1. ✅ Deploy ChangeDetection.io (follow Steps 1-11)
2. ✅ Test access via Tailscale (Step 11)
3. ✅ Configure email notifications (Step 13)
4. ✅ Add test products (Steps 12, 14, 15)
5. ✅ Monitor for 24-48 hours (Step 17)
6. ✅ Set up regular backups (see Backup section)

---

## Quick Reference Commands

```bash
# SSH to server
ssh axsys@YOUR_TAILSCALE_IP

# Get Tailscale IP
tailscale ip -4

# Navigate to deployment
cd /home/axsys/changedetection

# Start/stop
docker-compose up -d
docker-compose down

# View logs
docker-compose logs -f

# Check containers
docker ps

# Resource usage
docker stats

# Backup
tar -czf backup.tar.gz datastore/
```

---

## Support

- **ChangeDetection.io Docs**: https://github.com/dgtlmoon/changedetection.io/wiki
- **Apprise Notifications**: https://github.com/caronc/apprise/wiki
- **Tailscale Docs**: https://tailscale.com/kb/

---

**Deployment created on:** 2026-02-15
**Server:** Ubuntu Server
**Access:** Tailscale only (private network)
