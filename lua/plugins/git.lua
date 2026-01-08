return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "󰍵" },
        topdelete = { text = "▔" },
        changedelete = { text = "󱕖" },
        untracked = { text = "┆" },
      },
      signs_staged = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "󰍵" },
        topdelete = { text = "▔" },
        changedelete = { text = "󱕖" },
      },
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
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    opts = {
      enabled = false,
    },
    keys = {
      {
        "<leader>go",
        "<cmd>GitBlameOpenFileURL<cr>",
        desc = "Open File URL (Permalink)",
        mode = { "n", "v" },
      },
      {
        "<leader>gO",
        "<cmd>GitBlameCopyFileURL<cr>",
        desc = "Copy File URL (Permalink)",
        mode = { "n", "v" },
      },
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
