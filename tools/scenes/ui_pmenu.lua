-- Two windows, diagnostics, a bordered float, and insert-mode completion.
local root = os.getenv('NP_ROOT')
vim.cmd('edit ' .. (os.getenv('NP_LINUX') or '/media/dev/linux-next') .. '/drivers/block/zram/Kconfig')
vim.cmd('vsplit ' .. (os.getenv('NP_LINUX') or '/media/dev/linux-next') .. '/drivers/block/zram/zram_drv.c')
vim.cmd('vertical resize 84')
vim.cmd('3092')
vim.cmd('normal! zt')
local ns = vim.api.nvim_create_namespace('demo')
vim.diagnostic.config({ virtual_text = { prefix = '■' }, signs = true, underline = true, severity_sort = true })
local E, W, I, H = vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN, vim.diagnostic.severity.INFO, vim.diagnostic.severity.HINT
vim.diagnostic.set(ns, 0, {
  { lnum = 3093 - 1, col = 13, end_col = 27, severity = E, message = 'too few arguments' },
  { lnum = 3097 - 1, col = 8, end_col = 15, severity = W, message = 'value stored is never read' },
  { lnum = 3101 - 1, col = 22, end_col = 32, severity = I, message = 'zram_major: int' },
  { lnum = 3107 - 1, col = 1, end_col = 9, severity = H, message = 'use scnprintf()' },
})
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'struct gendisk *blk_alloc_disk(',
  '        struct queue_limits *lim, int node)',
  '',
  'Allocate a gendisk and its request queue.',
})
vim.api.nvim_open_win(buf, false, { relative = 'win', win = 0, row = 2, col = 30,
  width = 44, height = 4, border = 'single', title = ' blk_alloc_disk ', style = 'minimal' })
vim.o.complete = '.'
vim.api.nvim_win_set_cursor(0, { 3108, 0 })
