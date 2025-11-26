use clap::{Args, Subcommand};
use anyhow::Result;
use colored::*;
use std::process::Command;

#[derive(Subcommand)]
pub enum EnvCommands {
    Setup(SetupCommand),
    Check(CheckCommand),
}

#[derive(Args)]
pub struct SetupCommand {
    #[arg(long, help = "SDK only (skip full source checkout)")]
    pub sdk_only: bool,
}

#[derive(Args)]
pub struct CheckCommand {}

pub async fn handle(command: EnvCommands) -> Result<()> {
    match command {
        EnvCommands::Setup(cmd) => setup(cmd).await,
        EnvCommands::Check(_) => check().await,
    }
}

async fn setup(cmd: SetupCommand) -> Result<()> {
    let project_root = std::env::current_dir()?;
    
    let script = if cmd.sdk_only {
        project_root.join("tools/soliloquy/setup_sdk.sh")
    } else {
        project_root.join("tools/soliloquy/setup.sh")
    };
    
    if !script.exists() {
        eprintln!("{} Script not found: {}", "✗".red(), script.display());
        return Ok(());
    }

    println!("{} Setting up environment...", "🔧".yellow());
    
    let status = Command::new(&script).status()?;
    
    if status.success() {
        println!("{} Environment setup complete!", "✓".green());
        println!("\n  Run: source tools/soliloquy/env.sh");
    } else {
        eprintln!("{} Setup failed", "✗".red());
    }
    
    Ok(())
}

async fn check() -> Result<()> {
    println!("\n{}", "Environment Check".bold());
    println!("─────────────────────────────");
    
    check_command("gn", "GN");
    check_command("ninja", "Ninja");
    check_command("bazel", "Bazel");
    check_command("cargo", "Cargo");
    check_env_var("FUCHSIA_DIR");
    check_env_var("V_HOME");
    
    Ok(())
}

fn check_command(cmd: &str, name: &str) {
    match Command::new("which").arg(cmd).output() {
        Ok(output) if output.status.success() => {
            let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
            println!("  {} {}: {}", "✓".green(), name, path.bright_black());
        }
        _ => {
            println!("  {} {}: not found", "✗".red(), name);
        }
    }
}

fn check_env_var(var: &str) {
    match std::env::var(var) {
        Ok(value) => {
            println!("  {} {}: {}", "✓".green(), var, value.bright_black());
        }
        Err(_) => {
            println!("  {} {}: not set", "⚠".yellow(), var);
        }
    }
}
