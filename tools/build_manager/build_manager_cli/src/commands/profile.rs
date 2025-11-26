use clap::{Args, Subcommand};
use anyhow::Result;
use colored::*;

#[derive(Subcommand)]
pub enum ProfileCommands {
    Save(SaveCommand),
    Load(LoadCommand),
    List(ListCommand),
    Delete(DeleteCommand),
}

#[derive(Args)]
pub struct SaveCommand {
    #[arg(help = "Profile name")]
    pub name: String,
}

#[derive(Args)]
pub struct LoadCommand {
    #[arg(help = "Profile name")]
    pub name: String,
}

#[derive(Args)]
pub struct ListCommand {}

#[derive(Args)]
pub struct DeleteCommand {
    #[arg(help = "Profile name")]
    pub name: String,
}

pub async fn handle(command: ProfileCommands) -> Result<()> {
    match command {
        ProfileCommands::Save(cmd) => save(cmd).await,
        ProfileCommands::Load(cmd) => load(cmd).await,
        ProfileCommands::List(_) => list().await,
        ProfileCommands::Delete(cmd) => delete(cmd).await,
    }
}

async fn save(_cmd: SaveCommand) -> Result<()> {
    println!("{} Build profiles not yet implemented", "⚠".yellow());
    Ok(())
}

async fn load(_cmd: LoadCommand) -> Result<()> {
    println!("{} Build profiles not yet implemented", "⚠".yellow());
    Ok(())
}

async fn list() -> Result<()> {
    println!("{} Build profiles not yet implemented", "⚠".yellow());
    Ok(())
}

async fn delete(_cmd: DeleteCommand) -> Result<()> {
    println!("{} Build profiles not yet implemented", "⚠".yellow());
    Ok(())
}
