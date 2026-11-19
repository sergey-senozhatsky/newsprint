-- newsprint-sunday-faded: newsprint-sunday in the original, more muted inks.
-- Your vim.g.newsprint options still apply; see newsprint.lua next to this file.
vim.g.newsprint_variant = { name = 'newsprint-sunday-faded', inks = 'sunday', comments = 'sidebar', faded = true }
dofile(vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)), 'newsprint.lua'))
