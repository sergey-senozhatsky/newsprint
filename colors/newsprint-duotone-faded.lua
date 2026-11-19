-- newsprint-duotone-faded: newsprint-duotone in the original, more muted inks.
-- Your vim.g.newsprint options still apply; see newsprint.lua next to this file.
vim.g.newsprint_variant = { name = 'newsprint-duotone-faded', inks = 'duotone', comments = 'sidebar', faded = true }
dofile(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)) .. '/newsprint.lua')
