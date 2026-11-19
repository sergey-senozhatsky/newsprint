-- newsprint-sunday: slate, rosewood, sage and ochre inks, comments in sidebars.
-- Your vim.g.newsprint options still apply; see newsprint.lua next to this file.
vim.g.newsprint_variant = { name = 'newsprint-sunday', inks = 'sunday', comments = 'sidebar' }
dofile(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)) .. '/newsprint.lua')
