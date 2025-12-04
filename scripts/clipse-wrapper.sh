#!/bin/bash
# Wrapper for clipse - ensure listener is running before launching TUI

set -euo pipefail

# Ensure clipse listener is running
if ! pgrep -f "clipse.*listen" >/dev/null; then
    clipse -listen &
    sleep 0.5
fi

# Run clipse TUI (it will exit after paste or when user quits)
clipse
