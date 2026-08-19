return {
  {
    "seblyng/roslyn.nvim",
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.csharp_ls = { enabled = false }
      opts.servers.omnisharp = { enabled = false }
      opts.servers.roslyn_ls = { enabled = false }
      opts.servers.roslyn = {
        settings = vim.deepcopy((vim.lsp.config.roslyn_ls or {}).settings or {}),
      }
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "roslyn-language-server",
        "netcoredbg",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cs = {
          "csharpier",
        },
      },
    },
  },
}
