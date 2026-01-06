return {
  {
    "stevearc/conform.nvim",
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        -- * matches all filetypes
        ["*"] = {
          "trim_newlines",
          "trim_whitespace",
        },
      },
    },
  },
}
