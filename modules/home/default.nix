# Entry point for shared home-manager configuration.
# Imported by all platforms via hosts/*.nix — sharedPackages passed via _module.args.
{ pkgs, sharedPackages, ... }:
{
  imports = [
    ./shell.nix
    ./editor.nix
    ./terminal.nix
    ./git.nix
    ./files.nix
  ];

  home.stateVersion = "24.11";
  home.packages = sharedPackages pkgs;

  # Pin JAVA_HOME to JDK 21 so Maven compiles at the project's source/target 21
  # (mem-system) rather than whatever JDK maven was built against.
  home.sessionVariables.JAVA_HOME = pkgs.jdk21.home;

  # Path to the Lombok jar, consumed by nvim's jdtls.lua as a -javaagent so
  # jdtls itself understands Lombok-generated code (getters/setters/etc.)
  # during static analysis, not just at compile time.
  home.sessionVariables.LOMBOK_JAR = "${pkgs.lombok}/share/java/lombok.jar";
}
