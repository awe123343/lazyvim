return {
  {
    "scalameta/nvim-metals",
    ft = {
      "scala",
      "sbt",
      "sc",
      "java",
    },
    opts = function()
      local metals_config = require("metals").bare_config()

      metals_config.init_options = {
        statusBarProvider = "off",
      }

      return metals_config
    end,
  },
}
