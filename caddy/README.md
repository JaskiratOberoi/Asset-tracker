# Caddy reverse proxy for Asset Tracker API

Use this to expose the Node.js API at `api-asset.stellarinfomatica.com` without changing other Caddy server blocks.

## Option 1: Add to existing Caddyfile (recommended)

1. Open your main **Caddyfile** (e.g. on the Ares-CRM server at `server/Caddyfile`).
2. **Append** the following block at the end of the file (after any other `site { }` blocks). Do not modify existing server blocks.

```caddyfile
# Asset Tracker API
api-asset.stellarinfomatica.com {
	reverse_proxy 127.0.0.1:3080
}
```

3. If the API runs on a **different host** than Caddy, use that host and port instead of `127.0.0.1:3080`, e.g. `reverse_proxy http://192.168.1.10:3080`.
4. Reload Caddy:
   - Windows (Caddy as service): restart the Caddy service or run your `start-caddy-service.ps1` reload step if you have one.
   - Or: `caddy reload --config /path/to/Caddyfile`

## Option 2: Include this project’s snippet

If your Caddyfile supports `import`:

```caddyfile
import /path/to/Asset-tracker/caddy/api-asset-server-block.conf
```

Only the `api-asset.stellarinfomatica.com` block is in that file; other server blocks are unaffected.

## Port reference

- **3080** = host port where the Asset Tracker API container is exposed (`3080:4000` in docker-compose).
- If you run the API on another port on the Caddy host, change `3080` in the `reverse_proxy` line accordingly.

## Verify

After reloading Caddy:

- `http://api-asset.stellarinfomatica.com/health` should return `{"ok":true}`.
- Ensure DNS for `api-asset.stellarinfomatica.com` points to the server where Caddy is running.
