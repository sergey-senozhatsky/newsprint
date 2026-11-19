-- Every accent event at once: search hits, a selection, a Copilot suggestion,
-- TODO/FIXME, an error and a hint, a whitespace error, and an error message.
vim.cmd('edit ' .. (os.getenv('NP_LINUX') or '/media/dev/linux-next') .. '/drivers/block/zram/zram_drv.c')
vim.o.showmode = false
vim.api.nvim_buf_set_lines(0, 3091, 3092, false,
  { '\t/* TODO: split gendisk setup out. FIXME: leaks the idr slot */' })
local l = vim.api.nvim_buf_get_lines(0, 3102, 3103, false)[1]
vim.api.nvim_buf_set_lines(0, 3102, 3103, false, { l .. '   ' })
vim.cmd('3077')
vim.cmd('normal! zt')

local ns = vim.api.nvim_create_namespace('demo')
vim.diagnostic.config({ virtual_text = { prefix = '*' }, signs = true, underline = true })
vim.diagnostic.set(ns, 0, {
  { lnum = 3093 - 1, col = 13, end_col = 27, severity = vim.diagnostic.severity.ERROR,
    message = 'too few arguments to function call' },
  { lnum = 3101 - 1, col = 22, end_col = 32, severity = vim.diagnostic.severity.HINT,
    message = 'zram_major: int' },
})

local ghost = vim.api.nvim_create_namespace('ghost')
vim.api.nvim_buf_set_extmark(0, ghost, 3109, 0, {
  virt_text = { { 'zram_debugfs_register(zram);', 'CopilotSuggestion' } },
  virt_text_win_col = 8,
})

vim.fn.setreg('/', [[\<disk\>]])
vim.o.hlsearch = true
vim.api.nvim_win_set_cursor(0, { 3105, 1 })
