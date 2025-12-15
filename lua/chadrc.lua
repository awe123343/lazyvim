local M = {}

local light_grey = "light_grey"

M.base46 = {
  theme = "everblush",
  hl_add = {
    -- Gitsigns current-line blame defaults to `NonText` (very dim in base46/everblush).
    -- Keep it subtle but readable (matches your previous everblush.nvim tweak).
    GitSignsCurrentLineBlame = { fg = light_grey, italic = true },

    -- Used by `LazyVim.lualine.pretty_path()` in our lualine config.
    -- Keep paths readable but NOT italic (unlike `Comment`).
    LualinePath = { fg = light_grey },
  },
  hl_override = {
    -- base46's transparency preset ("glassy") doesn't change FloatTitle by default
    -- and it keeps a grey background, which looks odd in many setups.
    FloatTitle = { bg = "NONE" },
    FloatBorder = { bg = "NONE" },

    -- LazyVim shows "recorded keystrokes" in the statusline via a component that uses
    -- `Snacks.util.color("Statement")`. In everblush/base46 this can skew too red,
    -- so make `Statement` a softer purple for better contrast.
    Statement = { fg = "#ce89df" },

    -- Match LazyVim-vanilla: italic comments.
    -- (Keep base46's fg; just add the style.)
    Comment = { fg = light_grey, italic = true },

    -- Most code comments are highlighted via TreeSitter captures, not the legacy `Comment` group.
    -- base46 sets `@comment` without italics by default, so mirror `Comment` here.
    ["@comment"] = { fg = light_grey, italic = true },
  },
}

M.ui = {
  statusline = {
    enabled = false,
  },
  tabufline = {
    enabled = false,
  },
}

return M
