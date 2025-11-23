// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//! Test support utilities for Soliloquy OS
//! 
//! This crate provides mock FIDL servers and common assertion helpers
//! for testing Soliloquy components.

#[path = "src/mocks/mod.rs"]
pub mod mocks;
#[path = "src/assertions.rs"]
pub mod assertions;

pub use mocks::flatland::MockFlatland;
pub use mocks::touch_source::MockTouchSource;
pub use mocks::view_provider::MockViewProvider;
