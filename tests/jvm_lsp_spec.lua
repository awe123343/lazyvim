vim.opt.rtp:prepend(vim.fn.getcwd())

local original_backend = vim.env.NVIM_JVM_LSP

local function load_policy(backend)
  vim.env.NVIM_JVM_LSP = backend
  package.loaded["config.jvm_lsp"] = nil
  return require("config.jvm_lsp")
end

local function load_kotlin_spec(backend)
  vim.env.NVIM_JVM_LSP = backend
  package.loaded["config.jvm_lsp"] = nil
  return dofile(vim.fn.getcwd() .. "/lua/plugins/kotlin.lua")[1]
end

local function load_intellij_spec(backend)
  vim.env.NVIM_JVM_LSP = backend
  package.loaded["config.jvm_lsp"] = nil
  return dofile(vim.fn.getcwd() .. "/lua/plugins/intellij.lua")[1]
end

local function load_intellij_lsp()
  package.loaded["config.intellij_lsp"] = nil
  return require("config.intellij_lsp")
end

local function make_project(files)
  local root = vim.fn.tempname()
  assert(vim.fn.mkdir(root, "p") == 1, "must create temporary project root")
  for _, file in ipairs(files) do
    local path = vim.fs.joinpath(root, file)
    assert(vim.fn.mkdir(vim.fs.dirname(path), "p") == 1, "must create temporary project parent")
    assert(vim.fn.writefile({ "" }, path) == 0, "must create temporary project marker")
  end
  return root
end

local function test_policy()
  assert(load_policy(nil).use_intellij(), "IntelliJ must be the default backend")
  assert(load_policy("intellij").use_intellij(), "intellij must select the IntelliJ backend")
  assert(not load_policy("legacy").use_intellij(), "legacy must restore jdtls and kotlin_lsp")
end

local function test_legacy_kotlin_config()
  local spec = load_kotlin_spec("legacy")
  local server = spec.opts.servers.kotlin_lsp

  assert(server.enabled == true, "legacy Kotlin LSP must be enabled")
  assert(
    vim.deep_equal(server.cmd, { "kotlin-lsp", "--stdio" }),
    "legacy Kotlin LSP must use the Mason kotlin-lsp stdio command"
  )
  assert(
    server.cmd_env.JAVA_HOME == "/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home",
    "legacy Kotlin LSP must use the Java 21 runtime"
  )
  assert(type(server.root_dir) == "function", "legacy Kotlin LSP must provide native root_dir")
  assert(
    not (spec.opts.setup and spec.opts.setup.kotlin_lsp),
    "legacy Kotlin LSP must not use deprecated lspconfig setup"
  )

  local root = nil
  local bufnr = vim.fn.bufadd(vim.fn.getcwd() .. "/tests/jvm_lsp_spec.lua")
  server.root_dir(bufnr, function(dir)
    root = dir
  end)
  assert(
    root == vim.fs.dirname(vim.fn.getcwd() .. "/tests/jvm_lsp_spec.lua"),
    "legacy Kotlin LSP root_dir must call on_dir with a fallback root"
  )

  local project = make_project({ "settings.gradle", "build.gradle", "src/Main.kt" })
  local project_root
  local project_buf = vim.fn.bufadd(vim.fs.joinpath(project, "src/Main.kt"))
  server.root_dir(project_buf, function(dir)
    project_root = dir
  end)
  assert(
    project_root == vim.fn.resolve(project),
    "legacy Kotlin root_dir must prefer workspace Gradle markers"
  )
  vim.fn.delete(project, "rf")

  local client = { server_capabilities = { documentFormattingProvider = true } }
  server.on_attach(client)
  assert(not client.server_capabilities.documentFormattingProvider, "legacy Kotlin formatting must stay disabled")
end

