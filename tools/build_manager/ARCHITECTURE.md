# Soliloquy Build Manager - Architecture

## Overview

The Soliloquy Build Manager is a sophisticated build orchestration system designed specifically for the Soliloquy OS project. It provides unified interfaces for multiple build systems (GN, Bazel, Cargo) and offers both CLI and GUI experiences.

## Design Principles

1. **Separation of Concerns**: Core logic, CLI, and GUI are separate components
2. **Async by Default**: Built on Tokio for maximum performance
3. **Type Safety**: Leverages Rust's type system for correctness
4. **Extensibility**: Plugin architecture for future enhancements
5. **Cross-Platform**: Works on Linux, macOS, and (future) Windows

## Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     User Interfaces                      │
│  ┌──────────────────────┐   ┌───────────────────────┐  │
│  │   CLI (clap-based)   │   │  GUI (Tauri + React)  │  │
│  └──────────┬───────────┘   └───────────┬───────────┘  │
└─────────────┼───────────────────────────┼──────────────┘
              │                           │
              │         Commands          │ Tauri IPC
              ▼                           ▼
┌─────────────────────────────────────────────────────────┐
│                   Build Manager Core                     │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Build Manager Facade                │   │
│  │    (Coordinated access to all subsystems)        │   │
│  └──────┬──────────────┬──────────────┬─────────────┘   │
│         │              │              │                  │
│    ┌────▼────┐   ┌────▼─────┐   ┌───▼──────┐          │
│    │Executor │   │  Module  │   │Analytics │          │
│    │         │   │ Manager  │   │          │          │
│    └────┬────┘   └────┬─────┘   └───┬──────┘          │
│         │              │              │                  │
└─────────┼──────────────┼──────────────┼──────────────────┘
          │              │              │
          │              │              ▼
          │              │         ┌─────────┐
          │              │         │ SQLite  │
          │              │         │Database │
          │              │         └─────────┘
          │              │
          ▼              ▼
