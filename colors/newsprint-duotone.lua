-- newsprint-duotone: slate keywords, rosewood figures, comments in sidebars.
-- Your vim.g.newsprint options still apply; see newsprint.lua next to this file.
vim.g.newsprint_variant = { name = 'newsprint-duotone', inks = 'duotone', comments = 'sidebar' }
dofile(vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)), 'newsprint.lua'))
