# Soliloquy Servo Desktop UI

A Svelte v5 application that prototypes the Servo + V8 desktop surface for Soliloquy. The goal is to mirror the real runtime: Servo provides compositing, V8 executes apps, and this repo supplies the desktop shell authored in Svelte.

## Overview

- **Frontend:** Svelte 5 + Tailwind v4 + shadcn/ui components
- **Runtime contract:** Servo browser engine hosting a V8 runtime
- **Component Library:** shadcn-svelte for Button, Input, Label + reusable bits-ui primitives
- **Status:** Web build that Servo/V8 embed as the literal desktop surface (no more Tauri)

## Features

- **Ambient Greeting Surface:** Hero onboarding panel with live time/date, glassmorphic glow, and password prompt.
- **Task Canvas:** Secondary glass panel showcasing "what can we get started" copy, quick filters, and featured pickups.
- **Command Palette:** Global command bar pinned bottom-right with ⌘/Ctrl + \ hotkey plus fuzzy suggestions (disabled on auth/onboarding flows).
- **Tableware Bridge:** Live pickup banner fetches data from the sibling [`../plates/tableware`](../../plates/tableware) MCP service.
- **Responsive Layout:** Tailwind v4 + shadcn/ui components with custom Instrument Sans typography.

## Development

### Prerequisites

- Node.js 18+ (Corepack recommended)
- pnpm 10+ (`corepack enable pnpm`)
- Tailwind CSS v4 (installed via `@tailwindcss/vite`)
- V language (https://vlang.io) for the backend
- Plates Tableware running on `http://localhost:8000`

### Quick Start

1. **Start the Soliloquy backend (V):**

```bash
cd backend
v run main.v
```

The backend listens on `http://localhost:3030` and handles Google OAuth + Tableware proxying.

2. **Start the UI dev server:**

```bash
# From the project root
./tools/soliloquy/dev_ui.sh

# Or manually:
cd ui/desktop
pnpm install
pnpm dev
```

### Scripts

- `pnpm dev` – start the Svelte dev server (used by Servo during development)
- `pnpm build` – build the static bundle that Servo/V8 host
- `pnpm preview` – preview the production bundle locally
- `pnpm check` – run `svelte-check` + type analysis
- `pnpm check:watch` – watch mode for the same checks

### Tableware Endpoint

Set `VITE_TABLEWARE_BASE_URL` if your Tableware service is not running on `http://localhost:8000`. During onboarding you can also override the endpoint interactively; both paths call into the sibling `../plates/tableware` service.

### Build Output

`pnpm build` emits a static bundle in `build/`. Servo only needs the generated `index.html` + assets; point the runtime to that directory or use `./tools/soliloquy/build_ui.sh`.

## Architecture

```
src/
├── routes/
│   ├── +layout.svelte      # Ambient surfaces + command button
│   ├── +page.svelte        # Authentication surface
│   └── dashboard/+page.svelte # Home canvas
├── lib/
│   ├── components/
│   │   └── CommandPalette.svelte
│   ├── stores/
│   │   └── system.ts       # Clock + telemetry stores
│   └── system/
│       └── actions.ts      # Centralized system actions & command suggestions
├── app.css                 # Global styles + Instrument Sans import
└── app.html                # Template shell
```

### Command Palette

- `CommandPalette.svelte` exposes a suggestion list, input field, and close events
- Bound to the global shortcut (⌘/Ctrl + \) via layout-level listeners
- Suggestions are data-driven so Servo can later hydrate them from runtime metadata

### Routes

- `/` – Greeting + authentication page
- `/dashboard` – Workspace canvas with filters and featured cards

### State Management

- `systemClock` is a shared readable store updated once per second
- `clockDisplay` derives formatted strings via memoized `Intl.DateTimeFormat` instances (no repeated allocations)
- Components subscribe to the derived store to avoid duplicate intervals/timers

## Design System

- **Palette:** Deep black canvas with indigo/fuchsia glow orbs and soft glass panels
- **Typography:** Instrument Sans (400–700) for every heading, matched with uppercase tracking for system cues
- **Accessibility:** Command palette supports keyboard input, and the CTA button exposes clear labels + shortcuts

## Integration Path

1. **Prototype (current):** Pure web bundle served by Vite during development
2. **Servo Embed:** Servo loads `build/index.html` as the desktop scene and proxies bridge events to V8
3. **Zircon Wiring:** Bridge hooks connect to FIDL services for process launch, storage, and input routing

## Contributing

1. Keep components declarative and side-effect free; use stores/utilities for shared logic
2. Prefer data-driven configuration so Servo can hydrate state from FIDL in the future
3. Run `pnpm check` + `pnpm build` before submitting changes
4. Document any new palette shortcuts or surface copy updates in this README