┌─────────────────────────────────────────────────────────┐
│              Build System Abstractions                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Bazel     │  │  GN+Ninja   │  │   Cargo     │    │
│  │  Adapter    │  │   Adapter   │  │   Adapter   │    │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘    │
└─────────┼─────────────────┼─────────────────┼───────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────┐
│               External Build Systems                     │
│        Bazel          GN/Ninja          Cargo            │
└─────────────────────────────────────────────────────────┘
```

## Core Components

### Build Manager (`lib.rs`)

The main facade that provides unified access to all subsystems.

**Responsibilities:**
- Initialize and coordinate subsystems
- Provide clean API to clients
- Manage shared state and configuration

**Key Methods:**
```rust
async fn new(config: Config) -> Result<Self>
fn executor(&self) -> Arc<BuildExecutor>
fn module_manager(&self) -> Arc<ModuleManager>
fn analytics(&self) -> Arc<Analytics>
```

### Build Executor (`executor.rs`)

Manages build execution and lifecycle.

**Responsibilities:**
- Start and stop builds
- Monitor build progress
- Track active builds
- Clean build artifacts

**Key Methods:**
```rust
async fn start_build(&self, request: BuildRequest) -> Result<String>
async fn get_build_status(&self, build_id: &str) -> Result<BuildStatus>
async fn cancel_build(&self, build_id: &str) -> Result<()>
async fn clean(&self, system: BuildSystem, target: Option<String>) -> Result<()>
```

### Module Manager (`module_manager.rs`)

Discovers and manages project modules.

**Responsibilities:**
- Scan project for modules
- Parse build files (BUILD.bazel, BUILD.gn, Cargo.toml)
- Build dependency graph
- Track module metadata

**Key Methods:**
```rust
async fn list_modules(&self) -> Vec<Module>
async fn get_module(&self, name: &str) -> Result<Module>
async fn get_dependencies(&self, module: &str) -> Result<Vec<String>>
async fn get_dependency_graph(&self) -> Result<DependencyGraph>
```

### Analytics (`analytics.rs`)

Tracks build history and provides statistics.

**Responsibilities:**
- Store build records in SQLite
- Calculate statistics
- Query build history
- Track trends over time

**Key Methods:**
```rust
async fn record_build(&self, build: &Build) -> Result<()>
async fn get_statistics(&self) -> Result<BuildStatistics>
async fn get_build_history(&self, days: u32) -> Result<Vec<Build>>
async fn get_build(&self, build_id: &str) -> Result<Build>
```

### Configuration (`config.rs`)

Manages user configuration.

**Responsibilities:**
- Load/save configuration files
- Provide defaults
- Validate settings
- Platform-specific paths

**Structure:**
```rust
struct Config {
    general: GeneralConfig,        // Project root, default system
    build_systems: BuildSystemsConfig,  // Tool paths
    cache: CacheConfig,            // Cache settings
    notifications: NotificationsConfig, // Notification prefs
    ui: UiConfig,                  // UI preferences
}
```

## Build System Adapters

### Trait Interface

All build systems implement the `BuildSystemTrait`:

```rust
#[async_trait]
pub trait BuildSystemTrait: Send + Sync {
    async fn build(&self, request: BuildRequest) -> Result<Build>;
    async fn clean(&self, target: Option<String>) -> Result<()>;
    async fn test(&self, request: TestRequest) -> Result<TestRun>;
    async fn list_targets(&self) -> Result<Vec<String>>;
    async fn query_dependencies(&self, target: &str) -> Result<Vec<String>>;
    async fn get_build_files(&self) -> Result<Vec<PathBuf>>;
    fn name(&self) -> &str;
}
```

### Bazel Adapter

**Implementation Details:**
- Uses `bazel` command-line tool
- Spawns async processes with tokio
- Streams output in real-time
- Parses build errors from output

**Commands:**
```bash
bazel build <target> [--jobs N] [--verbose_failures]
bazel clean
bazel test <pattern>
bazel query "deps(<target>)"
```

### GN Adapter

**Implementation Details:**
- Uses `gn` for project generation
- Uses `ninja` for actual building
- Two-phase build (gen + build)
- Outputs to `out/default/`

**Commands:**
```bash
gn gen out/default
ninja -C out/default <target> [-j N] [-v]
gn ls out/default "//..."
gn desc out/default <target> deps
```

### Cargo Adapter

**Implementation Details:**
- Uses `cargo` command directly
- Supports package-specific builds
- Parses Cargo.toml for metadata
- Integrates with Rust toolchain

**Commands:**
```bash
cargo build [--package <name>] [--jobs N] [--verbose]
cargo clean [--package <name>]
cargo test [--package <name>] [<pattern>]
cargo metadata --format-version 1
```

## Data Models

### Build

Represents a single build execution.

```rust
struct Build {
    id: String,                    // Unique identifier
    target: String,                // Build target
    system: BuildSystem,           // Which build system
    status: BuildStatus,           // Current status
    options: BuildOptions,         // Build options used
    start_time: DateTime<Utc>,     // When started
    end_time: Option<DateTime<Utc>>, // When finished
    output: Vec<String>,           // Build output lines
    errors: Vec<BuildError>,       // Parsed errors
    warnings: Vec<BuildWarning>,   // Parsed warnings
    metrics: BuildMetrics,         // Performance metrics
}
```

### Module

Represents a project module/package.

```rust
struct Module {
    name: String,                  // Module name
    path: PathBuf,                 // File system path
    module_type: ModuleType,       // Type classification
    build_systems: Vec<BuildSystem>, // Supported systems
    dependencies: Vec<String>,     // Direct dependencies
    reverse_dependencies: Vec<String>, // Reverse deps
    source_files: Vec<PathBuf>,    // Source code files
    test_files: Vec<PathBuf>,      // Test files
}
```

### BuildMetrics

Performance and resource usage metrics.

```rust
struct BuildMetrics {
    duration_secs: Option<f64>,         // Total time
    cpu_usage_percent: Option<f32>,     // CPU usage
    memory_usage_mb: Option<u64>,       // Memory used
    disk_io_mb: Option<u64>,            // Disk I/O
    cache_hit_rate: Option<f32>,        // Cache efficiency
    artifacts_generated: usize,         // Output count
    artifacts_size_mb: Option<u64>,     // Output size
}
```

## CLI Architecture

### Command Structure

Uses `clap` for argument parsing with subcommands:

```
soliloquy-build
├── start <target>              # Start a build
├── stop <build-id>             # Stop a build
├── status [build-id]           # Check status
├── clean                       # Clean builds
├── module                      # Module operations
│   ├── list                    # List modules
│   ├── info <name>            # Module info
│   ├── deps <name>            # Dependencies
│   └── build <name>           # Build module
├── test                       # Test operations
│   ├── run [pattern]          # Run tests
│   ├── list                   # List tests
│   └── report                 # Test report
├── fidl                       # FIDL tools
│   ├── generate [lib]         # Generate bindings
│   └── list                   # List libraries
├── c2v                        # C-to-V translation
│   ├── translate <subsystem>  # Translate code
│   └── status                 # Translation status
├── env                        # Environment tools
│   ├── setup                  # Setup environment
│   └── check                  # Check environment
├── stats                      # Build statistics
├── history [--days N]         # Build history
├── compare <id1> <id2>        # Compare builds
└── profile                    # Build profiles
    ├── save <name>            # Save profile
    ├── load <name>            # Load profile
    ├── list                   # List profiles
    └── delete <name>          # Delete profile
