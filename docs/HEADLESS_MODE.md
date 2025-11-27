# Soliloquy Headless Mode

Soliloquy can run as a headless Cupboard sync server when no monitor is connected to the Zircon scenic service.

## How It Works

On startup, Soliloquy queries the Zircon scenic service via real FIDL bindings:

```
┌─────────────────────────────────────┐
│   Soliloquy Startup                 │
│                                     │
│   1. Query Zircon scenic (FIDL)     │
│      - fuchsia.ui.display.singleton │
│      - /dev/class/display/          │
│      - Real display metrics         │
│                                     │
│   2. Display found?                 │
│      ├─ YES → Desktop Mode          │
│      │   • Signal launcher          │
│      │   • Start V backend          │
│      │   • Launcher starts Servo    │
│      │   • Launcher starts V8       │
│      │                               │
│      └─ NO → Headless Mode          │
│          • Start V backend only     │
│          • Cupboard sync server     │
│          • No Servo/V8 launched     │
└─────────────────────────────────────┘
```

## Display Detection

The backend uses real Zircon FIDL bindings from `third_party/zircon_v/scenic/`:

```v
import scenic

// Detect displays via FIDL
result := scenic.detect_displays()

if result.query_result == .success && result.displays.len > 0 {
    // Desktop mode - display available
    display := result.displays[0]
    println('Display: ${display.metrics.extent_in_px_width}x${display.metrics.extent_in_px_height}')
} else {
    // Headless mode - no display
    println('Running as Cupboard sync server')
}
```

## Starting

### Using Scripts (Recommended)

```bash
# Development mode
./scripts/dev.sh

# Backend only (for headless testing)
./scripts/dev.sh --backend-only
```

### Manual

```bash
cd backend
v run .
```

## Test Display Detection

```bash
# Test display detection
./scripts/display_test.sh

# Simulate headless mode
./scripts/display_test.sh --simulate-headless

# JSON output
./scripts/display_test.sh --json

# On Zircon device
./scripts/zircon/display_detect.sh
```

## Headless Features

When running headless, Soliloquy provides:

✅ **Full Cupboard Storage**
- Memory storage with tags
- Vector embeddings
- Zircon persistence on Fuchsia (`/data/cupboard/`)

✅ **Device Sync Protocol**
- Push memories from devices
- Pull new memories to devices
- Device registry and tracking

✅ **Authentication**
- Google OAuth (same as Plates)
- Session management
- Multi-device support

✅ **Search Integration**
- Command parsing
- Memory retrieval
- Web search placeholders

✅ **Tableware Proxy**
- Pickup session forwarding
- Device status sync

❌ **Disabled in Headless**
- Servo + V8 rendering
- Svelte UI dev server
- Desktop window

## API Endpoints (Headless)

All standard endpoints remain available:

### Sync Endpoints
```bash
# Push memories from device
curl -X POST http://localhost:3030/api/sync/push \
  -H "Content-Type: application/json" \
  -H "Cookie: soliloquy_session=..." \
  -d '{
    "device_id": "phone_123",
    "device_name": "My Phone",
    "timestamp": 1732694400,
    "items": [
      {
        "id": "mem_1",
        "item_type": "memory",
        "content": "Example memory",
        "metadata": {},
        "created_at": 1732694400
      }
    ]
  }'

# Pull new memories
curl -X POST http://localhost:3030/api/sync/pull \
  -H "Content-Type: application/json" \
  -H "Cookie: soliloquy_session=..." \
  -d '{
    "device_id": "phone_123",
    "device_name": "My Phone",
    "timestamp": 1732694400,
    "items": []
  }'

# List devices
curl http://localhost:3030/api/sync/devices \
  -H "Cookie: soliloquy_session=..."

# Sync status
curl http://localhost:3030/api/sync/status
```

### Cupboard Endpoints
```bash
# Store memory
curl -X POST http://localhost:3030/api/cupboard/store \
  -H "Content-Type: application/json" \
  -H "Cookie: soliloquy_session=..." \
  -d '{
    "content": "Meeting notes",
    "metadata": { "source": "notes" },
    "tags": ["work", "meeting"],
    "source": "manual"
  }'

# Retrieve memories
curl -X POST http://localhost:3030/api/cupboard/retrieve \
  -H "Content-Type: application/json" \
  -H "Cookie: soliloquy_session=..." \
  -d '{
    "query": "meeting",
    "limit": 10
  }'

# Storage stats
curl http://localhost:3030/api/cupboard/stats \
  -H "Cookie: soliloquy_session=..."
```

