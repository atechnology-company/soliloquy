use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("Configuration error: {0}")]
    Config(String),

    #[error("Build system error: {0}")]
    BuildSystem(String),

    #[error("Module not found: {0}")]
    ModuleNotFound(String),

    #[error("Build failed: {0}")]
    BuildFailed(String),

    #[error("Test failed: {0}")]
    TestFailed(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Parse error: {0}")]
    Parse(String),

    #[error("Invalid argument: {0}")]
    InvalidArgument(String),

    #[error("Operation cancelled")]
    Cancelled,

    #[error("Unknown error: {0}")]
    Unknown(String),
}

pub type Result<T> = std::result::Result<T, Error>;
