-- Left: the colorscheme's own Lua; right: :help; bottom: an error message.
vim.cmd('edit ' .. os.getenv('NP_ROOT') .. '/colors/newsprint.lua')
vim.cmd('normal! 95Gzt')
vim.cmd('vertical help nvim_set_hl')
vim.cmd('wincmd h')
vim.api.nvim_win_set_cursor(0, { 111, 2 })
