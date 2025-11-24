//! Servo embedder for Soliloquy
//! 
//! This module provides the integration layer between Servo and Zircon,
//! implementing the necessary traits for windowing, events, and graphics.
//! It also integrates V8 for JavaScript execution.

use log::{info, error, debug, warn};
use std::sync::{Arc, Mutex};
use std::collections::HashMap;

use crate::v8_runtime::V8Runtime;

/// Main embedder context that bridges Servo browser engine with Zircon/Fuchsia.
///
/// `ServoEmbedder` manages the lifecycle of a web browser instance running on Soliloquy.
/// It coordinates between:
/// - Flatland compositor for GPU-accelerated graphics presentation
/// - V8 JavaScript runtime for script execution
/// - Servo's rendering engine for web content
/// - Zircon input event system
///
/// The embedder follows a state machine pattern (see [`EmbedderState`]) to ensure proper
/// initialization order and safe resource management.
pub struct ServoEmbedder {
    /// Flatland session for GPU-accelerated graphics compositing.
    /// Currently a placeholder; will connect to `fuchsia.ui.composition.Flatland` FIDL service.
    flatland_session: Option<Arc<Mutex<FlatlandSession>>>,
    /// View reference tokens for window management in Scenic scene graph.
    view_ref: Option<ViewRef>,
    /// Thread-safe queue for buffering input events before dispatch to Servo.
    event_queue: Arc<Mutex<Vec<InputEvent>>>,
    /// V8 JavaScript runtime instance for executing web page scripts.
    /// Initialized early and used throughout the embedder lifetime.
    v8_runtime: Option<V8Runtime>,
    /// Servo webview handle (placeholder for actual Servo browser instance).
    webview: Option<Arc<Mutex<ServoWebview>>>,
    /// Currently loaded URL, used for reload and navigation state.
    current_url: Option<String>,
    /// Current state in the embedder lifecycle (see state machine documentation).
    state: EmbedderState,
}

/// State machine for embedder lifecycle management.
///
/// The embedder transitions through these states in order:
/// 1. `Uninitialized` → `Initializing`: Begin resource allocation
/// 2. `Initializing` → `Ready`: All subsystems initialized, ready to load content
/// 3. `Ready` → `Loading`: URL load initiated
/// 4. `Loading` → `Running`: Content loaded and rendering active
///
/// Any state can transition to `Error(String)` on failure.
/// Only `Ready` and `Running` states accept new URL loads.
#[derive(Debug, Clone, PartialEq)]
pub enum EmbedderState {
    /// Initial state before any initialization.
    Uninitialized,
    /// Actively initializing V8, Flatland, and other subsystems.
    Initializing,
    /// All systems ready, waiting for content load.
    Ready,
    /// URL load in progress, page not yet rendered.
    Loading,
    /// Page loaded and actively rendering frames.
    Running,
    /// Unrecoverable error occurred; contains error description.
    Error(String),
}

/// Placeholder for Fuchsia Flatland compositor session.
///
/// In production, this will wrap `fuchsia.ui.composition.FlatlandProxy` for:
/// - Creating scene graph transforms and content nodes
/// - Submitting frame buffers for GPU composition
/// - Managing image/buffer lifetimes
///
/// Currently tracks session metadata for development/testing.
pub struct FlatlandSession {
    /// Session identifier for debugging and logging.
    pub session_id: u32,
    /// Viewport width in physical pixels.
    pub width: u32,
    /// Viewport height in physical pixels.
    pub height: u32,
}

/// View reference tokens for Scenic view tree integration.
///
/// Contains kernel object IDs (koids) for:
/// - `ViewRef`: Read-only reference for event routing and focus
/// - `ViewRefControl`: Write capability for view lifecycle management
///
/// These will be created via `fuchsia.ui.views` FIDL APIs.
#[derive(Debug, Clone)]
pub struct ViewRef {
    /// Kernel object ID for the ViewRef eventpair.
    pub view_ref_koid: u64,
    /// Kernel object ID for the ViewRefControl eventpair.
    pub view_ref_control_koid: u64,
}

/// Placeholder for Servo browser webview instance.
///
/// Represents a single browser tab/window. In production, this will interface with
/// Servo's embedding API to control navigation, access DOM, and manage render output.
pub struct ServoWebview {
    /// Currently loaded URL.
    pub url: Option<String>,
    /// Page title (from `<title>` element or navigation metadata).
    pub title: Option<String>,
    /// Whether a navigation/load operation is in progress.
    pub is_loading: bool,
}

