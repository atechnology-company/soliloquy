//! V8 Runtime helper for Soliloquy Shell
//! 
//! This module provides a thin wrapper around rusty_v8 to simplify
//! V8 isolate creation and JavaScript execution.

use log::{info, error, debug};
use rusty_v8 as v8;
use std::sync::Mutex;

/// V8 Runtime context wrapper
pub struct V8Runtime {
    platform: Option<v8::SharedRef<v8::Platform>>,
    isolate: Option<v8::OwnedIsolate>,
    context: Option<v8::Global<v8::Context>>,
    // Mutex for thread safety in async contexts
    _lock: Mutex<()>,
}

impl V8Runtime {
    /// Create a new V8 runtime
    pub fn new() -> Result<Self, String> {
        info!("Initializing V8 runtime");
        
        // Initialize V8 platform
        let platform = v8::new_default_platform(0, false).make_shared();
        v8::V8::initialize_platform(platform.clone());
        v8::V8::initialize();
        
        // Create isolate
        let mut isolate = v8::Isolate::new(v8::CreateParams::default());
        
        // Create context
        let context = {
            let scope = &mut v8::HandleScope::new(&mut isolate);
            let context = v8::Context::new(scope);
            v8::Global::new(scope, context)
        };
        
        debug!("V8 runtime initialized successfully");
        
        Ok(V8Runtime {
            platform: Some(platform),
            isolate: Some(isolate),
            context: Some(context),
            _lock: Mutex::new(()),
        })
    }
    
    /// Execute JavaScript code and return the result
    pub fn execute_script(&mut self, script: &str) -> Result<String, String> {
        let isolate = self.isolate.as_mut().ok_or("Isolate not initialized")?;
        let context = self.context.as_ref().ok_or("Context not initialized")?;
        
        let scope = &mut v8::HandleScope::new(isolate);
        let context = v8::Local::new(scope, context);
        let scope = &mut v8::ContextScope::new(scope, context);
        
        // Create script source
        let source = v8::String::new(scope, script).ok_or("Failed to create string")?;
        
        // Compile script
        let script = v8::Script::compile(scope, source, None)
            .ok_or("Failed to compile script")?;
        
        // Run script
        let result = script.run(scope);
        
        match result {
            Some(value) => {
                // Convert result to string
                let result_str = value.to_rust_string_lossy(scope);
                debug!("Script executed successfully: {}", result_str);
                Ok(result_str)
            }
            None => {
                error!("Script execution returned undefined");
                Ok("undefined".to_string())
            }
        }
    }
    
    /// Check if the runtime is initialized
    pub fn is_initialized(&self) -> bool {
        self.isolate.is_some() && self.context.is_some()
    }
    
    /// Get V8 version information
    pub fn get_version() -> String {
        v8::V8::get_version().to_string()
    }
}

impl Drop for V8Runtime {
    fn drop(&mut self) {
        info!("Shutting down V8 runtime");
        // Clean up V8
        if let Some(_platform) = self.platform.take() {
            unsafe {
                v8::V8::dispose();
            }
            // Note: dispose_platform may not be available in all rusty_v8 versions
            // v8::V8::dispose_platform();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_v8_runtime_creation() {
        let runtime = V8Runtime::new();
        assert!(runtime.is_ok());
        
        let runtime = runtime.unwrap();
        assert!(runtime.is_initialized());
    }
    
    #[test]
    fn test_simple_script_execution() {
        let mut runtime = V8Runtime::new().unwrap();
        
        let result = runtime.execute_script("1 + 1");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "2");
    }
    
    #[test]
    fn test_console_log() {
        let mut runtime = V8Runtime::new().unwrap();
        
        let script = r#"
        var message = "Hello from V8!";
        message;
        "#;
        
        let result = runtime.execute_script(script);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "Hello from V8!");
    }
}