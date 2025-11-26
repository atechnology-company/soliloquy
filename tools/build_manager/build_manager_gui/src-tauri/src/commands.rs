use crate::AppState;
use soliloquy_build_core::{BuildManager, Config, models::*, Result as CoreResult};
use serde_json::Value;
use tauri::State;

#[tauri::command]
pub async fn init_manager(state: State<'_, AppState>) -> Result<(), String> {
    let config = Config::load().map_err(|e| e.to_string())?;
    let manager = BuildManager::new(config).await.map_err(|e| e.to_string())?;
    
    *state.manager.write().await = Some(manager);
    
    Ok(())
}

#[tauri::command]
pub async fn start_build(
    state: State<'_, AppState>,
    target: String,
    system: String,
    options: Value,
) -> Result<String, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    let system: BuildSystem = system.parse().map_err(|e: soliloquy_build_core::Error| e.to_string())?;
    
    let build_options: BuildOptions = serde_json::from_value(options)
        .map_err(|e| e.to_string())?;
    
    let request = BuildRequest {
        target,
        system,
        options: build_options,
    };
    
    manager.executor().start_build(request).await.map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn stop_build(
    state: State<'_, AppState>,
    build_id: String,
) -> Result<(), String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    manager.executor().cancel_build(&build_id).await.map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_build_status(
    state: State<'_, AppState>,
    build_id: String,
) -> Result<Value, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    let status = manager.executor().get_build_status(&build_id).await.map_err(|e| e.to_string())?;
    
    serde_json::to_value(&status).map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_build(
    state: State<'_, AppState>,
    build_id: String,
) -> Result<Value, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    let build = manager.executor().get_build(&build_id).await.map_err(|e| e.to_string())?;
    
    serde_json::to_value(&build).map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn list_active_builds(
    state: State<'_, AppState>,
) -> Result<Vec<String>, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    Ok(manager.executor().list_active_builds().await)
}

#[tauri::command]
pub async fn clean_build(
    state: State<'_, AppState>,
    system: String,
    target: Option<String>,
) -> Result<(), String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    let system: BuildSystem = system.parse().map_err(|e: soliloquy_build_core::Error| e.to_string())?;
    
    manager.executor().clean(system, target).await.map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn list_modules(
    state: State<'_, AppState>,
) -> Result<Value, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    let modules = manager.module_manager().list_modules().await;
    
    serde_json::to_value(&modules).map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_module_info(
    state: State<'_, AppState>,
    name: String,
) -> Result<Value, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    let module = manager.module_manager().get_module(&name).await.map_err(|e| e.to_string())?;
    
    serde_json::to_value(&module).map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_dependencies(
    state: State<'_, AppState>,
    module_name: String,
) -> Result<Vec<String>, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    manager.module_manager().get_dependencies(&module_name).await.map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_dependency_graph(
    state: State<'_, AppState>,
) -> Result<Value, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    let graph = manager.module_manager().get_dependency_graph().await.map_err(|e| e.to_string())?;
    
    serde_json::to_value(&graph).map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_statistics(
    state: State<'_, AppState>,
) -> Result<Value, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    let stats = manager.analytics().get_statistics().await.map_err(|e| e.to_string())?;
    
    serde_json::to_value(&stats).map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_build_history(
    state: State<'_, AppState>,
    days: u32,
) -> Result<Value, String> {
    let manager_lock = state.manager.read().await;
    let manager = manager_lock.as_ref().ok_or("Manager not initialized")?;
    
    let history = manager.analytics().get_build_history(days).await.map_err(|e| e.to_string())?;
    
    serde_json::to_value(&history).map_err(|e| e.to_string())
}
