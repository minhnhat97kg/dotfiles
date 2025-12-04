#!/usr/bin/env bash
set -euo pipefail

# Claude Code Token-Saving Workflow Initializer
# Usage: claude-init [directory]
# If no directory specified, uses current directory

TEMPLATE_DIR="$HOME/.config/dotfiles/templates/claude-code"
TARGET_DIR="${1:-.}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Claude Code Workflow Initializer${NC}"
echo

# Resolve absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
echo -e "Initializing in: ${GREEN}$TARGET_DIR${NC}"
echo

# Check if CLAUDE.md already exists
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  echo -e "${YELLOW}Warning: CLAUDE.md already exists${NC}"
  read -p "Overwrite? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping CLAUDE.md"
    SKIP_CLAUDE=1
  fi
fi

# Create docs directory if it doesn't exist
mkdir -p "$TARGET_DIR/docs"

# Copy template files
if [ -z "${SKIP_CLAUDE:-}" ]; then
  cp "$TEMPLATE_DIR/CLAUDE.md.template" "$TARGET_DIR/CLAUDE.md"
  echo -e "${GREEN}✓${NC} Created CLAUDE.md"
else
  echo -e "${YELLOW}⊘${NC} Skipped CLAUDE.md"
fi

# Copy docs templates if they don't exist
if [ ! -f "$TARGET_DIR/docs/progress.md" ]; then
  cp "$TEMPLATE_DIR/docs/progress.md" "$TARGET_DIR/docs/progress.md"
  # Update date in progress.md
  TODAY=$(date +%Y-%m-%d)
  sed -i.bak "s/\[Date\]/$TODAY/" "$TARGET_DIR/docs/progress.md"
  rm -f "$TARGET_DIR/docs/progress.md.bak"
  echo -e "${GREEN}✓${NC} Created docs/progress.md"
else
  echo -e "${YELLOW}⊘${NC} docs/progress.md already exists"
fi

if [ ! -f "$TARGET_DIR/docs/workflow.md" ]; then
  cp "$TEMPLATE_DIR/docs/workflow.md" "$TARGET_DIR/docs/workflow.md"
  echo -e "${GREEN}✓${NC} Created docs/workflow.md"
else
  echo -e "${YELLOW}⊘${NC} docs/workflow.md already exists"
fi

echo
echo -e "${BLUE}Setup complete!${NC}"
echo
echo "Next steps:"
echo "1. Edit CLAUDE.md with your project context"
echo "2. In Claude Code, load context with: @CLAUDE.md"
echo "3. During sessions, use: /compact focus on [topic]"
echo "4. End sessions by appending summaries to docs/progress.md"
echo
echo -e "See ${GREEN}docs/workflow.md${NC} for detailed workflow instructions"
