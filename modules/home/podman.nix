# modules/home/podman.nix
# Rootless Podman with a Docker-API-compatible socket, so Docker-SDK-based
# tools (lazydocker connects via the Docker Go SDK, not the `docker` CLI)
# work against Podman transparently.
{ ... }:
{
  systemd.user.sockets.podman = {
    Unit = {
      Description = "Podman API Socket";
      Documentation = "man:podman-system-service(1)";
    };
    Socket = {
      ListenStream = "%t/podman/podman.sock";
      SocketMode = "0660";
    };
    Install.WantedBy = [ "sockets.target" ];
  };

  systemd.user.services.podman = {
    Unit = {
      Description = "Podman API Service";
      Requires = [ "podman.socket" ];
      After = [ "podman.socket" ];
      Documentation = "man:podman-system-service(1)";
      StartLimitIntervalSec = 0;
    };
    Service = {
      Delegate = true;
      Type = "exec";
      KillMode = "process";
      Environment = ''LOGGING="--log-level=info"'';
      ExecStart = "%h/.nix-profile/bin/podman $LOGGING system service";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Docker-SDK/CLI tools (lazydocker, docker-compose, etc.) pick this up to
  # talk to Podman's socket instead of a real Docker daemon.
  home.sessionVariables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";

  programs.zsh.shellAliases.docker = "podman";
}
