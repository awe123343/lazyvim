return {
  {
    "rainbowhxch/accelerated-jk.nvim",
    keys = {
      {
        "j",
        function()
          local count = vim.v.count
          -- If a count is provided (e.g., 28j), use regular movement
          if count > 0 then
            vim.cmd("normal! " .. count .. "gj")
            return
          end
          -- Disable snacks scroll during accelerated movement
          if Snacks and Snacks.scroll then
            Snacks.scroll.disable()
          end
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(accelerated_jk_gj)", true, true, true), "")
          -- Re-enable after movement settles
          vim.defer_fn(function()
            if Snacks and Snacks.scroll then
              Snacks.scroll.enable()
            end
          end, 100)
        end,
        mode = { "n" },
        desc = "Accelerated Down",
      },
      {
        "k",
        function()
          local count = vim.v.count
          -- If a count is provided (e.g., 28k), use regular movement
          if count > 0 then
            vim.cmd("normal! " .. count .. "gk")
            return
          end
          if Snacks and Snacks.scroll then
            Snacks.scroll.disable()
          end
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(accelerated_jk_gk)", true, true, true), "")
          vim.defer_fn(function()
            if Snacks and Snacks.scroll then
              Snacks.scroll.enable()
            end
          end, 100)
        end,
        mode = { "n" },
        desc = "Accelerated Up",
      },
    },
  },
}
