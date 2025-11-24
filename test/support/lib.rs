

//! Test support utilities for Soliloquy
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
