-- Loads newsprint under every combination of options, and every variant in
-- both editions, and reports failures.
--   nvim --headless -u NONE -i NONE --cmd 'set rtp^=.' -c 'luafile tools/check-options.lua' -c 'qa!'
local fails, n = {}, 0
local function try(label, fn)
  n = n + 1
  local ok, err = pcall(fn)
  if not ok then
    table.insert(fails, label .. ': ' .. tostring(err))
  end
end

for _, bg in ipairs({ 'light', 'dark' }) do
  for _, inks in ipairs({ 'black', 'duotone', 'sunday' }) do
    for _, faded in ipairs({ false, true }) do
      for _, comments in ipairs({ 'caption', 'sidebar' }) do
        for _, accent in ipairs({ false, 'red', 'desk' }) do
          for _, transparent in ipairs({ false, true }) do
            try(table.concat({ bg, inks, tostring(faded), comments, tostring(accent), tostring(transparent) }, ' '),
              function()
                vim.o.background = bg
                vim.g.newsprint = { inks = inks, faded = faded, comments = comments,
                                    accent = accent, transparent = transparent }
                vim.cmd('colorscheme newsprint')
              end)
          end
        end
      end
    end
  end
end

-- The variants: name, then the cterm colours keywords / numbers / strings get
-- and the comment background, in the light and the night edition.
local function c(g, k)
  return vim.api.nvim_get_hl(0, { name = g, link = false })[k]
end
local variants = {
  { 'newsprint',               { 233, 239, 239, nil }, { 255, 249, 249, nil } },
  { 'newsprint-duotone-faded', { 60, 95, 239, 254 },   { 103, 138, 249, 235 } },
  { 'newsprint-duotone',       { 61, 131, 239, 254 },  { 104, 174, 249, 235 } },
  { 'newsprint-sunday-faded',  { 60, 95, 65, 254 },    { 103, 138, 108, 235 } },
  { 'newsprint-sunday',        { 61, 131, 65, 254 },   { 104, 174, 108, 235 } },
}
vim.g.newsprint = nil
for _, v in ipairs(variants) do
  for i, bg in ipairs({ 'light', 'dark' }) do
    try(v[1] .. ' ' .. bg, function()
      vim.o.background = bg
      vim.cmd('colorscheme ' .. v[1])
      local want, got = v[i + 1], { c('Statement', 'ctermfg'), c('Number', 'ctermfg'),
                                    c('String', 'ctermfg'), c('Comment', 'ctermbg') }
      assert(vim.g.colors_name == v[1], 'colors_name is ' .. tostring(vim.g.colors_name))
      for j = 1, 4 do
        assert(want[j] == got[j], string.format('field %d: want %s, got %s', j, tostring(want[j]), tostring(got[j])))
      end
    end)
  end
end

-- A variant keeps its name across :set background, and personal options
-- still apply on top of it.
try('variant survives background toggle', function()
  vim.o.background = 'light'
  vim.cmd('colorscheme newsprint-sunday')
  vim.o.background = 'dark'
  assert(vim.g.colors_name == 'newsprint-sunday')
  assert(c('Statement', 'ctermfg') == 104)
end)
try('personal options on top of a variant', function()
  vim.o.background = 'light'
  vim.g.newsprint = { accent = 'red', italic = false }
  vim.cmd('colorscheme newsprint-sunday')
  assert(c('ErrorMsg', 'ctermbg') == 124 and c('Statement', 'ctermfg') == 61)
  assert(not c('Comment', 'italic'))
  vim.g.newsprint = nil
end)

io.stdout:write(string.format('%d checks, %d failures\n', n, #fails))
for _, f in ipairs(fails) do
  io.stdout:write('  ' .. f .. '\n')
end
