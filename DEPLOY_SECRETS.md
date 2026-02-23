# GitHub Actions deployment secrets

Add these in your GitHub repo: **Settings → Secrets and variables → Actions → New repository secret.**

---

## Tabular list: secrets and values for GitHub

| Secret name | Value to put in GitHub | Notes |
|-------------|------------------------|--------|
| `VITE_API_URL` | Your production API URL (e.g. `https://api.yourdomain.com`) | The backend API that the frontend calls for auth, assets, and files. |
| `FTP_USERNAME` | Your Hostinger FTP username | From Hostinger FTP Accounts. |
| `FTP_PASSWORD` | Your Hostinger FTP password | Use "Change FTP password" in Hostinger if needed. |

**Workflow env (in the YAML):** `FTP_SERVER`, `FTP_SERVER_DIR` — edit in `.github/workflows/deploy-hostinger.yml` if needed.

---

## Checklist

| Secret name    | You have it |
|----------------|------------|
| `VITE_API_URL` | ☐          |
| `FTP_USERNAME` | ☐          |
| `FTP_PASSWORD` | ☐          |

---

For local development, set `VITE_API_URL=http://localhost:4000` in `frontend/.env`.
