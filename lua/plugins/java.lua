return {
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      root_dir = function(path)
        -- Prioritize settings.gradle (only exists at true project root)
        return vim.fs.root(path, {
          "settings.gradle",
          "settings.gradle.kts",
          "gradlew",
        }) or vim.fs.root(path, {
          "build.gradle",
          "build.gradle.kts",
          "pom.xml",
          "build.xml",
        })
      end,
      on_attach = function(client, bufnr)
        if client and client.server_capabilities then
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end
      end,
      settings = {
        java = {
          format = { enabled = false },
          configuration = {
            runtimes = {
              {
                name = "JavaSE-25",
                path = "/Library/Java/JavaVirtualMachines/zulu-25.jdk/Contents/Home",
                default = true,
              },
              {
                name = "JavaSE-21",
                path = "/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home",
              },
              {
                name = "JavaSE-17",
                path = "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home",
              },
              {
                name = "JavaSE-11",
                path = "/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home",
              },
              {
                name = "JavaSE-1.8",
                path = "/Library/Java/JavaVirtualMachines/zulu-8.jdk/Contents/Home",
              },
            },
          },
        },
      },
    },
  },
}
