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

-- Treesitter-based folding
opt.foldmethod     = "expr"
opt.foldexpr       = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel      = 99
opt.foldlevelstart = 99
