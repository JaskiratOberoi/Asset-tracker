# Deployment Guide

## Deploying to Hostinger (assets.stellarinfomatica.com)

### Prerequisites

1. **SSH Access**: Ensure you have SSH access to your Hostinger account
2. **Build Tools**: Node.js and npm installed locally
3. **Deployment Tool**: Choose one:
   - `rsync` (recommended for Linux/Mac/WSL)
   - `scp` (available on most systems)
   - Manual upload via Hostinger File Manager

### Quick Deployment

#### Option 1: Using Bash Script (Linux/Mac/WSL)

```bash
# Set environment variables
export DEPLOY_USER="your-hostinger-username"
export DEPLOY_PATH="/domains/stellarinfomatica.com/public_html/assets"

# Run deployment
chmod +x deploy.sh
./deploy.sh
```

#### Option 2: Using PowerShell Script (Windows)

```powershell
# Run the deployment script
.\deploy.ps1

# Or with parameters
.\deploy.ps1 -DeployUser "your-username" -DeployPath "/domains/stellarinfomatica.com/public_html/assets"
```

#### Option 3: Manual Deployment

1. **Build the frontend:**
   ```bash
   cd frontend
   npm run build
   ```

2. **Upload dist folder:**
   - Log in to Hostinger File Manager
   - Navigate to your domain's public_html/assets directory
   - Upload all files from `frontend/dist/` folder
   - Ensure index.html is in the root of the assets directory

### Configuration

#### Finding Your Hostinger Path

The typical Hostinger path structure is:
```
/domains/[your-domain]/public_html/[subdomain-or-folder]
```

For `assets.stellarinfomatica.com`, it might be:
- `/domains/stellarinfomatica.com/public_html/assets`
- Or a subdomain configuration path

#### Setting Up SSH Keys (Recommended)

1. Generate SSH key (if you don't have one):
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
   ```

2. Add public key to Hostinger:
   - Copy `~/.ssh/id_rsa.pub`
   - Add it in Hostinger's SSH Keys section

3. Test connection:
   ```bash
   ssh your-username@assets.stellarinfomatica.com
   ```

### Deployment Steps

1. **Build the project:**
   ```bash
   cd frontend
   npm run build
   ```

2. **Verify build:**
   - Check that `frontend/dist` folder exists
   - Verify `index.html` is present

3. **Deploy:**
   - Use one of the deployment scripts above
   - Or manually upload via File Manager

4. **Verify deployment:**
   - Visit https://assets.stellarinfomatica.com
   - Check browser console for errors
   - Test login and admin dashboard

### Troubleshooting

#### Build Fails
- Ensure all dependencies are installed: `npm install`
- Check for TypeScript errors: `npm run build`
- Verify Node.js version compatibility

#### Upload Fails
- Verify SSH credentials
- Check remote path is correct
- Ensure you have write permissions on remote directory
- Try manual upload via File Manager as fallback

#### Site Not Loading
- Check file permissions on remote server (should be 644 for files, 755 for directories)
- Verify `index.html` is in the correct location
- Check `.htaccess` if using Apache (may need rewrite rules for Vue Router)
- Verify domain DNS settings point to correct directory

### Post-Deployment Checklist

- [ ] Site loads at https://assets.stellarinfomatica.com
- [ ] Login page is accessible
- [ ] Admin dashboard loads after login
- [ ] Assets table displays data
- [ ] Charts render correctly
- [ ] "View Bill" links work
- [ ] All routes work (no 404 errors)

### Environment Variables

For production, update `.env` or set environment variables:

```env
VITE_SUPABASE_URL=https://your-supabase-url.com
VITE_SUPABASE_ANON_KEY=your-production-anon-key
```

**Important**: Rebuild after changing environment variables!

### Automated Deployment (GitHub Actions)

A workflow at `.github/workflows/deploy-hostinger.yml` deploys automatically on push to `main` (or manually via "Run workflow"):

1. **Builds** the app with `npm run build` in `frontend/`, injecting:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
2. **Adds** an `.htaccess` in `dist/` so all requests fall back to `index.html` (fixes Vue Router 404s).
3. **Deploys** the `frontend/dist/` folder to the assets subdomain via SSH (rsync).

#### Required GitHub secrets

In the repo: **Settings → Secrets and variables → Actions**, add:

| Secret | Description |
|--------|-------------|
| `VITE_SUPABASE_URL` | Production Supabase project URL (e.g. `https://xxx.supabase.co`) |
| `VITE_SUPABASE_ANON_KEY` | Production Supabase anonymous key |
| `DEPLOY_SSH_KEY` | Private SSH key used to connect to Hostinger (full key, including `-----BEGIN ... -----`) |
| `DEPLOY_SSH_USER` | Hostinger SSH username |

#### Host and path

Default in the workflow:

- **Host:** `assets.stellarinfomatica.com`
- **Path:** `/domains/stellarinfomatica.com/public_html/assets`

To change them, edit the `env` block at the top of `.github/workflows/deploy-hostinger.yml`.
