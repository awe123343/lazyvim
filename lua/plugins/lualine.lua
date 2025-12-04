return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Define Everblush colors (Custom adjusted palette)
      local colors = {
        black = "#141b1e",
        white = "#dadada",
        red = "#e57474",
        green = "#8ccf7e",
        blue = "#67b0e8",
        yellow = "#e5c76b",
        purple = "#c47fd5",
        cyan = "#6cbfbf",
        grey = "#232a2d", -- Lighter Background
        light_grey = "#2d3437", -- Slightly lighter than grey for separation
        dark_grey = "#1e2528", -- Darker grey for inactive/bases
      }

      -- Define Everblush lualine theme (Custom Configuration)
      local everblush_theme = {
        normal = {
          a = { bg = colors.green, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        insert = {
          a = { bg = colors.blue, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        visual = {
          a = { bg = colors.purple, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        replace = {
          a = { bg = colors.red, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        command = {
          a = { bg = colors.yellow, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        inactive = {
          a = { bg = colors.black, fg = colors.white, gui = "bold" },
          b = { bg = colors.black, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
      }

      opts.options = opts.options or {}
      opts.options.theme = everblush_theme

      opts.sections = opts.sections or {}
      opts.sections.lualine_a = {
        {
          "mode",
          icon = "",
        },
      }
      return opts
    end,
  },
}
