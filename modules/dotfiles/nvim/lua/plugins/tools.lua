-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Tool plugins                                                   ║
-- ╚══════════════════════════════════════════════════════════════════╝

return {
  -- ── Catppuccin colorscheme ──────────────────────────────────────
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      integrations = {
        aerial     = true,
        cmp        = true,
        gitsigns   = true,
        harpoon    = true,
        mason      = true,
        native_lsp = { enabled = true },
        notify     = true,
        telescope  = true,
        treesitter = true,
        which_key  = true,
      },
    },
  },

  -- ── vim-tmux-navigator ──────────────────────────────────────────
  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>",  desc = "Navigate left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>",  desc = "Navigate down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>",    desc = "Navigate up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Navigate right" },
    },
  },

  -- ── lazygit.nvim ────────────────────────────────────────────────
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- ── undotree ────────────────────────────────────────────────────
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
  },

  -- ── oil.nvim (filesystem as buffer) ─────────────────────────────
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
    },
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    },
  },

  -- ── neotest ─────────────────────────────────────────────────────
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-go",
      "rouge8/neotest-rust",
      "Issafalcon/neotest-dotnet",
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      vim.list_extend(opts.adapters, {
        require("neotest-python"),
        require("neotest-go"),
        require("neotest-rust"),
        require("neotest-dotnet"),
      })
    end,
  },

  -- ── vim-dadbod (database UI) ─────────────────────────────────────
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },

  -- ── marks.nvim ──────────────────────────────────────────────────
  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
