local function test_async_compatibility()
  assert(package.loaded.promise == nil, "promise-async loaded before the shim")
  assert(package.loaded["async._core"] == nil, "async.nvim loaded before the shim")

  local async = require("async")

  assert(package.loaded.promise == nil, "requiring the shim eagerly loaded promise-async")
  assert(package.loaded["async._core"] == nil, "requiring the shim eagerly loaded async.nvim")
  assert(vim.is_callable(async), "async must remain callable for nvim-ufo")

  local root = vim.fn.getcwd() .. "/tests/fixtures/async-retired"
  local warnings = {}
  require("config.async_compat").new({
    plugins = {
      ["nvim-ufo"] = { dir = root .. "/nvim-ufo" },
      ["refactoring.nvim"] = { dir = root .. "/refactoring.nvim" },
    },
    schedule = function(callback)
      callback()
    end,
    notify_once = function(message, level, opts)
      warnings[#warnings + 1] = { message = message, level = level, opts = opts }
    end,
  })

  assert(#warnings == 1, "a namespaced consumer must trigger one retirement warning")
  assert(warnings[1].message:find("remove lua/async.lua", 1, true), warnings[1].message)
  assert(warnings[1].message:find("refactoring.nvim", 1, true), warnings[1].message)
  assert(warnings[1].level == vim.log.levels.WARN)

  assert(type(async.run) == "function", "async.run must remain available for refactoring.nvim")

  local promise_result
  async(function()
    return "promise-async"
  end):thenCall(function(result)
    promise_result = result
  end)

  assert(vim.wait(1000, function()
    return promise_result ~= nil
  end), "promise-async task did not complete")
  assert(promise_result == "promise-async")

  local task = async.run(function()
    return "async.nvim"
  end)

  assert(task:wait() == "async.nvim")

  vim.cmd.edit("tests/fixtures/async_compat")
  vim.wait(500)
  local plugins = require("lazy.core.config").plugins
  assert(plugins["nvim-ufo"]._.loaded, "nvim-ufo did not load for the fixture")
  assert(plugins["refactoring.nvim"]._.loaded, "refactoring.nvim did not load for the fixture")

  local messages = vim.api.nvim_exec2("messages", { output = true }).output
  assert(not messages:find("attempt to call upvalue 'async'", 1, true), messages)
  assert(not messages:find("upstream async module conflict appears fixed", 1, true), messages)
end

local ok, err = xpcall(test_async_compatibility, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd.cquit()
end

vim.cmd.qa()
