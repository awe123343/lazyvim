-- Icons from AstroNvim: FoldClosed (U+F460), FoldOpened (U+F47C)
local foldicon = {
  open = "\xef\x91\xbc",
  close = "\xef\x91\xa0",
}

return {
  -- nvim-ufo for better folding with LSP/Treesitter
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    opts = {
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
    },
    init = function()
      vim.o.foldcolumn = "1" -- show fold column
      vim.o.foldlevel = 99 -- start with all folds open
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    keys = {
      {
        "zR",
        function()
          require("ufo").openAllFolds()
        end,
        desc = "Open all folds",
      },
      {
        "zM",
        function()
          require("ufo").closeAllFolds()
        end,
        desc = "Close all folds",
      },
      {
        "zK",
        function()
          require("ufo").peekFoldedLinesUnderCursor()
        end,
        desc = "Peek folded lines",
      },
    },
  },

  -- statuscol.nvim for the nice fold icons in the status column
  {
    "luukvbaal/statuscol.nvim",
    event = "BufReadPost",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        relculright = true,
        segments = {
          {
            text = {
              -- Custom fold function using AstroNvim icons
              function(args)
                local foldinfo = vim.fn.foldlevel(args.lnum)
                if foldinfo == 0 then
                  return " "
                end
                local folded = vim.fn.foldclosed(args.lnum)
                if folded > 0 and folded == args.lnum then
                  return foldicon.close
                else
                  local foldstart = vim.fn.foldclosed(args.lnum) == -1
                    and vim.fn.foldlevel(args.lnum) > vim.fn.foldlevel(args.lnum - 1)
                  if foldstart then
                    return foldicon.open
                  end
                end
                return " "
              end,
            },
            click = "v:lua.ScFa",
          },
          { text = { "%s" }, click = "v:lua.ScSa" },
          { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
        },
      })
    end,
  },
}
