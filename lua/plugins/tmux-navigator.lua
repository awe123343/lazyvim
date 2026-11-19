-- In tmux: vim-tmux-navigator as usual.
-- In Rex (no tmux): move between nvim windows; at the edge, ask Rex to focus the neighbouring pane.
local function nav(wincmd, direction, tmux_cmd)
  return function()
    if vim.env.TMUX or not vim.env.REX_SESSION then
      return vim.cmd(tmux_cmd)
    end
    local win = vim.fn.winnr()
    vim.cmd("wincmd " .. wincmd)
    if vim.fn.winnr() == win then
      vim.system({
        vim.env.REX_BIN_DIR .. "/rex", "-S", vim.env.REX_SERVER,
        "api", "call", "session.focus_direction",
        vim.json.encode({ session_id = vim.env.REX_SESSION, direction = direction, wrap = true }),
      })
    end
  end
end

return {
  {
    "christoomey/vim-tmux-navigator",
    -- Keep the plugin from overwriting the mappings below when it loads.
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", nav("h", "left", "TmuxNavigateLeft"), mode = "n", desc = "Tmux Navigate Left" },
      { "<c-j>", nav("j", "down", "TmuxNavigateDown"), mode = "n", desc = "Tmux Navigate Down" },
      { "<c-k>", nav("k", "up", "TmuxNavigateUp"), mode = "n", desc = "Tmux Navigate Up" },
      { "<c-l>", nav("l", "right", "TmuxNavigateRight"), mode = "n", desc = "Tmux Navigate Right" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", mode = "n", desc = "Tmux Navigate Previous" },
    },
  },
}
