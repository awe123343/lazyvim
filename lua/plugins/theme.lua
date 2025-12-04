return {
  -- Add Everblush plugin (for lualine/picker assets)
  {
    "Everblush/everblush.nvim",
    name = "everblush",
    lazy = false, -- Load it so lualine can find the theme file
    config = function()
      -- Define our overrides function here to run when the theme plugin loads
      local function fix_highlights()
        local set_hl = vim.api.nvim_set_hl
        local subtle_grey = "#232a2d" -- Darker grey for invisible chars (less visible)
        local comment_grey = "#50575a" -- Lighter grey for actual comments (visible)

        -- Fix for Red ListChars (Whitespace/NonText) - keep these subtle
        set_hl(0, "Whitespace", { fg = subtle_grey })
        set_hl(0, "NonText", { fg = subtle_grey })
        set_hl(0, "SpecialKey", { fg = subtle_grey })

        -- Indentation guides - subtle
        set_hl(0, "IblIndent", { fg = subtle_grey })
        set_hl(0, "IblWhitespace", { fg = subtle_grey })

        -- Ensure Comments and Inline Blame use the visible grey
        -- "Comment" handles code comments
        -- "GitSignsCurrentLineBlame" handles inline git blame (if you use gitsigns)
        set_hl(0, "Comment", { fg = comment_grey, italic = true })
        set_hl(0, "GitSignsCurrentLineBlame", { fg = comment_grey, italic = true })
      end

      -- Apply immediately
      fix_highlights()

      -- Apply on ColorScheme change
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = fix_highlights,
      })

      -- Apply on NvThemeReload (base46 reload)
      vim.api.nvim_create_autocmd("User", {
        pattern = "NvThemeReload",
        callback = fix_highlights,
      })
    end,
  },

  -- Configure LazyVim to use everblush
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everblush",
    },
  },
}
