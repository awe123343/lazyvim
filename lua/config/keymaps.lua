-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Quit with 'q'
vim.keymap.set("n", "q", "<cmd>q<cr>", { desc = "Quit", silent = true })

-- Record macros with 'Q'
vim.keymap.set("n", "Q", "q", { desc = "Record Macro" })
