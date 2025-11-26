use std::sync::Arc;
use tokio::sync::RwLock;
use sqlx::{SqlitePool, sqlite::SqliteConnectOptions};
use chrono::{DateTime, Utc};
use crate::{
    Result, Error,
    models::*,
    config::Config,
};

pub struct Analytics {
    config: Arc<RwLock<Config>>,
    pool: SqlitePool,
}

impl Analytics {
    pub async fn new(config: Arc<RwLock<Config>>) -> Result<Self> {
        let db_path = Self::database_path()?;
        
        if let Some(parent) = db_path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }

        let options = SqliteConnectOptions::new()
            .filename(&db_path)
            .create_if_missing(true);

        let pool = SqlitePool::connect_with(options).await?;

        let analytics = Self {
            config,
            pool,
        };

        analytics.initialize_schema().await?;

        Ok(analytics)
    }

    async fn initialize_schema(&self) -> Result<()> {
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS builds (
                id TEXT PRIMARY KEY,
                target TEXT NOT NULL,
                system TEXT NOT NULL,
                status TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT,
                duration_secs REAL,
                cpu_usage REAL,
                memory_usage INTEGER,
                success INTEGER NOT NULL
            )
            "#,
        )
        .execute(&self.pool)
        .await?;

        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS build_errors (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                build_id TEXT NOT NULL,
                message TEXT NOT NULL,
                file TEXT,
                line INTEGER,
                FOREIGN KEY (build_id) REFERENCES builds(id)
            )
            "#,
        )
        .execute(&self.pool)
        .await?;

        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS test_runs (
                id TEXT PRIMARY KEY,
                start_time TEXT NOT NULL,
                end_time TEXT,
                total INTEGER NOT NULL,
                passed INTEGER NOT NULL,
                failed INTEGER NOT NULL,
                skipped INTEGER NOT NULL,
                duration_secs REAL
            )
            "#,
        )
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn record_build(&self, build: &Build) -> Result<()> {
        let success = matches!(build.status, BuildStatus::Success);
        let duration = build.end_time
            .and_then(|end| Some((end - build.start_time).num_milliseconds() as f64 / 1000.0));

        sqlx::query(
            r#"
            INSERT INTO builds 
            (id, target, system, status, start_time, end_time, duration_secs, success)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(&build.id)
        .bind(&build.target)
        .bind(build.system.to_string())
        .bind(format!("{:?}", build.status))
        .bind(build.start_time.to_rfc3339())
        .bind(build.end_time.map(|t| t.to_rfc3339()))
        .bind(duration)
        .bind(success as i32)
        .execute(&self.pool)
        .await?;

        for error in &build.errors {
            sqlx::query(
                r#"
                INSERT INTO build_errors (build_id, message, file, line)
                VALUES (?, ?, ?, ?)
                "#,
            )
            .bind(&build.id)
            .bind(&error.message)
            .bind(error.file.as_ref().map(|p| p.to_string_lossy().to_string()))
            .bind(error.line.map(|l| l as i64))
            .execute(&self.pool)
            .await?;
        }

        Ok(())
    }

    pub async fn get_build(&self, build_id: &str) -> Result<Build> {
        let row = sqlx::query_as::<_, (String, String, String, String, String, Option<String>)>(
            "SELECT id, target, system, status, start_time, end_time FROM builds WHERE id = ?"
        )
        .bind(build_id)
        .fetch_optional(&self.pool)
        .await?
        .ok_or_else(|| Error::InvalidArgument(format!("Build not found: {}", build_id)))?;

        let system: BuildSystem = row.2.parse()?;
        let start_time = DateTime::parse_from_rfc3339(&row.4)
            .map_err(|e| Error::Parse(e.to_string()))?
            .with_timezone(&Utc);
        let end_time = row.5
            .as_ref()
            .and_then(|s| DateTime::parse_from_rfc3339(s).ok())
            .map(|dt| dt.with_timezone(&Utc));

        Ok(Build {
            id: row.0,
            target: row.1,
            system,
            status: match row.3.as_str() {
                "Success" => BuildStatus::Success,
                "Failed" => BuildStatus::Failed,
                "Cancelled" => BuildStatus::Cancelled,
                "Running" => BuildStatus::Running,
                _ => BuildStatus::Pending,
            },
            options: BuildOptions::default(),
            start_time,
            end_time,
            output: Vec::new(),
            errors: Vec::new(),
            warnings: Vec::new(),
            metrics: BuildMetrics::default(),
        })
    }

    pub async fn get_build_status(&self, build_id: &str) -> Result<BuildStatus> {
        let build = self.get_build(build_id).await?;
        Ok(build.status)
    }

    pub async fn get_build_history(&self, days: u32) -> Result<Vec<Build>> {
        let since = Utc::now() - chrono::Duration::days(days as i64);
        
        let rows = sqlx::query_as::<_, (String, String, String, String, String, Option<String>)>(
            "SELECT id, target, system, status, start_time, end_time 
             FROM builds 
             WHERE start_time >= ? 
             ORDER BY start_time DESC"
        )
        .bind(since.to_rfc3339())
        .fetch_all(&self.pool)
        .await?;

        let mut builds = Vec::new();
        for row in rows {
            let system: BuildSystem = row.2.parse()?;
            let start_time = DateTime::parse_from_rfc3339(&row.4)
                .map_err(|e| Error::Parse(e.to_string()))?
                .with_timezone(&Utc);
            let end_time = row.5
                .as_ref()
                .and_then(|s| DateTime::parse_from_rfc3339(s).ok())
                .map(|dt| dt.with_timezone(&Utc));

            builds.push(Build {
                id: row.0,
                target: row.1,
                system,
                status: match row.3.as_str() {
                    "Success" => BuildStatus::Success,
                    "Failed" => BuildStatus::Failed,
                    "Cancelled" => BuildStatus::Cancelled,
                    "Running" => BuildStatus::Running,
                    _ => BuildStatus::Pending,
                },
                options: BuildOptions::default(),
                start_time,
                end_time,
                output: Vec::new(),
                errors: Vec::new(),
                warnings: Vec::new(),
                metrics: BuildMetrics::default(),
            });
        }

        Ok(builds)
    }

    pub async fn get_statistics(&self) -> Result<BuildStatistics> {
        let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM builds")
            .fetch_one(&self.pool)
            .await?;

        let successful: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM builds WHERE success = 1")
            .fetch_one(&self.pool)
            .await?;

        let avg_duration: (Option<f64>,) = sqlx::query_as(
            "SELECT AVG(duration_secs) FROM builds WHERE duration_secs IS NOT NULL"
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(BuildStatistics {
            total_builds: total.0 as usize,
            successful_builds: successful.0 as usize,
            failed_builds: (total.0 - successful.0) as usize,
            average_duration_secs: avg_duration.0.unwrap_or(0.0),
        })
    }

    fn database_path() -> Result<std::path::PathBuf> {
        let data_dir = if cfg!(target_os = "macos") {
            dirs::home_dir()
                .ok_or_else(|| Error::Config("Could not find home directory".to_string()))?
                .join("Library/Application Support/soliloquy-build")
        } else {
            dirs::data_local_dir()
                .ok_or_else(|| Error::Config("Could not find data directory".to_string()))?
                .join("soliloquy-build")
        };

        Ok(data_dir.join("analytics.db"))
    }
}

#[derive(Debug, Clone)]
pub struct BuildStatistics {
    pub total_builds: usize,
    pub successful_builds: usize,
    pub failed_builds: usize,
    pub average_duration_secs: f64,
}
