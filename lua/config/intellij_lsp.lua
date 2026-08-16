local M = {}

local GRADLE_WORKSPACE_MARKERS = {
  "settings.gradle",
  "settings.gradle.kts",
  "gradlew",
  "gradlew.bat",
}

local MAVEN_WORKSPACE_MARKERS = {
  "mvnw",
  "mvnw.cmd",
  "pom.xml",
}

local GRADLE_MODULE_MARKERS = {
  "build.gradle",
  "build.gradle.kts",
}

local MAVEN_MODULE_MARKERS = { "pom.xml" }

local function has_marker(root, markers)
  for _, marker in ipairs(markers) do
    if vim.uv.fs_stat(vim.fs.joinpath(root, marker)) then
      return true
    end
  end
  return false
end

---@param root string?
---@return "gradle"|"maven"?
function M.detect_build_tool(root)
  if not root then
    return nil
  end

  if has_marker(root, GRADLE_WORKSPACE_MARKERS) then
    return "gradle"
  end
  if has_marker(root, MAVEN_WORKSPACE_MARKERS) then
    return "maven"
  end
  if has_marker(root, GRADLE_MODULE_MARKERS) then
    return "gradle"
  end
  if has_marker(root, MAVEN_MODULE_MARKERS) then
    return "maven"
  end
  return nil
end

---@param base_before_init fun(params: table, config: table)
---@return fun(params: table, config: table)
function M.wrap_before_init(base_before_init)
  return function(params, config)
    base_before_init(params, config)

    local root_uri = params and params.rootUri
    local root = root_uri and vim.uri_to_fname(root_uri)
    local build_tool = M.detect_build_tool(root)
    if not build_tool then
      return
    end

    config.init_options = config.init_options or {}
    config.init_options.buildTools = config.init_options.buildTools or {}
    config.init_options.buildTools[root_uri] = build_tool
    params.initializationOptions = config.init_options
  end
end

local function notify_error(message)
  vim.notify("intellij-lsp: " .. tostring(message), vim.log.levels.ERROR)
end

local function request_command(client, command, uri, callback)
  local ok, request_ok = pcall(
    client.request,
    client,
    "workspace/executeCommand",
    {
      command = command,
      arguments = { { uri = uri } },
    },
    callback
  )
  if not ok then
    notify_error(request_ok)
    return false
  end
  if request_ok == false then
    notify_error(command .. " request was rejected")
    return false
  end
  return true
end

local function current_intellij_client(bufnr)
  return vim.lsp.get_clients({ name = "intellij", bufnr = bufnr })[1]
end

---@return boolean
function M.install_dap_shim()
  local ok, dap = pcall(require, "dap")
  if not ok or type(dap.adapters) ~= "table" then
    return false
  end

  local upstream_adapter = dap.adapters.intellij
  if type(upstream_adapter) ~= "function" then
    return false
  end
  if dap.adapters.intellij == M._dap_adapter then
    return true
  end

  local adapter = function(cb, config)
    config = config or {}

    local function start_debug_server()
      local ok_start, start_err = pcall(upstream_adapter, cb, config)
      if not ok_start then
        notify_error(start_err)
      end
    end

    if config.request ~= "launch" or config.classPaths ~= nil then
      return start_debug_server()
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local client = current_intellij_client(bufnr)
    if not client then
      notify_error("no running IntelliJ client for the current buffer")
      return
    end
    local uri = vim.uri_from_bufnr(bufnr)

    local function resolve_working_directory()
      if config.cwd ~= nil then
        return start_debug_server()
      end

      request_command(client, "intellij.java.resolveWorkingDirectory", uri, function(err, result)
        if err then
          notify_error(err)
          return
        end
        local cwd = (type(result) == "table" and result.workingDirectory)
          or (type(result) == "string" and result)
        if not cwd or cwd == "" then
          notify_error("could not resolve the IntelliJ working directory")
          return
        end
        config.cwd = cwd
        start_debug_server()
      end)
    end

    request_command(client, "intellij.java.resolveClasspath", uri, function(err, result)
      if err then
        notify_error(err)
        return
      end
      if type(result) ~= "table" or type(result.classpath) ~= "table" or #result.classpath == 0 then
        notify_error("could not resolve the IntelliJ classpath")
        return
      end
      config.classPaths = result.classpath
      resolve_working_directory()
    end)
  end

  M._dap_adapter = adapter
  dap.adapters.intellij = adapter
  return true
end

---@return boolean
function M.install_debug_main_shim()
  local dap_ok = pcall(require, "dap")
  if not dap_ok then
    return false
  end

  local module_ok, dap_module = pcall(require, "intellij-lsp.dap")
  if not module_ok or type(dap_module.debug_main) ~= "function" then
    return false
  end
  if dap_module.debug_main == M._debug_main_shim then
    return true
  end

  local debug_main = function()
    local setup_ok, setup_result = pcall(dap_module.setup)
    if not setup_ok then
      notify_error(setup_result)
      return
    end
    if setup_result == false then
      notify_error("nvim-dap is not installed")
      return
    end

    local run_ok, run = pcall(require, "intellij-lsp.run")
    if not run_ok or type(run.build_invocation) ~= "function" then
      notify_error(run_ok and "run.build_invocation is unavailable" or run)
      return
    end
    if type(run.ensure_compiled) ~= "function" then
      notify_error("run.ensure_compiled is unavailable")
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local client = current_intellij_client(bufnr)
    local build_ok, build_err = pcall(run.build_invocation, function(inv, err)
      if type(inv) ~= "table" or type(inv.classpath) ~= "table" then
        notify_error(err or "could not resolve a debug invocation")
        return
      end

      local ensure_ok, ensure_err = pcall(
        run.ensure_compiled,
        client and client.root_dir or inv.cwd,
        inv.classpath,
        function(compiled)
          if not compiled then
            return
          end
          local dap_loaded, dap = pcall(require, "dap")
          if not dap_loaded or type(dap.run) ~= "function" then
            notify_error(dap_loaded and "dap.run is unavailable" or dap)
            return
          end
          local run_ok, run_err = pcall(dap.run, {
            type = "intellij",
            request = "launch",
            name = "IntelliJ: " .. inv.main_class,
            javaExec = inv.java,
            mainClass = inv.main_class,
            classPaths = inv.classpath,
            cwd = inv.cwd,
          })
          if not run_ok then
            notify_error(run_err)
          end
        end
      )
      if not ensure_ok then
        notify_error(ensure_err)
      end
    end)
    if not build_ok then
      notify_error(build_err)
    end
  end

  M._debug_main_shim = debug_main
  dap_module.debug_main = debug_main
  return true
end

function M.setup(opts)
  vim.lsp.config("intellij", {
    before_init = M.wrap_before_init(function(params, config)
      local before_init = require("intellij-lsp.config").build().before_init
      before_init(params, config)
    end),
  })
  require("intellij-lsp").setup(opts)
  M.install_dap_shim()
  M.install_debug_main_shim()
end

return M
