# ms365-mcp

Dockerized deployment of the [ms-365-mcp-server](https://github.com/Softeria/ms-365-mcp-server) — a Model Context Protocol (MCP) server for Microsoft 365 services via the Microsoft Graph API.

This project provides a production-ready Docker image and Kubernetes manifests for self-hosting the MCP server with Streamable HTTP transport, OAuth 2.1 authentication, and persistent token caching.

## Features

- **90+ tools** for Microsoft 365: Outlook, Calendar, OneDrive, Excel, OneNote, To Do, Contacts, Search
- **Organization mode**: Teams, SharePoint, Shared Mailboxes, User Management
- **OAuth 2.1** authentication with PKCE (Proof Key for Code Exchange)
- **Streamable HTTP** transport on port 3000
- **Persistent token cache** — survives container restarts
- **Kubernetes-ready** with Deployment, Service, and PVC manifests

## Quick Start

### Docker Run

```bash
docker run -d -p 3000:3000 lharillo/ms365-mcp:latest
```

### With Organization Mode and Persistent Tokens

```bash
docker run -d \
  -p 3000:3000 \
  -e MS365_MCP_ORG_MODE=true \
  -v ms365-data:/app/data \
  lharillo/ms365-mcp:latest
```

### Docker Compose

```bash
docker compose up -d
```

See [docker-compose.yml](docker-compose.yml) for the full configuration.

## Kubernetes Deployment

Apply the manifests to deploy on a Kubernetes cluster:

```bash
kubectl apply -f k8s/
```

This creates:
- **PersistentVolumeClaim** — 100Mi for token cache persistence
- **Deployment** — single replica with health checks and resource limits
- **Service** — ClusterIP on port 3000

See [k8s/](k8s/) for the full manifests.

### Exposing via Cloudflare Tunnel

To expose the service externally, add an ingress rule to your `cloudflared` config:

```yaml
- hostname: ms365-mcp.example.com
  service: http://<cluster-ip>:3000
  originRequest:
    noTLSVerify: true
    http2Origin: true
    disableChunkedEncoding: true
```

Then create the DNS record:

```bash
cloudflared tunnel route dns <tunnel-id> ms365-mcp.example.com
```

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `MS365_MCP_ORG_MODE` | Enable organization mode (Teams, SharePoint, etc.) | `false` |
| `MS365_MCP_TOKEN_CACHE_PATH` | Path for MSAL token cache file | `/app/data/msal-cache.json` |
| `MS365_MCP_SELECTED_ACCOUNT_PATH` | Path for selected account metadata | `/app/data/selected-account.json` |
| `MS365_MCP_CLIENT_ID` | Custom Azure AD app client ID | built-in |
| `MS365_MCP_CLIENT_SECRET` | Azure AD client secret | — |
| `MS365_MCP_TENANT_ID` | Azure AD tenant ID | `common` |
| `MS365_MCP_OAUTH_TOKEN` | Pre-existing OAuth token (BYOT mode) | — |
| `MS365_MCP_CLOUD_TYPE` | Cloud environment (`global` or `china`) | `global` |
| `MS365_MCP_OUTPUT_FORMAT` | Output format (`toon` for 30-60% fewer tokens) | — |
| `READ_ONLY` | Disable write operations | `false` |
| `ENABLED_TOOLS` | Regex pattern to filter available tools | — |
| `LOG_LEVEL` | Logging level | `info` |
| `SILENT` | Disable console output | `false` |

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Health check — returns server status |
| `POST` | `/mcp` | MCP protocol endpoint (requires OAuth token) |
| `GET` | `/.well-known/oauth-authorization-server` | OAuth 2.1 server metadata |
| `GET` | `/authorize` | OAuth authorization flow (redirects to Microsoft login) |
| `POST` | `/token` | OAuth token exchange |

## Authentication

The server uses **OAuth 2.1 with PKCE** for authentication. When an MCP client connects:

1. The client discovers OAuth metadata at `/.well-known/oauth-authorization-server`
2. The client initiates the authorization flow at `/authorize`
3. The user is redirected to Microsoft login
4. After login, the client exchanges the authorization code for an access token at `/token`
5. The client includes the token in subsequent `POST /mcp` requests

Tokens are cached in the persistent volume at `/app/data/`, so re-authentication is only needed when tokens expire and cannot be refreshed.

### Supported Scopes

**Personal**: `Mail.Read`, `Mail.ReadWrite`, `Mail.Send`, `Calendars.ReadWrite`, `Files.ReadWrite`, `Notes.Read`, `Notes.Create`, `Tasks.ReadWrite`, `Contacts.ReadWrite`, `User.Read`

**Organization** (with `--org-mode`): `Chat.Read`, `ChatMessage.Read`, `ChatMessage.Send`, `Team.ReadBasic.All`, `Channel.ReadBasic.All`, `ChannelMessage.Read.All`, `ChannelMessage.Send`, `Sites.Read.All`, `User.Read.All`, `Group.Read.All`, `Group.ReadWrite.All`

## MCP Client Configuration

Point your MCP client to the server URL:

```
https://your-host/mcp
```

The client must support OAuth 2.1 with PKCE for authentication.

## Building

```bash
docker build -t lharillo/ms365-mcp:latest .
docker push lharillo/ms365-mcp:latest
```

## License

MIT

## Credits

- [Softeria/ms-365-mcp-server](https://github.com/Softeria/ms-365-mcp-server) — the upstream MCP server package
