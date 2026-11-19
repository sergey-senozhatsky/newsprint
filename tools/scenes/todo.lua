-- Kernel-style C with TODO/FIXME/XXX markers, #if 0 and a syntax error.
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  '// SPDX-License-Identifier: GPL-2.0',
  '#include <linux/module.h>',
  '#include "zram_drv.h"',
  '',
  '#define ZRAM_MAX_PRIO\t4',
  '',
  '/*',
  ' * TODO: make the batch size configurable per backing device.',
  ' * FIXME: this races with reset_store(). XXX: and with writeback.',
  ' */',
  'static __always_inline bool zram_prio_valid(u32 prio)',
  '{',
  '\tswitch (prio) {',
  '\tcase 0 ... ZRAM_MAX_PRIO - 1:',
  '\t\treturn true;',
  '\tdefault:',
  '\t\tbreak;',
  '\t}',
  '#if 0',
  '\tpr_debug("prio %u is out of range\\n", prio);',
  '#endif',
  '\treturn sizeof(prio) > 4 && likely(prio != (u32)-1));',
  '}',
})
vim.bo.filetype = 'c'
vim.api.nvim_win_set_cursor(0, { 22, 46 })
vim.cmd('redraw')
vim.api.nvim_echo({ { 'E492: Not an editor command: Gpush', 'ErrorMsg' } }, true, {})
