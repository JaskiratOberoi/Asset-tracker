#!/bin/bash
# Deployment script for Hostinger
# Deploys the frontend dist folder to assets.stellarinfomatica.com

set -e

echo "🚀 Starting deployment process..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
REMOTE_HOST="assets.stellarinfomatica.com"
REMOTE_USER="${DEPLOY_USER:-your-username}"  # Set via environment variable or replace
REMOTE_PATH="${DEPLOY_PATH:-/domains/stellarinfomatica.com/public_html/assets}"  # Adjust to your Hostinger path
LOCAL_DIST="./frontend/dist"

# Check if dist folder exists
if [ ! -d "$LOCAL_DIST" ]; then
    echo -e "${BLUE}📦 Building frontend...${NC}"
    cd frontend
    npm run build
    cd ..
fi

if [ ! -d "$LOCAL_DIST" ]; then
    echo -e "${RED}❌ Error: dist folder not found after build${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build completed${NC}"

# Check if rsync is available
if ! command -v rsync &> /dev/null; then
    echo -e "${RED}❌ rsync is not installed. Please install it first.${NC}"
    exit 1
fi

# Deploy using rsync
echo -e "${BLUE}📤 Uploading files to ${REMOTE_HOST}...${NC}"

rsync -avz --delete \
    --exclude='.DS_Store' \
    --exclude='.git' \
    "$LOCAL_DIST/" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo -e "${GREEN}🌐 Your site is live at: https://${REMOTE_HOST}${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi
