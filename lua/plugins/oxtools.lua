-- Oxlint + Oxfmt layered on top of LazyVim eslint/prettier extras
--
-- Linting: oxlint when project has oxlint config; eslint only when project has
--          eslint config but no oxlint config (eslint-only project)
-- Formatting: oxfmt when project has oxfmt config; prettier otherwise
--             (handled by the prettier extra)

local oxlint_fts = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "vue",
  "svelte",
}

local oxfmt_fts = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "css",
  "json",
  "jsonc",
  "markdown",
  "markdown.mdx",
  "mdx",
  "toml",
  "yaml",
  "vue",
  "svelte",
}

vim.filetype.add({
  extension = {
    mdx = "markdown.mdx",
  },
})

local eslint_configs = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.json",
  ".eslintrc.yml",
  ".eslintrc.yaml",
  "eslint.config.js",
  "eslint.config.cjs",
  "eslint.config.mjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
}

local oxlint_configs = {
  "oxlintrc.json",
  ".oxlintrc.json",
  ".oxlintrc.jsonc",
  "oxlint.config.js",
  "oxlint.config.cjs",
  "oxlint.config.mjs",
  "oxlint.config.ts",
  "oxlint.config.mts",
  "oxlint.config.cts",
}

local oxfmt_configs = {
  "oxfmtrc.json",
  ".oxfmtrc.json",
  ".oxfmtrc.jsonc",
  "oxfmt.config.js",
  "oxfmt.config.cjs",
  "oxfmt.config.mjs",
  "oxfmt.config.ts",
  "oxfmt.config.mts",
  "oxfmt.config.cts",
}

---@param filename string
---@param configs string[]
---@return string? root
---@return string? config
local function nearest_config(filename, configs)
  if not filename or filename == "" then
    return nil
  end

  local root = vim.fs.root(filename, configs)
  if not root then
    return nil
  end

  for _, name in ipairs(configs) do
    local config = root .. "/" .. name
    if vim.uv.fs_stat(config) then
      return root, config
    end
  end

  return nil
end

---@param ctx? {filename?: string}
---@return string
local function ctx_filename(ctx)
  return ctx and ctx.filename or vim.api.nvim_buf_get_name(0)
end

---@param root string?
---@param name string
---@return string
local function node_bin(root, name)
  local local_bin = root and (root .. "/node_modules/.bin/" .. name) or nil
  return local_bin and vim.uv.fs_stat(local_bin) and local_bin or name
end

--- True when buffer has eslint config but no nearer oxlint config.
local eslint_only = LazyVim.memoize(function(filename)
  return nearest_config(filename, eslint_configs) ~= nil
    and nearest_config(filename, oxlint_configs) == nil
end)

--- True when buffer has oxlint config.
local is_oxlint_project = LazyVim.memoize(function(filename)
  return nearest_config(filename, oxlint_configs) ~= nil
end)

--- True when buffer has oxfmt config.
local is_oxfmt_project = LazyVim.memoize(function(filename)
  return nearest_config(filename, oxfmt_configs) ~= nil
end)

return {
  -- oxlint via nvim-lint (skipped for eslint-only projects)
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      for _, ft in ipairs(oxlint_fts) do
        opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
        table.insert(opts.linters_by_ft[ft], "oxlint")
      end
      opts.linters = opts.linters or {}
      opts.linters.oxlint = {
        condition = function(ctx)
          return is_oxlint_project(ctx_filename(ctx)) and not eslint_only(ctx_filename(ctx))
        end,
        cmd = function()
          local root = nearest_config(vim.api.nvim_buf_get_name(0), oxlint_configs)
          return node_bin(root, "oxlint")
        end,
        args = {
          "--format",
          "github",
          "--config",
          function()
            local _, config = nearest_config(vim.api.nvim_buf_get_name(0), oxlint_configs)
            return config or ""
          end,
        },
      }
    end,
  },

  -- eslint LSP: only start for eslint-only projects (no oxlint config)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        eslint = {
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, eslint_configs)
            if root and not nearest_config(vim.api.nvim_buf_get_name(bufnr), oxlint_configs) then
              on_dir(root)
            end
          end,
        },
      },
    },
  },

  -- oxfmt via conform.nvim (prepended before prettier, stop_after_first)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters.oxfmt = {
        command = function(_, ctx)
          local root = nearest_config(ctx_filename(ctx), oxfmt_configs)
          return node_bin(root, "oxfmt")
        end,
        condition = function(_, ctx)
          return is_oxfmt_project(ctx_filename(ctx))
        end,
        cwd = function(_, ctx)
          local root = nearest_config(ctx_filename(ctx), oxfmt_configs)
          return root
        end,
        args = function(_, ctx)
          local _, config = nearest_config(ctx_filename(ctx), oxfmt_configs)
          return {
            "--config",
            config,
            "--stdin-filepath",
            ctx_filename(ctx),
          }
        end,
      }
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(oxfmt_fts) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], 1, "oxfmt")
        opts.formatters_by_ft[ft].stop_after_first = true
      end
    end,
  },

  -- Mason: ensure oxlint is installed (prettier from the extra)
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "oxlint" } },
  },
}
