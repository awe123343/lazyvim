# Async compatibility retirement design

## Context

`nvim-ufo` and `refactoring.nvim` currently consume incompatible plugins that
both export the top-level Lua module `async`. The local `lua/async.lua` shim
keeps both APIs available, but eagerly loads both implementations and gives no
signal when upstream removes the collision.

## Goals

- Preserve both current consumers without changing their plugin sources.
- Avoid loading either async implementation until its API is actually used.
- Detect when fewer than two consumers still use the bare `async` module.
- Emit one actionable warning telling the user to remove the compatibility
  shim after the upstream namespace fix lands.
- Keep the check local and deterministic; startup must not access the network.

## Non-goals

- Automatically delete configuration files.
- Pin plugin commits or infer fixes from version numbers.
- Patch files under Neovim's plugin data directory.

## Design

### Lazy compatibility proxy

`lua/async.lua` will return a proxy with two lazy paths:

- Calling the proxy loads `promise-async` and forwards the call. This is the
  API currently used by `nvim-ufo`.
- Reading a field such as `run`, `await`, or `wrap` loads `async.nvim` and
  forwards the field. This is the API currently used by `refactoring.nvim`.

Each provider is loaded at most once. Merely requiring the proxy loads neither
provider.

If one consumer moves to a namespaced module, its path on the proxy is no
longer exercised and that provider is not loaded by the shim. If both consumers
move, nothing requires `lua/async.lua`, so the shim performs no work.

### Retirement detection

When the shim is loaded, it will inspect the installed Lua sources for
`nvim-ufo` and `refactoring.nvim` and conservatively look for active bare
`require("async")` / `require 'async'` calls. It will not inspect documentation
or contact upstream.

When both consumers still use the bare name, no notification is emitted. When
fewer than two do, the name collision no longer requires the compatibility
proxy. The shim schedules a `vim.notify_once()` warning that identifies which
consumer changed and asks the user to remove `lua/async.lua` and its dedicated
compatibility regression test.

Detection is intentionally advisory: failure to read a plugin source results
in no retirement warning, not a startup failure.

## Error handling

- A provider is resolved only when its API is used.
- If the required provider or its `lua/async.lua` entry point is missing, the
  shim raises an error naming that provider and expected path.
- Source-inspection failures suppress only the optional warning.
- The warning is emitted at most once per Neovim process.

## Tests

The headless Neovim regression will verify:

1. Requiring the shim alone loads neither provider implementation.
2. Calling the proxy executes a real `promise-async` task.
3. Accessing `run` executes a real `async.nvim` task.
4. The current two-consumer state emits no retirement warning.
5. A fixture representing one namespaced consumer emits exactly one removal
   warning.
6. Opening a file still loads `nvim-ufo` and `refactoring.nvim` without the
   original `attempt to call upvalue 'async'` error.

The final verification command will run the regression under headless Neovim
with isolated cache and state directories, followed by a direct file-open smoke
test and `git diff --check`.
