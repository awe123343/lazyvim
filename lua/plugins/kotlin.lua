local jvm_lsp = require("config.jvm_lsp")
local use_intellij = jvm_lsp.use_intellij()

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable kotlin_language_server from LazyVim extra
        kotlin_language_server = { enabled = false },
        kotlin_lsp = {
          enabled = not use_intellij,
          cmd = { "kotlin-lsp", "--stdio" },
          cmd_env = {
            JAVA_HOME = "/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home",
          },
          root_dir = function(bufnr, on_dir)
            local path = vim.api.nvim_buf_get_name(bufnr)
            local root = vim.fs.root(path, {
              "settings.gradle",
              "settings.gradle.kts",
              "gradlew",
            }) or vim.fs.root(path, {
              "build.gradle",
              "build.gradle.kts",
              "pom.xml",
              "build.xml",
            }) or vim.fs.dirname(path)
            on_dir(root)
          end,
          on_attach = function(client)
            client.server_capabilities.documentFormattingProvider = false
          end,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "kotlin-lsp", "ktfmt", "ktlint" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ktfmt = {
          prepend_args = { "--meta-style" },
        },
      },
      formatters_by_ft = {
        kotlin = { "ktfmt", "ktlint" },
      },
    },
  },
}
