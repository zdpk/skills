use std::collections::{BTreeMap, BTreeSet};
use std::env;
use std::fmt;
use std::fs;
use std::io::ErrorKind;
use std::path::{Path, PathBuf};

use anyhow::{Context, Result, anyhow, bail};
use serde::{Deserialize, Serialize};
use walkdir::WalkDir;

const FRONTMATTER_ALLOWED_FIELDS: &[&str] = &["name", "description"];
const FORBIDDEN_SKILL_DOCS: &[&str] = &[
    "README.md",
    "CHANGELOG.md",
    "INSTALL.md",
    "INSTALLATION_GUIDE.md",
    "QUICK_REFERENCE.md",
];

#[derive(Clone, Debug, Serialize)]
pub struct Skill {
    pub name: String,
    pub description: String,
    pub category: String,
    pub path: PathBuf,
    pub relative_path: PathBuf,
    pub version: Option<String>,
    pub registered: bool,
}

#[derive(Clone, Debug, Deserialize, Serialize, Default)]
pub struct Registry {
    #[serde(default)]
    pub skill: Vec<RegistryEntry>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct RegistryEntry {
    pub name: String,
    pub category: String,
    pub path: String,
    pub version: String,
}

#[derive(Clone, Copy, Debug)]
pub enum BumpLevel {
    Major,
    Minor,
    Patch,
}

#[derive(Clone, Debug, Serialize)]
pub struct BumpOutcome {
    pub name: String,
    pub before: String,
    pub after: String,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Ord, PartialOrd, Serialize)]
pub enum Target {
    Codex,
    Claude,
    Antigravity,
    AntigravityIde,
    Agents,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
pub enum LinkState {
    Installed,
    Missing,
    StaleLink,
    BrokenLink,
    ExternalLink,
    RealDirConflict,
    RealFileConflict,
}

#[derive(Clone, Debug, Serialize)]
pub struct TargetSkillStatus {
    pub target: Target,
    pub skill: String,
    pub status: LinkState,
    pub source_path: PathBuf,
    pub target_path: PathBuf,
    pub link_target: Option<PathBuf>,
}

#[derive(Clone, Debug)]
pub struct InstallPlan {
    pub targets: Vec<Target>,
    pub dry_run: bool,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum InstallStatus {
    AlreadyLinked,
    WouldLink,
    WouldUpdate,
    Linked,
    Updated,
    RefusedExternalLink,
    RefusedExistingPath,
    Error,
}

#[derive(Clone, Debug)]
pub struct InstallResult {
    pub target: Target,
    pub skill: String,
    pub status: InstallStatus,
    pub source_path: PathBuf,
    pub target_path: PathBuf,
    pub detail: Option<String>,
}

impl Registry {
    pub fn skill(&self, name: &str) -> Option<&RegistryEntry> {
        self.skill.iter().find(|entry| entry.name == name)
    }

    fn skill_mut(&mut self, name: &str) -> Option<&mut RegistryEntry> {
        self.skill.iter_mut().find(|entry| entry.name == name)
    }
}

impl Target {
    pub fn defaults() -> Vec<Self> {
        vec![
            Self::Codex,
            Self::Claude,
            Self::Antigravity,
            Self::AntigravityIde,
        ]
    }

    pub fn all_with_agents() -> Vec<Self> {
        vec![
            Self::Codex,
            Self::Claude,
            Self::Antigravity,
            Self::AntigravityIde,
            Self::Agents,
        ]
    }

    pub fn dir(self) -> PathBuf {
        match self {
            Self::Codex => env_path("CODEX_SKILLS_DIR")
                .or_else(|| env_home_path("CODEX_HOME", "skills"))
                .unwrap_or_else(|| home().join(".codex/skills")),
            Self::Claude => env_path("CLAUDE_SKILLS_DIR")
                .or_else(|| env_home_path("CLAUDE_HOME", "skills"))
                .unwrap_or_else(|| home().join(".claude/skills")),
            Self::Antigravity => env_path("ANTIGRAVITY_SKILLS_DIR")
                .unwrap_or_else(|| home().join(".gemini/antigravity/global_skills")),
            Self::AntigravityIde => env_path("ANTIGRAVITY_IDE_SKILLS_DIR")
                .unwrap_or_else(|| home().join(".gemini/antigravity-ide/global_skills")),
            Self::Agents => {
                env_path("AGENTS_SKILLS_DIR").unwrap_or_else(|| home().join(".agents/skills"))
            }
        }
    }
}

impl fmt::Display for Target {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Codex => write!(f, "codex"),
            Self::Claude => write!(f, "claude"),
            Self::Antigravity => write!(f, "antigravity"),
            Self::AntigravityIde => write!(f, "antigravity-ide"),
            Self::Agents => write!(f, "agents"),
        }
    }
}