impl ServoEmbedder {
    /// Creates and initializes a new Servo embedder instance.
    ///
    /// Performs the following initialization steps:
    /// 1. Creates V8 runtime and executes a test script to verify functionality
    /// 2. Initializes Flatland graphics session (currently placeholder)
    /// 3. Creates view reference tokens for window management
    /// 4. Transitions state from `Uninitialized` → `Initializing` → `Ready`
    ///
    /// # Returns
    /// - `Ok(ServoEmbedder)`: Fully initialized embedder ready to load URLs
    /// - `Err(String)`: V8 initialization failure (critical error)
    ///
    /// # Examples
    /// ```no_run
    /// let embedder = ServoEmbedder::new()?;
    /// embedder.load_url("https://example.com")?;
    /// ```
    pub fn new() -> Result<Self, String> {
        info!("Initializing Servo embedder");
        
        let mut embedder = ServoEmbedder {
            flatland_session: None,
            view_ref: None,
            event_queue: Arc::new(Mutex::new(Vec::new())),
            v8_runtime: None,
            webview: None,
            current_url: None,
            state: EmbedderState::Uninitialized,
        };
        
        embedder.state = EmbedderState::Initializing;
        
        // Initialize V8 runtime
        match V8Runtime::new() {
            Ok(v8_runtime) => {
                info!("V8 runtime initialized successfully");
                embedder.v8_runtime = Some(v8_runtime);
                
                // Test V8 with a simple script
                if let Some(ref mut runtime) = embedder.v8_runtime {
                    match runtime.execute_script("'V8 is ready'") {
                        Ok(result) => debug!("V8 test script result: {}", result),
                        Err(e) => warn!("V8 test script failed: {}", e),
                    }
                }
            }
            Err(e) => {
                error!("Failed to initialize V8 runtime: {}", e);
                return Err(format!("V8 initialization failed: {}", e));
            }
        }
        
        // Initialize Flatland session
        match embedder.init_flatland() {
            Ok(session) => {
                info!("Flatland session initialized");
                embedder.flatland_session = Some(Arc::new(Mutex::new(session)));
            }
            Err(e) => {
                warn!("Failed to initialize Flatland session: {}", e);
                // Continue without Flatland for now
            }
        }
        
        // Create view reference
        embedder.view_ref = Some(ViewRef {
            view_ref_koid: 12345, // TODO: Generate actual koid
            view_ref_control_koid: 12346,
        });
        
        embedder.state = EmbedderState::Ready;
        info!("Servo embedder initialized successfully");
        
        Ok(embedder)
    }
    
    /// Initializes a Flatland compositor session for graphics output.
    ///
    /// **Placeholder Implementation:** Currently returns a mock session.
    /// Production version will connect to `fuchsia.ui.composition.Flatland` FIDL protocol
    /// and create a scene graph with image pipes for Servo's render output.
    fn init_flatland(&self) -> Result<FlatlandSession, String> {
        debug!("Initializing Flatland session (placeholder)");
        
        Ok(FlatlandSession {
            session_id: 1,
            width: 1920,
            height: 1080,
        })
    }
    
