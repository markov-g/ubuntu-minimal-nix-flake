-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  AI plugins — Copilot + Avante (Claude)                         ║
-- ╚══════════════════════════════════════════════════════════════════╝

return {
  -- ── GitHub Copilot ──────────────────────────────────────────────
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept      = "<Tab>",
          accept_word = "<C-l>",
          accept_line = "<C-j>",
          next        = "<M-]>",
          prev        = "<M-[>",
          dismiss     = "<C-]>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help     = false,
      },
    },
  },

  -- ── Avante (Claude chat panel) ──────────────────────────────────
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      provider = "claude",
      providers = {
        claude = {
          model = "claude-sonnet-4-6",
          extra_request_body = {
            max_tokens = 4096,
          },
        },
      },
      mappings = {
        diff = {
          ours    = "co",
          theirs  = "ct",
          both    = "cb",
          cursor  = "cc",
        },
        jump = {
          next = "]]",
          prev = "[[",
        },
      },
    },
  },
}
