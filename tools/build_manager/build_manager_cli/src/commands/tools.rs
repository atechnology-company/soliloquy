use clap::{Args, Subcommand};
use anyhow::Result;
use colored::*;
use std::process::Command;

#[derive(Subcommand)]
pub enum FidlCommands {
    Generate(GenerateCommand),
    List(ListCommand),
}

#[derive(Subcommand)]
pub enum C2vCommands {
    Translate(TranslateCommand),
    Status(StatusCommand),
}

#[derive(Args)]
pub struct GenerateCommand {
    #[arg(help = "FIDL library name (optional, generates all if not provided)")]
    pub library: Option<String>,
}

#[derive(Args)]
pub struct ListCommand {}

#[derive(Args)]
pub struct TranslateCommand {
    #[arg(help = "Subsystem to translate")]
    pub subsystem: String,

    #[arg(long, help = "Dry run (show what would be translated)")]
    pub dry_run: bool,

    #[arg(long, help = "Output directory")]
    pub out_dir: Option<String>,
}

#[derive(Args)]
pub struct StatusCommand {}

pub async fn handle_fidl(command: FidlCommands) -> Result<()> {
    match command {
        FidlCommands::Generate(cmd) => fidl_generate(cmd).await,
        FidlCommands::List(_) => fidl_list().await,
    }
}

pub async fn handle_c2v(command: C2vCommands) -> Result<()> {
    match command {
        C2vCommands::Translate(cmd) => c2v_translate(cmd).await,
        C2vCommands::Status(_) => c2v_status().await,
    }
}

async fn fidl_generate(cmd: GenerateCommand) -> Result<()> {
    println!("{} Generating FIDL bindings...", "🔧".yellow());
    
    let project_root = std::env::current_dir()?;
    let script = project_root.join("tools/soliloquy/gen_fidl_bindings.sh");
    
    if !script.exists() {
        eprintln!("{} Script not found: {}", "✗".red(), script.display());
        return Ok(());
    }

    let mut command = Command::new(&script);
    
    if let Some(lib) = cmd.library {
        command.arg(&lib);
    }

    let status = command.status()?;
    
    if status.success() {
        println!("{} FIDL bindings generated successfully!", "✓".green());
    } else {
        eprintln!("{} FIDL generation failed", "✗".red());
    }
    
    Ok(())
}

async fn fidl_list() -> Result<()> {
    println!("{} Available FIDL libraries:", "ℹ".blue());
    println!("  • fuchsia.ui.composition");
    println!("  • fuchsia.ui.views");
    println!("  • fuchsia.input");
    Ok(())
}

async fn c2v_translate(cmd: TranslateCommand) -> Result<()> {
    println!("{} Translating {} to V...", "🔄".yellow(), cmd.subsystem.cyan());
    
    let project_root = std::env::current_dir()?;
    let script = project_root.join("tools/soliloquy/c2v_pipeline.sh");
    
    if !script.exists() {
        eprintln!("{} Script not found: {}", "✗".red(), script.display());
        return Ok(());
    }

    let mut command = Command::new(&script);
    command.arg("--subsystem").arg(&cmd.subsystem);
    
    if cmd.dry_run {
        command.arg("--dry-run");
    }
    
    if let Some(out_dir) = cmd.out_dir {
        command.arg("--out-dir").arg(out_dir);
    }

    let status = command.status()?;
    
    if status.success() {
        println!("{} Translation completed successfully!", "✓".green());
    } else {
        eprintln!("{} Translation failed", "✗".red());
    }
    
    Ok(())
}

async fn c2v_status() -> Result<()> {
    println!("\n{}", "C-to-V Translation Status".bold());
    println!("─────────────────────────────");
    println!("  {} kernel/vm - COMPLETE", "✓".green());
    println!("  {} kernel/lib/libc - Not started", "○".bright_black());
    println!("  {} kernel/lib/ktl - Not started", "○".bright_black());
    Ok(())
}
