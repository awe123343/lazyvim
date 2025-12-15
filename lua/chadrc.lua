local M = {}

M.base46 = {
  theme = "everblush",
  hl_override = {
    -- base46's transparency preset ("glassy") doesn't change FloatTitle by default
    -- and it keeps a grey background, which looks odd in many setups.
    FloatTitle = { bg = "NONE" },
    FloatBorder = { bg = "NONE" },
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
