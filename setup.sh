#!/bin/bash

#
# ChangeDetection.io Setup Script for Ubuntu Server
# Run this script on your Ubuntu server after transferring files
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}ChangeDetection.io Setup${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check if running on Ubuntu
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}Error: Cannot detect OS. Is this Ubuntu?${NC}"
    exit 1
fi

source /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    echo -e "${YELLOW}Warning: Not running on Ubuntu. Detected: $ID${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/engine/install/ubuntu/"
    exit 1
fi

# Check if docker compose is available (either plugin or standalone)
DOCKER_COMPOSE_CMD=""
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v ${DOCKER_COMPOSE_CMD} &> /dev/null; then
    DOCKER_COMPOSE_CMD="${DOCKER_COMPOSE_CMD}"
else
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    echo "Install with: sudo apt install docker-compose-plugin"
    echo "Or: sudo apt install docker-compose"
    exit 1
fi

echo -e "${GREEN}✓ Using: ${DOCKER_COMPOSE_CMD}${NC}"

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo -e "${RED}Error: Tailscale is not installed${NC}"
    echo "Please install Tailscale first: https://tailscale.com/download/linux"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

# Get Tailscale IP
echo -e "${YELLOW}Getting Tailscale IP...${NC}"
TAILSCALE_IP=$(tailscale ip -4)

if [ -z "$TAILSCALE_IP" ]; then
    echo -e "${RED}Error: Could not get Tailscale IP${NC}"
    echo "Is Tailscale running? Check: sudo systemctl status tailscaled"
    exit 1
fi

echo -e "${GREEN}✓ Tailscale IP: ${TAILSCALE_IP}${NC}"
echo ""

# Check if port 5000 is available
echo -e "${YELLOW}Checking if port 5000 is available...${NC}"
if sudo ss -tulpn | grep -q ":5000 "; then
    echo -e "${RED}Error: Port 5000 is already in use${NC}"
    echo "Check what's using it: sudo ss -tulpn | grep 5000"
    exit 1
fi

echo -e "${GREEN}✓ Port 5000 is available${NC}"
echo ""

# Update ${DOCKER_COMPOSE_CMD}.yml with Tailscale IP
echo -e "${YELLOW}Updating ${DOCKER_COMPOSE_CMD}.yml with Tailscale IP...${NC}"

if [ ! -f ${DOCKER_COMPOSE_CMD}.yml ]; then
    echo -e "${RED}Error: ${DOCKER_COMPOSE_CMD}.yml not found${NC}"
    echo "Are you in the changedetection directory?"
    exit 1
fi

# Backup original
cp ${DOCKER_COMPOSE_CMD}.yml ${DOCKER_COMPOSE_CMD}.yml.backup

# Replace placeholder with actual Tailscale IP
sed -i "s/YOUR_TAILSCALE_IP/${TAILSCALE_IP}/g" ${DOCKER_COMPOSE_CMD}.yml

echo -e "${GREEN}✓ Updated ${DOCKER_COMPOSE_CMD}.yml${NC}"
echo ""

# Create datastore directory if it doesn't exist
echo -e "${YELLOW}Creating datastore directory...${NC}"
mkdir -p datastore
echo -e "${GREEN}✓ Datastore directory created${NC}"
echo ""

# Pull Docker images
echo -e "${YELLOW}Pulling Docker images...${NC}"
${DOCKER_COMPOSE_CMD} pull

echo -e "${GREEN}✓ Docker images pulled${NC}"
echo ""

# Start containers
echo -e "${YELLOW}Starting ChangeDetection.io...${NC}"
${DOCKER_COMPOSE_CMD} up -d

echo -e "${GREEN}✓ Containers started${NC}"
echo ""

# Wait a few seconds for containers to initialize
echo -e "${YELLOW}Waiting for containers to initialize...${NC}"
sleep 5

# Check container status
echo -e "${YELLOW}Checking container status...${NC}"
${DOCKER_COMPOSE_CMD} ps

echo ""

# Verify containers are running
if ! docker ps | grep -q changedetection; then
    echo -e "${RED}Warning: changedetection container may not be running${NC}"
    echo "Check logs: ${DOCKER_COMPOSE_CMD} logs changedetection"
else
    echo -e "${GREEN}✓ changedetection container is running${NC}"
