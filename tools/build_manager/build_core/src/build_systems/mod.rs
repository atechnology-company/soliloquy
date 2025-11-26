pub mod bazel;
pub mod gn;
pub mod cargo;

use async_trait::async_trait;
use crate::{Result, models::{Build, BuildRequest, TestRun, TestRequest}};
use std::path::PathBuf;

#[async_trait]
pub trait BuildSystemTrait: Send + Sync {
    async fn build(&self, request: BuildRequest) -> Result<Build>;
    
    async fn clean(&self, target: Option<String>) -> Result<()>;
    
    async fn test(&self, request: TestRequest) -> Result<TestRun>;
    
    async fn list_targets(&self) -> Result<Vec<String>>;
    
    async fn query_dependencies(&self, target: &str) -> Result<Vec<String>>;
    
    async fn get_build_files(&self) -> Result<Vec<PathBuf>>;
    
    fn name(&self) -> &str;
}

pub fn get_build_system(
    system: &crate::models::BuildSystem,
    project_root: PathBuf,
) -> Result<Box<dyn BuildSystemTrait>> {
    match system {
        crate::models::BuildSystem::Bazel => {
            Ok(Box::new(bazel::BazelSystem::new(project_root)))
        }
        crate::models::BuildSystem::GN => {
            Ok(Box::new(gn::GnSystem::new(project_root)))
        }
        crate::models::BuildSystem::Cargo => {
            Ok(Box::new(cargo::CargoSystem::new(project_root)))
        }
    }
}