local function test_intellij_build_tool_config()
  local spec = load_intellij_spec("intellij")
  local intellij_lsp = load_intellij_lsp()

  assert(
    spec.opts.build_tool == nil,
    "IntelliJ LSP must select the build tool per workspace"
  )
  assert(type(spec.config) == "function", "IntelliJ LSP must use a custom config wrapper")

  local gradle = make_project({ "settings.gradle.kts", "pom.xml" })
  local maven = make_project({ "mvnw", "build.gradle" })
  local gradle_module = make_project({ "build.gradle" })
  local pom = make_project({ "pom.xml" })
  local empty = make_project({})

  assert(intellij_lsp.detect_build_tool(gradle) == "gradle", "Gradle workspace markers must win")
  assert(intellij_lsp.detect_build_tool(maven) == "maven", "Maven workspace markers must win")
  assert(intellij_lsp.detect_build_tool(gradle_module) == "gradle", "Gradle module markers must be detected")
  assert(intellij_lsp.detect_build_tool(pom) == "maven", "Maven module markers must be detected")
  assert(intellij_lsp.detect_build_tool(empty) == nil, "unmarked workspaces must leave importer unset")

  local old_lsp_config = vim.lsp.config
  local old_intellij = package.loaded["intellij-lsp"]
  local old_intellij_config = package.loaded["intellij-lsp.config"]
  local registered
  local setup_opts

  vim.lsp.config = function(name, overrides)
    if name == "intellij" then
      registered = overrides
    end
  end
  package.loaded["intellij-lsp"] = {
    setup = function(opts)
      setup_opts = opts
    end,
  }
  package.loaded["intellij-lsp.config"] = {
    build = function()
      return {
        before_init = function(params, config)
          config.init_options = config.init_options or {}
          config.init_options.base_before_init = true
          params.initializationOptions = config.init_options
        end,
      }
    end,
  }

  spec.config(nil, spec.opts)
  assert(type(registered.before_init) == "function", "IntelliJ spec must register a before_init wrapper")
  assert(setup_opts == spec.opts, "IntelliJ spec must pass opts through the plugin setup")

  local params = { rootUri = vim.uri_from_fname(gradle) }
  local config = { init_options = {} }
  registered.before_init(params, config)
  assert(config.init_options.base_before_init, "before_init wrapper must preserve upstream initialization")
  assert(
    config.init_options.buildTools[params.rootUri] == "gradle",
    "before_init wrapper must select the workspace build tool"
  )
  assert(params.initializationOptions == config.init_options, "initialization options must stay synchronized")

  local maven_params = { rootUri = vim.uri_from_fname(maven) }
  local maven_config = { init_options = {} }
  registered.before_init(maven_params, maven_config)
  assert(
    maven_config.init_options.buildTools[maven_params.rootUri] == "maven",
    "before_init wrapper must select Maven for Maven workspaces"
  )

  vim.lsp.config = old_lsp_config
  package.loaded["intellij-lsp"] = old_intellij
  package.loaded["intellij-lsp.config"] = old_intellij_config

  vim.fn.delete(gradle, "rf")
  vim.fn.delete(maven, "rf")
  vim.fn.delete(gradle_module, "rf")
  vim.fn.delete(pom, "rf")
  vim.fn.delete(empty, "rf")
end

