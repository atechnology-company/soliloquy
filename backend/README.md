# Soliloquy Backend (V)

Local backend service that provides Google OAuth integration, proxies requests to Plates Tableware, and bridges to Zircon system services.

## Architecture

```
backend/
├── main.v        # Entry point and vweb app setup
├── config.v      # Configuration from environment
├── auth.v        # Google OAuth authentication
├── tableware.v   # Tableware MCP proxy endpoints
└── zircon.v      # Zircon IPC bridge for Fuchsia services
```

## Features

- **Google OAuth:** Sign in with the same Google account used by Plates
- **Session Management:** Cookie-based sessions for authenticated users
- **Tableware Proxy:** Forwards pickup and device data requests to Tableware MCP service
- **Zircon Integration:** IPC bridge to native Fuchsia services (scenic, audio, input, storage)

## Setup

1. Install V language: https://vlang.io

2. Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
# Edit .env with your Google OAuth credentials
```

3. Get Google OAuth credentials from https://console.cloud.google.com/apis/credentials

4. Make sure Plates Tableware is running on `http://localhost:8000`

## Development

```bash
# Run the backend
v run .

# Build binary
v -prod .

# Build for Fuchsia (with Zircon support)
v -os fuchsia -prod .
```

The backend will listen on `http://localhost:3030`.

## Endpoints

### Authentication
- `GET /health` - Health check
- `GET /api/auth/google` - Initiate Google OAuth flow
- `GET /api/auth/google/callback` - OAuth callback handler
- `GET /api/auth/user` - Get current authenticated user
- `POST /api/auth/logout` - Sign out

### User Data
- `POST /api/user/onboarding` - Update onboarding completion status

### Tableware Proxy
- `GET /api/pickups/current` - Get current pickup session (proxied to Tableware)

### Zircon Services (Fuchsia only)
- `GET /api/zircon/status` - Check Zircon service status
- `POST /api/zircon/channel/create` - Create a new Zircon IPC channel
- `POST /api/zircon/channel/write` - Write message to Zircon channel
- `POST /api/zircon/channel/read` - Read message from Zircon channel

## UI Integration

Update `ui/desktop/.env`:

```
VITE_TABLEWARE_BASE_URL=http://localhost:3030
```

The Soliloquy UI will connect to this backend, which handles auth and proxies Tableware requests.

## Zircon Integration

When running on Fuchsia, the backend automatically initializes IPC channels to system services using the V bindings in `third_party/zircon_v/ipc/`. This provides:

- **Scenic:** UI composition and rendering
- **Audio:** System audio input/output
- **Input:** Keyboard, mouse, touch events
- **Storage:** Persistent file system access

The Zircon module uses conditional compilation (`$if fuchsia { ... }`) to enable these features only when building for Fuchsia targets.

## Cupboard Memory Storage

Cupboard provides universal memory storage for Soliloquy, similar to Plates' Cupboard but integrated with Zircon for persistent storage on Fuchsia.

### Features
- Store and retrieve user memories with embeddings
- Tag-based organization
- Source tracking (user, search, clipboard, pickup)
- Vector similarity search (TODO)
- Zircon-backed persistence on Fuchsia

### Endpoints
- `POST /api/cupboard/store` - Store a memory
- `POST /api/cupboard/retrieve` - Retrieve memories by query
- `POST /api/cupboard/delete` - Delete a memory
- `GET /api/cupboard/stats` - Get storage statistics

## Search Integration

The command bar (`/api/search`) provides a unified search interface that combines:
- Web search (Perplexity API integration)
- Cupboard memory retrieval
- Plates command execution
- Browser navigation

### Search Card Types
- `web` - Web search results with carousel layout
- `cupboard` - Stored memories from Cupboard
- `command` - Plates command execution
- `browser` - URL navigation

### Endpoints
- `POST /api/search` - Perform unified search
- `POST /api/search/suggestions` - Get search suggestions

## Headless Mode

Soliloquy automatically detects if a display is available. When running without a display (e.g., on a headless server, Raspberry Pi, or cloud VM), it runs as a Cupboard sync server only.

### Display Detection

- **Linux**: Checks `DISPLAY`, `WAYLAND_DISPLAY`, or `/dev/fb0`
- **macOS**: Assumes display available (development mode)
- **Fuchsia**: Queries Zircon scenic service for active displays

### Headless Server Capabilities

When no display is detected:
- ✅ Cupboard memory storage
- ✅ Device sync endpoints
- ✅ Google OAuth authentication
- ✅ Tableware proxy
- ✅ Zircon services (on Fuchsia)
- ❌ Servo + V8 desktop (skipped)
- ❌ UI rendering

### Sync Protocol

Devices can sync their data with a headless Soliloquy server:

**Push memories to server**:
```json
POST /api/sync/push
{
  "device_id": "iphone_123",
  "device_name": "Max's iPhone",
  "timestamp": 1732694400,
  "items": [
    {
      "id": "mem_1",
      "item_type": "memory",
      "content": "Meeting notes from today",
      "metadata": { "source": "notes_app" },
      "created_at": 1732694400
    }
  ]
}
```

**Pull new memories from server**:
```json
POST /api/sync/pull
{
  "device_id": "iphone_123",
  "device_name": "Max's iPhone",
  "timestamp": 1732694400,
  "items": []
}
```

Response includes any memories created after the client's timestamp.

### Running Headless

```bash
# Manually start backend only
cd backend
v run .

# Or use the start script (auto-detects headless)
./tools/soliloquy/start.sh
```

The server will log:
```
🚫 No display detected - running in headless Cupboard server mode
📡 Devices can sync to http://hostname:3030
```

### Use Cases

- **Home Server**: Raspberry Pi running 24/7 as family Cupboard sync
- **Cloud VM**: DigitalOcean/AWS instance for remote memory access
- **IoT Device**: Headless Fuchsia board syncing sensor data
- **Dev Container**: Docker container for testing sync protocol
