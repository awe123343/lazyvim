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
  callback = function(event)
    local bufnr = event.buf

    -- Respect LazyVim's autoformat toggles
    if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
      return
    end

    local save = vim.fn.winsaveview()

    -- Trim trailing blank lines (run for all files)
    while vim.fn.getline("$") == "" and vim.fn.line("$") > 1 do
      vim.cmd("silent! $delete _")
    end

    -- Skip markdown/mdx files for whitespace trimming (preserve hard breaks)
    local ft = vim.bo[bufnr].filetype
    if ft == "markdown" or ft == "mdx" then
      vim.fn.winrestview(save)
      return
    end

    -- Trim trailing whitespace (for non-markdown files)
    vim.cmd([[keepjumps keeppatterns silent! %s/\s\+$//e]])

    vim.fn.winrestview(save)
  end,
})
