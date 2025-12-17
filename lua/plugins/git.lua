return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 200,
      },
      current_line_blame_formatter = " <author> • <author_time:%Y-%m-%d %H:%M:%S> • <summary> • <abbrev_sha>",
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { winbar_info = true },
        file_history = { winbar_info = true },
        merge_tool = {
          layout = "diff3_horizontal",
          disable_diagnostics = true,
          winbar_info = true,
        },
      },
      hooks = {
        -- Prevents other UI plugins from messing up the diff view
        diff_buf_read = function(bufnr)
          vim.b[bufnr].view_activated = false
        end,
      },
    },
  },
}