fi

if ! docker ps | grep -q changedetection-playwright; then
    echo -e "${RED}Warning: playwright container may not be running${NC}"
    echo "Check logs: ${DOCKER_COMPOSE_CMD} logs playwright-chrome"
else
    echo -e "${GREEN}✓ playwright container is running${NC}"
fi

echo ""

# Save connection info
echo -e "${YELLOW}Saving connection info...${NC}"
cat > TAILSCALE-INFO.txt <<EOF
ChangeDetection.io Access Information
======================================

Tailscale IP: ${TAILSCALE_IP}
ChangeDetection URL: http://${TAILSCALE_IP}:5000
Immich URL: http://${TAILSCALE_IP}:2283

Deployment Date: $(date)

Quick Commands:
---------------
# View logs
${DOCKER_COMPOSE_CMD} logs -f

# Restart service
${DOCKER_COMPOSE_CMD} restart

# Stop service
${DOCKER_COMPOSE_CMD} down

# Start service
${DOCKER_COMPOSE_CMD} up -d

# Check status
docker ps

# Resource usage
docker stats
EOF

echo -e "${GREEN}✓ Connection info saved to TAILSCALE-INFO.txt${NC}"
echo ""

# Set up Tailscale Serve for HTTPS (default, matching Immich setup)
echo ""
echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}Setting up HTTPS via Tailscale Serve${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""
echo -e "Enabling HTTPS access on port 8444 (matching Immich on 8443)"
echo ""

# Check if port 8444 is available
if sudo ss -tulpn | grep -q ":8444 "; then
    echo -e "${RED}Warning: Port 8444 is already in use${NC}"
    echo "Skipping Tailscale Serve setup"
    HTTPS_ENABLED=false
else
    echo -e "${YELLOW}Configuring Tailscale Serve...${NC}"
    sudo tailscale serve --bg --https=8444 5000

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Tailscale Serve enabled on port 8444${NC}"
        echo ""
        echo -e "Checking Tailscale Serve status..."
        tailscale serve status
        echo ""
        HTTPS_ENABLED=true
    else
        echo -e "${RED}Failed to set up Tailscale Serve${NC}"
        echo "You can set it up manually later with:"
        echo "  sudo tailscale serve --bg --https=8444 5000"
        HTTPS_ENABLED=false
    fi
fi

echo ""

# Final success message
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "Access ChangeDetection.io at:"

if [ "$HTTPS_ENABLED" = true ]; then
    echo -e "${GREEN}https://${TAILSCALE_IP}:8444${NC} (HTTPS via Tailscale Serve) ⭐ Recommended"
    echo -e "${GREEN}http://${TAILSCALE_IP}:5000${NC} (Direct HTTP - fallback)"
else
    echo -e "${GREEN}http://${TAILSCALE_IP}:5000${NC} (Direct HTTP)"
    echo -e "${YELLOW}HTTPS not enabled. Enable with: sudo tailscale serve --bg --https=8444 5000${NC}"
fi

echo ""
echo -e "Verify Immich still works at:"
echo -e "${GREEN}http://${TAILSCALE_IP}:2283${NC} (Direct)"
echo -e "${GREEN}https://${TAILSCALE_IP}:8443${NC} (HTTPS via Tailscale Serve)"
echo ""
echo -e "Next steps:"
echo -e "1. Open ${GREEN}http://${TAILSCALE_IP}:5000${NC} in your browser (via Tailscale)"
echo -e "2. Add your first product watch"
echo -e "3. Configure email notifications (see DEPLOYMENT-GUIDE.md)"
echo -e "4. Test with Amazon product first"
echo -e "5. Then add Flipkart and Myntra products"
echo ""
echo -e "Documentation:"
echo -e "- Full guide: ${YELLOW}DEPLOYMENT-GUIDE.md${NC}"
echo -e "- Tailscale Serve setup: ${YELLOW}TAILSCALE-SERVE-SETUP.md${NC}"
echo -e "- Selectors: ${YELLOW}SELECTORS-REFERENCE.md${NC}"
echo -e "- Connection info: ${YELLOW}TAILSCALE-INFO.txt${NC}"
echo ""
echo -e "${GREEN}Happy price tracking!${NC}"
