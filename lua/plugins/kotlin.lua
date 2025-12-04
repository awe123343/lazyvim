return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = {
          root_dir = function(path)
            -- Prioritize settings.gradle/gradlew (only exists at true project root)
            return vim.fs.root(path, {
              "settings.gradle",
              "settings.gradle.kts",
              "gradlew",
            }) or vim.fs.root(path, {
              "build.gradle",
              "build.gradle.kts",
              "pom.xml",
              "build.xml",
            })
          end,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "ktfmt", "ktlint" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        kotlin = { "ktfmt", "ktlint" },
      },
    },
  },
}
