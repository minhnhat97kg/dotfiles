-- Eclipse JDT Language Server. Provided by nix (`jdt-language-server` in
-- flake.nix), which puts a `jdtls` wrapper on PATH; it resolves the launcher
-- jar and requires a JDK 21+ on PATH to run (also nix-provided: jdk21).
--
-- jdtls keeps its index/metadata in a per-project workspace dir; scope it by
-- the project root so switching projects doesn't corrupt a shared cache.
local workspace = vim.fn.stdpath("cache")
  .. "/jdtls/"
  .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

-- LOMBOK_JAR is set by home-manager (modules/home/default.nix) to the nix
-- store path of lombok.jar. Passing it as a javaagent lets jdtls itself
-- understand Lombok-generated members (getters/setters/builders/etc.) for
-- completion, diagnostics, and navigation.
local cmd = { "jdtls", "-data", workspace }
local lombok_jar = vim.env.LOMBOK_JAR
if lombok_jar and lombok_jar ~= "" then
  table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
end

return {
  cmd = cmd,
  filetypes = { "java" },
  -- java-debug plugin jar (mason: java-debug-adapter). jdtls loads it as an
  -- OSGi bundle and then serves DAP sessions via the
  -- vscode.java.startDebugSession workspace command (see init.lua dap_setup).
  -- An empty glob (mason package missing) is harmless — jdtls just starts
  -- without debug support.
  init_options = {
    bundles = vim.fn.glob(
      vim.fn.stdpath("data")
        .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
      false,
      true
    ),
  },
  root_markers = {
    "settings.gradle",
    "settings.gradle.kts",
    "build.gradle",
    "build.gradle.kts",
    "pom.xml",
    "mvnw",
    "gradlew",
    ".git",
  },
  settings = {
    java = {
      signatureHelp = { enabled = true },
      completion = {
        favoriteStaticMembers = {
          "org.junit.jupiter.api.Assertions.*",
          "org.mockito.Mockito.*",
          "java.util.Objects.requireNonNull",
        },
      },
      -- Reuse the JDK jdtls itself runs under; override per-project if you
      -- need to compile against a different runtime.
      configuration = { updateBuildConfiguration = "interactive" },
      inlayHints = { parameterNames = { enabled = "all" } },
    },
  },
}
