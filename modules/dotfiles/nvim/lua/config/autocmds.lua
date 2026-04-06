-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Autocommands                                                   ║
-- ╚══════════════════════════════════════════════════════════════════╝
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("YankHighlight", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Resize splits on terminal resize
autocmd("VimResized", {
  group = augroup("ResizeSplits", { clear = true }),
  callback = function() vim.cmd("tabdo wincmd =") end,
})

-- Close certain buffers with q
autocmd("FileType", {
  group = augroup("CloseWithQ", { clear = true }),
  pattern = { "help", "qf", "man", "notify", "lspinfo", "checkhealth" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

-- Wrap + spell for prose filetypes
autocmd("FileType", {
  group = augroup("ProseSettings", { clear = true }),
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.wrap  = true
    vim.opt_local.spell = true
  end,
})

-- 2-space indent for Nix files
autocmd("FileType", {
  group = augroup("NixIndent", { clear = true }),
  pattern = { "nix" },
  callback = function()
    vim.opt_local.tabstop    = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab  = true
  end,
})