impl fmt::Display for LinkState {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Installed => write!(f, "installed"),
            Self::Missing => write!(f, "missing"),
            Self::StaleLink => write!(f, "stale-link"),
            Self::BrokenLink => write!(f, "broken-link"),
            Self::ExternalLink => write!(f, "external-link"),
            Self::RealDirConflict => write!(f, "real-dir-conflict"),
            Self::RealFileConflict => write!(f, "real-file-conflict"),
        }
    }
}

impl Serialize for InstallStatus {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(match self {
            Self::AlreadyLinked => "already-linked",
            Self::WouldLink => "would-link",
            Self::WouldUpdate => "would-update",
            Self::Linked => "linked",
            Self::Updated => "updated",
            Self::RefusedExternalLink => "refused-external-link",
            Self::RefusedExistingPath => "refused-existing-path",
            Self::Error => "error",
        })
    }
}

impl InstallStatus {
    pub fn is_failure(self) -> bool {
        matches!(
            self,
            Self::RefusedExternalLink | Self::RefusedExistingPath | Self::Error
        )
    }
}

impl fmt::Display for InstallStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::AlreadyLinked => write!(f, "already-linked"),
            Self::WouldLink => write!(f, "would-link"),
            Self::WouldUpdate => write!(f, "would-update"),
            Self::Linked => write!(f, "linked"),
            Self::Updated => write!(f, "updated"),
            Self::RefusedExternalLink => write!(f, "refused-external-link"),
            Self::RefusedExistingPath => write!(f, "refused-existing-path"),
            Self::Error => write!(f, "error"),
        }
    }
}

pub fn default_repo_root() -> Result<PathBuf> {
    if let Ok(value) = env::var("SKILLS_REPO") {
        return Ok(PathBuf::from(value));
    }

    let current = env::current_dir().context("read current directory")?;
    for candidate in current.ancestors() {
        if candidate.join("skills").is_dir() && candidate.join(".git").exists() {
            return Ok(candidate.to_path_buf());
        }
    }

    Ok(current)
}

pub fn discover_skills(repo: &Path) -> Result<Vec<Skill>> {
    let registry = load_registry(repo).unwrap_or_default();
    let by_name: BTreeMap<String, RegistryEntry> = registry
        .skill
        .into_iter()
        .map(|entry| (entry.name.clone(), entry))
        .collect();

    let mut skills = Vec::new();
    for skill_dir in skill_dirs(repo)? {
        let skill_file = skill_dir.join("SKILL.md");
        let fields = parse_frontmatter(&skill_file)?.0;
        let name = fields.get("name").cloned().unwrap_or_default();
        let description = fields.get("description").cloned().unwrap_or_default();
        let relative_path = skill_dir
            .strip_prefix(repo)
            .unwrap_or(&skill_dir)
            .to_path_buf();
        let category = category_for(&relative_path);
        let registry_entry = by_name.get(&name);

        skills.push(Skill {
            name,
            description,
            category,
            path: skill_dir,
            relative_path,
            version: registry_entry.map(|entry| entry.version.clone()),
            registered: registry_entry.is_some(),
        });
    }
    skills.sort_by(|left, right| left.name.cmp(&right.name));
    Ok(skills)
}

pub fn validate_skills(repo: &Path) -> Result<Vec<String>> {
    let mut errors = Vec::new();
    let mut names = BTreeMap::new();

    for skill_dir in skill_dirs(repo)? {
        validate_one_skill(repo, &skill_dir, &mut errors)?;
        if let Ok((fields, _)) = parse_frontmatter(&skill_dir.join("SKILL.md"))
            && let Some(name) = fields.get("name")
            && let Some(previous) = names.insert(name.clone(), skill_dir.clone())
        {
            errors.push(format!(
                "{}: duplicate skill name also used by {}",
                skill_dir.join("SKILL.md").display(),
                previous.display()
            ));
        }
    }

    errors.extend(validate_registry(repo)?);
    Ok(errors)
}

