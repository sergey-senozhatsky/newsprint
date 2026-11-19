-- zram_write_page(): strings with format specifiers, unlikely(), #define, for.
vim.cmd('edit ' .. (os.getenv('NP_LINUX') or '/media/dev/linux-next') .. '/drivers/block/zram/zram_drv.c')
if os.getenv('NP_TS') == '1' then vim.treesitter.start() end
vim.cmd('2291')
vim.cmd('normal! zt')
vim.api.nvim_win_set_cursor(0, { 2316, 1 })