```

### Output Formatting

Uses `colored` crate for beautiful terminal output:

- ✓ Green for success
- ✗ Red for errors
- ⚠ Yellow for warnings
- ℹ Blue for information
- Cyan for highlighting
- Gray for secondary info

## GUI Architecture

### Technology Stack

- **Backend**: Tauri (Rust)
- **Frontend**: React 18 + TypeScript
- **Styling**: Tailwind CSS
- **Build**: Vite
- **State**: React hooks
- **Router**: React Router

### Component Structure

```
src/
├── App.tsx                    # Main app component
├── main.tsx                   # Entry point
├── styles.css                 # Global styles
└── views/
    ├── Dashboard.tsx          # Overview dashboard
    ├── BuildView.tsx          # Build management
    ├── ModulesView.tsx        # Module browser
    ├── TestsView.tsx          # Test management
    ├── AnalyticsView.tsx      # Analytics & history
    └── SettingsView.tsx       # Settings panel
```

### Tauri Commands

Commands exposed to frontend via IPC:

```rust
#[tauri::command]
async fn init_manager(state: State<AppState>) -> Result<(), String>

#[tauri::command]
async fn start_build(state, target, system, options) -> Result<String, String>

#[tauri::command]
async fn list_modules(state: State<AppState>) -> Result<Value, String>

#[tauri::command]
async fn get_statistics(state: State<AppState>) -> Result<Value, String>

// ... etc
```

### Frontend Service Layer

```typescript
// src/services/api.ts
import { invoke } from "@tauri-apps/api/tauri";

