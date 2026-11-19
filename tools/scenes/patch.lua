vim.cmd('edit ' .. os.getenv('NP_ROOT') .. '/tools/samples/0001-zram-fix-quadratic-writeback-bitmap-search.patch')
vim.wo.spell = true
vim.api.nvim_win_set_cursor(0, { 4, 0 })
