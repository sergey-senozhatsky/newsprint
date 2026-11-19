-- zram_add(): block comments, #if/#ifdef, numbers, true/false, strings, gotos.
vim.cmd('edit ' .. (os.getenv('NP_LINUX') or '/media/dev/linux-next') .. '/drivers/block/zram/zram_drv.c')
if os.getenv('NP_TS') == '1' then vim.treesitter.start() end
vim.o.hlsearch = false
vim.cmd('3058')
vim.cmd('normal! zt')
vim.api.nvim_win_set_cursor(0, { 3093, 1 })
