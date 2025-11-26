use clap::Args;
use anyhow::Result;
use colored::*;
use soliloquy_build_core::{BuildManager, Config};

#[derive(Args)]
pub struct StatsCommand {}

#[derive(Args)]
pub struct HistoryCommand {
    #[arg(long, short = 'd', default_value = "7", help = "Number of days")]
    pub days: u32,
}

#[derive(Args)]
pub struct CompareCommand {
    #[arg(help = "First build ID")]
    pub build_id_1: String,

    #[arg(help = "Second build ID")]
    pub build_id_2: String,
}

pub async fn stats(_cmd: StatsCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config).await?;
    
    match manager.analytics().get_statistics().await {
        Ok(stats) => {
            println!("\n{}", "Build Statistics".bold());
            println!("─────────────────────────────");
            println!("  Total Builds:      {}", stats.total_builds.to_string().cyan());
            println!("  Successful:        {} ({}%)", 
                stats.successful_builds.to_string().green(),
                if stats.total_builds > 0 {
                    format!("{:.1}", (stats.successful_builds as f64 / stats.total_builds as f64) * 100.0)
                } else {
                    "0.0".to_string()
                }
            );
            println!("  Failed:            {}", stats.failed_builds.to_string().red());
            println!("  Avg Duration:      {:.1}s", stats.average_duration_secs);
        }
        Err(e) => {
            eprintln!("{} Failed to get statistics: {}", "✗".red(), e);
        }
    }
    
    Ok(())
}

pub async fn history(cmd: HistoryCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config).await?;
    
    match manager.analytics().get_build_history(cmd.days).await {
        Ok(builds) => {
            println!("\n{} (last {} days)", "Build History".bold(), cmd.days);
            println!("─────────────────────────────");
            
            if builds.is_empty() {
                println!("  No builds found");
            } else {
                for build in builds.iter().take(20) {
                    let status_str = format_status(&build.status);
                    let duration = build.end_time
                        .map(|end| (end - build.start_time).num_milliseconds() as f64 / 1000.0)
                        .unwrap_or(0.0);
                    
                    println!("  {} {} {} ({:.1}s)", 
                        status_str,
                        build.target.cyan(),
                        build.system.to_string().yellow(),
                        duration
                    );
                }
                
                if builds.len() > 20 {
                    println!("\n  ... and {} more", builds.len() - 20);
                }
            }
        }
        Err(e) => {
            eprintln!("{} Failed to get build history: {}", "✗".red(), e);
        }
    }
    
    Ok(())
}

pub async fn compare(cmd: CompareCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config).await?;
    
    let build1 = manager.analytics().get_build(&cmd.build_id_1).await?;
    let build2 = manager.analytics().get_build(&cmd.build_id_2).await?;
    
    println!("\n{}", "Build Comparison".bold());
    println!("─────────────────────────────");
    
    let duration1 = build1.end_time
        .map(|end| (end - build1.start_time).num_milliseconds() as f64 / 1000.0)
        .unwrap_or(0.0);
    let duration2 = build2.end_time
        .map(|end| (end - build2.start_time).num_milliseconds() as f64 / 1000.0)
        .unwrap_or(0.0);
    
    println!("  Build 1:");
    println!("    Status:   {}", format_status(&build1.status));
    println!("    Duration: {:.1}s", duration1);
    println!();
    println!("  Build 2:");
    println!("    Status:   {}", format_status(&build2.status));
    println!("    Duration: {:.1}s", duration2);
    println!();
    
    let diff = duration2 - duration1;
    let diff_pct = if duration1 > 0.0 {
        (diff / duration1) * 100.0
    } else {
        0.0
    };
    
    if diff.abs() < 0.1 {
        println!("  Difference: ~same");
    } else if diff > 0.0 {
        println!("  Difference: {:.1}s slower ({:+.1}%)", diff.abs(), diff_pct);
    } else {
        println!("  Difference: {:.1}s faster ({:+.1}%)", diff.abs(), diff_pct);
    }
    
    Ok(())
}

fn format_status(status: &soliloquy_build_core::models::BuildStatus) -> colored::ColoredString {
    use soliloquy_build_core::models::BuildStatus;
    match status {
        BuildStatus::Success => "✓".green(),
        BuildStatus::Failed => "✗".red(),
        BuildStatus::Running => "⋯".yellow(),
        BuildStatus::Cancelled => "⊘".bright_black(),
        BuildStatus::Pending => "○".blue(),
    }
}
