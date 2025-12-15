return {
  {
    "folke/todo-comments.nvim",
    opts = {
      sign_priority = 200, -- Higher than default LSP diagnostic priority (100)
      colors = {
        info_blue = { "#67b0e8" },
        error_red = { "#e57474" },
      },
      keywords = {
        FIX = { color = "error_red" },
        NOTE = { color = "info_blue" },
      },
    },
  },
}
