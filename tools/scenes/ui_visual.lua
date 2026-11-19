-- Tabs, a fold, a visual selection, a matched paren.
vim.cmd('edit ' .. (os.getenv('NP_LINUX') or '/media/dev/linux-next') .. '/drivers/block/zram/zram_drv.c')
vim.cmd('tabedit ' .. (os.getenv('NP_LINUX') or '/media/dev/linux-next') .. '/drivers/block/zram/zram_drv.h')
vim.cmd('tabedit ' .. (os.getenv('NP_LINUX') or '/media/dev/linux-next') .. '/drivers/block/zram/Kconfig')
vim.cmd('tabfirst')
vim.cmd('2355')
vim.cmd('normal! zt')
vim.wo.foldmethod = 'manual'
vim.cmd('2373,2379fold')
vim.fn.setreg('/', [[\<page\>]])
vim.o.hlsearch = true
vim.api.nvim_win_set_cursor(0, { 2361, 5 })
