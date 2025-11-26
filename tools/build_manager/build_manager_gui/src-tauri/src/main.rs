#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;

use soliloquy_build_core::{BuildManager, Config};
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct AppState {
    manager: Arc<RwLock<Option<BuildManager>>>,
}

#[tokio::main]
async fn main() {
    let app_state = AppState {
        manager: Arc::new(RwLock::new(None)),
    };

    tauri::Builder::default()
        .manage(app_state)
        .invoke_handler(tauri::generate_handler![
            commands::init_manager,
            commands::start_build,
            commands::stop_build,
            commands::get_build_status,
            commands::get_build,
            commands::list_active_builds,
            commands::clean_build,
            commands::list_modules,
            commands::get_module_info,
            commands::get_dependencies,
            commands::get_dependency_graph,
            commands::get_statistics,
            commands::get_build_history,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
