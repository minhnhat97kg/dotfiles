# Claude Code Token-Saving Workflow

This document explains the token management workflow for this project.

## Core Principle
Keep CLAUDE.md under 5,000 tokens with essential project context. Use modular docs/ files for detailed information, loading them on-demand with `@filename.md`.

## Session Management

### Start of Session
```
Load context:
@CLAUDE.md
@docs/progress.md
```

### During Session
- Run `/compact <focus>` every ~40 messages to summarize and reduce token usage
- Example: `/compact focus on code changes and architectural decisions`

### End of Session
1. Run `/compact focus on code samples, decisions, and next steps`
2. Copy the compact summary and append to `docs/progress.md`
3. Format as:
   ```
   ## YYYY-MM-DD: Session Title
   - Key change 1
   - Key change 2
   - Next steps
   ```

## File Organization

### CLAUDE.md (Core Context)
- Project summary & active features
- Tech stack
- Code style & naming conventions
- Key paths and file structure
- Common commands
- Known bugs and TODOs
- Recent changes

### docs/ Directory (Modular Docs)
- `progress.md` - Session summaries over time
- `workflow.md` - This file (token management guide)
- `tableplus-to-nvim-db.md` - Specific feature documentation
- Additional files as needed for: APIs, configs, edge cases, commands

### Loading Docs On-Demand
Use `@` references when you need specific context:
```
@docs/tableplus-to-nvim-db.md - for database tooling context
@docs/progress.md - for historical session context
```

## Prompt Optimization

### Good Prompts (Precise)
- "Update modules/darwin.nix line 45 to add `jq` to systemPackages"
- "Fix the SSH key decryption in scripts/secrets-sync.sh to handle missing directory"
- "Add LSP config for Python in nvim/lsp/python.lua following the existing pattern in nvim/lsp/lua.lua"

### Bad Prompts (Vague)
- "Can you fix the bug?"
- "Make it work better"
- "Update the config"

### Batching
Instead of:
1. "What's in flake.nix?"
2. "What's in modules/shared.nix?"
3. "How do I add a package?"

Ask:
"Read flake.nix and modules/shared.nix, then explain how to add a package to shared packages vs platform-specific packages"

## Maintenance

### When CLAUDE.md Gets Too Large
1. Identify less-critical sections (detailed examples, historical notes)
2. Move to docs/[topic].md
3. Add brief reference in CLAUDE.md: "See @docs/[topic].md for details"

### Avoid /clear
Never use `/clear` unless intentionally resetting everything. Sessions remain available for reference.

## Token Budget Awareness
- Current session starts at ~20k tokens with context loading
- Running `/compact` can reduce by 50-80%
- Goal: Stay under 100k tokens per session through regular compacting