local function test_intellij_dap_adapter()
  local intellij_lsp = load_intellij_lsp()
  local old_dap = package.loaded["dap"]
  local old_run = package.loaded["intellij-lsp.run"]
  local old_get_clients = vim.lsp.get_clients
  local old_get_current_buf = vim.api.nvim_get_current_buf
  local old_uri_from_bufnr = vim.uri_from_bufnr
  local old_notify = vim.notify
  local current_buf = 17
  local uris = {
    [17] = "file:///workspace/src/Main.kt",
    [29] = "file:///other/src/Main.java",
  }
  local clients_by_buf = {}
  local requests = {}
  local pending = {}
  local upstream_calls = {}
  local notifications = {}
  local build_calls = 0

  local function restore()
    vim.lsp.get_clients = old_get_clients
    vim.api.nvim_get_current_buf = old_get_current_buf
    vim.uri_from_bufnr = old_uri_from_bufnr
    vim.notify = old_notify
    package.loaded["dap"] = old_dap
    package.loaded["intellij-lsp.run"] = old_run
  end

  local ok, err = xpcall(function()
    vim.api.nvim_get_current_buf = function()
      return current_buf
    end
    vim.uri_from_bufnr = function(bufnr)
      return uris[bufnr]
    end
    vim.lsp.get_clients = function(filter)
      return clients_by_buf[filter and filter.bufnr] or {}
    end
    vim.notify = function(message, level)
      notifications[#notifications + 1] = { message = message, level = level }
    end

    local client_a
    client_a = {
      root_dir = "/workspace",
      request = function(_, method, params, cb)
        requests[#requests + 1] = { client = client_a, method = method, params = params }
        pending[#pending + 1] = cb
      end,
    }
    local client_b = {
      root_dir = "/other",
      request = function()
        error("wrong client used after buffer switch")
      end,
    }
    clients_by_buf[17] = { client_a }
    clients_by_buf[29] = { client_b }

    local function upstream_adapter(cb, config)
      upstream_calls[#upstream_calls + 1] = config
      cb({ type = "server", host = "127.0.0.1", port = 4711, id = "intellij_debugger" })
    end

    local dap = { adapters = { intellij = upstream_adapter } }
    package.loaded["dap"] = dap
    package.loaded["intellij-lsp.run"] = {
      build_invocation = function()
        build_calls = build_calls + 1
        error("generic adapter must not parse the current buffer")
      end,
    }

    assert(intellij_lsp.install_dap_shim(), "DAP shim must install when nvim-dap is available")
    local launch = {
      request = "launch",
      javaExec = "/explicit/java",
      mainClass = "sample.MainKt",
    }
    local received
    dap.adapters.intellij(function(adapter)
      received = adapter
    end, launch)
    assert(#requests == 1, "launch must resolve the classpath first")
    assert(requests[1].client == client_a, "launch must capture the attached client")
    assert(requests[1].params.command == "intellij.java.resolveClasspath", "launch must resolve classpath")
    assert(requests[1].params.arguments[1].uri == uris[17], "launch must capture the original buffer URI")

    current_buf = 29
    pending[1](nil, { classpath = { "/workspace/build/classes" } })
    assert(#requests == 2, "launch must resolve the working directory after classpath")
    assert(requests[2].client == client_a, "async resolution must keep the original client")
    assert(requests[2].params.command == "intellij.java.resolveWorkingDirectory", "launch must resolve cwd")
    assert(requests[2].params.arguments[1].uri == uris[17], "async resolution must keep the original URI")

    pending[2](nil, { workingDirectory = "/workspace" })
    assert(build_calls == 0, "generic adapter must not call Java-only build_invocation")
    assert(launch.classPaths[1] == "/workspace/build/classes", "launch must supply classPaths")
    assert(launch.cwd == "/workspace", "launch must supply cwd")
    assert(launch.javaExec == "/explicit/java", "launch must preserve explicit javaExec")
    assert(launch.mainClass == "sample.MainKt", "launch must preserve explicit Kotlin mainClass")
    assert(received and received.port == 4711, "launch must return the upstream IntelliJ DAP adapter")
    assert(#upstream_calls == 1, "launch must delegate to the upstream adapter once")

    local explicit = {
      request = "launch",
      classPaths = { "/explicit/classes" },
      cwd = "/explicit",
      mainClass = "NoMainBuffer.main",
    }
    dap.adapters.intellij(function() end, explicit)
    assert(#requests == 2, "explicit classPaths and cwd must skip resolver requests")
    assert(build_calls == 0, "explicit no-main launch must not parse the buffer")

    local attach = { request = "attach", hostName = "127.0.0.1", port = 5005 }
    dap.adapters.intellij(function() end, attach)
    assert(#requests == 2, "attach must not resolve project invocation data")
    assert(build_calls == 0, "attach must not call build_invocation")

    current_buf = 41
    clients_by_buf[41] = nil
    local callbacks = 0
    dap.adapters.intellij(function()
      callbacks = callbacks + 1
    end, { request = "launch", mainClass = "prompted.Main" })
    assert(callbacks == 0, "missing client must not invoke the DAP callback")
    assert(#notifications > 0, "missing client must be reported")

    current_buf = 17
    clients_by_buf[17] = {
      {
        request = function(_, _, _, cb)
          pending[#pending + 1] = cb
        end,
      },
    }
    dap.adapters.intellij(function()
      callbacks = callbacks + 1
    end, { request = "launch", mainClass = "broken.Main" })
    pending[#pending]({ message = "resolver failed" }, nil)
    assert(callbacks == 0, "resolver errors must not invoke the DAP callback")
    assert(#notifications > 1, "resolver errors must be reported")

    clients_by_buf[17] = {
      {
        request = function()
          return false
        end,
      },
    }
    local before_rejected = #notifications
    dap.adapters.intellij(function()
      callbacks = callbacks + 1
    end, { request = "launch", mainClass = "rejected.Main" })
    assert(callbacks == 0, "rejected resolver requests must not invoke the DAP callback")
    assert(#notifications == before_rejected + 1, "rejected resolver requests must be reported")
  end, debug.traceback)
  restore()
  assert(ok, err)
end

local function test_intellij_debug_main()
  local intellij_lsp = load_intellij_lsp()
  local old_dap = package.loaded["dap"]
  local old_run = package.loaded["intellij-lsp.run"]
  local old_dap_module = package.loaded["intellij-lsp.dap"]
  local old_get_clients = vim.lsp.get_clients
  local old_notify = vim.notify
  local received
  local setup_calls = 0
  local build_calls = 0
  local ensure_calls = 0

  local function restore()
    vim.lsp.get_clients = old_get_clients
    vim.notify = old_notify
    package.loaded["dap"] = old_dap
    package.loaded["intellij-lsp.run"] = old_run
    package.loaded["intellij-lsp.dap"] = old_dap_module
  end

  local ok, err = xpcall(function()
    package.loaded["dap"] = {
      run = function(config)
        received = config
      end,
    }
    package.loaded["intellij-lsp.run"] = {
      build_invocation = function(cb)
        build_calls = build_calls + 1
        cb({
          java = "/jdk/bin/java",
          main_class = "org.example.Main",
          classpath = { "/project/build/classes" },
          cwd = "/project",
        })
      end,
      ensure_compiled = function(root, classpath, cb)
        ensure_calls = ensure_calls + 1
        assert(root == "/project", "debug_main must preserve the invocation root")
        assert(classpath[1] == "/project/build/classes", "debug_main must preserve the invocation classpath")
        cb(true)
      end,
    }
    package.loaded["intellij-lsp.dap"] = {
      setup = function()
        setup_calls = setup_calls + 1
        return true
      end,
      debug_main = function()
        error("upstream debug_main must be replaced")
      end,
    }
    vim.lsp.get_clients = function()
      return { { root_dir = "/project" } }
    end
    vim.notify = function()
      error("debug_main fixture must not notify")
    end

    assert(intellij_lsp.install_debug_main_shim(), "debug_main shim must install")
    local wrapped = package.loaded["intellij-lsp.dap"].debug_main
    assert(intellij_lsp.install_debug_main_shim(), "debug_main shim must be idempotent")
    assert(package.loaded["intellij-lsp.dap"].debug_main == wrapped, "debug_main must not be wrapped twice")
    package.loaded["intellij-lsp.dap"].debug_main()

    assert(setup_calls == 1, "debug_main must initialize upstream DAP once")
    assert(build_calls == 1, "debug_main must resolve the invocation once")
    assert(ensure_calls == 1, "debug_main must preserve ensure_compiled")
    assert(received.classPaths[1] == "/project/build/classes", "debug_main must pass classPaths to DAP")
    assert(received.cwd == "/project", "debug_main must pass cwd to DAP")
    assert(received.javaExec == "/jdk/bin/java", "debug_main must pass javaExec to DAP")
    assert(received.mainClass == "org.example.Main", "debug_main must pass mainClass to DAP")
  end, debug.traceback)
  restore()
  assert(ok, err)
end

local ok, err = xpcall(function()
  test_policy()
  test_legacy_kotlin_config()
  test_intellij_build_tool_config()
  test_intellij_dap_adapter()
  test_intellij_debug_main()
end, debug.traceback)
vim.env.NVIM_JVM_LSP = original_backend

if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd.cquit()
end

vim.cmd.qa()
