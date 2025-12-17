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

return {
  {
    "nvim-lualine/lualine.nvim",
    init = function()
      local hl = require("util.hl")

      -- Fix Trouble breadcrumbs "white blocks":
      -- Trouble's statusline segments end with `%*` which resets to `StatusLine`.
      -- The separators between segments are plain spaces, so they inherit `StatusLine`.
      -- If `StatusLine.bg` doesn't match lualine's background, you get blocky separators.
      -- We keep LazyVim's breadcrumbs implementation intact and just align `StatusLine`.
      hl.on_colorscheme("lualine_statusline", function()
        vim.api.nvim_set_hl(0, "StatusLine", { fg = colors.white, bg = colors.black })
        vim.api.nvim_set_hl(0, "StatusLineNC", { fg = colors.white, bg = colors.black })
      end)

      -- We want italic comments globally, but using `Comment` as `pretty_path().directory_hl`
      -- makes the whole path italic. Create a non-italic path highlight with the same fg.
      hl.on_colorscheme("lualine_path_hl", function()
        local fg = hl.get_fg({ "Comment" })
        if fg then
          vim.api.nvim_set_hl(0, "LualinePath", { fg = fg })
        end
      end)
    end,
    opts = function(_, opts)
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

      -- Match LazyVim-vanilla look: dim directories + accent-colored filename in the path
      -- `LazyVim.lualine.pretty_path()` defaults to `filename_hl = "Bold"` and empty `directory_hl`,
      -- which in our custom lualine theme ends up looking too white.
      if opts.sections.lualine_c then
        for i, component in ipairs(opts.sections.lualine_c) do
          -- In LazyVim, pretty_path is inserted as a bare table wrapper: { LazyVim.lualine.pretty_path() }
          -- so it's a table with a single [1]=function and no extra keys.
          if
            type(component) == "table"
            and type(component[1]) == "function"
            and component.cond == nil
            and component.color == nil
            and component.icon == nil
            and component.padding == nil
            and component.separator == nil
            and component.fmt == nil
          then
            opts.sections.lualine_c[i] = {
              LazyVim.lualine.pretty_path({
                directory_hl = "LualinePath",
                filename_hl = "Bold",
              }),
            }
            break
          end
        end
      end

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
            local exclude = {
              ["trim_whitespace"] = true,
              ["trim_newlines"] = true,
            }

            for _, fmt in ipairs(formatters) do
              -- 1. If string, use it.
              -- 2. If table with .name (rare in this API but safe), use it.
              -- 3. If table array (alternatives), use the first entry [1].
              local name = type(fmt) == "string" and fmt or (fmt.name or fmt[1])

              if name and type(name) == "string" and not exclude[name] then
                table.insert(names, name)
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
