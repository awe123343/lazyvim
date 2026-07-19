local M = {}

local consumers = { "nvim-ufo", "refactoring.nvim" }

local function has_bare_async_require(source)
  return source:find("require%s*%(%s*['\"]async['\"]%s*%)") ~= nil
    or source:find("require%s+['\"]async['\"]") ~= nil
end

local function consumer_uses_bare_async(plugin)
  if not plugin or not plugin.dir then
    return nil
  end

  local files = vim.fn.globpath(plugin.dir .. "/lua", "**/*.lua", false, true)
  if #files == 0 then
    return nil
  end

  for _, path in ipairs(files) do
    local file = io.open(path, "r")
    if not file then
      return nil
    end

    local source = file:read("*a")
    file:close()
    if has_bare_async_require(source) then
      return true
    end
  end

  return false
end

local function warn_when_retired(plugins, schedule, notify_once)
  local legacy = {}
  local namespaced = {}

  for _, name in ipairs(consumers) do
    local uses_bare = consumer_uses_bare_async(plugins[name])
    if uses_bare == nil then
      return
    elseif uses_bare then
      legacy[#legacy + 1] = name
    else
      namespaced[#namespaced + 1] = name
    end
  end

  if #legacy == #consumers then
    return
  end

  schedule(function()
    notify_once(
      ("The upstream async module conflict appears fixed (namespaced consumers: %s); remove lua/async.lua and its compatibility test.")
        :format(table.concat(namespaced, ", ")),
      vim.log.levels.WARN,
      { title = "async compatibility" }
    )
  end)
end

local function load_provider(plugins, plugin_name)
  local plugin = plugins[plugin_name]
  assert(plugin and plugin.dir, ("plugin %q is unavailable"):format(plugin_name))

  local path = plugin.dir .. "/lua/async.lua"
  local chunk, err = loadfile(path)
  assert(chunk, err or ("unable to load %s"):format(path))
  return chunk()
end

function M.new(opts)
  opts = opts or {}
  local plugins = opts.plugins or require("lazy.core.config").plugins
  local providers = {}

  warn_when_retired(plugins, opts.schedule or vim.schedule, opts.notify_once or vim.notify_once)

  local function provider(name)
    if providers[name] == nil then
      providers[name] = load_provider(plugins, name)
    end
    return providers[name]
  end

  return setmetatable({}, {
    __call = function(_, ...)
      return provider("promise-async")(...)
    end,
    __index = function(_, key)
      local structured = provider("async.nvim")
      local value = structured[key]
      if value ~= nil then
        return value
      end
      return provider("promise-async")[key]
    end,
  })
end

return M
