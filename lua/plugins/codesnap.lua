local prefix = "<leader>S"

local function patch_codesnap()
  local data_dir = vim.fn.stdpath("data")
  local codesnap_dir = data_dir .. "/lazy/codesnap.nvim"
  local generator_so = codesnap_dir .. "/lua/generator.so"
  local init_file = codesnap_dir .. "/lua/codesnap/init.lua"

  -- Prevent downloading pre-compiled libraries
  package.loaded["codesnap.fetch"] = {
    ensure_lib = function()
      if vim.fn.filereadable(generator_so) == 1 then
        return generator_so
      end
      error("generator.so not found. Please run :Lazy build codesnap.nvim")
    end,
  }

  -- Pre-load generator using loadlib to avoid cpath pollution
  local generator_module = nil
  if vim.fn.filereadable(generator_so) == 1 then
    local load_func, err = package.loadlib(generator_so, "luaopen_generator")
    if load_func then
      generator_module = load_func()
      package.loaded["generator"] = generator_module
    end
  end

  -- Mock codesnap.module to prevent it from polluting cpath
  package.loaded["codesnap.module"] = {
    generator = generator_module,
    load_generator = function()
      return generator_module
    end,
    get_lib_extension = function()
      return "so"
    end,
    generator_file_path = function()
      return generator_so
    end,
  }

  -- Patch static config to fix save_path nil error and apply our settings
  local ok, real_static = pcall(require, "codesnap.static")
  if ok and real_static and real_static.config then
    real_static.config.save_path = "~/Pictures/codesnap"
    real_static.config.show_line_number = true
    if real_static.config.snapshot_config then
      real_static.config.snapshot_config.theme = "candy"
      if real_static.config.snapshot_config.window then
        real_static.config.snapshot_config.window.mac_window_bar = false
      end
      if
        real_static.config.snapshot_config.code_config and real_static.config.snapshot_config.code_config.breadcrumbs
      then
        real_static.config.snapshot_config.code_config.breadcrumbs.enable = true
      end
      if real_static.config.snapshot_config.watermark then
        real_static.config.snapshot_config.watermark.content = ""
      end
    end
  end

  -- Patch init.lua: fix bugs in v2.0.0
  -- 1. save_snapshot doesn't exist, should be save(file_path, config)
  -- 2. "config.save_path" variable is undefined, should use "save_path"
  if vim.fn.filereadable(init_file) == 1 then
    local content = vim.fn.readfile(init_file)
    local new_content = {}
    local patched = false
    for _, line in ipairs(content) do
      if line:find('require%("generator"%)%.save_snapshot%(config%)') then
        line = '  require("generator").save(save_path, config_module.get_config())'
        patched = true
      elseif line:find("%.%. config%.save_path") or line:find('" .. config.save_path') then
        -- Only replace standalone "config.save_path", not "static.config.save_path"
        line = line:gsub('" %.%. config%.save_path', '" .. save_path')
        patched = true
      end
      table.insert(new_content, line)
    end
    if patched then
      vim.fn.writefile(new_content, init_file)
    end
  end
end

return {
  "mistricky/codesnap.nvim",
  build = "make build_generator && rm -rf lua/libs",
  init = function()
    patch_codesnap()
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
    show_line_number = true,
    snapshot_config = {
      theme = "candy",
      window = {
        mac_window_bar = false,
      },
      code_config = {
        breadcrumbs = {
          enable = true,
        },
      },
      watermark = {
        content = "",
      },
    },
  },
}
