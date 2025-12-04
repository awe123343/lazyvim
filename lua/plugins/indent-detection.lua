return {
  "nmac427/guess-indent.nvim",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("guess-indent").setup({
      auto_cmd = false,
      verbose = false, -- Disable notifications
    })
    -- Run guess-indent AFTER filetype detection to override any defaults
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        vim.schedule(function()
          vim.cmd("silent! GuessIndent silent")
          vim.cmd("redrawstatus")
        end)
      end,
    })
  end,
}
