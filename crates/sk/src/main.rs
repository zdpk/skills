use std::path::PathBuf;

use anyhow::Result;
use clap::{Parser, Subcommand, ValueEnum};

use sk::{
    BumpLevel, InstallPlan, InstallStatus, Skill, Target, bump_skill_version, default_repo_root,
    discover_skills, install_skills, load_registry, status_for_targets, validate_skills,
};

#[derive(Parser)]
#[command(name = "sk")]
#[command(about = "Manage root skills from zdpk/skills")]
struct Cli {
    #[arg(long, global = true, value_name = "PATH")]
    repo: Option<PathBuf>,

    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    List {
        #[arg(long)]
        json: bool,
    },
    Status {
        #[arg(long)]
        json: bool,

        #[arg(long)]
        all: bool,

        #[arg(long = "target", value_enum)]
        targets: Vec<TargetArg>,
    },
    Validate,
    Install(InstallArgs),
    Update(InstallArgs),
    Version {
        skill: Option<String>,

        #[arg(long)]
        json: bool,
    },
    Bump {
        skill: String,

        #[arg(value_enum)]
        level: BumpArg,

        #[arg(long)]
        dry_run: bool,
    },
}

#[derive(clap::Args)]
struct InstallArgs {
    #[arg(long)]
    all: bool,

    #[arg(long = "target", value_enum)]
    targets: Vec<TargetArg>,

    #[arg(long)]
    dry_run: bool,
}

#[derive(Clone, Copy, Debug, ValueEnum)]
enum TargetArg {
    Codex,
    Claude,
    Antigravity,
    AntigravityIde,
    Agents,
}

#[derive(Clone, Copy, Debug, ValueEnum)]
enum BumpArg {
    Major,
    Minor,
    Patch,
}

impl From<TargetArg> for Target {
    fn from(value: TargetArg) -> Self {
        match value {
            TargetArg::Codex => Target::Codex,
            TargetArg::Claude => Target::Claude,
            TargetArg::Antigravity => Target::Antigravity,
            TargetArg::AntigravityIde => Target::AntigravityIde,
            TargetArg::Agents => Target::Agents,
        }
    }
}

impl From<BumpArg> for BumpLevel {
    fn from(value: BumpArg) -> Self {
        match value {
            BumpArg::Major => BumpLevel::Major,
            BumpArg::Minor => BumpLevel::Minor,
            BumpArg::Patch => BumpLevel::Patch,
        }
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let repo = cli.repo.unwrap_or(default_repo_root()?);

    match cli.command {
        Command::List { json } => {
            let skills = discover_skills(&repo)?;
            if json {
                println!("{}", serde_json::to_string_pretty(&skills)?);
            } else {
                print_skill_table(&skills);
            }
        }
        Command::Status { json, all, targets } => {
            let selected = selected_targets(all, targets);
            let statuses = status_for_targets(&repo, &selected)?;
            if json {
                println!("{}", serde_json::to_string_pretty(&statuses)?);
            } else {
                print_status_table(&statuses);
            }
        }
        Command::Validate => {
            let errors = validate_skills(&repo)?;
            if errors.is_empty() {
                println!("Validated {} skill(s).", discover_skills(&repo)?.len());
            } else {
                for error in errors {
                    eprintln!("ERROR: {error}");
                }
                std::process::exit(1);
            }
        }
        Command::Install(args) | Command::Update(args) => {
            let selected = selected_targets(args.all, args.targets);
            let plan = InstallPlan {
                targets: selected,
                dry_run: args.dry_run,
            };
            let results = install_skills(&repo, &plan)?;
            print_install_results(&results);
            if results.iter().any(|result| result.status.is_failure()) {
                std::process::exit(1);
            }
        }
        Command::Version { skill, json } => {
            let registry = load_registry(&repo)?;
            if json {
                if let Some(skill) = skill {
                    let entry = registry.skill(&skill);
                    println!("{}", serde_json::to_string_pretty(&entry)?);
                } else {
                    println!("{}", serde_json::to_string_pretty(&registry)?);
                }
            } else if let Some(skill) = skill {
                match registry.skill(&skill) {
                    Some(entry) => println!("{} {}", entry.name, entry.version),
                    None => {
                        eprintln!("skill not found in registry: {skill}");
                        std::process::exit(1);
                    }
                }
            } else {
                for entry in registry.skill {
                    println!("{} {}", entry.name, entry.version);
                }
            }
        }
        Command::Bump {
            skill,
            level,
            dry_run,
        } => {
            let outcome = bump_skill_version(&repo, &skill, level.into(), dry_run)?;
            if dry_run {
                println!(
                    "Would bump {} {} -> {}",
                    outcome.name, outcome.before, outcome.after
                );
            } else {
                println!(
                    "Bumped {} {} -> {}",
                    outcome.name, outcome.before, outcome.after
                );
            }
        }
    }

    Ok(())
}

fn selected_targets(all: bool, targets: Vec<TargetArg>) -> Vec<Target> {
    if all || targets.is_empty() {
        Target::defaults()
    } else {
        targets.into_iter().map(Target::from).collect()
    }
}

fn print_skill_table(skills: &[Skill]) {
    println!(
        "{:<22} {:<12} {:<10} {:<38} DESCRIPTION",
        "NAME", "CATEGORY", "VERSION", "PATH"
    );
    for skill in skills {
        println!(
            "{:<22} {:<12} {:<10} {:<38} {}",
            skill.name,
            skill.category,
            skill.version.as_deref().unwrap_or("-"),
            skill.relative_path.display(),
            skill.description
        );
    }
}

fn print_status_table(statuses: &[sk::TargetSkillStatus]) {
    println!("{:<16} {:<22} {:<18} PATH", "TARGET", "SKILL", "STATUS");
    for status in statuses {
        println!(
            "{:<16} {:<22} {:<18} {}",
            status.target,
            status.skill,
            status.status,
            status.target_path.display()
        );
    }
}

fn print_install_results(results: &[sk::InstallResult]) {
    for result in results {
        let prefix = match result.status {
            InstallStatus::Linked | InstallStatus::Updated => "ok",
            InstallStatus::AlreadyLinked => "same",
            InstallStatus::WouldLink | InstallStatus::WouldUpdate => "dry-run",
            InstallStatus::RefusedExternalLink
            | InstallStatus::RefusedExistingPath
            | InstallStatus::Error => "error",
        };
        println!(
            "[{}] {} {}: {} -> {}",
            prefix,
            result.target,
            result.skill,
            result.target_path.display(),
            result.source_path.display()
        );
        if let Some(detail) = &result.detail {
            println!("  {}", detail);
        }
    }
}
