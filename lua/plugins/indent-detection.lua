if true then
  return {}
end
return {
  "nmac427/guess-indent.nvim",
  -- event = "BufReadPre", -- Load before reading a file to ensure detection runs
  config = function()
    require("guess-indent").setup({})
  end,
}
