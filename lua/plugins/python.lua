return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "ty",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = {},
      },
    },
  },
  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      name = {
        ".venv",
      },
      auto = true,
      options = {
        notify_user_on_venv_activation = true,
      },
    },
  },
}
