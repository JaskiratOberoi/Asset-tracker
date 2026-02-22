# GitHub Actions deployment secrets

Add these in your GitHub repo: **Settings → Secrets and variables → Actions → New repository secret.**

Use the **exact secret names** below so the workflow (`.github/workflows/deploy-hostinger.yml`) can use them.

---

## Secret names and values

### 1. `VITE_SUPABASE_URL`
- **Value:** Your Supabase project URL.
- **Where to get it:** [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Settings** → **API** → **Project URL**.
- **Example shape:** `https://xxxxxxxxxxxxx.supabase.co` (no trailing slash).

### 2. `VITE_SUPABASE_ANON_KEY`
- **Value:** Your Supabase anonymous (public) key.
- **Where to get it:** Same Supabase project → **Settings** → **API** → **Project API keys** → **anon** / **public**.
- **Example shape:** Long JWT string (e.g. `eyJhbGciOiJIUzI1NiIsInR5cCI6...`).

### 3. `DEPLOY_SSH_USER`
- **Value:** Your Hostinger SSH username (the one you use to `ssh user@assets.stellarinfomatica.com`).
- **Where to get it:** Hostinger → **Advanced** → **SSH Access** (or similar). Often looks like `u123456789` or your panel username.

### 4. `DEPLOY_SSH_KEY`
- **Value:** The **entire** private SSH key used to log in to Hostinger (the one whose public key you added in Hostinger).
- **Where to get it:**
  - If you already use SSH: copy the contents of your private key file (e.g. `~/.ssh/id_rsa` or `~/.ssh/id_ed25519`).
  - Include the first and last lines: `-----BEGIN ... KEY-----` and `-----END ... KEY-----`.
- **Important:** Paste the full key, with line breaks. Do not add a passphrase for the key used in CI, or configure the workflow to unlock it.

---

## Checklist

| Secret name             | You have it |
|-------------------------|------------|
| `VITE_SUPABASE_URL`     | ☐          |
| `VITE_SUPABASE_ANON_KEY`| ☐          |
| `DEPLOY_SSH_USER`       | ☐          |
| `DEPLOY_SSH_KEY`        | ☐          |

---

## Using this repo as the remote

After you create a repository on GitHub (e.g. `https://github.com/YourOrg/Asset-tracker.git`):

```powershell
cd x:\Asset-tracker
git init
git add .
git commit -m "Initial commit with Hostinger deploy workflow"
git branch -M main
git remote add origin https://github.com/YourOrg/Asset-tracker.git
git push -u origin main
```

Replace `YourOrg/Asset-tracker` with your actual GitHub **username-or-org/repo-name**. Pushing to `main` will trigger the deploy workflow once the four secrets above are set.