    /// Loads a URL into the webview and initializes the page.
    ///
    /// This method:
    /// 1. Validates embedder state (must be `Ready` or `Running`)
    /// 2. Transitions to `Loading` state
    /// 3. Creates a Servo webview instance (currently placeholder)
    /// 4. Executes JavaScript initialization code via V8 to simulate page load
    /// 5. Transitions to `Running` state on success
    ///
    /// **Placeholder:** Currently uses V8 to simulate page load. Production version
    /// will invoke Servo's navigation API: `servo::webview::load(url)`.
    ///
    /// # Arguments
    /// * `url` - The URL to load (e.g., "https://example.com")
    ///
    /// # Returns
    /// - `Ok(())`: URL loaded successfully, page is rendering
    /// - `Err(String)`: Invalid state or load failure
    ///
    /// # Examples
    /// ```no_run
    /// embedder.load_url("https://soliloquy.dev")?;
    /// ```
    pub fn load_url(&mut self, url: &str) -> Result<(), String> {
        if self.state != EmbedderState::Ready && self.state != EmbedderState::Running {
            return Err(format!("Embedder not ready for loading URLs. Current state: {:?}", self.state));
        }
        
        validate_url(url)?;
        
        info!("Loading URL: {}", url);
        self.state = EmbedderState::Loading;
        self.current_url = Some(url.to_string());
        
        // Create Servo webview
        let webview = ServoWebview {
            url: Some(url.to_string()),
            title: None,
            is_loading: true,
        };
        self.webview = Some(Arc::new(Mutex::new(webview)));
        
        // Execute JavaScript to initialize the page
        if let Some(ref mut runtime) = self.v8_runtime {
            let init_script = format!(
                r#"
                console.log('Loading URL: {}');
                // Simulate page load
                var page = {{
                    url: '{}',
                    title: 'Soliloquy Page',
                    ready: true
                }};
                page.title;
                "#,
                url, url
            );
            
            match runtime.execute_script(&init_script) {
                Ok(result) => {
                    debug!("Page initialization script result: {}", result);
                    
                    // Update webview title
                    if let Some(ref webview_arc) = self.webview {
                        if let Ok(mut webview) = webview_arc.lock() {
                            webview.title = Some(result);
                            webview.is_loading = false;
                        }
                    }
                }
                Err(e) => {
                    error!("Failed to execute page initialization script: {}", e);
                }
            }
        }
        
        // TODO: Call into actual Servo API
        // servo::webview::load(url);
        
        self.state = EmbedderState::Running;
        info!("URL loaded successfully: {}", url);
        Ok(())
    }
    
    /// Processes and dispatches input events to the webview.
    ///
    /// Input events are:
    /// 1. Queued to the internal event buffer for tracking
    /// 2. Converted to JavaScript handlers (current implementation)
    /// 3. Dispatched to V8 runtime for web page interaction
    ///
    /// **Placeholder:** Production version will convert Fuchsia input events
    /// (from `fuchsia.ui.input3` or `fuchsia.ui.pointer`) to Servo's event format
    /// and call `servo::input::handle_event(event)`.
    ///
    /// # Arguments
    /// * `event` - Touch or keyboard input event to process
    ///
    /// # Examples
    /// ```no_run
    /// embedder.handle_input(InputEvent::Touch { x: 100.0, y: 200.0 });
    /// embedder.handle_input(InputEvent::Key { code: 13 }); // Enter key
    /// ```
    pub fn handle_input(&mut self, event: InputEvent) {
        debug!("Handling input event: {:?}", event);
        
        // Add to event queue (clone to avoid move)
        if let Ok(mut queue) = self.event_queue.lock() {
            queue.push(event.clone());
        }
        
        // TODO: Convert Fuchsia input events to Servo events
        // servo::input::handle_event(event);
        
        // Execute JavaScript for input handling if needed
        if let Some(ref mut runtime) = self.v8_runtime {
            match event {
                InputEvent::Touch { x, y } => {
                    let script = format!(
                        r#"
                        if (window.handleTouch) {{
                            window.handleTouch({}, {});
                        }}
                        'Touch handled at ({}, {})';
                        "#,
                        x, y, x, y
                    );
                    
                    if let Ok(result) = runtime.execute_script(&script) {
                        debug!("Touch handling script result: {}", result);
                    }
                }
                InputEvent::Key { code } => {
                    let script = format!(
                        r#"
                        if (window.handleKey) {{
                            window.handleKey({});
                        }}
                        'Key handled: {}';
                        "#,
                        code, code
                    );
                    
                    if let Ok(result) = runtime.execute_script(&script) {
                        debug!("Key handling script result: {}", result);
                    }
                }
            }
        }
    }
    
    /// Submits the current frame to the Flatland compositor for display.
    ///
    /// This method is called on each frame of the render loop and:
    /// 1. Retrieves the current Flatland session
    /// 2. Submits buffered scene graph updates and image content
    /// 3. Executes optional JavaScript frame callbacks via V8
    ///
    /// **Placeholder:** Production version will call `flatland::present(session)`
    /// to submit Servo's rendered frame buffer to the Fuchsia compositor. This involves
    /// creating Flatland content nodes linked to Vulkan/Magma image pipes.
    ///
    /// # Returns
    /// - `Ok(())`: Frame submitted successfully
    /// - `Err(String)`: Presentation failure (rare; logged as warning)
    pub fn present(&mut self) -> Result<(), String> {
        debug!("Presenting frame");
        
        // TODO: Submit Flatland frame
        if let Some(ref session_arc) = self.flatland_session {
            if let Ok(session) = session_arc.lock() {
                debug!("Presenting to Flatland session {}", session.session_id);
                // flatland::present(session);
            }
        }
        
        // Execute JavaScript for frame presentation
        if let Some(ref mut runtime) = self.v8_runtime {
            let frame_script = r#"
            if (window.onFrame) {
                window.onFrame();
            }
            'Frame presented';
            "#;
            
            match runtime.execute_script(frame_script) {
                Ok(result) => debug!("Frame script result: {}", result),
                Err(e) => warn!("Frame script failed: {}", e),
            }
        }
        
        Ok(())
    }
    
