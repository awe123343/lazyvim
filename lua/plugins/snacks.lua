return {
  "folke/snacks.nvim",
  init = function()
    local hl = require("util.hl")

    -- Snacks picker/explorer dims the "dir" part of paths by default by linking it to `NonText`.
    -- With base46/everblush our `NonText` is intentionally very subtle, which makes paths hard to read.
    -- Fix: reuse the `Comment` fg for the dir portion, but without inheriting `Comment`'s styles.
    hl.on_colorscheme("snacks_picker_dir_contrast", function()
      local fg = hl.get_fg({ "Comment", "Directory", "Normal" })
      if not fg then
        return
      end

      -- `snacks.picker.config.highlights` defines these with `default=true`,
      -- so setting them here prevents Snacks from overwriting them later.
      vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = fg })
      vim.api.nvim_set_hl(0, "SnacksPickerPathHidden", { fg = fg })
      vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", { fg = fg })
      -- Untracked/ignored git files also default to `NonText` (too dim).
      vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { fg = fg })
      vim.api.nvim_set_hl(0, "SnacksPickerGitStatusIgnored", { fg = fg })
    end, { defer_vim_enter = 80 })
  end,
  opts = {
    notifier = {
      timeout = 10000, -- 10 seconds (default is 3000)
    },
    styles = {
      notification = {
        wo = { wrap = true },
      },
    },
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
