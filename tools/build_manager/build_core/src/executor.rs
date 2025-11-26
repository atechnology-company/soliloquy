use std::sync::Arc;
use tokio::sync::RwLock;
use dashmap::DashMap;
use crate::{
    Result, Error,
    models::*,
    config::Config,
    analytics::Analytics,
    build_systems::{self, BuildSystemTrait},
};

pub struct BuildExecutor {
    config: Arc<RwLock<Config>>,
    analytics: Arc<Analytics>,
    active_builds: DashMap<String, Arc<RwLock<Build>>>,
}

impl BuildExecutor {
    pub async fn new(
        config: Arc<RwLock<Config>>,
        analytics: Arc<Analytics>,
    ) -> Result<Self> {
        Ok(Self {
            config,
            analytics,
            active_builds: DashMap::new(),
        })
    }

    pub async fn start_build(&self, request: BuildRequest) -> Result<String> {
        let config = self.config.read().await;
        let project_root = config.general.project_root.clone();
        drop(config);

        let build_system = build_systems::get_build_system(&request.system, project_root)?;
        
        let build = build_system.build(request).await?;
        let build_id = build.id.clone();
        
        self.analytics.record_build(&build).await?;
        
        Ok(build_id)
    }

    pub async fn get_build_status(&self, build_id: &str) -> Result<BuildStatus> {
        if let Some(build) = self.active_builds.get(build_id) {
            let build = build.read().await;
            Ok(build.status.clone())
        } else {
            self.analytics.get_build_status(build_id).await
        }
    }

    pub async fn get_build(&self, build_id: &str) -> Result<Build> {
        if let Some(build) = self.active_builds.get(build_id) {
            let build = build.read().await;
            Ok(build.clone())
        } else {
            self.analytics.get_build(build_id).await
        }
    }

    pub async fn list_active_builds(&self) -> Vec<String> {
        self.active_builds.iter().map(|entry| entry.key().clone()).collect()
    }

    pub async fn cancel_build(&self, build_id: &str) -> Result<()> {
        if let Some(build_ref) = self.active_builds.get(build_id) {
            let mut build = build_ref.write().await;
            build.status = BuildStatus::Cancelled;
            Ok(())
        } else {
            Err(Error::InvalidArgument(format!("Build not found: {}", build_id)))
        }
    }

    pub async fn clean(&self, system: BuildSystem, target: Option<String>) -> Result<()> {
        let config = self.config.read().await;
        let project_root = config.general.project_root.clone();
        drop(config);

        let build_system = build_systems::get_build_system(&system, project_root)?;
        build_system.clean(target).await
    }
}
