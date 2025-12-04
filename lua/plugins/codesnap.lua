local prefix = "<leader>S"

return {
  "mistricky/codesnap.nvim",
  build = "make",
  cmd = { "CodeSnap", "CodeSnapSave", "CodeSnapHighlight", "CodeSnapSaveHighlight" },
  keys = {
    { prefix, "", desc = " CodeSnap", mode = "x" },
    { prefix .. "s", ":'<,'>CodeSnap<CR>", desc = "Snapshot to clipboard", mode = "x" },
    { prefix .. "S", ":'<,'>CodeSnapSave<CR>", desc = "Snapshot save to file", mode = "x" },
    { prefix .. "h", ":'<,'>CodeSnapHighlight<CR>", desc = "Snapshot highlight to clipboard", mode = "x" },
    { prefix .. "H", ":'<,'>CodeSnapSaveHighlight<CR>", desc = "Snapshot highlight save to file", mode = "x" },
  },
  opts = {
    mac_window_bar = false,
    watermark = "",
    save_path = "~/Pictures/codesnap",
    bg_theme = "bamboo",
    has_breadcrumbs = false,
    has_line_number = false,
  },
}
