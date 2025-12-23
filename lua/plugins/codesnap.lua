local prefix = "<leader>S"

local function patch_codesnap_runtime()
  local data_dir = vim.fn.stdpath("data")
  local plugin_dir = data_dir .. "/lazy/codesnap.nvim"
  local generator_so = plugin_dir .. "/lua/generator.so"

  local function ensure_generator_path()
    if vim.fn.filereadable(generator_so) == 1 then
      return generator_so
    end
    error("CodeSnap: generator.so not found. Run :Lazy build codesnap.nvim", 0)
  end

  package.loaded["codesnap.fetch"] = {
    ensure_lib = ensure_generator_path,
  }

  local patched_module = {
    generator = nil,
  }

  function patched_module.get_lib_extension()
    return "so"
  end

  function patched_module.generator_file_path()
    return ensure_generator_path()
  end

  function patched_module.load_generator()
    if patched_module.generator then
      return patched_module.generator
    end

    local load_func, err = package.loadlib(ensure_generator_path(), "luaopen_generator")
    if not load_func then
      error("CodeSnap: failed to load generator: " .. (err or "unknown error"), 0)
    end

    local ok, module_or_err = pcall(load_func)
    if not ok then
      error("CodeSnap: generator init failed: " .. module_or_err, 0)
    end

    patched_module.generator = module_or_err
    package.loaded["generator"] = module_or_err
    return patched_module.generator
  end

  package.loaded["codesnap.module"] = patched_module
end

return {
  "mistricky/codesnap.nvim",
  build = "make build_generator && rm -rf lua/libs",
  config = function(_, opts)
    patch_codesnap_runtime()

    local codesnap = require("codesnap")
    codesnap.setup(opts)

    local static = require("codesnap.static")
    local module = require("codesnap.module")
    local config_module = require("codesnap.config")
    local generator = module.load_generator()

    -- Ensure save_path always exists so commands do not crash
    static.config.save_path = static.config.save_path or opts.save_path or "~/Pictures/codesnap"

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

    local function redefine_command(name, fn)
      vim.api.nvim_create_user_command(name, function(params)
        local arg = params.fargs[1]
        local ok, err = xpcall(function()
          fn(arg)
        end, debug.traceback)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end, { nargs = "*", range = "%", force = true })
    end

    redefine_command("CodeSnapSave", codesnap.save)
  end,
  cmd = {
    "CodeSnap",
    "CodeSnapSave",
    "CodeSnapHighlight",
    "CodeSnapSaveHighlight",
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
        return ":'<,'>CodeSnapSaveHighlight " .. filename .. "\r"
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
