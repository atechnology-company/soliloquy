pub mod build_systems;
pub mod module_manager;
pub mod executor;
pub mod analytics;
pub mod config;
pub mod error;
pub mod models;
pub mod utils;

pub use error::{Error, Result};
pub use config::Config;

use std::sync::Arc;
use tokio::sync::RwLock;

pub struct BuildManager {
    config: Arc<RwLock<Config>>,
    executor: Arc<executor::BuildExecutor>,
    module_manager: Arc<module_manager::ModuleManager>,
    analytics: Arc<analytics::Analytics>,
}

impl BuildManager {
    pub async fn new(config: Config) -> Result<Self> {
        let config = Arc::new(RwLock::new(config));
        
        let analytics = Arc::new(analytics::Analytics::new(config.clone()).await?);
        let module_manager = Arc::new(module_manager::ModuleManager::new(config.clone()).await?);
        let executor = Arc::new(executor::BuildExecutor::new(
            config.clone(),
            analytics.clone(),
        ).await?);

        Ok(Self {
            config,
            executor,
            module_manager,
            analytics,
        })
    }

    pub fn executor(&self) -> Arc<executor::BuildExecutor> {
        self.executor.clone()
    }

    pub fn module_manager(&self) -> Arc<module_manager::ModuleManager> {
        self.module_manager.clone()
    }

    pub fn analytics(&self) -> Arc<analytics::Analytics> {
        self.analytics.clone()
    }

    pub async fn config(&self) -> Config {
        self.config.read().await.clone()
    }

    pub async fn update_config(&self, config: Config) -> Result<()> {
        *self.config.write().await = config;
        Ok(())
    }
}