export const api = {
  async startBuild(target: string, system: string, options: BuildOptions) {
    return invoke<string>("start_build", { target, system, options });
  },
  
  async listModules() {
    return invoke<Module[]>("list_modules");
  },
  
  // ... etc
};
```

## Database Schema

SQLite database for analytics and history.

### Tables

**builds**
```sql
CREATE TABLE builds (
    id TEXT PRIMARY KEY,
    target TEXT NOT NULL,
    system TEXT NOT NULL,
    status TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT,
    duration_secs REAL,
    cpu_usage REAL,
    memory_usage INTEGER,
    success INTEGER NOT NULL
);
```

**build_errors**
```sql
CREATE TABLE build_errors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    build_id TEXT NOT NULL,
    message TEXT NOT NULL,
    file TEXT,
    line INTEGER,
    FOREIGN KEY (build_id) REFERENCES builds(id)
);
```

**test_runs**
```sql
CREATE TABLE test_runs (
    id TEXT PRIMARY KEY,
    start_time TEXT NOT NULL,
    end_time TEXT,
    total INTEGER NOT NULL,
    passed INTEGER NOT NULL,
    failed INTEGER NOT NULL,
    skipped INTEGER NOT NULL,
    duration_secs REAL
);
```

## Concurrency Model

### Async Runtime

- Built on Tokio async runtime
- All I/O is non-blocking
- Parallel build execution support
- Efficient resource usage

### Synchronization

- `Arc<RwLock<T>>` for shared mutable state
- `DashMap` for concurrent hash maps
- `parking_lot` for faster locks where needed
- Message passing for complex coordination

### Build Isolation

Each build runs in its own:
- Process (spawned via tokio::process)
- Working directory
- Output stream
- Error tracking

## Error Handling

### Error Types

```rust
enum Error {
    Config(String),           // Configuration errors
    BuildSystem(String),      // Build system errors
    ModuleNotFound(String),   // Module not found
    BuildFailed(String),      // Build failed
    TestFailed(String),       // Test failed
    Io(std::io::Error),       // I/O errors
    Database(sqlx::Error),    // Database errors
    // ... etc
}
```

### Error Propagation

- Uses `Result<T, Error>` throughout
- Converts errors with `?` operator
- Provides context with `.map_err()`
- User-friendly error messages

## Performance Considerations

### Build Execution

- Parallel builds supported
- Streaming output (no memory accumulation)
- Efficient process spawning
- Resource monitoring

### Module Discovery

- Cached results
- Incremental updates
- File system watching (future)
- Lazy loading

### Database

- Indexed queries
- Prepared statements
- Connection pooling
- Async operations

### GUI

- Virtual scrolling for large lists
- Debounced search
- Lazy loading of data
- Optimistic updates

## Security Considerations

### Command Injection

- All user input sanitized
- No shell evaluation
- Direct process spawning
- Argument validation

### File System

- Path validation
- Restricted to project directory
- No symbolic link following
- Permission checks

### Database

- Parameterized queries
- No dynamic SQL
- Input validation
- Regular schema validation

## Testing Strategy

### Unit Tests

- Test individual functions
- Mock external dependencies
- Fast execution
- High coverage

### Integration Tests

- Test component interactions
- Use test fixtures
- Real build systems (where possible)
- End-to-end scenarios

### GUI Tests

- Component tests (React Testing Library)
- E2E tests (future: Playwright)
- Visual regression tests (future)

## Deployment

### CLI Distribution

- Published to crates.io
- Binary releases on GitHub
- Installation via `cargo install`
- System package managers (future)

### GUI Distribution

- Native installers (DMG, AppImage, MSI)
- Auto-update support (Tauri feature)
- Portable builds
- Signed binaries (future)

## Future Enhancements

### Plugin System

```rust
trait Plugin {
    fn name(&self) -> &str;
    fn on_build_start(&mut self, build: &Build) -> Result<()>;
    fn on_build_end(&mut self, build: &Build) -> Result<()>;
    fn commands(&self) -> Vec<Command>;
}
```

### Remote Builds

- gRPC API for remote execution
- Build distribution
- Result caching
- Load balancing

### AI Integration

- Error prediction
- Build optimization
- Natural language queries
- Automatic fixes

## Maintenance

### Code Organization

- Clear module boundaries
- Minimal dependencies
- Documentation for public APIs
- Examples for complex features

### Versioning

- Semantic versioning
- Changelog maintenance
- Migration guides
- Deprecation warnings

### Monitoring

- Error telemetry (opt-in)
- Performance metrics
- Usage analytics
- Crash reporting
