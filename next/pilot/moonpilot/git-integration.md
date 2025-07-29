# Git Integration

## Background

Currently, there are two approaches to managing AI modifications: git-based solutions and checkpoint-based solutions. We believe the git approach is superior, as it can effectively utilize existing IDE review tools, provides a clear timeline, and has good rollback characteristics. Therefore, we decided to have MoonPilot use git to manage both manual user modifications and agent modifications.

You no longer need to fear AI making chaotic code changes!

## Setup

We introduce a configuration file for the first time. Create a file `.moonagent/moonagent.yml` in your current project with the following content:

```yaml
# MoonPilot Project Configuration
# This configuration file controls moon pilot behavior for this project

# Enable automatic commits when files are modified
auto_commit: true
```

After this, restart and enter moon pilot for the changes to take effect.

## How It Works

MoonPilot follows a structured git workflow to ensure clean separation between user and agent modifications:

### Detection Phase
When you submit a requirement, MoonPilot first analyzes the current git state to detect any uncommitted changes. This includes:
- Modified files in the working directory
- Staged changes ready for commit
- New untracked files that may be relevant to your project

### User Work Preservation
If MoonPilot detects that you have previously modified code, it will automatically create a commit for your work before making any modifications. This ensures your changes are safely preserved with a clear commit message like:

```markdown
moonagent_pre_user work before implementing authentication
```

### Agent Modifications
After preserving your work, MoonPilot proceeds with its own modifications. It analyzes your requirements, implements the necessary changes, and creates a separate commit with a descriptive message:

```markdown
moonagent_post_implemented JWT authentication with tests
```

### Workflow Benefits
This two-commit approach provides:
- **Clear Attribution**: Distinguishes between user and agent contributions
- **Safe Experimentation**: Your work is always preserved before agent modifications
- **Granular Control**: Each change set can be reviewed, modified, or reverted independently
- **Conflict Resolution**: Reduces merge conflicts by maintaining clean commit boundaries


## Managing Commit History

If you don't like these commit messages, you can:

1. **Rebase**: Merge multiple commits into one using interactive rebase
2. **Rewrite**: Add your preferred commit message
3. **Submit**: Create a proper PR for submission

This approach provides several benefits:

- **Clear history**: Each change is tracked with timestamps and attribution
- **Easy review**: Use familiar git tools to review changes
- **Safe rollback**: Easily revert specific changes if needed
- **Collaboration**: Share and discuss changes using standard git workflows

## Best Practices

- Review agent commits before merging to main branches
- Use meaningful branch names when working with MoonPilot
- Combine related commits before creating pull requests
- Keep the git history clean for better collaboration 