pub fn load_registry(repo: &Path) -> Result<Registry> {
    let path = registry_path(repo);
    if !path.exists() {
        return Ok(Registry::default());
    }
    let raw = fs::read_to_string(&path).with_context(|| format!("read {}", path.display()))?;
    toml::from_str(&raw).with_context(|| format!("parse {}", path.display()))
}

pub fn write_registry(repo: &Path, registry: &Registry) -> Result<()> {
    let path = registry_path(repo);
    let raw = toml::to_string_pretty(registry).context("serialize registry")?;
    fs::write(&path, raw).with_context(|| format!("write {}", path.display()))
}

pub fn status_for_targets(repo: &Path, targets: &[Target]) -> Result<Vec<TargetSkillStatus>> {
    let skills = discover_skills(repo)?;
    let mut statuses = Vec::new();
    for target in normalized_targets(targets) {
        let target_root = target.dir();
        for skill in &skills {
            let target_path = target_root.join(&skill.name);
            let status = link_state(repo, &skill.path, &target_path)?;
            statuses.push(TargetSkillStatus {
                target,
                skill: skill.name.clone(),
                status: status.0,
                source_path: skill.path.clone(),
                target_path,
                link_target: status.1,
            });
        }
    }
    Ok(statuses)
}

pub fn install_skills(repo: &Path, plan: &InstallPlan) -> Result<Vec<InstallResult>> {
    let errors = validate_skills(repo)?;
    if !errors.is_empty() {
        bail!("cannot install invalid skills:\n{}", errors.join("\n"));
    }

    let skills = discover_skills(repo)?;
    let mut results = Vec::new();
    for target in normalized_targets(&plan.targets) {
        let target_root = target.dir();
        for skill in &skills {
            results.push(refresh_link(
                repo,
                target,
                &skill.name,
                &skill.path,
                &target_root.join(&skill.name),
                plan.dry_run,
            ));
        }
    }
    Ok(results)
}

pub fn bump_skill_version(
    repo: &Path,
    name: &str,
    level: BumpLevel,
    dry_run: bool,
) -> Result<BumpOutcome> {
    let mut registry = load_registry(repo)?;
    let entry = registry
        .skill_mut(name)
        .ok_or_else(|| anyhow!("skill not found in registry: {name}"))?;

    let before = entry.version.clone();
    let after = bump_version(&before, level)?;
    entry.version = after.clone();

    if !dry_run {
        write_registry(repo, &registry)?;
    }

    Ok(BumpOutcome {
        name: name.to_string(),
        before,
        after,
    })
}

fn validate_one_skill(repo: &Path, skill_dir: &Path, errors: &mut Vec<String>) -> Result<()> {
    let skill_file = skill_dir.join("SKILL.md");
    if !skill_file.is_file() {
        errors.push(format!("{}: missing SKILL.md", skill_dir.display()));
        return Ok(());
    }

    match parse_frontmatter(&skill_file) {
        Ok((fields, frontmatter_errors)) => {
            errors.extend(
                frontmatter_errors
                    .into_iter()
                    .map(|error| format!("{}: {}", skill_file.display(), error)),
            );
            let extra_fields: Vec<_> = fields
                .keys()
                .filter(|field| !FRONTMATTER_ALLOWED_FIELDS.contains(&field.as_str()))
                .cloned()
                .collect();
            if !extra_fields.is_empty() {
                errors.push(format!(
                    "{}: unsupported frontmatter fields: {}",
                    skill_file.display(),
                    extra_fields.join(", ")
                ));
            }

            match fields.get("name") {
                Some(name) if !valid_skill_name(name) => errors.push(format!(
                    "{}: name must use lowercase letters, numbers, and hyphens",
                    skill_file.display()
                )),
                Some(name) if name != &skill_dir.file_name().unwrap().to_string_lossy() => {
                    errors.push(format!(
                        "{}: name must match directory name {:?}",
                        skill_file.display(),
                        skill_dir.file_name().unwrap().to_string_lossy()
                    ));
                }
                Some(_) => {}
                None => errors.push(format!(
                    "{}: missing frontmatter name",
                    skill_file.display()
                )),
            }
            if !fields.contains_key("description") {
                errors.push(format!(
                    "{}: missing frontmatter description",
                    skill_file.display()
                ));
            }
        }
        Err(error) => errors.push(format!("{}: {}", skill_file.display(), error)),
    }

    for doc_name in FORBIDDEN_SKILL_DOCS {
        if skill_dir.join(doc_name).exists() {
            errors.push(format!(
                "{}: keep operational docs at repository root",
                skill_dir.join(doc_name).display()
            ));
        }
    }

    let relative_path = skill_dir.strip_prefix(repo).unwrap_or(skill_dir);
    if relative_path.components().count() < 3 {
        errors.push(format!(
            "{}: root skills should live under skills/<category>/<skill-name>",
            skill_dir.display()
        ));
    }

    Ok(())
}

