-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Editor options                                                 ║
-- ╚══════════════════════════════════════════════════════════════════╝
local opt = vim.opt

opt.relativenumber = true
opt.number         = true
opt.tabstop        = 2
opt.shiftwidth     = 2
opt.expandtab      = true
opt.smartindent    = true

opt.wrap           = false
opt.colorcolumn    = "120"
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.signcolumn     = "yes"

opt.clipboard      = "unnamedplus"
opt.undofile       = true
opt.swapfile       = false

opt.ignorecase     = true
opt.smartcase      = true

opt.splitbelow     = true
opt.splitright     = true

opt.termguicolors  = true
opt.cursorline     = true

-- Folding: treesitter-based via nvim-ufo (async, fast).
-- ufo sets foldmethod/foldexpr itself; we just set the limits.
opt.foldcolumn     = "1"
opt.foldlevel      = 99
opt.foldlevelstart = 99
opt.foldenable     = true
