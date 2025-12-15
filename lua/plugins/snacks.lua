return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      replace_netrw = true,
    },
    picker = {
      hidden = true,
      ignored = true,
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
        files = {
          hidden = true,
          ignored = true,
        },
      },
    },
  },
}
