return {
  {
    "NvChad/base46",
    build = function()
      require("base46").load_all_highlights()
    end,
  },
  {
    "NvChad/ui",
    lazy = false,
    dependencies = {
      "NvChad/base46",
      "nvim-lua/plenary.nvim",
      "NvChad/volt",
    },
    config = function()
      require("base46").load_all_highlights()
      require("nvchad")
    end,
  },
  -- Prevent LazyVim from overriding base46 highlights with its default colorscheme (tokyonight).
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function() end,
    },
  },
  { "NvChad/volt", lazy = true },
}
