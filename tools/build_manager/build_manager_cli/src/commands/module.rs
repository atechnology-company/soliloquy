use clap::{Args, Subcommand};
use anyhow::Result;
use colored::*;
use soliloquy_build_core::{BuildManager, Config};

#[derive(Subcommand)]
pub enum ModuleCommands {
    List(ListCommand),
    Info(InfoCommand),
    Deps(DepsCommand),
    Build(BuildModuleCommand),
}

#[derive(Args)]
pub struct ListCommand {
    #[arg(long, help = "Filter by module type")]
    pub filter: Option<String>,
}

#[derive(Args)]
pub struct InfoCommand {
    #[arg(help = "Module name")]
    pub name: String,
}

#[derive(Args)]
pub struct DepsCommand {
    #[arg(help = "Module name")]
    pub name: String,

    #[arg(long, help = "Show reverse dependencies")]
    pub reverse: bool,
}

#[derive(Args)]
pub struct BuildModuleCommand {
    #[arg(help = "Module name")]
    pub name: String,
}

pub async fn handle(command: ModuleCommands) -> Result<()> {
    match command {
        ModuleCommands::List(cmd) => list(cmd).await,
        ModuleCommands::Info(cmd) => info(cmd).await,
        ModuleCommands::Deps(cmd) => deps(cmd).await,
        ModuleCommands::Build(cmd) => build(cmd).await,
    }
}

async fn list(cmd: ListCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config).await?;
    
    let modules = manager.module_manager().list_modules().await;
    
    println!("{} Found {} modules\n", "✓".green(), modules.len());
    
    for module in modules {
        if let Some(ref filter) = cmd.filter {
            if !module.name.contains(filter) {
                continue;
            }
        }
        
        println!("  {} {}", "•".cyan(), module.name.bold());
        println!("    Path: {}", module.path.display().to_string().bright_black());
    }
    
    Ok(())
}

async fn info(cmd: InfoCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config).await?;
    
    match manager.module_manager().get_module(&cmd.name).await {
        Ok(module) => {
            println!("\n{}", module.name.bold().cyan());
            println!("─────────────────────────────");
            println!("  Path:         {}", module.path.display());
            println!("  Type:         {:?}", module.module_type);
            println!("  Build Systems: {:?}", module.build_systems);
            println!("  Dependencies: {}", module.dependencies.len());
            println!("  Source Files: {}", module.source_files.len());
            println!("  Test Files:   {}", module.test_files.len());
        }
        Err(e) => {
            eprintln!("{} Module not found: {}", "✗".red(), e);
            std::process::exit(1);
        }
    }
    
    Ok(())
}

async fn deps(cmd: DepsCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config).await?;
    
    let deps = if cmd.reverse {
        manager.module_manager().get_reverse_dependencies(&cmd.name).await?
    } else {
        manager.module_manager().get_dependencies(&cmd.name).await?
    };
    
    let label = if cmd.reverse { "Reverse Dependencies" } else { "Dependencies" };
    
    println!("\n{} for {}", label.bold(), cmd.name.cyan());
    println!("─────────────────────────────");
    
    if deps.is_empty() {
        println!("  None");
    } else {
        for dep in deps {
            println!("  • {}", dep);
        }
    }
    
    Ok(())
}

async fn build(_cmd: BuildModuleCommand) -> Result<()> {
    println!("{} Module build not yet implemented", "⚠".yellow());
    Ok(())
}
