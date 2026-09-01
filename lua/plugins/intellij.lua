local jvm_lsp = require("config.jvm_lsp")

return {
  {
    "gipo355/nvim-intellij-lsp",
    enabled = jvm_lsp.use_intellij(),
    ft = { "java", "kotlin" },
    opts = {
      kotlin = true,
      data_sharing = "none",
      isolate_index = true,
      organize_imports_on_save = false,
      inlay_hints = true,
      root_markers = {
        { "gradlew", "gradlew.bat", "mvnw", "mvnw.cmd" },
        { "settings.gradle", "settings.gradle.kts", "MODULE.bazel", "WORKSPACE", "WORKSPACE.bazel" },
        { "build.gradle", "build.gradle.kts", "pom.xml", "BUILD.bazel", "BUILD" },
        { ".git" },
      },
    },
    config = function(_, opts)
      require("config.intellij_lsp").setup(opts)
    end,
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("intellij_lsp_formatting", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "intellij" then
            return
          end
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })
    end,
  },
}
