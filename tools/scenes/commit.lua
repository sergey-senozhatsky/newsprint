vim.cmd('edit ' .. os.getenv('NP_ROOT') .. '/tools/samples/git/COMMIT_EDITMSG')
vim.wo.spell = true
vim.api.nvim_win_set_cursor(0, { 1, 0 })