    /// Returns the current embedder lifecycle state.
    ///
    /// Use this to check if the embedder is ready for operations like URL loading.
    pub fn get_state(&self) -> &EmbedderState {
        &self.state
    }
    
    /// Returns the currently loaded URL, if any.
    ///
    /// # Returns
    /// - `Some(&String)`: URL that was passed to `load_url()`
    /// - `None`: No URL has been loaded yet
    pub fn get_current_url(&self) -> Option<&String> {
        self.current_url.as_ref()
    }
    
    /// Retrieves metadata about the current webview state.
    ///
    /// # Returns
    /// A map containing:
    /// - `"url"`: Currently loaded URL
    /// - `"title"`: Page title from `<title>` element
    /// - `"loading"`: Whether a navigation is in progress ("true"/"false")
    ///
    /// Returns `None` if no webview has been created.
    pub fn get_webview_info(&self) -> Option<HashMap<String, String>> {
        if let Some(ref webview_arc) = self.webview {
            if let Ok(webview) = webview_arc.lock() {
                let mut info = HashMap::new();
                if let Some(ref url) = webview.url {
                    info.insert("url".to_string(), url.clone());
                }
                if let Some(ref title) = webview.title {
                    info.insert("title".to_string(), title.clone());
                }
                info.insert("loading".to_string(), webview.is_loading.to_string());
                return Some(info);
            }
        }
        None
    }
    
    /// Executes arbitrary JavaScript code in the page context.
    ///
    /// Provides direct access to the V8 runtime for executing scripts.
    /// In production, this would execute within Servo's JavaScript context
    /// with access to the DOM and web APIs.
    ///
    /// # Arguments
    /// * `script` - JavaScript source code to execute
    ///
    /// # Returns
    /// - `Ok(String)`: String representation of the script's return value
    /// - `Err(String)`: V8 runtime not initialized or script execution error
    ///
    /// # Examples
    /// ```no_run
    /// let title = embedder.execute_js("document.title")?;
    /// embedder.execute_js("console.log('Hello from Soliloquy')")?;
    /// ```
    pub fn execute_js(&mut self, script: &str) -> Result<String, String> {
        if let Some(ref mut runtime) = self.v8_runtime {
            runtime.execute_script(script)
        } else {
            Err("V8 runtime not initialized".to_string())
        }
    }
}

/// Input event types for user interaction.
///
/// Represents simplified input events that will be mapped from Fuchsia's
/// input protocols (`fuchsia.ui.input3` for keyboard, `fuchsia.ui.pointer` for touch/mouse).
#[derive(Debug, Clone)]
pub enum InputEvent {
    /// Touch or mouse pointer event with viewport coordinates.
    Touch { 
        /// X coordinate in viewport pixels (0 = left edge).
        x: f32, 
        /// Y coordinate in viewport pixels (0 = top edge).
        y: f32 
    },
    /// Keyboard event with key code.
    Key { 
        /// USB HID key code or custom key identifier.
        code: u32 
    },
}

