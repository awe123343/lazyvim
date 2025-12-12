return {
  -- Add Everblush plugin (for lualine/picker assets)
  {
    "Everblush/everblush.nvim",
    name = "everblush",
    lazy = false, -- Load it so lualine can find the theme file
    config = function()
      local function fix_highlights()
        local set_hl = vim.api.nvim_set_hl

        -- Everblush colors
        local green = "#8ccf7e"
        local red = "#e57474"
        local yellow = "#e5c76b"
        local orange = "#fcb163"
        local light_grey = "#50575a"
        local white = "#dadada"
        local subtle_grey = "#232a2d"

        -- Subtle backgrounds (90% black mixed with color)
        local add_bg = "#1f2d27"
        local del_bg = "#282326"
        local change_bg = "#1a2124"

        -- Whitespace/NonText - subtle
        set_hl(0, "Whitespace", { fg = subtle_grey })
        set_hl(0, "NonText", { fg = subtle_grey })
        set_hl(0, "SpecialKey", { fg = subtle_grey })
        set_hl(0, "IblIndent", { fg = subtle_grey })
        set_hl(0, "IblWhitespace", { fg = subtle_grey })

        -- Comments
        set_hl(0, "Comment", { fg = light_grey, italic = true })
        set_hl(0, "GitSignsCurrentLineBlame", { fg = light_grey, italic = true })

        -- Float title
        set_hl(0, "FloatTitle", { bg = "#14191e", fg = white })

        -- Base highlights (for fallback chain)
        set_hl(0, "Added", { fg = green })
        set_hl(0, "Removed", { fg = red })
        set_hl(0, "Changed", { fg = yellow })

        -- Diff highlights
        set_hl(0, "DiffAdd", { bg = add_bg, fg = green })
        set_hl(0, "DiffDelete", { bg = del_bg, fg = red })
        set_hl(0, "DiffChange", { bg = change_bg, fg = light_grey })
        set_hl(0, "DiffText", { bg = change_bg, fg = white })

        -- GitSigns gutter signs
        set_hl(0, "GitSignsAdd", { fg = green })
        set_hl(0, "GitSignsChange", { fg = yellow })
        set_hl(0, "GitSignsDelete", { fg = red })
        set_hl(0, "GitSignsUntracked", { fg = green })
        set_hl(0, "GitSignsTopdelete", { fg = red })
        set_hl(0, "GitSignsChangedelete", { fg = orange })

        -- GitSigns preview popup (with subtle line backgrounds)
        set_hl(0, "GitSignsAddPreview", { bg = add_bg, fg = green })
        set_hl(0, "GitSignsDeletePreview", { bg = del_bg, fg = red })

        -- GitSigns inline virtual lines (with subtle backgrounds)
        set_hl(0, "GitSignsAddVirtLn", { bg = add_bg, fg = green })
        set_hl(0, "GitSignsDeleteVirtLn", { bg = del_bg, fg = red })
        set_hl(0, "GitSignsChangeVirtLn", { bg = change_bg, fg = light_grey })

        -- GitSigns line highlights
        set_hl(0, "GitSignsAddLn", { bg = add_bg, fg = green })
        set_hl(0, "GitSignsDeleteLn", { bg = del_bg, fg = red })
        set_hl(0, "GitSignsChangeLn", { bg = change_bg, fg = light_grey })

        -- Word-level inline diff (reverse video)
        set_hl(0, "GitSignsAddInline", { reverse = true })
        set_hl(0, "GitSignsDeleteInline", { reverse = true })
        set_hl(0, "GitSignsChangeInline", { reverse = true })
        set_hl(0, "GitSignsAddVirtLnInline", { reverse = true })
        set_hl(0, "GitSignsDeleteVirtLnInline", { reverse = true })
        set_hl(0, "GitSignsChangeVirtLnInline", { reverse = true })
        set_hl(0, "GitSignsAddLnInline", { reverse = true })
        set_hl(0, "GitSignsDeleteLnInline", { reverse = true })
        set_hl(0, "GitSignsChangeLnInline", { reverse = true })

        -- Diff syntax highlighting
        set_hl(0, "diffAdded", { fg = green })
        set_hl(0, "diffRemoved", { fg = red })
        set_hl(0, "diffChanged", { fg = light_grey })
        set_hl(0, "diffLine", { fg = "#6cbfbf" })
        set_hl(0, "diffFile", { fg = white })
        set_hl(0, "diffOldFile", { fg = "#f48383" })
        set_hl(0, "diffNewFile", { fg = "#67b0e8" })
      end

      fix_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = fix_highlights,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "NvThemeReload",
        callback = fix_highlights,
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.defer_fn(fix_highlights, 100)
        end,
      })
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everblush",
    },
  },
}
