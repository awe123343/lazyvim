local prefix = "<leader>S"

return {
  "mistricky/codesnap.nvim",
  config = function(_, opts)
    local codesnap = require("codesnap")
    codesnap.setup(opts)

    local static = require("codesnap.static")
    local config_module = require("codesnap.config")
    local generator = require("generator")

    -- Upstream main.save is broken (references undefined `config` local and
    -- has no fallback to static.config.save_path), so override it.
    codesnap.save = function(save_path)
      local path = save_path
      if path == nil or path == "" then
        path = static.config.save_path
      end
      if path == nil or path == "" then
        error("Save path is not specified", 0)
      end

      static.config.save_path = path

      local matched_extension = path:match("%.(.+)$")
      if matched_extension ~= "png" and matched_extension ~= nil then
        error("The extension of save_path should be .png", 0)
      end

      generator.save(path, config_module.get_config())
      vim.notify("Save snapshot in " .. path .. " successfully")
    end

    -- Upstream plugin/codesnap.lua captures codesnap.save at load time,
    -- so we must re-register the command to pick up our override.
    vim.api.nvim_create_user_command("CodeSnapSave", function(params)
      local ok, err = xpcall(function()
        codesnap.save(params.fargs[1])
      end, debug.traceback)
      if not ok then
        vim.notify(err, vim.log.levels.ERROR)
      end
    end, { nargs = "*", range = "%", force = true })
  end,
  cmd = {
    "CodeSnap",
    "CodeSnapSave",
    "CodeSnapHighlight",
    "CodeSnapHighlightSave",
    "CodeSnapASCII",
  },
  keys = {
    { prefix .. "s", ":'<,'>CodeSnap<CR>", desc = "Snapshot to clipboard", mode = "v" },
    {
      prefix .. "S",
      function()
        local filename = "~/Pictures/codesnap/" .. os.date("%Y-%m-%d-%H%M%S") .. ".png"
        return ":'<,'>CodeSnapSave " .. filename .. "\r"
      end,
      desc = "Snapshot save to file",
      mode = "v",
      expr = true,
    },
    { prefix .. "h", ":'<,'>CodeSnapHighlight<CR>", desc = "Snapshot highlight to clipboard", mode = "v" },
    {
      prefix .. "H",
      function()
        local filename = "~/Pictures/codesnap/" .. os.date("%Y-%m-%d-%H%M%S") .. ".png"
        return ":'<,'>CodeSnapHighlightSave " .. filename .. "\r"
      end,
      desc = "Snapshot highlight save to file",
      mode = "v",
      expr = true,
    },
    { prefix .. "a", ":'<,'>CodeSnapASCII<CR>", desc = "Snapshot ASCII to clipboard", mode = "v" },
  },
  opts = {
    save_path = "~/Pictures/codesnap",
    show_line_number = false,
    snapshot_config = {
      theme = "candy",
      window = {
        mac_window_bar = false,
      },
      code_config = {
        breadcrumbs = {
          enable = false,
        },
      },
      watermark = {
        content = "",
      },
    },
  },
}
