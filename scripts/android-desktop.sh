#!/usr/bin/env bash
# android-desktop.sh - Manage XFCE4 desktop environment on Android via VNC
set -euo pipefail

SCRIPT_NAME="android-desktop"
VNC_DIR="$HOME/.vnc"
SSH_DIR="$HOME/.ssh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

show_help() {
    cat <<EOF
Usage: $SCRIPT_NAME <command>

Manage XFCE4 desktop environment on Android (nix-on-droid) via VNC.

Commands:
    start       Start VNC server with XFCE4 desktop
    stop        Stop VNC server
    restart     Restart VNC server
    status      Show VNC server status
    ssh-start   Start SSH server
    ssh-stop    Stop SSH server
    ssh-status  Show SSH server status
    info        Show connection information
    password    Change VNC password
    help        Show this help message

Examples:
    $SCRIPT_NAME start        # Start desktop environment
    $SCRIPT_NAME info         # Get connection details
    $SCRIPT_NAME password     # Change VNC password

Connection:
    VNC clients: RealVNC Viewer, TigerVNC Viewer, VNC Viewer (Android)
    Default VNC password: vnc123 (change with: $SCRIPT_NAME password)
    Default VNC port: 5901
    Default SSH port: 8022

EOF
}

check_vnc_running() {
    pgrep -f "Xvnc.*:1" >/dev/null 2>&1
}

check_ssh_running() {
    pgrep -f "sshd -f $SSH_DIR/sshd_config" >/dev/null 2>&1
}

get_ip_address() {
    if command -v ip >/dev/null 2>&1; then
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -n1
    else
        hostname -I 2>/dev/null | awk '{print $1}' || echo "Unable to determine IP"
    fi
}

start_vnc() {
    if check_vnc_running; then
        print_warning "VNC server is already running"
        show_status
        return 0
    fi

    if [ ! -f "$VNC_DIR/start-vnc.sh" ]; then
        print_error "VNC not configured. Run 'make android' to set up."
        exit 1
    fi

    print_info "Starting VNC server with XFCE4 desktop..."
    "$VNC_DIR/start-vnc.sh"
}

stop_vnc() {
    if ! check_vnc_running; then
        print_warning "VNC server is not running"
        return 0
    fi

    if [ ! -f "$VNC_DIR/stop-vnc.sh" ]; then
        print_error "VNC stop script not found"
        exit 1
    fi

    print_info "Stopping VNC server..."
    "$VNC_DIR/stop-vnc.sh"
}

restart_vnc() {
    print_info "Restarting VNC server..."
    stop_vnc
    sleep 1
    start_vnc
}

show_status() {
    echo ""
    echo "=== VNC Server Status ==="
    if check_vnc_running; then
        print_status "VNC server is running"
        pgrep -fa "Xvnc.*:1" | head -n1
        echo ""
        echo "Connection Details:"
        IP=$(get_ip_address)
        echo "  Display:    :1"
        echo "  Port:       5901"
        if [ "$IP" != "Unable to determine IP" ]; then
            echo "  VNC URL:    vnc://$IP:5901"
        fi
        echo "  Password:   Set via 'vncpasswd' (default: vnc123)"
    else
        print_warning "VNC server is not running"
        echo "  Start with: $SCRIPT_NAME start"
    fi

    echo ""
    echo "=== SSH Server Status ==="
    if check_ssh_running; then
        print_status "SSH server is running"
        pgrep -fa "sshd -f $SSH_DIR/sshd_config" | head -n1
        echo ""
        echo "Connection Details:"
        IP=$(get_ip_address)
        echo "  Port:       8022"
        if [ "$IP" != "Unable to determine IP" ]; then
            echo "  SSH:        ssh -p 8022 nix-on-droid@$IP"
        fi
    else
        print_warning "SSH server is not running"
        echo "  Start with: $SCRIPT_NAME ssh-start"
    fi
    echo ""
}

start_ssh() {
    if check_ssh_running; then
        print_warning "SSH server is already running"
        return 0
    fi

    if [ ! -f "$SSH_DIR/start-sshd.sh" ]; then
        print_error "SSH not configured. Run 'make android' to set up."
        exit 1
    fi

    print_info "Starting SSH server..."
    "$SSH_DIR/start-sshd.sh"
}

stop_ssh() {
    if ! check_ssh_running; then
        print_warning "SSH server is not running"
        return 0
    fi

    if [ ! -f "$SSH_DIR/stop-sshd.sh" ]; then
        print_error "SSH stop script not found"
        exit 1
    fi

    print_info "Stopping SSH server..."
    "$SSH_DIR/stop-sshd.sh"
}

show_info() {
    IP=$(get_ip_address)

    cat <<EOF

=== Android Desktop Connection Info ===

VNC Connection:
  URL:       vnc://$IP:5901
  Display:   :1
  Port:      5901
  Password:  Set via 'vncpasswd' (default: vnc123)

SSH Connection:
  Command:   ssh -p 8022 nix-on-droid@$IP
  Port:      8022
  Auth:      Auto-generated key in ~/.ssh/android_client_key

Desktop Environment:
  - XFCE4 with full desktop experience
  - Firefox browser
  - File managers: Thunar, PCManFM
  - Terminal: XFCE4 Terminal, xterm
  - Audio: PulseAudio with pavucontrol

Recommended VNC Clients:
  - Desktop: RealVNC Viewer, TigerVNC Viewer
  - Android: VNC Viewer (RealVNC)
  - iOS: VNC Viewer (RealVNC)

Quick Commands:
  Start desktop:    $SCRIPT_NAME start
  Stop desktop:     $SCRIPT_NAME stop
  Check status:     $SCRIPT_NAME status
  Change password:  $SCRIPT_NAME password

EOF
}

change_password() {
    print_info "Changing VNC password..."
    vncpasswd
    print_status "VNC password updated"
    if check_vnc_running; then
        print_warning "Restart VNC for changes to take effect: $SCRIPT_NAME restart"
    fi
}

# Main command handler
case "${1:-}" in
    start)
        start_vnc
        ;;
    stop)
        stop_vnc
        ;;
    restart)
        restart_vnc
        ;;
    status)
        show_status
        ;;
    ssh-start)
        start_ssh
        ;;
    ssh-stop)
        stop_ssh
        ;;
    ssh-status)
        if check_ssh_running; then
            print_status "SSH server is running on port 8022"
        else
            print_warning "SSH server is not running"
        fi
        ;;
    info)
        show_info
        ;;
    password)
        change_password
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        print_error "No command specified"
        echo ""
        show_help
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
