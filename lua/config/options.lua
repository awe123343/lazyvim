-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- Tab settings (treat hard tabs as 4 spaces)
opt.tabstop = 4
-- opt.shiftwidth = 4
-- opt.softtabstop = 4
-- opt.expandtab = true

opt.list = true
-- Replace · to • to have more visible whitespace characters
opt.listchars = {
  -- space = "·", -- Removed: don't show all spaces (would show in middle of words)
  tab = "  ▸",
  nbsp = "␣",
  -- lead = "·",
  trail = "·",
  extends = "›", -- Character to show when line extends beyond screen
  precedes = "‹", -- Character to show when line precedes screen
}

-- NvChad Base46 Cache Setup
-- We keep this here to ensure the cache path is set globally before any plugin loads.
-- This is often required by base46 to know where to write/read its compiled files.
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"

-- Pre-load base46 highlights from cache
-- We keep this to ensure NvChad highlights are available as early as possible,
-- preventing a "flash of unstyled content" or missing highlights during startup
-- before the plugin actually loads.
if vim.fn.filereadable(vim.g.base46_cache .. "defaults") == 1 then
  dofile(vim.g.base46_cache .. "defaults")
end
if vim.fn.filereadable(vim.g.base46_cache .. "statusline") == 1 then
  dofile(vim.g.base46_cache .. "statusline")
end
