-- Oxlint + Oxfmt layered on top of LazyVim eslint/prettier extras
--
-- Linting: oxlint by default; eslint only when project has eslint config
--          but no oxlint config (eslint-only project)
-- Formatting: oxfmt when project has oxlintrc.json; prettier otherwise
--             (handled by the prettier extra)

local js_fts = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "vue",
  "svelte",
}

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
}

---@param root string
---@param configs string[]
---@return boolean
local function has_config(root, configs)
  for _, name in ipairs(configs) do
    if vim.uv.fs_stat(root .. "/" .. name) then
      return true
    end
  end
  return false
end

--- True when project has eslint config but no oxlint config.
local eslint_only = LazyVim.memoize(function(root)
  return has_config(root, eslint_configs) and not has_config(root, oxlint_configs)
end)

--- True when project has oxlint config.
local is_oxc_project = LazyVim.memoize(function(root)
  return has_config(root, oxlint_configs)
end)

return {
  -- oxlint via nvim-lint (skipped for eslint-only projects)
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      for _, ft in ipairs(js_fts) do
        opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
        table.insert(opts.linters_by_ft[ft], "oxlint")
      end
      opts.linters = opts.linters or {}
      opts.linters.oxlint = {
        condition = function()
          return not eslint_only(LazyVim.root.get())
        end,
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
            if root and not has_config(root, oxlint_configs) then
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
        condition = function()
          return is_oxc_project(LazyVim.root.get())
        end,
      }
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(js_fts) do
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
