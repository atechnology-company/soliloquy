# Soliloquy Shell UI

A Tauri + Svelte application that prototypes the Soliloquy shell interface. This UI mockup demonstrates the desktop environment design and user experience concepts for the Soliloquy operating system.

## Overview

The Soliloquy Shell UI is a prototype that shows how the web-native desktop environment will look and feel. It's built with modern web technologies that mirror the actual stack that will be used in the production OS:

- **Frontend**: Svelte (matching the Plates vision)
- **Desktop Runtime**: Tauri (for development prototyping)
- **Styling**: Tailwind CSS
- **Production Runtime**: Servo (replaces Tauri in the actual OS)

## Features

### Current Implementation

- **Status Bar**: Top bar showing system status, network connectivity, battery, and time
- **Launcher Grid**: Application launcher with icon-based navigation
- **Webview Placeholder**: Mock area showing where Servo-rendered content will appear
- **Responsive Design**: Adapts to different window sizes
- **Dark Theme**: Consistent with the Soliloquy design language

### Production Vision

In the actual Soliloquy, this UI will be rendered by:

- **Servo Browser Engine**: Replaces Tauri's webview
- **WebRender + Vulkan**: Hardware-accelerated graphics via Mali-G57
- **V8 Runtime**: JavaScript execution engine
- **Zircon Graphics Stack**: System-level rendering pipeline

## Development

### Prerequisites

- Node.js 18+ 
- Rust 1.70+
- (macOS) Xcode Command Line Tools
- (Linux) Basic build tools

### Quick Start

```bash
# From the project root
./tools/soliloquy/dev_ui.sh
```

Or manually:

```bash
cd ui/tauri-shell
npm install
npm run tauri:dev
```

### Available Scripts

- `npm run dev` - Start Svelte development server
- `npm run build` - Build for production
- `npm run tauri:dev` - Start Tauri development server
- `npm run tauri:build` - Build Tauri application
- `npm run check` - Type checking and linting

## Architecture

### Component Structure

```
src/
├── routes/
│   ├── +layout.svelte      # Main shell layout
│   └── +page.svelte        # Home page
├── lib/components/
│   ├── StatusBar.svelte    # Top status bar
│   ├── LauncherGrid.svelte # Application launcher
│   └── WebviewPlaceholder.svelte # Servo content area
└── app.css                 # Global styles
```

### Integration with Servo Runtime

The webview placeholder demonstrates where actual Servo-rendered content will appear:

1. **URL Routing**: Applications will be served via `servo://` protocol
2. **Web Applications**: HTML/CSS/JS apps running in Servo
3. **System Integration**: Access to Zircon system services via FIDL
4. **Graphics Pipeline**: WebRender → Vulkan → Mali-G57

### Asset Serving

In production:
- Static assets served by Soliloquy system services
- Web applications loaded from local filesystem
- Network requests routed through Zircon network stack

## Design System

### Colors
- **Primary**: Blue gradient (#1e40af → #7c3aed)
- **Background**: Dark gray (#111827 → #1f2937)
- **Text**: White and gray variants
- **Accent**: Blue for interactive elements

### Typography
- **System Font**: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto
- **Weights**: 400 (regular), 500 (medium), 700 (bold)
- **Sizes**: Responsive scaling from 12px to 72px

## Usage in Development Workflow

### When to Use This Scaffold

1. **UI/UX Design**: Prototype and iterate on shell interface
2. **Component Development**: Build and test individual UI components
3. **User Testing**: Gather feedback on desktop experience
4. **Screenshots**: Generate marketing and documentation materials
5. **Integration Testing**: Test web application compatibility

### Building for Review

```bash
# Build for screenshots/demos
npm run tauri:build

# Output will be in src-tauri/target/release/bundle/
```

### Integration Path

1. **Phase 1** (Current): Tauri prototype for design validation
2. **Phase 2**: Port components to run in Servo
3. **Phase 3**: Integration with Zircon system services
4. **Phase 4**: Production deployment on Soliloquy

## Contributing

When contributing to the UI:

1. Follow Svelte and Tailwind conventions
2. Maintain component reusability
3. Test with different window sizes
4. Consider accessibility (keyboard navigation, screen readers)
5. Keep performance in mind for target hardware (Radxa Cubie A5E)