### Display Info
```bash
# Check display status
curl http://localhost:3030/api/display/info

# Response:
{
  "available": "false",
  "width": "0",
  "height": "0",
  "name": "none",
  "connection": "none",
  "mode": "headless"
}
```

## Use Cases

### 1. Headless Zircon Device

Fuchsia/Zircon device with no monitor connected:

```bash
# On Zircon device (headless)
v -os fuchsia -prod backend/
# Deploy to device via `ffx`

# Server available at http://device-ip:3030
# Other devices sync via /api/sync endpoints
```

All connected devices can sync memories to this central server.

### 2. Development Board

Zircon-based SBC for home server:

```bash
# On development board (no display)
./tools/soliloquy/start.sh

# Automatically detects no monitor
# Runs as Cupboard sync server only
```

### 3. IoT Data Collector

Fuchsia device collecting sensor data:

```bash
# On IoT device (headless)
# Soliloquy automatically detects no display
# Stores data in Cupboard
# Other devices query via sync/pull
```

## Network Configuration

### Local Network Access

By default, the server binds to `0.0.0.0:3030`, making it accessible from other devices on the network:

```bash
# From another device
curl http://soliloquy-server:3030/health
```

### Firewall Rules

Open port 3030 if running a firewall:

```bash
# UFW (Ubuntu)
sudo ufw allow 3030/tcp

# iptables
sudo iptables -A INPUT -p tcp --dport 3030 -j ACCEPT

# firewalld (Fedora)
sudo firewall-cmd --add-port=3030/tcp --permanent
sudo firewall-cmd --reload
```

### Reverse Proxy (Optional)

Use Caddy or Nginx for HTTPS:

```caddyfile
# Caddyfile
cupboard.example.com {
    reverse_proxy localhost:3030
}
```

## Monitoring

### Check Server Status

```bash
# Health check
curl http://localhost:3030/health

# Sync status
curl http://localhost:3030/api/sync/status
```

### Logs

```bash
# Backend logs to stdout
cd backend
v run . 2>&1 | tee soliloquy.log
```

### Systemd Service (Linux)

Create `/etc/systemd/system/soliloquy.service`:

```ini
[Unit]
Description=Soliloquy Headless Cupboard Server
After=network.target

[Service]
Type=simple
User=soliloquy
WorkingDirectory=/opt/soliloquy/backend
ExecStart=/usr/local/bin/v run .
Restart=on-failure
RestartSec=10

Environment=GOOGLE_CLIENT_ID=...
Environment=GOOGLE_CLIENT_SECRET=...
Environment=TABLEWARE_BASE_URL=http://localhost:8000

[Install]
WantedBy=multi-user.target
```

## Security

### Authentication Required

All sync endpoints require a valid session cookie from Google OAuth:

1. Device must authenticate via `/api/auth/google`
2. Receive `soliloquy_session` cookie
3. Include cookie in all sync requests

### Network Security

- Run behind a firewall for local network only
- Use reverse proxy with HTTPS for internet access
- Consider VPN (Tailscale, WireGuard) for remote access

### Environment Variables

Store secrets in `.env` file:

```bash
# backend/.env
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-secret
SESSION_SECRET=random-secret-key
```

Never commit `.env` to git.

## Troubleshooting

### Server won't start

```bash
# Check V installation
v version

# Check port availability
netstat -tuln | grep 3030

# Check environment variables
cat backend/.env
```

### Can't connect from other devices

```bash
# Check server is binding to all interfaces
netstat -tuln | grep 3030
# Should show 0.0.0.0:3030, not 127.0.0.1:3030

# Check firewall
sudo ufw status
```

### Display detected incorrectly

Display detection is passive and only queries Zircon scenic. If the device node exists in `/dev/class/display/`, a monitor is assumed to be present. This is controlled by the Fuchsia kernel and cannot be overridden.

## Client Integration

Example client code for syncing from a device:

```typescript
// TypeScript client example
async function syncToServer(serverUrl: string, sessionCookie: string) {
  const response = await fetch(`${serverUrl}/api/sync/push`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Cookie': sessionCookie
    },
    body: JSON.stringify({
      device_id: 'my_device_123',
      device_name: 'My Device',
      timestamp: Date.now() / 1000,
      items: [
        {
          id: 'mem_' + Date.now(),
          item_type: 'memory',
          content: 'Example memory content',
          metadata: { source: 'app' },
          created_at: Date.now() / 1000
        }
      ]
    })
  });
  
  const result = await response.json();
  console.log(`Synced ${result.synced_count} items`);
}
```

See `ui/desktop/src/lib/api/sync.ts` for full implementation.
