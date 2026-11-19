-- Replays the "how to try" steps (switching options at runtime) against
-- whatever newsprint is first on 'runtimepath':
--   nvim --headless -u NONE -i NONE --cmd 'set rtp^=.' -c 'luafile tools/check-switching.lua' -c 'qa!'
local function show(label)
  local s = vim.api.nvim_get_hl(0, { name = 'Search' })
  local v = vim.api.nvim_get_hl(0, { name = 'Visual' })
  local e = vim.api.nvim_get_hl(0, { name = 'ErrorMsg' })
  io.stdout:write(string.format('%-36s Search=%-4s Visual=%-4s ErrorMsg=%s\n',
    label, tostring(s.ctermbg), tostring(v.ctermbg), tostring(e.ctermbg)))
end

vim.o.background = 'light'
vim.cmd('colorscheme newsprint')
show('default (black & white)')

vim.g.newsprint = { accent = 'desk' }
vim.cmd('colorscheme newsprint')
show("accent = 'desk'")

vim.g.newsprint = { accent = 'red' }
vim.cmd('colorscheme newsprint')
show("accent = 'red'")

vim.g.newsprint = { accent = 'desk' }
vim.cmd('colorscheme newsprint')
vim.o.background = 'dark'
show("accent = 'desk', then bg=dark")

vim.g.newsprint = nil
vim.o.background = 'light'
show('newsprint = nil, then bg=light')

vim.cmd("let g:newsprint = {'accent': 'desk'}")
vim.cmd('colorscheme newsprint')
show("vimscript: let g:newsprint (desk)")
io.stdout:write('loaded from: ' .. vim.api.nvim_get_runtime_file('colors/newsprint.lua', false)[1] .. '\n')
