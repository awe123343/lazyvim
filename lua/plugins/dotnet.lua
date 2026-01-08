return {
  {
    "neovim/nvim-lspconfig",
    -- dependencies = { "Decodetalkers/csharpls-extended-lsp.nvim" },
    opts = function(_, opts)
      -- Poll until capability ready, then force refresh inlay hints
      local function make_inlay_hints_on_attach(client, bufnr)
        local function refresh_inlay_hints()
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end
          if client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            return
          end
          vim.defer_fn(refresh_inlay_hints, 1000) -- retry in 1s
        end
        vim.defer_fn(refresh_inlay_hints, 1000)
      end

      opts.servers = opts.servers or {}
      opts.servers.csharp_ls = {
        enabled = true,
        on_attach = make_inlay_hints_on_attach,
      }
      opts.servers.omnisharp = {
        enabled = false,
        on_attach = make_inlay_hints_on_attach,
      }
    end,
  },
  -- {
  --   "Decodetalkers/csharpls-extended-lsp.nvim",
  --   ft = "cs",
  --   config = function()
  --     require("csharpls_extended").buf_read_cmd_bind()
  --   end,
  -- },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "csharp-language-server",
        -- "omnisharp",
        "netcoredbg",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cs = {
          -- "csharpier",
        },
      },
    },
  },
}
