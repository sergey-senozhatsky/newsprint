-- Loads newsprint under every combination of options and reports failures.
--   nvim --headless -u NONE -i NONE --cmd 'set rtp^=.' -c 'luafile tools/check-options.lua' -c 'qa!'
local fails, n = {}, 0
for _, bg in ipairs({ 'light', 'dark' }) do
  for _, inks in ipairs({ 'black', 'duotone', 'sunday' }) do
    for _, comments in ipairs({ 'caption', 'sidebar' }) do
      for _, accent in ipairs({ false, 'red', 'desk' }) do
        for _, transparent in ipairs({ false, true }) do
          vim.o.background = bg
          vim.g.newsprint = { inks = inks, comments = comments, accent = accent, transparent = transparent }
          local ok, err = pcall(vim.cmd, 'colorscheme newsprint')
          n = n + 1
          if not ok then
            table.insert(fails, string.format('%s %s %s %s %s: %s', bg, inks, comments,
              tostring(accent), tostring(transparent), err))
          end
        end
      end
    end
  end
end
-- spot-check that the knobs actually land
vim.o.background = 'light'
vim.g.newsprint = { inks = 'sunday', comments = 'sidebar' }
vim.cmd('colorscheme newsprint')
local function c(g, k) return tostring(vim.api.nvim_get_hl(0, { name = g, link = false })[k]) end
io.stdout:write(string.format('%d combinations, %d failures\n', n, #fails))
for _, f in ipairs(fails) do io.stdout:write('  ' .. f .. '\n') end
io.stdout:write(string.format('sunday+sidebar: Statement=%s Number=%s String=%s PreProc=%s Comment=%s/%s gitcommitBranch.bg=%s\n',
  c('Statement', 'ctermfg'), c('Number', 'ctermfg'), c('String', 'ctermfg'), c('PreProc', 'ctermfg'),
  c('Comment', 'ctermfg'), c('Comment', 'ctermbg'), c('gitcommitBranch', 'ctermbg')))
vim.g.newsprint = nil
vim.cmd('colorscheme newsprint')
io.stdout:write(string.format('defaults:       Statement=%s Number=%s String=%s PreProc=%s Comment=%s/%s\n',
  c('Statement', 'ctermfg'), c('Number', 'ctermfg'), c('String', 'ctermfg'), c('PreProc', 'ctermfg'),
  c('Comment', 'ctermfg'), c('Comment', 'ctermbg')))
