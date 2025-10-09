# Assets Folder Agents Guide

## Architecture Overview

Collection of template files for project configurations, primarily YAML templates for development tools.

Main files: `mtg-template.yml` (Mutagen sync configuration template).

Data flow: Templates copied and customized for specific projects.

## Developer Workflows

- **Using templates**: Copy `mtg-template.yml` to project root, replace placeholders (PROJECT_NAME, LOCAL_PATH, etc.)
- **Customization**: Edit ports, paths, ignore patterns for specific project needs
- **Sync setup**: Use customized template with Mutagen for local-remote file synchronization

## Conventions & Patterns

- **Placeholder format**: Use CAPS_WITH_UNDERSCORES for variables to replace (e.g., PROJECT_NAME, LOCAL_PATH)
- **YAML structure**: Standard Mutagen config with sync sections, ignore paths, SSH settings
- **Ignore patterns**: Common ML/data files excluded (checkpoints, logs, data directories)

## Integration Points

- **Mutagen**: File synchronization tool for local-remote development
- **SSH**: Configured for remote connections with keepalive settings
- **Project structure**: Assumes standard ML project layout with data/, logs/, outputs/ directories
