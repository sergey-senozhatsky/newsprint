-- zram_add(): comments, initializers, #if/#ifdef, gotos and labels, strings.
vim.cmd('edit ' .. (os.getenv('NP_LINUX') or '/media/dev/linux-next') .. '/drivers/block/zram/zram_drv.c')
if os.getenv('NP_TS') == '1' then
  vim.treesitter.start()
end
vim.cmd('3044')
vim.cmd('normal! zt')
vim.fn.setreg('/', [[\<device_id\>]])
vim.o.hlsearch = true
vim.api.nvim_win_set_cursor(0, { 3084, 1 })
