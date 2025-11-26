use async_trait::async_trait;
use std::path::PathBuf;
use std::process::Stdio;
use tokio::process::Command;
use tokio::io::{BufReader, AsyncBufReadExt};
use chrono::Utc;
use crate::{
    Result, Error,
    models::*,
};
use super::BuildSystemTrait;

pub struct CargoSystem {
    project_root: PathBuf,
}

impl CargoSystem {
    pub fn new(project_root: PathBuf) -> Self {
        Self { project_root }
    }

    async fn run_command(&self, args: &[&str]) -> Result<Vec<String>> {
        let mut cmd = Command::new("cargo");
        cmd.current_dir(&self.project_root);
        cmd.args(args);
        cmd.stdout(Stdio::piped());
        cmd.stderr(Stdio::piped());

        let mut child = cmd.spawn()
            .map_err(|e| Error::BuildSystem(format!("Failed to spawn cargo: {}", e)))?;

        let mut output_lines = Vec::new();

        if let Some(stdout) = child.stdout.take() {
            let reader = BufReader::new(stdout);
            let mut lines = reader.lines();
            
            while let Ok(Some(line)) = lines.next_line().await {
                output_lines.push(line);
            }
        }

        let status = child.wait().await
            .map_err(|e| Error::BuildSystem(format!("Failed to wait for cargo: {}", e)))?;

        if !status.success() {
            return Err(Error::BuildFailed("Cargo command failed".to_string()));
        }

        Ok(output_lines)
    }
}

#[async_trait]
impl BuildSystemTrait for CargoSystem {
    async fn build(&self, request: BuildRequest) -> Result<Build> {
        let start_time = Utc::now();
        let build_id = uuid::Uuid::new_v4().to_string();

        let mut args = vec!["build"];
        
        if let Some(jobs) = request.options.parallel_jobs {
            args.push("--jobs");
            args.push(&jobs.to_string());
        }

        if request.options.verbose {
            args.push("--verbose");
        }

        if !request.target.is_empty() && request.target != "all" {
            args.push("--package");
            args.push(&request.target);
        }

        args.extend(request.options.extra_args.iter().map(|s| s.as_str()));

        let output = self.run_command(&args).await;
        
        let (status, output_lines, errors) = match output {
            Ok(lines) => (BuildStatus::Success, lines, Vec::new()),
            Err(e) => (
                BuildStatus::Failed,
                Vec::new(),
                vec![BuildError {
                    message: e.to_string(),
                    file: None,
                    line: None,
                    column: None,
                    suggestion: None,
                }],
            ),
        };

        Ok(Build {
            id: build_id,
            target: request.target,
            system: BuildSystem::Cargo,
            status,
            options: request.options,
            start_time,
            end_time: Some(Utc::now()),
            output: output_lines,
            errors,
            warnings: Vec::new(),
            metrics: BuildMetrics::default(),
        })
    }

    async fn clean(&self, target: Option<String>) -> Result<()> {
        let mut args = vec!["clean"];
        if let Some(t) = target {
            args.push("--package");
            args.push(&t);
        }

        self.run_command(&args).await?;
        Ok(())
    }

    async fn test(&self, request: TestRequest) -> Result<TestRun> {
        let start_time = Utc::now();
        let test_id = uuid::Uuid::new_v4().to_string();

        let mut args = vec!["test"];
        
        if let Some(pattern) = &request.pattern {
            args.push(pattern);
        }

        if let Some(module) = &request.module {
            args.push("--package");
            args.push(module);
        }

        let output = self.run_command(&args).await;
        
        let (status, results) = match output {
            Ok(_) => (BuildStatus::Success, Vec::new()),
            Err(_) => (BuildStatus::Failed, Vec::new()),
        };

        Ok(TestRun {
            id: test_id,
            request,
            status,
            start_time,
            end_time: Some(Utc::now()),
            results,
            summary: TestSummary::default(),
        })
    }

    async fn list_targets(&self) -> Result<Vec<String>> {
        let metadata = self.run_command(&["metadata", "--format-version", "1"]).await?;
        Ok(metadata)
    }

    async fn query_dependencies(&self, target: &str) -> Result<Vec<String>> {
        let args = vec!["tree", "--package", target];
        let output = self.run_command(&args).await?;
        Ok(output)
    }

    async fn get_build_files(&self) -> Result<Vec<PathBuf>> {
        let mut build_files = Vec::new();
        
        for entry in walkdir::WalkDir::new(&self.project_root)
            .follow_links(false)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let file_name = entry.file_name().to_string_lossy();
            if file_name == "Cargo.toml" {
                build_files.push(entry.path().to_path_buf());
            }
        }

        Ok(build_files)
    }

    fn name(&self) -> &str {
        "cargo"
    }
}
