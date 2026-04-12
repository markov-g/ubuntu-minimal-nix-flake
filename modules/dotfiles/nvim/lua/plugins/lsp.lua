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

-- Servers/packages that lang.dotnet tries to install via Mason but
-- we don't want (either unused or fail to install cleanly).
local skip_mason = {
  "fsautocomplete",   -- F# LSP — not used
  "omnisharp",        -- legacy C# LSP — we'll rely on roslyn_ls instead
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

        -- Disable .NET servers we can't / don't want to auto-install
        fsautocomplete = { enabled = false },
        omnisharp      = { enabled = false },
      },
    },
  },

  -- ── mason.nvim: skip unwanted packages ──────────────────────────
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      opts.ensure_installed = vim.tbl_filter(function(pkg)
        return not vim.tbl_contains(skip_mason, pkg)
      end, opts.ensure_installed)
    end,
  },

  -- ── mason-lspconfig: evict Nix-managed + skipped servers ────────
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      opts.ensure_installed = vim.tbl_filter(function(server)
        return not vim.tbl_contains(nix_managed, server)
          and not vim.tbl_contains(skip_mason, server)
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
