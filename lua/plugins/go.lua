return {
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    build = function()
      vim.cmd([[silent! GoInstallDeps]])
    end,
    opts = {},
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "goimports-reviser",
        "golines",
        "gofumpt",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = {
          "goimports-reviser",
          "golines",
          "gofumpt",
        },
      },
    },
  },
}
