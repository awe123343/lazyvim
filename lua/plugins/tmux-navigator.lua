return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", mode = "n", desc = "Tmux Navigate Left" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", mode = "n", desc = "Tmux Navigate Down" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", mode = "n", desc = "Tmux Navigate Up" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", mode = "n", desc = "Tmux Navigate Right" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", mode = "n", desc = "Tmux Navigate Previous" },
    },
  },
}
