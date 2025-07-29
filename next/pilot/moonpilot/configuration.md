# Configuration

## Ignoring Files and Directories

If you have directories or files that you want MoonPilot to ignore, you can configure this by placing a `.moonagentignore` file in your project root directory. The format is identical to `.gitignore`.

If no `.moonagentignore` file is set, MoonPilot will use the project's `.gitignore` as the default. Files excluded by either ignore file will not be monitored by MoonPilot.

### .moonagentignore Format

The `.moonagentignore` file follows the same syntax as `.gitignore`:

```bash
# Ignore specific files
secret.txt
config.local.json

# Ignore directories
node_modules/
.vscode/
dist/

# Ignore file patterns
*.log
*.tmp
temp_*

# Ignore nested patterns
docs/**/*.draft.md

# Use ! to negate (include) previously ignored patterns
!important.log
```

## Project Configuration

### moonagent.yml

Create a `.moonagent/moonagent.yml` file in your project root to configure MoonPilot behavior:

```yaml
# MoonPilot Project Configuration
# This configuration file controls moon pilot behavior for this project

# Enable automatic commits when files are modified
auto_commit: true

# Additional configuration options can be added here
```

### Available Configuration Options

- **auto_commit**: When set to `true`, MoonPilot will automatically create git commits before and after making changes to your code
- Additional configuration options may be added in future versions 