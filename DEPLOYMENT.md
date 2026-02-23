# Deployment Guide

## Deploying to Hostinger (assets.stellarinfomatica.com)

### Prerequisites

1. **FTP Access**: Hostinger uses FTP (not SSH) for file deployment. Ensure you have FTP credentials from hPanel.
2. **Build Tools**: Node.js and npm installed locally
3. **Deployment**: Use the GitHub Actions workflow (FTP), or manual upload via Hostinger File Manager

### Quick Deployment

#### Option 1: Automated (GitHub Actions + FTP)

Push to `main` with the three secrets set (see below). The workflow builds and deploys via FTP.

#### Option 2: Manual Deployment

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

#### Finding Your Hostinger FTP Details

- **FTP server:** In hPanel → **Files** → **FTP Accounts** (e.g. `ftp.stellarinfomatica.com` or the host shown there).
- **Remote path:** From your FTP root, the web root is usually `public_html`. For the assets subdomain use e.g. `public_html/assets`.

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
- Verify FTP username and password in GitHub Secrets
- Check `FTP_SERVER` and `FTP_SERVER_DIR` in the workflow (Hostinger FTP path is often `public_html/assets`)
- Try logging in with an FTP client to confirm credentials and path
- Use manual upload via File Manager as fallback

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
VITE_API_URL=https://api.yourdomain.com
```

**Important**: Rebuild after changing environment variables!

### Automated Deployment (GitHub Actions + FTP)

A workflow at `.github/workflows/deploy-hostinger.yml` deploys automatically on push to `main` (or manually via "Run workflow"):

1. **Builds** the app with `npm run build` in `frontend/`, injecting **`VITE_API_URL`** (production API URL).
2. **Adds** an `.htaccess` in `dist/` so all requests fall back to `index.html` (fixes Vue Router 404s).
3. **Deploys** the `frontend/dist/` folder to the assets subdomain via **FTP** (Hostinger uses FTP, not SSH).

#### Required GitHub secrets

In the repo: **Settings → Secrets and variables → Actions**, add:

| Secret | Description |
|--------|-------------|
| `VITE_API_URL` | Production backend API URL (e.g. `https://api.yourdomain.com`) |
| `FTP_USERNAME` | Hostinger FTP username (from hPanel → FTP Accounts) |
| `FTP_PASSWORD` | Hostinger FTP password for that user |

#### Host and path

Edit the `env` block at the top of `.github/workflows/deploy-hostinger.yml` if needed:

- **`FTP_SERVER`** – FTP hostname (default: `ftp.stellarinfomatica.com`). Use the host shown in Hostinger FTP Accounts.
- **`FTP_SERVER_DIR`** – Remote directory (default: `public_html/assets`). Path from FTP root to your app folder.
