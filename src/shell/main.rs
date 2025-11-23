// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

mod zircon_window;
mod servo_embedder;

use fuchsia_component::server::ServiceFs;
use fuchsia_async as fasync;
use futures::StreamExt;
use log::{info, error};
use servo_embedder::ServoEmbedder;
use zircon_window::ZirconWindow;

#[fasync::run_singlethreaded]
async fn main() {
    fuchsia_syslog::init().unwrap();
    info!("Soliloquy Shell starting...");

    // Initialize Servo embedder
    let embedder = ServoEmbedder::new();
    embedder.load_url("https://example.com");

    // Initialize Window
    let window = ZirconWindow::new();
    // window.present(); // Placeholder

    let mut fs = ServiceFs::new_local();
    
    // TODO: Expose services if needed
    // fs.take_and_serve_directory_handle().unwrap();

    info!("Soliloquy Shell running.");
    
    // Keep the component running
    fs.collect::<()>().await;
}