fn validate_registry(repo: &Path) -> Result<Vec<String>> {
    let registry = load_registry(repo)?;
    let skills = skill_dirs(repo)?;
    let discovered: BTreeSet<_> = skills
        .iter()
        .filter_map(|dir| parse_frontmatter(&dir.join("SKILL.md")).ok())
        .filter_map(|(fields, _)| fields.get("name").cloned())
        .collect();
    let mut seen = BTreeSet::new();
    let mut errors = Vec::new();

    for entry in registry.skill {
        if !seen.insert(entry.name.clone()) {
            errors.push(format!(
                "{}: duplicate registry entry for {}",
                registry_path(repo).display(),
                entry.name
            ));
        }
        if !valid_skill_name(&entry.name) {
            errors.push(format!(
                "{}: invalid registry skill name {}",
                registry_path(repo).display(),
                entry.name
            ));
        }
        if !discovered.contains(&entry.name) {
            errors.push(format!(
                "{}: registry skill not found under skills/: {}",
                registry_path(repo).display(),
                entry.name
            ));
        }
        if !repo.join(&entry.path).join("SKILL.md").is_file() {
            errors.push(format!(
                "{}: registry path missing SKILL.md for {}: {}",
                registry_path(repo).display(),
                entry.name,
                entry.path
            ));
        }
        if parse_version(&entry.version).is_err() {
            errors.push(format!(
                "{}: invalid semver version for {}: {}",
                registry_path(repo).display(),
                entry.name,
                entry.version
            ));
        }
    }

    Ok(errors)
}

fn parse_frontmatter(path: &Path) -> Result<(BTreeMap<String, String>, Vec<String>)> {
    let text = fs::read_to_string(path).with_context(|| format!("read {}", path.display()))?;
    let mut lines = text.lines();
    let Some(first) = lines.next() else {
        bail!("missing YAML frontmatter");
    };
    if first.trim() != "---" {
        bail!("missing YAML frontmatter");
    }

    let mut fields = BTreeMap::new();
    let mut errors = Vec::new();
    for (offset, raw_line) in lines.enumerate() {
        let line_number = offset + 2;
        let line = raw_line.trim();
        if line == "---" {
            return Ok((fields, errors));
        }
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        let Some((key, value)) = line.split_once(':') else {
            errors.push(format!("frontmatter line {line_number} is not key: value"));
            continue;
        };
        fields.insert(
            key.trim().to_string(),
            value
                .trim()
                .trim_matches('"')
                .trim_matches('\'')
                .to_string(),
        );
    }

    bail!("unterminated YAML frontmatter");
}

fn skill_dirs(repo: &Path) -> Result<Vec<PathBuf>> {
    let skills_root = repo.join("skills");
    if !skills_root.exists() {
        return Ok(Vec::new());
    }

    let mut dirs = Vec::new();
    for entry in WalkDir::new(&skills_root).follow_links(false) {
        let entry = entry?;
        if entry.file_type().is_file() && entry.file_name() == "SKILL.md" {
            dirs.push(entry.path().parent().unwrap().to_path_buf());
        }
    }
    dirs.sort();
    Ok(dirs)
}

fn category_for(relative_path: &Path) -> String {
    relative_path
        .components()
        .nth(1)
        .map(|component| component.as_os_str().to_string_lossy().into_owned())
        .unwrap_or_else(|| "-".to_string())
}

fn registry_path(repo: &Path) -> PathBuf {
    repo.join("skills/registry.toml")
}

fn valid_skill_name(value: &str) -> bool {
    let bytes = value.as_bytes();
    !bytes.is_empty()
        && bytes[0].is_ascii_alphanumeric()
        && bytes
            .iter()
            .all(|byte| byte.is_ascii_lowercase() || byte.is_ascii_digit() || *byte == b'-')
}

