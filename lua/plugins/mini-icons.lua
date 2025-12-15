return {
  {
    "nvim-mini/mini.icons",
    opts = function(_, opts)
      opts = opts or {}
      opts.filetype = opts.filetype or {}

      -- Snacks filetypes can otherwise fall back to a red icon highlight.
      -- Force them to use a muted green like the old everblush.nvim setup.
      local green = { glyph = "", hl = "MiniIconsDarkGreen" }
      opts.filetype.snacks_explorer = green
      opts.filetype.snacks_picker_list = green
      opts.filetype.snacks_picker_input = green
      opts.filetype.snacks = green
    end,
    init = function()
      -- Keep LazyVim's devicons compatibility: many plugins (including lualine)
      -- will `require("nvim-web-devicons")`. LazyVim replaces that with mini.icons.
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end

      require("util.hl").on_colorscheme("mini_icons_dark_green", function()
        -- Muted green (matches old everblush.nvim tweak)
        vim.api.nvim_set_hl(0, "MiniIconsDarkGreen", { fg = "#6c9c73" })
      end)
    end,
  },
}
