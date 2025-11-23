// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[tauri::command]
fn get_soliloquy_info() -> serde_json::Value {
    serde_json::json!({
        "name": "Soliloquy OS",
        "version": "0.1.0",
        "kernel": "Zircon",
        "browser_engine": "Servo",
        "js_runtime": "V8",
        "graphics": "WebRender + Vulkan",
        "target_hardware": "Radxa Cubie A5E"
    })
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![greet, get_soliloquy_info])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}