fn normalized_targets(targets: &[Target]) -> Vec<Target> {
    if targets.is_empty() {
        return Target::defaults();
    }
    let mut unique = targets.to_vec();
    unique.sort();
    unique.dedup();
    unique
}

fn link_state(repo: &Path, source: &Path, target: &Path) -> Result<(LinkState, Option<PathBuf>)> {
    let metadata = match fs::symlink_metadata(target) {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == ErrorKind::NotFound => return Ok((LinkState::Missing, None)),
        Err(error) => return Err(error).with_context(|| format!("read {}", target.display())),
    };

    if metadata.file_type().is_symlink() {
        let raw =
            fs::read_link(target).with_context(|| format!("readlink {}", target.display()))?;
        let absolute = if raw.is_absolute() {
            raw.clone()
        } else {
            target.parent().unwrap_or_else(|| Path::new(".")).join(&raw)
        };

        if !absolute.exists() {
            return Ok((LinkState::BrokenLink, Some(raw)));
        }

        let source_real = source.canonicalize()?;
        let target_real = absolute.canonicalize()?;
        if source_real == target_real {
            Ok((LinkState::Installed, Some(raw)))
        } else if target_real.starts_with(repo.canonicalize()?) {
            Ok((LinkState::StaleLink, Some(raw)))
        } else {
            Ok((LinkState::ExternalLink, Some(raw)))
        }
    } else if metadata.is_dir() {
        Ok((LinkState::RealDirConflict, None))
    } else {
        Ok((LinkState::RealFileConflict, None))
    }
}

fn refresh_link(
    repo: &Path,
    target: Target,
    skill: &str,
    source: &Path,
    target_path: &Path,
    dry_run: bool,
) -> InstallResult {
    match link_state(repo, source, target_path) {
        Ok((LinkState::Installed, _)) => InstallResult {
            target,
            skill: skill.to_string(),
            status: InstallStatus::AlreadyLinked,
            source_path: source.to_path_buf(),
            target_path: target_path.to_path_buf(),
            detail: None,
        },
        Ok((LinkState::Missing, _)) => {
            if dry_run {
                return InstallResult {
                    target,
                    skill: skill.to_string(),
                    status: InstallStatus::WouldLink,
                    source_path: source.to_path_buf(),
                    target_path: target_path.to_path_buf(),
                    detail: None,
                };
            }
            if let Err(error) = create_symlink(source, target_path) {
                return install_error(target, skill, source, target_path, error);
            }
            InstallResult {
                target,
                skill: skill.to_string(),
                status: InstallStatus::Linked,
                source_path: source.to_path_buf(),
                target_path: target_path.to_path_buf(),
                detail: None,
            }
        }
        Ok((LinkState::StaleLink | LinkState::BrokenLink, link_target)) => {
            if !link_points_inside_repo(repo, target_path, link_target.as_ref()) {
                return InstallResult {
                    target,
                    skill: skill.to_string(),
                    status: InstallStatus::RefusedExternalLink,
                    source_path: source.to_path_buf(),
                    target_path: target_path.to_path_buf(),
                    detail: link_target
                        .map(|path| format!("existing link target: {}", path.display())),
                };
            }
            if dry_run {
                return InstallResult {
                    target,
                    skill: skill.to_string(),
                    status: InstallStatus::WouldUpdate,
                    source_path: source.to_path_buf(),
                    target_path: target_path.to_path_buf(),
                    detail: None,
                };
            }
            if let Err(error) = fs::remove_file(target_path)
                .with_context(|| format!("remove {}", target_path.display()))
                .and_then(|_| create_symlink(source, target_path))
            {
                return install_error(target, skill, source, target_path, error);
            }
            InstallResult {
                target,
                skill: skill.to_string(),
                status: InstallStatus::Updated,
                source_path: source.to_path_buf(),
                target_path: target_path.to_path_buf(),
                detail: None,
            }
        }
        Ok((LinkState::ExternalLink, link_target)) => InstallResult {
            target,
            skill: skill.to_string(),
            status: InstallStatus::RefusedExternalLink,
            source_path: source.to_path_buf(),
            target_path: target_path.to_path_buf(),
            detail: link_target.map(|path| format!("existing link target: {}", path.display())),
        },
        Ok((LinkState::RealDirConflict | LinkState::RealFileConflict, _)) => InstallResult {
            target,
            skill: skill.to_string(),
            status: InstallStatus::RefusedExistingPath,
            source_path: source.to_path_buf(),
            target_path: target_path.to_path_buf(),
            detail: Some("existing path is not a symlink".to_string()),
        },
        Err(error) => install_error(target, skill, source, target_path, error),
    }
}

