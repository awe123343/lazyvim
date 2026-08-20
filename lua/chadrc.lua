local M = {}

local light_grey = "light_grey"

-- Everblush semantic token accents (TokyoNight-style differentiation)
-- TokyoNight differentiates a few semantic token groups beyond Treesitter by using subtle tints.
-- We keep the same *idea* but pick colors that fit Everblush.
local semantic = {
  interface = "#7dd3c0", -- Lighter teal - interfaces stand out from classes
  defaultlib = "#5a9fd4", -- Muted blue - built-in types look different
  error = "#e57474", -- Red for unresolved references
}

M.base46 = {
  theme = "everblush",
  hl_add = {
    BufferLineFill = { bg = "black2" },

    -- Gitsigns current-line blame defaults to `NonText` (very dim in base46/everblush).
    -- Keep it subtle but readable (matches your previous everblush.nvim tweak).
    GitSignsCurrentLineBlame = { fg = light_grey, italic = true },

    -- Used by `LazyVim.lualine.pretty_path()` in our lualine config.
    -- Keep paths readable but NOT italic (unlike `Comment`).
    LualinePath = { fg = light_grey },

    -------------------------------------------------------------------------
    -- LSP Semantic Tokens (TokyoNight-style enhancements)
    -- Ported from TokyoNight's `groups/semantic_tokens.lua`, but using Everblush-tinted accents.
    -- These add value beyond Treesitter by using LSP's deeper understanding.
    -------------------------------------------------------------------------

    -- Base semantic-to-Treesitter links (TokyoNight-style)
    ["@lsp.type.boolean"] = { link = "@boolean" },
    ["@lsp.type.builtinType"] = { link = "@type.builtin" },
    ["@lsp.type.comment"] = { link = "@comment" },
    ["@lsp.type.decorator"] = { link = "@attribute" },
    ["@lsp.type.deriveHelper"] = { link = "@attribute" },
    ["@lsp.type.enum"] = { link = "@type" },
    ["@lsp.type.enumMember"] = { link = "@constant" },
    ["@lsp.type.escapeSequence"] = { link = "@string.escape" },
    ["@lsp.type.formatSpecifier"] = { link = "@markup.list" },
    ["@lsp.type.generic"] = { link = "@variable" },
    ["@lsp.type.keyword"] = { link = "@keyword" },
    ["@lsp.type.lifetime"] = { link = "@keyword.storage" },
    ["@lsp.type.namespace"] = { link = "@module" },
    ["@lsp.type.namespace.python"] = { link = "@variable" },
    ["@lsp.type.number"] = { link = "@number" },
    ["@lsp.type.operator"] = { link = "@operator" },
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "@property" },
    ["@lsp.type.selfKeyword"] = { link = "@variable.builtin" },
    ["@lsp.type.selfTypeKeyword"] = { link = "@variable.builtin" },
    ["@lsp.type.string"] = { link = "@string" },
    ["@lsp.type.typeAlias"] = { link = "@type.definition" },

    -- Custom colors for differentiation (Everblush accents)
    ["@lsp.type.interface"] = { fg = semantic.interface }, -- Interfaces vs classes
    ["@lsp.typemod.type.defaultLibrary"] = { fg = semantic.defaultlib }, -- Built-in types
    ["@lsp.typemod.typeAlias.defaultLibrary"] = { fg = semantic.defaultlib },
    ["@lsp.type.unresolvedReference"] = { undercurl = true, sp = semantic.error },

    -- Defer to Treesitter for regular variables (don't override them globally)
    ["@lsp.type.variable"] = {},

    -- Type modifiers (TokyoNight-style)
    ["@lsp.typemod.class.defaultLibrary"] = { link = "@type.builtin" },
    ["@lsp.typemod.enum.defaultLibrary"] = { link = "@type.builtin" },
    ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "@constant.builtin" },
    ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
    ["@lsp.typemod.keyword.async"] = { link = "@keyword.coroutine" },
    ["@lsp.typemod.keyword.injected"] = { link = "@keyword" },
    ["@lsp.typemod.macro.defaultLibrary"] = { link = "@function.builtin" },
    ["@lsp.typemod.method.defaultLibrary"] = { link = "@function.builtin" },
    ["@lsp.typemod.operator.injected"] = { link = "@operator" },
    ["@lsp.typemod.string.injected"] = { link = "@string" },
    ["@lsp.typemod.struct.defaultLibrary"] = { link = "@type.builtin" },
    ["@lsp.typemod.variable.callable"] = { link = "@function" },
    ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
    ["@lsp.typemod.variable.injected"] = { link = "@variable" },
    ["@lsp.typemod.variable.static"] = { link = "@constant" },
    -- ---------------------------------------------------------------------
    -- Extra mappings for `ty` (python) semantic tokens
    -- TokyoNight targets pyright/basedpyright; `ty` uses a few different token types/modifiers.
    -- ---------------------------------------------------------------------
    ["@lsp.type.builtinConstant"] = { link = "@constant.builtin" }, -- True/False/None
    ["@lsp.typemod.variable.readonly"] = { link = "@constant" }, -- ALL_CAPS readonly vars
    ["@lsp.type.selfParameter"] = { link = "@variable.builtin" }, -- `self` in signatures
    ["@lsp.type.clsParameter"] = { link = "@variable.builtin" }, -- `cls` in signatures
    ["@lsp.type.typeParameter"] = { link = "@type" }, -- generic params
  },
  hl_override = {
    -- base46's transparency preset ("glassy") doesn't change FloatTitle by default
    -- and it keeps a grey background, which looks odd in many setups.
    FloatTitle = { bg = "NONE" },
    FloatBorder = { bg = "NONE" },

    -- Match LazyVim-vanilla: italic comments.
    -- (Keep base46's fg; just add the style.)
    Comment = { fg = light_grey, italic = true },

    -- Most code comments are highlighted via TreeSitter captures, not the legacy `Comment` group.
    -- base46 sets `@comment` without italics by default, so mirror `Comment` here.
    ["@comment"] = { fg = light_grey, italic = true },

    -- TODO/FIXME/HACK/NOTE keywords: match TokyoNight style (just fg, no bold/bg).
    ["@comment.todo"] = { fg = "black", bg = "#8ccf7e" }, -- green (subtle)
    ["@comment.note"] = { fg = "black", bg = "#67b0e8" }, -- blue (info)
    ["@comment.hint"] = { fg = "black", bg = "#67b0e8" }, -- blue (info)
    ["@comment.warning"] = { fg = "black", bg = "#e5c76b" }, -- yellow (warning)
    ["@comment.error"] = { fg = "black", bg = "#e57474" }, -- red (error/fixme)

    -- TokyoNight-style *roles*, but tuned for Everblush:
    -- - parameters: cyan (so they don't collide with JSX tags (yellow) or JSX attributes (red))
    -- - members/properties: Everblush red (closer to NvChad/base46 everblush look, esp. in Python classes)
    -- This keeps `fg` != `draft`, and also `fg` != `value/title` in JSX.
    ["@variable.parameter"] = { fg = "#6cbfbf" }, -- everblush cyan
    ["@variable.member"] = { fg = "#e57474" }, -- everblush red
    ["@variable.member.key"] = { fg = "#e57474" },
    ["@property"] = { fg = "#e57474" },
  },
}

M.ui = {
  statusline = {
    enabled = false,
  },
  tabufline = {
    enabled = false,
  },
}

return M
