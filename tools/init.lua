-- Preview environment for render.py: the visual side of a kernel hacker's
-- init.vim (line numbers, cursorline, cc=80, list with tab:→, a custom
-- statusline, a whitespace-error match), with this repository's newsprint
-- first on 'runtimepath'.  Plugins and linuxsty.vim are used when present.
local root = os.getenv('NP_ROOT')
local home = os.getenv('HOME')

vim.opt.rtp:prepend(root)
for _, p in ipairs({ 'vim-polyglot', 'vim-fugitive', 'vim-easymotion' }) do
  local dir = home .. '/.nvim/plugged/' .. p
  if vim.fn.isdirectory(dir) == 1 then
    vim.opt.rtp:prepend(dir)
  end
end
if vim.fn.isdirectory(home .. '/.nvim/plugged/vim-polyglot/after') == 1 then
  vim.opt.rtp:append(home .. '/.nvim/plugged/vim-polyglot/after')
end

vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')

vim.o.number = true
vim.o.showmatch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.tabstop = 8
vim.o.shiftwidth = 8
vim.o.hlsearch = true
vim.o.ruler = true
vim.o.scrolloff = 7
vim.o.cursorline = true
vim.o.colorcolumn = '80'
vim.o.list = true
vim.o.listchars = 'tab:→ ,trail:←,extends:$,nbsp:='
vim.o.statusline = '%F%m%r%h%w [FORMAT=%{&ff}] [TYPE=%Y] [POS=%04l,%04v][%p%%]'
vim.o.laststatus = 2
vim.o.foldmethod = 'indent'
vim.o.foldlevel = 100
vim.o.shortmess = 'atI'
vim.o.showcmd = true
vim.o.swapfile = false
vim.o.background = os.getenv('NP_BG') or 'light'
vim.o.termguicolors = os.getenv('NP_TGC') == '1'

local linuxsty = home .. '/.vim/plugin/linuxsty.vim'
if vim.fn.filereadable(linuxsty) == 1 then
  vim.g.linuxsty_patterns = { '/media/dev/', home .. '/chromiumos/' }
  vim.cmd('source ' .. linuxsty)
end

local opts = os.getenv('NP_OPTS')  -- a Lua table literal, e.g. "{ inks = 'sunday' }"
if opts and opts ~= '' then
  vim.g.newsprint = loadstring('return ' .. opts)()
end
vim.cmd('colorscheme newsprint')
vim.cmd([[match LeadingWS /\(\t \{1,}[^*(! ]\)\|\( \{1,}$\)\|\(^ \)/]])
