-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- Tab settings (treat hard tabs as 4 spaces)
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true

-- Show whitespace characters (like VSCode)
opt.list = true
opt.listchars = {
  space = "·",
  tab = " ▸",
  nbsp = "␣",
  lead = ".",
  trail = ".",
  extends = "›", -- Character to show when line extends beyond screen
  precedes = "‹", -- Character to show when line precedes screen
}
