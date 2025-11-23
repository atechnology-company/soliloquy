// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

mod zircon_window;
mod servo_embedder;
mod v8_runtime;

#[cfg(test)]
mod integration_tests;

use fuchsia_component::server::ServiceFs;
use fuchsia_async as fasync;
use futures::StreamExt;
use log::{info, error, debug};
use servo_embedder::{ServoEmbedder, InputEvent};
use zircon_window::ZirconWindow;

#[fasync::run_singlethreaded]
async fn main() {
    fuchsia_syslog::init().unwrap();
    info!("Soliloquy Shell starting...");

    // Initialize Servo embedder
    let mut embedder = match ServoEmbedder::new() {
        Ok(embedder) => {
            info!("Servo embedder initialized successfully");
            embedder
        }
        Err(e) => {
            error!("Failed to initialize Servo embedder: {}", e);
            return;
        }
    };

    // Load initial URL
    match embedder.load_url("https://example.com") {
        Ok(_) => info!("Initial URL loaded successfully"),
        Err(e) => error!("Failed to load initial URL: {}", e),
    }

    // Test V8 execution
    match embedder.execute_js("console.log('V8 is working in Soliloquy!'); 'V8 Test Success'") {
        Ok(result) => info!("V8 test result: {}", result),
        Err(e) => error!("V8 test failed: {}", e),
    }

    // Initialize Window
    let window = ZirconWindow::new();
    
    // Simulate some input events for testing
    embedder.handle_input(InputEvent::Touch { x: 100.0, y: 200.0 });
    embedder.handle_input(InputEvent::Key { code: 13 }); // Enter key

    // Present a frame
    match embedder.present() {
        Ok(_) => debug!("Frame presented successfully"),
        Err(e) => error!("Failed to present frame: {}", e),
    }

    // Print embedder state
    info!("Embedder state: {:?}", embedder.get_state());
    if let Some(url) = embedder.get_current_url() {
        info!("Current URL: {}", url);
    }
    
    if let Some(webview_info) = embedder.get_webview_info() {
        info!("Webview info: {:?}", webview_info);
    }

    let mut fs = ServiceFs::new_local();
    
    // TODO: Expose services if needed
    // fs.take_and_serve_directory_handle().unwrap();

    info!("Soliloquy Shell running.");
    
    // Keep the component running
    fs.collect::<()>().await;
}
