local M = {}

function M.use_intellij()
  return vim.env.NVIM_JVM_LSP ~= "legacy"
end

return M
