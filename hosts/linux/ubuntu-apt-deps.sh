#!/usr/bin/env bash
# hosts/linux/ubuntu-apt-deps.sh
# System (apt) packages the `ubuntu` home-manager host assumes exist.
# These are intentionally NOT installed via Nix:
#   - kitty: the Nix-built kitty crashes on EGL init on non-NixOS systems
#     (its bundled Mesa/EGL doesn't match the host GPU driver). apt's build
#     links against the system's own Mesa, which works correctly.
#   - fcitx5 + frontends: need to register GTK/Qt immodules into system-wide
#     paths that a user-level Nix profile can't reach on a non-NixOS machine.
#   - swaylock: the Nix build is compiled WITHOUT PAM and authenticates by
#     reading /etc/shadow directly, which needs the binary to be setuid root.
#     A read-only Nix-store binary can't be setuid, so it rejects every
#     (correct) password. Ubuntu's swaylock is PAM-enabled and ships its own
#     /etc/pam.d/swaylock, so it unlocks out of the box.
#   - tlp: laptop power management. It tunes runtime-PM knobs (CPU EPP, PCIe
#     ASPM, USB/WiFi/audio autosuspend, turbo) per AC/battery state that
#     power-profiles-daemon leaves alone. TLP and PPD conflict, so we mask PPD
#     and retire the old ac-watch.sh profile-switcher (see modules/home/niri.nix).
#     Must be a system service (needs /etc + root), so it can't live in
#     home-manager. Config is dropped into /etc/tlp.d/ below.
# Run once on a fresh machine: ./hosts/linux/ubuntu-apt-deps.sh
set -euo pipefail

sudo apt update
sudo apt install -y \
  kitty \
  swaylock \
  fcitx5 fcitx5-lotus fcitx5-config-qt \
  fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 \
  fcitx5-frontend-qt5 fcitx5-frontend-qt6 \
  tlp tlp-rdw

# TLP owns power management; power-profiles-daemon would fight it. Mask PPD so
# nothing (GNOME, the old ac-watch service) can pull it back up, then enable TLP.
sudo systemctl disable --now power-profiles-daemon.service 2>/dev/null || true
sudo systemctl mask power-profiles-daemon.service 2>/dev/null || true
sudo systemctl enable --now tlp.service

# Battery-focused TLP tuning for this Intel Core Ultra (Meteor Lake, intel_pstate
# in active mode → EPP-based). On AC: balanced + turbo. On battery: power EPP,
# low-power platform profile, no turbo, and aggressive device power-saving.
sudo install -d -m 0755 /etc/tlp.d
sudo tee /etc/tlp.d/01-battery.conf >/dev/null <<'EOF'
# Managed by dotfiles (hosts/linux/ubuntu-apt-deps.sh). Re-run that script to
# refresh. Reload after edits with: sudo tlp start

# --- CPU: intel_pstate active mode uses the powersave governor + EPP hint ---
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power
# Turbo eats battery for little perceived gain on light loads.
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0

# --- PCIe / runtime device power management ---
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersave
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto

# --- USB autosuspend (TLP excludes input devices/keyboards by default) ---
USB_AUTOSUSPEND=1

# --- WiFi: power save on battery only (can add a little latency) ---
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# --- Audio codec: idle-suspend on battery ---
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1
EOF

# Apply immediately (auto-detects AC vs battery).
sudo tlp start
