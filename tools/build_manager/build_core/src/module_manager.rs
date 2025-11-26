use std::sync::Arc;
use std::path::PathBuf;
use std::collections::HashMap;
use tokio::sync::RwLock;
use petgraph::Graph;
use petgraph::graph::NodeIndex;
use crate::{
    Result, Error,
    models::*,
    config::Config,
};

pub struct ModuleManager {
    config: Arc<RwLock<Config>>,
    modules: Arc<RwLock<HashMap<String, Module>>>,
    dependency_graph: Arc<RwLock<Graph<String, DependencyType>>>,
}

impl ModuleManager {
    pub async fn new(config: Arc<RwLock<Config>>) -> Result<Self> {
        let manager = Self {
            config,
            modules: Arc::new(RwLock::new(HashMap::new())),
            dependency_graph: Arc::new(RwLock::new(Graph::new())),
        };

        manager.discover_modules().await?;
        
        Ok(manager)
    }

    async fn discover_modules(&self) -> Result<()> {
        let config = self.config.read().await;
        let project_root = config.general.project_root.clone();
        drop(config);

        let mut modules = HashMap::new();

        for entry in walkdir::WalkDir::new(&project_root)
            .follow_links(false)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            let file_name = entry.file_name().to_string_lossy();

            if file_name == "BUILD.bazel" || file_name == "BUILD.gn" || file_name == "Cargo.toml" {
                if let Some(module) = self.parse_module(path).await? {
                    modules.insert(module.name.clone(), module);
                }
            }
        }

        *self.modules.write().await = modules;
        
        Ok(())
    }

    async fn parse_module(&self, build_file: &std::path::Path) -> Result<Option<Module>> {
        let file_name = build_file.file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("");

        let module_dir = build_file.parent().unwrap_or(build_file);
        let module_name = module_dir.file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("unknown")
            .to_string();

        let mut build_systems = Vec::new();
        match file_name {
            "BUILD.bazel" => build_systems.push(BuildSystem::Bazel),
            "BUILD.gn" => build_systems.push(BuildSystem::GN),
            "Cargo.toml" => build_systems.push(BuildSystem::Cargo),
            _ => {}
        }

        let source_files = self.find_source_files(module_dir).await?;
        let test_files = self.find_test_files(module_dir).await?;

        Ok(Some(Module {
            name: module_name,
            path: module_dir.to_path_buf(),
            module_type: ModuleType::Library,
            build_systems,
            dependencies: Vec::new(),
            reverse_dependencies: Vec::new(),
            source_files,
            test_files,
        }))
    }

    async fn find_source_files(&self, dir: &std::path::Path) -> Result<Vec<PathBuf>> {
        let mut files = Vec::new();
        
        for entry in walkdir::WalkDir::new(dir)
            .max_depth(2)
            .follow_links(false)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            if entry.file_type().is_file() {
                if let Some(ext) = entry.path().extension() {
                    let ext_str = ext.to_string_lossy();
                    if ext_str == "rs" || ext_str == "cc" || ext_str == "cpp" || 
                       ext_str == "c" || ext_str == "v" {
                        files.push(entry.path().to_path_buf());
                    }
                }
            }
        }

        Ok(files)
    }

    async fn find_test_files(&self, dir: &std::path::Path) -> Result<Vec<PathBuf>> {
        let mut files = Vec::new();
        
        for entry in walkdir::WalkDir::new(dir)
            .max_depth(2)
            .follow_links(false)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            if entry.file_type().is_file() {
                let file_name = entry.file_name().to_string_lossy();
                if file_name.contains("test") {
                    files.push(entry.path().to_path_buf());
                }
            }
        }

        Ok(files)
    }

    pub async fn get_module(&self, name: &str) -> Result<Module> {
        let modules = self.modules.read().await;
        modules.get(name)
            .cloned()
            .ok_or_else(|| Error::ModuleNotFound(name.to_string()))
    }

    pub async fn list_modules(&self) -> Vec<Module> {
        let modules = self.modules.read().await;
        modules.values().cloned().collect()
    }

    pub async fn get_dependencies(&self, module_name: &str) -> Result<Vec<String>> {
        let module = self.get_module(module_name).await?;
        Ok(module.dependencies)
    }

    pub async fn get_reverse_dependencies(&self, module_name: &str) -> Result<Vec<String>> {
        let module = self.get_module(module_name).await?;
        Ok(module.reverse_dependencies)
    }

    pub async fn get_dependency_graph(&self) -> Result<DependencyGraph> {
        let modules = self.modules.read().await;
        let mut edges = Vec::new();

        for module in modules.values() {
            for dep in &module.dependencies {
                edges.push(DependencyEdge {
                    from: module.name.clone(),
                    to: dep.clone(),
                    edge_type: DependencyType::Direct,
                });
            }
        }

        Ok(DependencyGraph {
            modules: modules.clone(),
            edges,
        })
    }

    pub async fn refresh(&self) -> Result<()> {
        self.discover_modules().await
    }
}
