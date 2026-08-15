local uv = vim.uv or vim.loop
-- Preserve shell-selected project/BSP JAVA_HOME separately from the Metals
-- server JVM, which is always launched with JDK 25.
local inherited_java_home = vim.env.JAVA_HOME
local metals_java_bin
local root_patterns = { ".git" }
local ignored = {
  [".bloop"] = true,
  [".bsp"] = true,
  [".git"] = true,
  [".gradle"] = true,
  [".idea"] = true,
  [".metals"] = true,
  [".scala-build"] = true,
  build = true,
  dist = true,
  node_modules = true,
  out = true,
  target = true,
}

local function normalize(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end
  path = vim.fs.normalize((uv.fs_realpath and uv.fs_realpath(path)) or path):gsub("/+$", "")
  return path == "" and "/" or path
end

local function contains(parent, path)
  parent, path = normalize(parent), normalize(path)
  return parent and path and (parent == path or parent == "/" or vim.startswith(path, parent .. "/"))
end

local function folder_path(folder)
  if type(folder) == "string" then
    return normalize(folder)
  end
  if type(folder) ~= "table" then
    return nil
  end
  if folder.name then
    return normalize(folder.name)
  end
  if folder.uri and vim.uri_to_fname then
    local ok, path = pcall(vim.uri_to_fname, folder.uri)
    return ok and normalize(path) or nil
  end
end

local function add_folders(value, result)
  if type(value) == "string" or (type(value) == "table" and (value.name or value.uri)) then
    local path = folder_path(value)
    if path and not vim.tbl_contains(result, path) then
      result[#result + 1] = path
    end
  elseif type(value) == "table" then
    for _, folder in pairs(value) do
      add_folders(folder, result)
    end
  end
end

local function buffer_path(startpath)
  local name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  return normalize(name ~= "" and name or startpath)
end

local function workspace_root(startpath, explicit)
  local path, folders = buffer_path(startpath), {}
  add_folders(explicit, folders)
  for _, client in ipairs(vim.lsp.get_clients({ name = "metals" })) do
    add_folders(client.workspace_folders, folders)
  end
  local best
  for _, folder in ipairs(folders) do
    if contains(folder, path) and (not best or #folder > #best) then
      best = folder
    end
  end
  return best
end

local function resolve_root(startpath, explicit)
  local path = buffer_path(startpath)
  return workspace_root(startpath, explicit)
    or (path and normalize(vim.fs.root(path, root_patterns)))
    or normalize(vim.fn.getcwd())
end

local function is_scala_source(path)
  path = path:gsub("\\", "/")
  if path:sub(-6) ~= ".scala" then
    return false
  end
  for segment in path:gmatch("[^/]+") do
    if ignored[segment] then
      return false
    end
  end
  return path:sub(1, 4) == "src/" or path:find("/src/", 1, true) ~= nil
end

local function git_scala_source(root)
  if vim.fn.executable("git") ~= 1 or not vim.system then
    return nil
  end
  local ok, result = pcall(function()
    return vim.system({
      "git",
      "-C",
      root,
      "ls-files",
      "--cached",
      "--others",
      "--exclude-standard",
      "-z",
      "--",
      ".",
    }, { text = true }):wait()
  end)
  if not ok or result.code ~= 0 then
    return nil
  end
  for entry in (result.stdout or ""):gmatch("[^%z]+") do
    if is_scala_source(entry) then
      return true
    end
  end
  return false
end

local function disk_scala_source(root)
  local depth_limit, entry_limit, entries = 8, 4096, 0
  local function scan(path, depth, in_src)
    if depth > depth_limit or entries >= entry_limit then
      return false
    end
    local handle = uv.fs_scandir(path)
    if not handle then
      return false
    end
    while entries < entry_limit do
      local name, kind = uv.fs_scandir_next(handle)
      if not name then
        break
      end
      entries = entries + 1
      if kind == "file" then
        if in_src and name:sub(-6) == ".scala" then
          return true
        end
      elseif kind == "directory" and not ignored[name] then
        if scan(vim.fs.joinpath(path, name), depth + 1, in_src or name == "src") then
          return true
        end
      end
    end
    return false
  end
  return scan(root, 0, vim.fs.basename(root) == "src")
end

local function has_scala_source(root)
  local result = git_scala_source(root)
  if result == nil then
    return disk_scala_source(root)
  end
  return result
end

local function scala_filetype(bufnr)
  local ft = vim.bo[bufnr].filetype
  return ft == "scala" or ft == "sbt" or ft == "sc"
end

local function metals_client_roots(client)
  local roots = {}
  if client.workspace_folders and next(client.workspace_folders) then
    add_folders(client.workspace_folders, roots)
  else
    add_folders(client.root_dir, roots)
    add_folders(client.config and client.config.root_dir, roots)
  end
  return roots
end

local function has_metals_for_root(bufnr, root)
  local path = normalize(vim.api.nvim_buf_get_name(bufnr))
  for _, client in ipairs(vim.lsp.get_clients({ name = "metals" })) do
    for _, client_root in ipairs(metals_client_roots(client)) do
      if client_root == root or contains(client_root, path) then
        return true
      end
    end
  end
  return false
end

local function should_attach(bufnr, explicit)
  if scala_filetype(bufnr) then
    return true
  end
  local root = resolve_root(vim.api.nvim_buf_get_name(bufnr), explicit)
  return has_metals_for_root(bufnr, root) or has_scala_source(root)
end

local function with_metals(bufnr, action)
  if #vim.lsp.get_clients({ bufnr = bufnr, name = "metals" }) == 0 then
    vim.notify("Metals is not attached to this buffer", vim.log.levels.INFO)
    return
  end
  vim.api.nvim_buf_call(bufnr, action)
end

local function workspace_path(raw, prompt, must_exist)
  local path = raw ~= "" and raw or vim.fn.input(prompt, vim.fn.expand("%:p:h"), "dir")
  if not path or path == "" then
    return nil
  end
  path = vim.fn.fnamemodify(path, ":p")
  if must_exist and vim.fn.isdirectory(path) == 0 then
    vim.notify(path .. " is not a valid directory", vim.log.levels.WARN)
    return nil
  end
  return normalize(path)
end

local function change_workspace(path, remove)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, name = "metals" })) do
    if remove then
      for index, folder in ipairs(client.workspace_folders or {}) do
        if folder_path(folder) == path then
          client:notify("workspace/didChangeWorkspaceFolders", { event = { added = {}, removed = { folder } } })
          table.remove(client.workspace_folders, index)
          break
        end
      end
    else
      local exists
      for _, folder in ipairs(client.workspace_folders or {}) do
        exists = folder_path(folder) == path
        if exists then
          break
        end
      end
      if not exists then
        local folder = { name = path, uri = vim.uri_from_fname(path) }
        client:notify("workspace/didChangeWorkspaceFolders", { event = { added = { folder }, removed = {} } })
        client.workspace_folders = client.workspace_folders or {}
        client.workspace_folders[#client.workspace_folders + 1] = folder
      end
    end
  end
end

local function list_workspace()
  local result = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, name = "metals" })) do
    for _, folder in ipairs(client.workspace_folders or {}) do
      local path = folder_path(folder)
      if path and not vim.tbl_contains(result, path) then
        result[#result + 1] = path
      end
    end
  end
  return result
end

local function setup_commands()
  local function create(name, callback, opts)
    if vim.fn.exists(":" .. name) == 0 then
      vim.api.nvim_create_user_command(name, callback, opts)
    end
  end
  create("MetalsWorkspaceAdd", function(args)
    with_metals(0, function()
      local path = workspace_path(args.args, "Workspace Folder: ", true)
      if path then
        change_workspace(path)
      end
    end)
  end, { nargs = "?", desc = "Add a Metals workspace folder" })
  create("MetalsWorkspaceRemove", function(args)
    with_metals(0, function()
      local path = workspace_path(args.args, "Workspace Folder: ", false)
      if path then
        change_workspace(path, true)
      end
    end)
  end, { nargs = "?", desc = "Remove a Metals workspace folder" })
  create("MetalsWorkspaceList", function()
    with_metals(0, function()
      local folders = list_workspace()
      vim.notify(#folders == 0 and "No Metals workspace folders" or table.concat(folders, "\n"), vim.log.levels.INFO)
    end)
  end, { desc = "List Metals workspace folders" })
end

local function setup_mappings(bufnr)
  for _, mapping in ipairs({
    { "<leader>mwa", "MetalsWorkspaceAdd", "Add Metals workspace folder" },
    { "<leader>mwr", "MetalsWorkspaceRemove", "Remove Metals workspace folder" },
    { "<leader>mwl", "MetalsWorkspaceList", "List Metals workspace folders" },
  }) do
    vim.keymap.set("n", mapping[1], "<cmd>" .. mapping[2] .. "<cr>", { buffer = bufnr, desc = mapping[3], silent = true })
  end
end

local function metals_command(config, bufnr)
  local metals_config = require("metals.config")
  local probe = vim.deepcopy(config)
  probe.cmd = nil

  -- Let nvim-metals generate the launcher command so its current Metals JVM
  -- flags, .jvmopts filtering, and serverProperties stay in sync upstream.
  local cached_config = metals_config.get_config_cache()
  local ok, generated = pcall(metals_config.validate_config, probe, bufnr)
  metals_config.set_config_cache(cached_config)
  if not ok then
    error(generated)
  end
  if not generated or type(generated.cmd) ~= "table" then
    return nil
  end

  local launcher = generated.cmd[1]
  local java_options, launcher_args = {}, {}
  for index = 2, #generated.cmd do
    local argument = generated.cmd[index]
    if vim.startswith(argument, "-J-") then
      java_options[#java_options + 1] = argument:sub(3)
    else
      launcher_args[#launcher_args + 1] = argument
    end
  end

  local command = { metals_java_bin, "-Xss4m", "-Xms100m" }
  vim.list_extend(command, java_options)
  vim.list_extend(command, { "-jar", launcher })
  vim.list_extend(command, launcher_args)
  return command
end

return {
  {
    "scalameta/nvim-metals",
    ft = { "scala", "sbt", "sc", "java" },
    opts = function(_, opts)
      local config = vim.tbl_deep_extend("force", require("metals").bare_config(), opts or {})
      config.init_options = vim.tbl_deep_extend("force", {}, config.init_options or {})
      config.init_options.statusBarProvider = "off"
      config.settings = vim.tbl_deep_extend("force", {}, config.settings or {})
      config.settings.serverVersion = "[2.min,)"
      local metals_java_home = vim.trim(vim.fn.system({ "/usr/libexec/java_home", "-v25" }))
      assert(vim.v.shell_error == 0, "nvim-metals requires JDK 25")
      metals_java_bin = vim.fs.joinpath(metals_java_home, "bin", "java")
      assert(vim.fn.executable(metals_java_bin) == 1, "nvim-metals requires a JDK 25 java executable")
      config.cmd_env = vim.tbl_deep_extend("force", {}, config.cmd_env or {})
      if inherited_java_home and inherited_java_home ~= "" then
        config.cmd_env.JAVA_HOME = inherited_java_home
      end
      config.root_patterns = root_patterns
      config.find_root_dir = function(_, startpath)
        return resolve_root(startpath, config.workspace_folders)
      end
      local on_attach = config.on_attach
      config.on_attach = function(client, bufnr)
        if on_attach then
          on_attach(client, bufnr)
        end
        if not client or client.name == "metals" then
          setup_mappings(bufnr)
        end
      end
      return config
    end,
    config = function(self, config)
      setup_commands()
      local group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = self.ft,
        group = group,
        callback = function(args)
          if should_attach(args.buf, config.workspace_folders) then
            vim.api.nvim_buf_call(args.buf, function()
              local root_config = vim.deepcopy(config)
              local command = metals_command(root_config, args.buf)
              if command then
                root_config.cmd = command
              end
              require("metals").initialize_or_attach(root_config)
            end)
          end
        end,
      })
    end,
  },
}
