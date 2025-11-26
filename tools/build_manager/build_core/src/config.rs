use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use crate::{Error, Result};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub general: GeneralConfig,
    pub build_systems: BuildSystemsConfig,
    pub cache: CacheConfig,
    pub notifications: NotificationsConfig,
    pub ui: UiConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneralConfig {
    pub project_root: PathBuf,
    pub default_build_system: String,
    pub parallel_jobs: usize,
    pub log_level: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildSystemsConfig {
    pub gn_path: String,
    pub ninja_path: String,
    pub bazel_path: String,
    pub cargo_path: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CacheConfig {
    pub enabled: bool,
    pub max_size_gb: u64,
    pub clean_threshold_days: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NotificationsConfig {
    pub enabled: bool,
    pub on_success: bool,
    pub on_failure: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UiConfig {
    pub theme: String,
    pub font_size: u16,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            general: GeneralConfig {
                project_root: std::env::current_dir().unwrap_or_default(),
                default_build_system: "bazel".to_string(),
                parallel_jobs: num_cpus::get(),
                log_level: "info".to_string(),
            },
            build_systems: BuildSystemsConfig {
                gn_path: "gn".to_string(),
                ninja_path: "ninja".to_string(),
                bazel_path: "bazel".to_string(),
                cargo_path: "cargo".to_string(),
            },
            cache: CacheConfig {
                enabled: true,
                max_size_gb: 50,
                clean_threshold_days: 30,
            },
            notifications: NotificationsConfig {
                enabled: true,
                on_success: true,
                on_failure: true,
            },
            ui: UiConfig {
                theme: "dark".to_string(),
                font_size: 14,
            },
        }
    }
}

impl Config {
    pub fn load() -> Result<Self> {
        let config_path = Self::config_path()?;
        
        if !config_path.exists() {
            let config = Self::default();
            config.save()?;
            return Ok(config);
        }

        let content = std::fs::read_to_string(&config_path)
            .map_err(|e| Error::Config(format!("Failed to read config: {}", e)))?;
        
        toml::from_str(&content)
            .map_err(|e| Error::Config(format!("Failed to parse config: {}", e)))
    }

    pub fn save(&self) -> Result<()> {
        let config_path = Self::config_path()?;
        
        if let Some(parent) = config_path.parent() {
            std::fs::create_dir_all(parent)
                .map_err(|e| Error::Config(format!("Failed to create config dir: {}", e)))?;
        }

        let content = toml::to_string_pretty(self)
            .map_err(|e| Error::Config(format!("Failed to serialize config: {}", e)))?;
        
        std::fs::write(&config_path, content)
            .map_err(|e| Error::Config(format!("Failed to write config: {}", e)))?;

        Ok(())
    }

    fn config_path() -> Result<PathBuf> {
        let config_dir = if cfg!(target_os = "macos") {
            dirs::home_dir()
                .ok_or_else(|| Error::Config("Could not find home directory".to_string()))?
                .join("Library/Application Support/soliloquy-build")
        } else {
            dirs::config_dir()
                .ok_or_else(|| Error::Config("Could not find config directory".to_string()))?
                .join("soliloquy-build")
        };

        Ok(config_dir.join("config.toml"))
    }
}

fn num_cpus() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4)
}
