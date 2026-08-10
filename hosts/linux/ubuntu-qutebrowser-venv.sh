#!/usr/bin/env bash
# hosts/linux/ubuntu-qutebrowser-venv.sh
# The Nix-built qutebrowser fails EGL/GPU init on this machine (same root
# cause as kitty, but QtWebEngine/Chromium hits it harder — the browser
# window never paints and qutebrowser exits silently). apt's qutebrowser is
# permanently frozen at 2.5.4 / Chromium 87 upstream, so instead this
# installs qutebrowser into a pip venv, which links against the system's own
# Qt/Mesa and works correctly.
# Run once on a fresh machine: ./hosts/linux/ubuntu-qutebrowser-venv.sh
set -euo pipefail

VENV_DIR="$HOME/.local/venvs/qutebrowser"

python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install qutebrowser PyQt6 PyQt6-WebEngine

echo "qutebrowser installed to $VENV_DIR"
echo "The 'qutebrowser' shell alias (see modules/home/qutebrowser.nix) points here already."
