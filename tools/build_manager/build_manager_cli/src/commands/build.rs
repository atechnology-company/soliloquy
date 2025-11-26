use clap::{Args, ValueEnum};
use anyhow::Result;
use colored::*;
use soliloquy_build_core::{BuildManager, Config, models::*};

#[derive(Args)]
pub struct StartCommand {
    #[arg(help = "Build target (e.g., //src/shell:soliloquy_shell)")]
    pub target: String,

    #[arg(long, short = 's', value_enum, help = "Build system to use")]
    pub system: Option<BuildSystemArg>,

    #[arg(long, short = 'j', help = "Number of parallel jobs")]
    pub jobs: Option<usize>,

    #[arg(long, short = 'v', help = "Verbose output")]
    pub verbose: bool,

    #[arg(long, help = "Clean before building")]
    pub clean: bool,

    #[arg(long, help = "Build profile to use")]
    pub profile: Option<String>,

    #[arg(last = true, help = "Extra arguments to pass to build system")]
    pub extra_args: Vec<String>,
}

#[derive(Args)]
pub struct StopCommand {
    #[arg(help = "Build ID to stop")]
    pub build_id: String,
}

#[derive(Args)]
pub struct StatusCommand {
    #[arg(help = "Build ID (optional, shows all if not provided)")]
    pub build_id: Option<String>,

    #[arg(long, short = 'f', help = "Follow build progress")]
    pub follow: bool,
}

#[derive(Args)]
pub struct CleanCommand {
    #[arg(long, short = 's', value_enum, help = "Build system to clean")]
    pub system: BuildSystemArg,

    #[arg(help = "Target to clean (optional)")]
    pub target: Option<String>,
}

#[derive(Clone, ValueEnum)]
pub enum BuildSystemArg {
    Gn,
    Bazel,
    Cargo,
}

impl From<BuildSystemArg> for BuildSystem {
    fn from(arg: BuildSystemArg) -> Self {
        match arg {
            BuildSystemArg::Gn => BuildSystem::GN,
            BuildSystemArg::Bazel => BuildSystem::Bazel,
            BuildSystemArg::Cargo => BuildSystem::Cargo,
        }
    }
}

pub async fn start(cmd: StartCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config.clone()).await?;
    
    let system = cmd.system
        .map(BuildSystem::from)
        .unwrap_or_else(|| config.general.default_build_system.parse().unwrap_or(BuildSystem::Bazel));

    println!("{} Starting build...", "✓".green());
    println!("  Target: {}", cmd.target.cyan());
    println!("  System: {}", format!("{}", system).yellow());

    let request = BuildRequest {
        target: cmd.target,
        system,
        options: BuildOptions {
            clean: cmd.clean,
            parallel_jobs: cmd.jobs,
            verbose: cmd.verbose,
            profile: cmd.profile,
            extra_args: cmd.extra_args,
        },
    };

    match manager.executor().start_build(request).await {
        Ok(build_id) => {
            println!("{} Build started successfully!", "✓".green());
            println!("  Build ID: {}", build_id.bright_black());
        }
        Err(e) => {
            eprintln!("{} Build failed: {}", "✗".red(), e);
            std::process::exit(1);
        }
    }

    Ok(())
}

pub async fn stop(cmd: StopCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config).await?;

    println!("{} Stopping build {}...", "⏸".yellow(), cmd.build_id);

    match manager.executor().cancel_build(&cmd.build_id).await {
        Ok(_) => println!("{} Build stopped", "✓".green()),
        Err(e) => {
            eprintln!("{} Failed to stop build: {}", "✗".red(), e);
            std::process::exit(1);
        }
    }

    Ok(())
}

pub async fn status(cmd: StatusCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config).await?;

    if let Some(build_id) = cmd.build_id {
        match manager.executor().get_build(&build_id).await {
            Ok(build) => print_build(&build),
            Err(e) => {
                eprintln!("{} Build not found: {}", "✗".red(), e);
                std::process::exit(1);
            }
        }
    } else {
        let builds = manager.executor().list_active_builds().await;
        if builds.is_empty() {
            println!("No active builds");
        } else {
            println!("Active builds:");
            for build_id in builds {
                println!("  • {}", build_id.cyan());
            }
        }
    }

    Ok(())
}

pub async fn clean(cmd: CleanCommand) -> Result<()> {
    let config = Config::load()?;
    let manager = BuildManager::new(config).await?;

    let system: BuildSystem = cmd.system.into();
    
    println!("{} Cleaning {} builds...", "🧹".yellow(), system);

    match manager.executor().clean(system, cmd.target).await {
        Ok(_) => println!("{} Clean complete", "✓".green()),
        Err(e) => {
            eprintln!("{} Clean failed: {}", "✗".red(), e);
            std::process::exit(1);
        }
    }

    Ok(())
}

fn print_build(build: &Build) {
    println!("\n{}", "Build Information".bold());
    println!("─────────────────────────────");
    println!("  ID:     {}", build.id.bright_black());
    println!("  Target: {}", build.target.cyan());
    println!("  System: {}", format!("{}", build.system).yellow());
    println!("  Status: {}", format_status(&build.status));
    println!("  Start:  {}", build.start_time);
    
    if let Some(end) = build.end_time {
        println!("  End:    {}", end);
        let duration = (end - build.start_time).num_milliseconds() as f64 / 1000.0;
        println!("  Duration: {:.2}s", duration);
    }

    if !build.errors.is_empty() {
        println!("\n{}", "Errors:".red().bold());
        for error in &build.errors {
            println!("  • {}", error.message);
        }
    }
}

fn format_status(status: &BuildStatus) -> colored::ColoredString {
    match status {
        BuildStatus::Success => "Success".green(),
        BuildStatus::Failed => "Failed".red(),
        BuildStatus::Running => "Running".yellow(),
        BuildStatus::Cancelled => "Cancelled".bright_black(),
        BuildStatus::Pending => "Pending".blue(),
    }
}
