return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Add csharp_ls alongside omnisharp (from LazyVim extra)
        csharp_ls = {},
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "csharp-language-server" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cs = {
          -- "csharpier",
        },
      },
    },
  },
}
