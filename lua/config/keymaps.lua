-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Quit with 'q'
vim.keymap.set("n", "q", "<cmd>q<cr>", { desc = "Quit", silent = true })

-- Record macros with 'Q'
vim.keymap.set("n", "Q", "q", { desc = "Record Macro" })

-- Buffer switching with Tab / Shift-Tab
vim.keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })

-- Cmd+/ to toggle comment
vim.keymap.set("n", "<leader>/", "gcc", { desc = "Toggle Comment", remap = true })
vim.keymap.set("v", "<leader>/", "gc", { desc = "Toggle Comment", remap = true })
