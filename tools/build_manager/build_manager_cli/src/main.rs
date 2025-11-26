mod commands;

use clap::{Parser, Subcommand};
use anyhow::Result;

#[derive(Parser)]
#[command(name = "soliloquy-build")]
#[command(about = "Soliloquy OS Build Manager CLI", long_about = None)]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Start(commands::build::StartCommand),
    
    Stop(commands::build::StopCommand),
    
    Status(commands::build::StatusCommand),
    
    Clean(commands::build::CleanCommand),
    
    Module {
        #[command(subcommand)]
        command: commands::module::ModuleCommands,
    },
    
    Test {
        #[command(subcommand)]
        command: commands::test::TestCommands,
    },
    
    Fidl {
        #[command(subcommand)]
        command: commands::tools::FidlCommands,
    },
    
    C2v {
        #[command(subcommand)]
        command: commands::tools::C2vCommands,
    },
    
    Env {
        #[command(subcommand)]
        command: commands::env::EnvCommands,
    },
    
    Stats(commands::analytics::StatsCommand),
    
    History(commands::analytics::HistoryCommand),
    
    Compare(commands::analytics::CompareCommand),
    
    Profile {
        #[command(subcommand)]
        command: commands::profile::ProfileCommands,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Start(cmd) => commands::build::start(cmd).await,
        Commands::Stop(cmd) => commands::build::stop(cmd).await,
        Commands::Status(cmd) => commands::build::status(cmd).await,
        Commands::Clean(cmd) => commands::build::clean(cmd).await,
        Commands::Module { command } => commands::module::handle(command).await,
        Commands::Test { command } => commands::test::handle(command).await,
        Commands::Fidl { command } => commands::tools::handle_fidl(command).await,
        Commands::C2v { command } => commands::tools::handle_c2v(command).await,
        Commands::Env { command } => commands::env::handle(command).await,
        Commands::Stats(cmd) => commands::analytics::stats(cmd).await,
        Commands::History(cmd) => commands::analytics::history(cmd).await,
        Commands::Compare(cmd) => commands::analytics::compare(cmd).await,
        Commands::Profile { command } => commands::profile::handle(command).await,
    }
}
