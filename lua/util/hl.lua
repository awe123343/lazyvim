-- Utility for highlight-group management
-- Reduces boilerplate when setting highlights that must survive colorscheme changes.

local M = {}

--- Get the foreground color from the first hl group that defines one.
--- @param names string[] List of highlight group names to try (in order).
--- @return number|nil fg The foreground color as an integer, or nil if none found.
function M.get_fg(names)
  for _, name in ipairs(names) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl and type(hl.fg) == "number" then
      return hl.fg
    end
  end
  return nil
end

--- Register a callback that runs now AND on every colorscheme / theme change.
--- @param name string Unique augroup name (prevents duplicates).
--- @param fn function The callback to run (no arguments).
--- @param opts? { defer_vim_enter?: number } Optional: defer ms on VimEnter.
function M.on_colorscheme(name, fn, opts)
  opts = opts or {}

  -- Run immediately (scheduled so hl groups from base46 are likely loaded).
  vim.schedule(fn)

  local group = vim.api.nvim_create_augroup(name, { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = fn,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "NvThemeReload",
    callback = fn,
  })

  if opts.defer_vim_enter then
    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      callback = function()
        vim.defer_fn(fn, opts.defer_vim_enter)
      end,
    })
  end
end

return M
