# ChangeDetection.io - Price Tracker

Self-hosted price tracking for Amazon, Flipkart, Myntra, and other e-commerce sites.

## Quick Start

**For detailed deployment instructions, see:** [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)

## Access

- **Port:** 5000
- **Access via Tailscale:** `http://[YOUR_TAILSCALE_IP]:5000`
- **No public internet access** - Tailscale only (secure)

## Features

✅ Track prices on any website (Amazon, Flipkart, Myntra, etc.)
✅ JavaScript rendering via Playwright (handles dynamic sites)
✅ Email notifications on price changes
✅ Visual selector tools (no coding needed)
✅ Flexible filters (price decrease, percentage change, etc.)
✅ Multiple notification channels (40+ via Apprise)

## Port Allocation

- **Immich:** Port 2283 (existing)
- **ChangeDetection.io:** Port 5000 (new)
- **No conflicts** - both accessible via same Tailscale IP

## Supported Sites

| Site | JavaScript Rendering | Tested |
|------|---------------------|--------|
| Amazon | ✅ Yes | ✅ |
| Flipkart | ✅ Required | 🔄 Pending |
| Myntra | ✅ Required | 🔄 Pending |
| AliExpress | ✅ Yes | ⚠️ Not tested |
| eBay | ✅ Yes | ⚠️ Not tested |

## Files

- `docker-compose.yml` - Main deployment config
- `DEPLOYMENT-GUIDE.md` - Step-by-step Ubuntu server deployment
- `datastore/` - Persistent data (created on first run)

## Quick Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f

# Update
docker-compose pull && docker-compose up -d
```

## Email Notification Format (Apprise)

**Gmail Example:**
```
mailto://your-email@gmail.com:app-password@smtp.gmail.com:587?to=your-email@gmail.com
```

Add this in: Settings → Notifications → Notification URLs

## Backup

```bash
# Backup datastore
tar -czf changedetection-backup-$(date +%Y%m%d).tar.gz datastore/

# Restore
tar -xzf changedetection-backup-YYYYMMDD.tar.gz
```

## Deployment Checklist

- [ ] Transfer files to Ubuntu server
- [ ] SSH into server via Tailscale
- [ ] Update docker-compose.yml with Tailscale IP
- [ ] Pull Docker images
- [ ] Start containers
- [ ] Access web interface
- [ ] Configure email notifications
- [ ] Add test product (Amazon)
- [ ] Add Flipkart product
- [ ] Add Myntra product
- [ ] Verify notifications work
- [ ] Set up backups

## Resources

- **Official Docs:** https://github.com/dgtlmoon/changedetection.io/wiki
- **Apprise:** https://github.com/caronc/apprise/wiki
- **Tailscale:** https://tailscale.com/kb/

---

**Status:** Ready for deployment
**Last Updated:** 2026-02-15
