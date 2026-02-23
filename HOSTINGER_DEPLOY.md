# Deploy to Hostinger with GitHub Actions

This guide explains how to deploy the Asset Tracker frontend to Hostinger using the GitHub Actions workflow and which secrets to configure.

---

## 1. GitHub Secrets (required)

Add these in your GitHub repo: **Settings → Secrets and variables → Actions → New repository secret.**

| Secret name       | What to put | Where you get it |
|-------------------|-------------|------------------|
| **VITE_API_URL**  | Your production API URL, e.g. `https://api.yourdomain.com` (no trailing slash) | The URL where your Node.js backend API is hosted. The frontend will call this for login, assets, and files. |
| **FTP_USERNAME**  | Hostinger FTP username | hPanel → **Files** → **FTP Accounts** → username for the account you use to deploy |
| **FTP_PASSWORD**  | Hostinger FTP password for that user | Same FTP account; use “Change FTP password” in hPanel if needed |

**Summary:** You need exactly **3 secrets**: `VITE_API_URL`, `FTP_USERNAME`, `FTP_PASSWORD`.

---

## 2. Workflow configuration (optional)

The workflow file `.github/workflows/deploy-hostinger.yml` already sets:

- **FTP_SERVER:** `46.28.45.60` (Hostinger FTP host)
- **FTP_SERVER_DIR:** `public_html/assets` (files are deployed into this folder)

If your Hostinger FTP host or target folder is different, edit the `env` block at the top of that file:

```yaml
env:
  FTP_SERVER: your-ftp-host.example.com   # or IP
  FTP_SERVER_DIR: public_html/assets      # path from FTP root to app folder
```

---

## 3. How deployment runs

1. **Trigger:** Every push to the `main` branch, or manually via **Actions** → **Deploy to Hostinger** → **Run workflow**.
2. **Build:** Installs frontend deps, runs `npm run build` with `VITE_API_URL` from secrets.
3. **SPA routing:** Adds `.htaccess` in `dist/` so all routes fall back to `index.html`.
4. **Upload:** Uploads the contents of `frontend/dist/` to the FTP server into `FTP_SERVER_DIR`.

---

## 4. Before first deploy

1. **Create the 3 secrets** in GitHub (see table above).
2. **Backend API:** Your production backend (Node.js API + Postgres + MongoDB) must be deployed and reachable at the URL you set as `VITE_API_URL`. The frontend only deploys to Hostinger; the API is deployed elsewhere.
3. **FTP path:** On Hostinger, the path `public_html/assets` (or whatever you set in `FTP_SERVER_DIR`) should exist, or the workflow will create it if your FTP user can create directories.

---

## 5. Deploy

- **Automatic:** Push (or merge) to `main`. The workflow runs and deploys.
- **Manual:** GitHub → **Actions** → **Deploy to Hostinger** → **Run workflow** → **Run workflow**.

---

## 6. After deploy

- Open your site (e.g. `https://assets.stellarinfomatica.com` or your assets subdomain).
- Check: homepage, login, admin dashboard, assets table, charts, “View Bill” links.
- If you see wrong API or CORS errors, confirm `VITE_API_URL` is correct and the backend allows your frontend origin.

---

## Quick reference: secrets checklist

| Secret           | Added? |
|------------------|--------|
| VITE_API_URL     | ☐      |
| FTP_USERNAME     | ☐      |
| FTP_PASSWORD     | ☐      |
