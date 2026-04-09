-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  AI plugins — Copilot + Claude Code                             ║
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

  -- ── Claude Code (terminal + editor integration) ─────────────────
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    opts = {
      terminal = {
        split_side = "right",
        split_width_percentage = 0.40,
      },
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>",             desc = "Toggle Claude Code" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",         desc = "Focus Claude Code" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",     desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>",   desc = "Continue Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",         desc = "Add buffer to Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",    desc = "Accept Claude diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",      desc = "Reject Claude diff" },
    },
  },
}
