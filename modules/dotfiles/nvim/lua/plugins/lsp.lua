-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  LSP — dual Nix/Mason management                               ║
-- ╚══════════════════════════════════════════════════════════════════╝
--
-- Servers listed with `mason = false` are installed by Nix and already
-- on PATH. Mason handles everything else.

-- Servers that Nix manages (do NOT let Mason install these)
local nix_managed = {
  "nil_ls",     -- Nix
  "gopls",      -- Go
  "rust_analyzer",
  "clangd",     -- C/C++
  "zls",        -- Zig
  "bashls",
  "lua_ls",
  "ts_ls",
  "yamlls",
  "jsonls",
}

return {
  -- ── nvim-lspconfig: server definitions ──────────────────────────
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Nix-managed servers
        nil_ls         = { mason = false },
        gopls          = { mason = false },
        rust_analyzer  = { mason = false },
        clangd         = { mason = false },
        zls            = { mason = false },
        bashls         = { mason = false, filetypes = { "sh", "bash" } },
        lua_ls         = { mason = false },
        ts_ls          = { mason = false },
        jsonls         = { mason = false },
        yamlls         = {
          mason = false,
          settings = {
            yaml = {
              schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "/docker-compose*.yml",
              },
            },
          },
        },
      },
    },
  },

  -- ── Mason: evict Nix-managed servers from ensure_installed ──────
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      opts.ensure_installed = vim.tbl_filter(function(server)
        return not vim.tbl_contains(nix_managed, server)
      end, opts.ensure_installed)
    end,
  },

  -- ── Treesitter: additional parsers ──────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash", "c", "css", "diff", "dockerfile",
        "go", "gomod", "gosum", "html", "javascript",
        "json", "lua", "luadoc", "markdown", "markdown_inline",
        "nix", "python", "query", "regex", "rust",
        "scala", "sql", "terraform", "toml", "tsx",
        "typescript", "vim", "vimdoc", "xml", "yaml",
        "zig",
        "c_sharp",
      },
    },
  },
}
