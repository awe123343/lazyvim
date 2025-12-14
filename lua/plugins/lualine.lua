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

      -- NvChad auto-lualine pastel colors
      local pastel_colors = {
        normal = "#9ae38a",
        insert = "#c4ffd3",
        visual = "#9affff",
        replace = "#f6f8ff",
        command = "#b6f0ff",
        terminal = "#b6f0ff",
        inactive = "#9ae38a",
      }

      -- Define Everblush lualine theme (Custom Configuration)
      local everblush_theme = {
        normal = {
          a = { bg = pastel_colors.normal, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        insert = {
          a = { bg = pastel_colors.insert, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        visual = {
          a = { bg = pastel_colors.visual, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        replace = {
          a = { bg = pastel_colors.replace, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        command = {
          a = { bg = pastel_colors.command, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        inactive = {
          a = { bg = colors.black, fg = colors.white, gui = "bold" },
          b = { bg = colors.black, fg = colors.white },
          c = { bg = colors.black, fg = colors.white },
        },
        terminal = {
          a = { bg = pastel_colors.terminal, fg = colors.black, gui = "bold" },
          b = { bg = colors.grey, fg = colors.white },
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

      -- Helper to get mode-based color
      local function get_mode_color()
        local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
        local mode_colors = {
          n = pastel_colors.normal,
          i = pastel_colors.insert,
          v = pastel_colors.visual,
          V = pastel_colors.visual,
          ["\22"] = pastel_colors.visual,
          s = pastel_colors.visual, -- select = visual
          S = pastel_colors.visual,
          ["\19"] = pastel_colors.visual,
          c = pastel_colors.command,
          R = pastel_colors.replace,
          t = pastel_colors.terminal,
        }
        return mode_colors[mode] or pastel_colors.normal
      end

      opts.sections.lualine_b = {
        {
          "branch",
          color = function()
            return { fg = get_mode_color() }
          end,
        },
      }

      -- Helper to deduplicate list
      local function unique_list(list)
        local seen = {}
        local result = {}
        for _, v in ipairs(list) do
          if not seen[v] then
            seen[v] = true
            table.insert(result, v)
          end
        end
        return result
      end

      -- Tab/space indicator styled like Copilot (text/icon only, no pill)
      local indent_indicator = {
        function()
          local expandtab = vim.bo.expandtab
          local size = expandtab and vim.bo.shiftwidth or vim.bo.tabstop
          if size == 0 then
            size = expandtab and vim.o.shiftwidth or vim.o.tabstop
          end
          local icon = expandtab and "␣" or "⇥"
          return string.format("%s %d", icon, size)
        end,
        padding = 1,
        color = function()
          return { fg = colors.yellow }
        end,
      }

      -- LSP/Formatters/Linters component
      local lsp_component = {
        function()
          local buf_ft = vim.bo.filetype
          local names = {}

          -- Get LSP clients (exclude copilot, null-ls)
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          if #clients == 0 then
            return "LSP Inactive"
          end

          for _, client in ipairs(clients) do
            if client.name ~= "copilot" then
              table.insert(names, client.name)
            end
          end

          -- Get formatters from conform.nvim
          local conform_ok, conform = pcall(require, "conform")
          if conform_ok then
            local formatters = conform.list_formatters_for_buffer(0)
            for _, fmt in ipairs(formatters) do
              if type(fmt) == "string" then
                table.insert(names, fmt)
              elseif type(fmt) == "table" and fmt.name then
                table.insert(names, fmt.name)
              end
            end
          end

          -- Get linters from nvim-lint
          local lint_ok, lint = pcall(require, "lint")
          if lint_ok then
            local linters = lint.linters_by_ft[buf_ft] or {}
            for _, linter in ipairs(linters) do
              if type(linter) == "string" then
                table.insert(names, linter)
              end
            end
          end

          -- Deduplicate and return
          local unique_names = unique_list(names)
          if #unique_names == 0 then
            return "LSP Inactive"
          end
          return table.concat(unique_names, ", ")
        end,
        icon = " ",
        padding = 1,
        -- separator = { left = "" },
        separator = { left = "" },
      }

      opts.sections.lualine_x = opts.sections.lualine_x or {}

      -- Append components to the end of lualine_x
      table.insert(opts.sections.lualine_x, indent_indicator)

      -- Move LSP component to lualine_y (grey background)
      opts.sections.lualine_y = {
        lsp_component,
        {
          "progress",
          separator = { left = "" },
          padding = { left = 1, right = 1 },
          color = function()
            return {
              fg = get_mode_color(),
              bg = colors.black,
            }
          end,
        },
      }

      -- Move Progress/Location to lualine_z (green background, replacing time)
      opts.sections.lualine_z = {
        {
          "location",
          padding = { left = 1, right = 1 },
        },
      }

      return opts
    end,
  },
}