fn install_error(
    target: Target,
    skill: &str,
    source: &Path,
    target_path: &Path,
    error: anyhow::Error,
) -> InstallResult {
    InstallResult {
        target,
        skill: skill.to_string(),
        status: InstallStatus::Error,
        source_path: source.to_path_buf(),
        target_path: target_path.to_path_buf(),
        detail: Some(error.to_string()),
    }
}

fn create_symlink(source: &Path, target: &Path) -> Result<()> {
    if let Some(parent) = target.parent() {
        fs::create_dir_all(parent).with_context(|| format!("mkdir {}", parent.display()))?;
    }
    #[cfg(unix)]
    {
        std::os::unix::fs::symlink(source, target)
            .with_context(|| format!("symlink {} -> {}", target.display(), source.display()))
    }
    #[cfg(windows)]
    {
        std::os::windows::fs::symlink_dir(source, target)
            .with_context(|| format!("symlink {} -> {}", target.display(), source.display()))
    }
}

fn link_points_inside_repo(repo: &Path, target_path: &Path, link_target: Option<&PathBuf>) -> bool {
    let Some(link_target) = link_target else {
        return false;
    };
    let absolute = if link_target.is_absolute() {
        link_target.clone()
    } else {
        target_path
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .join(link_target)
    };
    absolute.starts_with(repo)
}

fn env_path(name: &str) -> Option<PathBuf> {
    env::var_os(name).map(PathBuf::from)
}

fn env_home_path(name: &str, suffix: &str) -> Option<PathBuf> {
    env::var_os(name).map(|value| PathBuf::from(value).join(suffix))
}

fn home() -> PathBuf {
    env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("."))
}

fn parse_version(value: &str) -> Result<(u64, u64, u64)> {
    let mut parts = value.split('.');
    let major = parts
        .next()
        .ok_or_else(|| anyhow!("missing major"))?
        .parse::<u64>()?;
    let minor = parts
        .next()
        .ok_or_else(|| anyhow!("missing minor"))?
        .parse::<u64>()?;
    let patch = parts
        .next()
        .ok_or_else(|| anyhow!("missing patch"))?
        .parse::<u64>()?;
    if parts.next().is_some() {
        bail!("too many version components");
    }
    Ok((major, minor, patch))
}

fn bump_version(value: &str, level: BumpLevel) -> Result<String> {
    let (mut major, mut minor, mut patch) = parse_version(value)?;
    match level {
        BumpLevel::Major => {
            major += 1;
            minor = 0;
            patch = 0;
        }
        BumpLevel::Minor => {
            minor += 1;
            patch = 0;
        }
        BumpLevel::Patch => patch += 1,
    }
    Ok(format!("{major}.{minor}.{patch}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_frontmatter_fields() {
        let dir = tempfile_dir("parse_frontmatter_fields");
        let file = dir.join("SKILL.md");
        fs::write(
            &file,
            "---\nname: ja-ko\ndescription: Japanese: Korean\n---\n# Body\n",
        )
        .unwrap();

        let (fields, errors) = parse_frontmatter(&file).unwrap();
        assert!(errors.is_empty());
        assert_eq!(fields["name"], "ja-ko");
        assert_eq!(fields["description"], "Japanese: Korean");
    }

    #[test]
    fn bumps_semver_components() {
        assert_eq!(bump_version("1.2.3", BumpLevel::Patch).unwrap(), "1.2.4");
        assert_eq!(bump_version("1.2.3", BumpLevel::Minor).unwrap(), "1.3.0");
        assert_eq!(bump_version("1.2.3", BumpLevel::Major).unwrap(), "2.0.0");
    }

    #[test]
    fn rejects_invalid_skill_name() {
        assert!(valid_skill_name("ja-core"));
        assert!(!valid_skill_name("Ja-core"));
        assert!(!valid_skill_name("ja_core"));
    }

    fn tempfile_dir(name: &str) -> PathBuf {
        let dir = env::temp_dir().join(format!("sk-test-{}-{}", name, std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        dir
    }
}