fn validate_url(url: &str) -> Result<(), String> {
    if url.is_empty() {
        return Err("URL cannot be empty".to_string());
    }
    
    if url.trim().is_empty() {
        return Err("URL cannot be only whitespace".to_string());
    }
    
    let url_lower = url.to_lowercase();
    if !url_lower.starts_with("http://") && !url_lower.starts_with("https://") {
        return Err("URL must start with http:// or https://".to_string());
    }
    
    if url.len() < 10 {
        return Err("URL is too short to be valid".to_string());
    }
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_url_validation_valid() {
        assert!(validate_url("https://example.com").is_ok());
        assert!(validate_url("http://example.com").is_ok());
        assert!(validate_url("https://www.example.com/path").is_ok());
        assert!(validate_url("HTTP://EXAMPLE.COM").is_ok());
    }

    #[test]
    fn test_url_validation_empty() {
        assert!(validate_url("").is_err());
        assert_eq!(validate_url("").unwrap_err(), "URL cannot be empty");
    }

    #[test]
    fn test_url_validation_whitespace() {
        assert!(validate_url("   ").is_err());
        assert_eq!(validate_url("  ").unwrap_err(), "URL cannot be only whitespace");
    }

    #[test]
    fn test_url_validation_invalid_scheme() {
        assert!(validate_url("ftp://example.com").is_err());
        assert!(validate_url("example.com").is_err());
        assert!(validate_url("www.example.com").is_err());
        let err = validate_url("ftp://example.com").unwrap_err();
        assert!(err.contains("http://") || err.contains("https://"));
    }

    #[test]
    fn test_url_validation_too_short() {
        assert!(validate_url("http://a").is_err());
        assert_eq!(validate_url("http://a").unwrap_err(), "URL is too short to be valid");
    }

    #[test]
    fn test_embedder_state_transitions() {
        let embedder = ServoEmbedder::new().expect("Should initialize");
        assert_eq!(embedder.get_state(), &EmbedderState::Ready);
    }

    #[test]
    fn test_embedder_load_when_uninitialized() {
        let mut embedder = ServoEmbedder {
            flatland_session: None,
            view_ref: None,
            event_queue: Arc::new(Mutex::new(Vec::new())),
            v8_runtime: None,
            webview: None,
            current_url: None,
            state: EmbedderState::Uninitialized,
        };
        
        let result = embedder.load_url("https://example.com");
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("not ready"));
    }

    #[test]
    fn test_embedder_load_when_initializing() {
        let mut embedder = ServoEmbedder {
            flatland_session: None,
            view_ref: None,
            event_queue: Arc::new(Mutex::new(Vec::new())),
            v8_runtime: None,
            webview: None,
            current_url: None,
            state: EmbedderState::Initializing,
        };
        
        let result = embedder.load_url("https://example.com");
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("not ready"));
    }

    #[test]
    fn test_embedder_repeated_loads() {
        let mut embedder = ServoEmbedder::new().expect("Should initialize");
        
        assert!(embedder.load_url("https://first.com").is_ok());
        assert_eq!(embedder.get_state(), &EmbedderState::Running);
        assert_eq!(embedder.get_current_url(), Some(&"https://first.com".to_string()));
        
        assert!(embedder.load_url("https://second.com").is_ok());
        assert_eq!(embedder.get_state(), &EmbedderState::Running);
        assert_eq!(embedder.get_current_url(), Some(&"https://second.com".to_string()));
    }

    #[test]
    fn test_embedder_load_invalid_url() {
        let mut embedder = ServoEmbedder::new().expect("Should initialize");
        
        assert!(embedder.load_url("").is_err());
        assert_eq!(embedder.get_state(), &EmbedderState::Ready);
        assert_eq!(embedder.get_current_url(), None);
    }

    #[test]
    fn test_embedder_load_url_no_scheme() {
        let mut embedder = ServoEmbedder::new().expect("Should initialize");
        
        let result = embedder.load_url("example.com");
        assert!(result.is_err());
        assert_eq!(embedder.get_state(), &EmbedderState::Ready);
    }

    #[test]
    fn test_embedder_state_remains_running_after_multiple_loads() {
        let mut embedder = ServoEmbedder::new().expect("Should initialize");
        
        for i in 0..5 {
            let url = format!("https://example{}.com", i);
            assert!(embedder.load_url(&url).is_ok());
            assert_eq!(embedder.get_state(), &EmbedderState::Running);
        }
    }

    #[test]
    fn test_embedder_error_state() {
        let embedder = ServoEmbedder {
            flatland_session: None,
            view_ref: None,
            event_queue: Arc::new(Mutex::new(Vec::new())),
            v8_runtime: None,
            webview: None,
            current_url: None,
            state: EmbedderState::Error("Test error".to_string()),
        };
        
        assert_eq!(embedder.get_state(), &EmbedderState::Error("Test error".to_string()));
    }

    #[test]
    fn test_url_validation_edge_cases() {
        assert!(validate_url("https://").is_err());
        assert!(validate_url("https://a.b").is_ok());
        assert!(validate_url("https://example.com:8080").is_ok());
        assert!(validate_url("https://example.com/path?query=value#fragment").is_ok());
    }
}
