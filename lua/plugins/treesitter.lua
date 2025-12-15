return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, {
        "comment", -- for TODO/FIXME/HACK highlighting
      })
      -- Disable Treesitter highlighting for bash/sh/zsh - use Vim's built-in syntax instead
      opts.highlight = opts.highlight or {}
      opts.highlight.disable = opts.highlight.disable or {}
      vim.list_extend(opts.highlight.disable, { "bash" })
    end,
  },
}
