-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Trim trailing whitespace + trailing blank lines on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    -- trim whitespace
    vim.cmd([[silent! %s/\s\+$//e]])
    -- trim trailing blank lines
    while vim.fn.getline("$") == "" and vim.fn.line("$") > 1 do
      vim.cmd("silent! $delete _")
    end
    vim.fn.winrestview(save)
  end,
})
