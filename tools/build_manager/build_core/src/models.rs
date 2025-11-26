use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum BuildSystem {
    GN,
    Bazel,
    Cargo,
}

impl std::fmt::Display for BuildSystem {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BuildSystem::GN => write!(f, "gn"),
            BuildSystem::Bazel => write!(f, "bazel"),
            BuildSystem::Cargo => write!(f, "cargo"),
        }
    }
}

impl std::str::FromStr for BuildSystem {
    type Err = crate::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "gn" => Ok(BuildSystem::GN),
            "bazel" => Ok(BuildSystem::Bazel),
            "cargo" => Ok(BuildSystem::Cargo),
            _ => Err(crate::Error::InvalidArgument(format!("Unknown build system: {}", s))),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum BuildStatus {
    Pending,
    Running,
    Success,
    Failed,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildRequest {
    pub target: String,
    pub system: BuildSystem,
    pub options: BuildOptions,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildOptions {
    pub clean: bool,
    pub parallel_jobs: Option<usize>,
    pub verbose: bool,
    pub profile: Option<String>,
    pub extra_args: Vec<String>,
}

impl Default for BuildOptions {
    fn default() -> Self {
        Self {
            clean: false,
            parallel_jobs: None,
            verbose: false,
            profile: None,
            extra_args: Vec::new(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Build {
    pub id: String,
    pub target: String,
    pub system: BuildSystem,
    pub status: BuildStatus,
    pub options: BuildOptions,
    pub start_time: DateTime<Utc>,
    pub end_time: Option<DateTime<Utc>>,
    pub output: Vec<String>,
    pub errors: Vec<BuildError>,
    pub warnings: Vec<BuildWarning>,
    pub metrics: BuildMetrics,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct BuildMetrics {
    pub duration_secs: Option<f64>,
    pub cpu_usage_percent: Option<f32>,
    pub memory_usage_mb: Option<u64>,
    pub disk_io_mb: Option<u64>,
    pub cache_hit_rate: Option<f32>,
    pub artifacts_generated: usize,
    pub artifacts_size_mb: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildError {
    pub message: String,
    pub file: Option<PathBuf>,
    pub line: Option<usize>,
    pub column: Option<usize>,
    pub suggestion: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildWarning {
    pub message: String,
    pub file: Option<PathBuf>,
    pub line: Option<usize>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Module {
    pub name: String,
    pub path: PathBuf,
    pub module_type: ModuleType,
    pub build_systems: Vec<BuildSystem>,
    pub dependencies: Vec<String>,
    pub reverse_dependencies: Vec<String>,
    pub source_files: Vec<PathBuf>,
    pub test_files: Vec<PathBuf>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum ModuleType {
    Library,
    Binary,
    Test,
    Driver,
    Shell,
    Generated,
    Other(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestRequest {
    pub pattern: Option<String>,
    pub category: Option<TestCategory>,
    pub module: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum TestCategory {
    Unit,
    Integration,
    System,
    All,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestRun {
    pub id: String,
    pub request: TestRequest,
    pub status: BuildStatus,
    pub start_time: DateTime<Utc>,
    pub end_time: Option<DateTime<Utc>>,
    pub results: Vec<TestResult>,
    pub summary: TestSummary,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TestSummary {
    pub total: usize,
    pub passed: usize,
    pub failed: usize,
    pub skipped: usize,
    pub duration_secs: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestResult {
    pub name: String,
    pub module: String,
    pub status: TestStatus,
    pub duration_secs: f64,
    pub output: Option<String>,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum TestStatus {
    Passed,
    Failed,
    Skipped,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildProfile {
    pub name: String,
    pub description: Option<String>,
    pub build_system: BuildSystem,
    pub targets: Vec<String>,
    pub options: BuildOptions,
    pub environment: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DependencyGraph {
    pub modules: HashMap<String, Module>,
    pub edges: Vec<DependencyEdge>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DependencyEdge {
    pub from: String,
    pub to: String,
    pub edge_type: DependencyType,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum DependencyType {
    Direct,
    Indirect,
    Test,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TranslationStatus {
    pub subsystem: String,
    pub total_files: usize,
    pub translated_files: usize,
    pub translation_complete: bool,
    pub tests_passing: Option<usize>,
    pub tests_total: Option<usize>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FidlLibrary {
    pub name: String,
    pub path: PathBuf,
    pub generated: bool,
    pub bindings_path: Option<PathBuf>,
}
