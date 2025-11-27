# Soliloquy Architecture

Soliloquy is a Servo + V8 desktop environment with integrated search, memory storage, and Zircon IPC bridge.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Soliloquy Desktop                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Svelte 5 UI (ui/desktop)                             │  │
│  │  - SearchBar: Unified command/search/browser bar      │  │
│  │  - SearchCarousel: Perplexity-style result cards      │  │
│  │  - Google OAuth integration                           │  │
│  └─────────────────┬─────────────────────────────────────┘  │
│                    │                                          │
│  ┌─────────────────▼─────────────────────────────────────┐  │
│  │  V Backend (backend/)                                  │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐  │  │
│  │  │  auth.v  │ │ search.v │ │cupboard.v│ │zircon.v │  │  │
│  │  │ (Google) │ │(Unified) │ │(Memories)│ │  (IPC)  │  │  │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬────┘  │  │
│  │       │            │            │            │         │  │
│  │       └────────────┴────────────┴────────────┘         │  │
│  │                    │                                    │  │
│  └────────────────────┼────────────────────────────────────┘  │
│                       │                                        │
└───────────────────────┼────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
  ┌─────────┐    ┌──────────┐    ┌──────────────┐
  │ Plates  │    │Perplexity│    │   Zircon     │
  │Tableware│    │   API    │    │  Services    │
  └─────────┘    └──────────┘    │ (Fuchsia)    │
                                  └──────────────┘
```

## Components

### UI Layer (`ui/desktop/`)

**Svelte 5 + Tailwind v4 + shadcn/ui**

- **SearchBar Component**: Large, minimal search input that acts as:
  - Command bar (Plates commands with `/` or `>`)
  - Search engine (web search via Perplexity)
  - Browser (URL navigation)
  - Memory retrieval (Cupboard queries)

- **SearchCarousel Component**: Horizontal scrolling card layout inspired by Perplexity
  - Card types: `web`, `cupboard`, `command`, `browser`
  - Smooth animations and hover effects
  - Click to navigate or execute

- **Authentication**: Google OAuth flow (shared with Plates)

### Backend Layer (`backend/`)

**V Language + vweb framework**

#### `main.v`
- Entry point and vweb app setup
- Initializes Cupboard and Zircon subsystems
- Health check endpoint

#### `auth.v`
- Google OAuth flow (same as Plates Tableware)
- Cookie-based session management
- User authentication endpoints

#### `search.v`
- Unified search interface
- Command parsing (`/command`, `>command`, URLs)
- Web search integration (Perplexity API)
- Cupboard memory search
- Returns carousel-ready `SearchCard[]`

#### `cupboard.v`
- Universal memory storage (inspired by Plates Cupboard)
- Stores: user memories, search history, clipboard, pickups
- Tag-based organization
- Vector embeddings (TODO)
- Zircon persistence on Fuchsia

#### `zircon.v`
- IPC bridge to Fuchsia system services
- Channel creation, read, write
- Conditional compilation (`$if fuchsia`)
- Services: Scenic (UI), Audio, Input, Storage

#### `tableware.v`
- Proxy to Plates Tableware MCP server
- Pickup session forwarding
- Onboarding state management

#### `config.v`
- Environment-based configuration
- Google OAuth credentials
- Tableware endpoint
- Session secrets

## Data Flow

### Search Flow

1. User types in SearchBar
2. On submit → `POST /api/search` with query
3. Backend parses intent:
   - URL → return `browser` card
   - `/command` → return `command` card
   - Text → search Cupboard + Web
4. Returns `SearchResponse` with `SearchCard[]`
5. UI renders SearchCarousel
6. User clicks card → navigate/execute

### Memory Storage Flow

1. User interaction generates memory
2. `POST /api/cupboard/store` with content + metadata
3. Backend stores in-memory (dev) or Zircon (Fuchsia)
4. Returns memory ID
5. Memory available for future retrieval via search

### Zircon IPC Flow (Fuchsia only)

1. Backend initializes Zircon channels on startup
2. Frontend calls `POST /api/zircon/channel/create`
3. Backend creates channel pair via `third_party/zircon_v/ipc/`
4. Frontend writes messages via `POST /api/zircon/channel/write`
5. System services respond via channel read

## Integration Points

### Plates Tableware
- Pickup session sync
- Device status
- Clipboard history
- Real-time activity feed

### Perplexity API (TODO)
- Web search with AI summaries
- Carousel card generation
- Follow-up questions

### Zircon Services (Fuchsia)
- Scenic: UI composition
- Audio: System audio I/O
- Input: Keyboard/mouse/touch
- Storage: Persistent file system

## Security

- **Authentication**: Google OAuth with same credentials as Plates
- **Sessions**: HTTP-only cookies with 7-day expiration
- **CORS**: Restricted to `localhost:5173` (dev) and production origins
- **Zircon**: Channel-based IPC with handle validation

## Performance

- **In-memory caching**: Sessions and memories cached in V maps
- **Lazy initialization**: Zircon only initializes on Fuchsia
- **Conditional compilation**: Platform-specific code excluded via `$if`
- **Carousel rendering**: Virtual scrolling for large result sets (TODO)

## Headless Mode

When no display is detected, Soliloquy automatically runs as a **headless Cupboard sync server**:

- Servo + V8 desktop **does not start**
- Backend runs on port 3030 as a sync endpoint
- Devices can push/pull memories via `/api/sync/push` and `/api/sync/pull`
- Display detection: Passively queries Zircon scenic service for connected displays via `/dev/class/display/`

**Sync Endpoints**:
- `POST /api/sync/push` - Device pushes memories to server
- `POST /api/sync/pull` - Device pulls new memories from server
- `GET /api/sync/devices` - List registered devices
- `GET /api/sync/status` - Server mode and stats

**Use Cases**:
- Fuchsia device as headless Cupboard server (no monitor connected)
- Zircon-based SBC running as home sync hub
- Development boards for IoT data collection

## Development Workflow

### With Display (Desktop Mode)
1. Start Plates Tableware: `cd plates/tableware/backend && go run .`
2. Start Soliloquy: `./tools/soliloquy/start.sh`
3. Navigate to `http://localhost:5173`

### Headless Mode (Server Only)
1. Start Soliloquy backend: `cd backend && v run .`
2. Server available at `http://localhost:3030`
3. Connect devices to sync endpoint

**Quick Start Script**: `./tools/soliloquy/start.sh`
- Auto-detects display availability
- Starts backend + UI (if display present)
- Starts backend only (if headless)

## Deployment (Fuchsia)

1. Build backend with Zircon: `v -os fuchsia -prod .`
2. Build UI bundle: `cd ui/desktop && pnpm build`
3. Package as Fuchsia component
4. Deploy to target device

## Future Enhancements

- [ ] Perplexity API integration for real web search
- [ ] Vector similarity search in Cupboard
- [ ] SurrealDB persistence layer
- [ ] WebRTC tunneling for remote access
- [ ] Native Zircon service integrations (Scenic, Audio)
- [ ] Command palette with fuzzy search
- [ ] File browser integration
- [ ] Tab management
