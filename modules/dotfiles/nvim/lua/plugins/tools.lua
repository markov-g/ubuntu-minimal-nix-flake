-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Tool plugins                                                   ║
-- ╚══════════════════════════════════════════════════════════════════╝

return {
  -- ── mini.animate: tuned way down for performance ────────────────
  -- Keeps the plugin loaded (so fade transitions still happen) but
  -- disables the cursor/scroll/resize animations that caused lag.
  {
    "nvim-mini/mini.animate",
    event = "VeryLazy",
    opts = function(_, opts)
      opts = opts or {}
      local animate = require("mini.animate")
      -- Disable the expensive per-step animations
      opts.cursor = { enable = false }
      opts.scroll = { enable = false }
      opts.resize = { enable = false }
      -- Keep window open/close fade — it's cheap and looks nice
      opts.open = {
        timing = animate.gen_timing.linear({ duration = 80, unit = "total" }),
      }
      opts.close = {
        timing = animate.gen_timing.linear({ duration = 80, unit = "total" }),
      }
      return opts
    end,
  },

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

  -- ── nvim-ufo: async treesitter folding (fast, no input lag) ─────
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    opts = {
      provider_selector = function(_, ft, _)
        -- Prefer treesitter, fall back to indent-based folds
        return { "treesitter", "indent" }
      end,
    },
    init = function()
      -- ufo needs these set BEFORE it loads
      vim.o.foldcolumn     = "1"
      vim.o.foldlevel      = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable     = true
    end,
    keys = {
      { "zR", function() require("ufo").openAllFolds() end,  desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
    },
  },
}
