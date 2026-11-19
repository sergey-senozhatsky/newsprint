-- newsprint.lua -- a black & white colorscheme for Neovim, set like a newspaper.
--
-- One ink, many tints.  Instead of colour, structure is carried the way a
-- broadsheet carries it:
--
--   weight   bold ink for keywords and for "headlines": the names being
--            defined (functions, macros, typedefs), titles, the commit
--            summary, the mail subject, the hunk's function;
--   slant    italic "captions": comments, quoted mail, virtual text;
--   tint     a ladder of halftone greys -- body text, secondary matter
--            (types, literals, preprocessor), captions, column rules -- and
--            light screens behind the UI (cursor line, selection, menus);
--   reverse  white-on-black "reverse type" for the few things that must jump
--            off the page: the status bar, the current search hit, the
--            selected menu item, error messages and TODOs.
--
-- Every grey sits exactly on the xterm-256 grey ramp, so a 256-colour
-- terminal ('notermguicolors') prints the very same page as a truecolor one.
-- With 'termguicolors' the paper additionally gets a faint newsprint warmth.
--
--   :set background=light   morning edition: ink on newsprint   (default)
--   :set background=dark    night edition:   newsprint on ink
--
-- Variants, each its own :colorscheme (colors/newsprint-*.lua):
--
--   newsprint                 black & white
--   newsprint-duotone         slate keywords, rosewood figures; comments boxed
--   newsprint-sunday          ...plus sage strings and ochre preprocessor
--   newsprint-duotone-faded   the same two, in the original, more muted
--   newsprint-sunday-faded      slate and rosewood
--
-- Options (all optional; set them before :colorscheme):
--
--   vim.g.newsprint = {
--     bold        = true,   -- bold keywords and headlines
--     italic      = true,   -- italic comments and captions
--     warm        = true,   -- warm newsprint paper (truecolor only)
--     transparent = false,  -- keep the terminal's own background
--     inks        = 'black',   -- 'black', 'duotone' or 'sunday': "Tinted inks"
--     faded       = false,     -- the original, more muted slate and rosewood
--     comments    = 'caption', -- 'caption' (grey italic) or 'sidebar' (boxed)
--     accent      = false,  -- false, 'red' or 'desk': see "Spot colour"
--   }
--
-- A variant's own settings win over these; everything else still applies,
-- e.g. { accent = 'red' } with :colorscheme newsprint-sunday.

-- A variant hands its name and settings over in g:newsprint_variant.
local variant = vim.g.newsprint_variant or {}
vim.g.newsprint_variant = nil
local name = variant.name or 'newsprint'
variant.name = nil

vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') == 1 then
  vim.cmd('syntax reset')
end
vim.g.colors_name = name

local opt = vim.tbl_extend('force', {
  bold = true,
  italic = true,
  warm = true,
  transparent = false,
  inks = 'black',
  faded = false,
  comments = 'caption',
  accent = false,
}, vim.g.newsprint or {}, variant)

-- The page ------------------------------------------------------------------
--
-- Roles, darkest ink last.  Values are xterm-256 indices; 232..255 is the grey
-- ramp (8, 18, ... 238), 16 and 231 are pure black and white.
--
--   bg .. bg4   paper and the halftone screens laid over it
--   rule        column rules, whitespace markers, end-of-page tildes
--   faint       margin notes: line numbers, fold column
--   soft        punctuation, borders
--   muted       captions: comments, preprocessor
--   dim         secondary matter: types, strings, constants
--   fg          body text
--   ink         solid ink: keywords and headlines
--   rev_*       reverse type (current search hit, selected item, errors)
--   bar_*       the status bar band

local editions = {
  light = {
    bg = 255, bg1 = 254, bg2 = 253, bg3 = 252, bg4 = 250,
    rule = 250, faint = 247, soft = 245, muted = 242, dim = 239,
    fg = 235, ink = 233,
    rev_fg = 255, rev_bg = 235,
    bar_fg = 255, bar_bg = 235,
    -- the editor's desk, used only with the `accent` option
    red = 124, red_bg = 224, blue = 67, blue_bg = 153, marker = 229, marker_fg = 233,
    -- muted inks, used only with the `inks` option
    slate = 61, rosewood = 131, sage = 65, ochre = 94,
  },
  dark = {
    bg = 234, bg1 = 235, bg2 = 236, bg3 = 238, bg4 = 240,
    rule = 238, faint = 241, soft = 243, muted = 245, dim = 249,
    fg = 252, ink = 255,
    rev_fg = 234, rev_bg = 252,
    bar_fg = 255, bar_bg = 239,
    red = 167, red_bg = 52, blue = 110, blue_bg = 24, marker = 178, marker_fg = 233,
    slate = 104, rosewood = 174, sage = 108, ochre = 137,
  },
}

-- The original, more muted slate and rosewood: one step down the colour cube.
local faded = {
  light = { slate = 60, rosewood = 95 },
  dark = { slate = 103, rosewood = 138 },
}

local bg = vim.o.background == 'dark' and 'dark' or 'light'
local edition = vim.tbl_extend('force', editions[bg], opt.faded and faded[bg] or {})

local cube = { 0, 95, 135, 175, 215, 255 }

-- xterm-256 index (16..255) -> r, g, b
local function rgb(idx)
  if idx >= 232 then
    local v = 8 + 10 * (idx - 232)
    return v, v, v
  end
  idx = idx - 16
  return cube[math.floor(idx / 36) + 1], cube[math.floor(idx / 6) % 6 + 1], cube[idx % 6 + 1]
end

-- Truecolor rendition of a palette entry.  Greys keep their lightness and get
-- a breath of newsprint warmth that fades out towards solid black; accent
-- inks print exactly as in 256 colours.
local function hex(idx)
  local r, g, b = rgb(idx)
  if opt.warm and r == g and g == b then
    local s = r / 238
    r, g, b = r + 4 * s, g + 1 * s, b - 7 * s
  end
  local function byte(x)
    return math.max(0, math.min(255, math.floor(x + 0.5)))
  end
  return string.format('#%02x%02x%02x', byte(r), byte(g), byte(b))
end

local function hl(group, spec)
  if type(spec) == 'string' then
    vim.api.nvim_set_hl(0, group, { link = spec })
    return
  end
  local v = {}
  if spec.fg then
    v.fg, v.ctermfg = hex(edition[spec.fg]), edition[spec.fg]
  end
  if spec.bg and not (opt.transparent and spec.bg == 'bg') then
    v.bg, v.ctermbg = hex(edition[spec.bg]), edition[spec.bg]
  end
  if spec.sp then
    v.sp = hex(edition[spec.sp])
  end
  for _, attr in ipairs({ 'underline', 'undercurl', 'underdotted', 'underdashed',
                          'underdouble', 'strikethrough', 'reverse', 'nocombine' }) do
    v[attr] = spec[attr]
  end
  v.bold = opt.bold and spec.bold or nil
  v.italic = opt.italic and spec.italic or nil
  if spec.cterm then
    -- Attributes for 256-colour terminals, when they should differ.
    v.cterm = spec.cterm
  end
  vim.api.nvim_set_hl(0, group, v)
end

local S = {}

-- Editor chrome ---------------------------------------------------------------

S.Normal         = { fg = 'fg', bg = 'bg' }
S.NormalFloat    = { fg = 'fg', bg = 'bg2' }
S.FloatBorder    = { fg = 'soft', bg = 'bg2' }
S.FloatTitle     = { fg = 'ink', bg = 'bg2', bold = true }
S.FloatFooter    = { fg = 'muted', bg = 'bg2', italic = true }

S.Cursor         = { fg = 'bg', bg = 'ink' }
S.lCursor        = 'Cursor'
S.CursorIM       = 'Cursor'
S.TermCursor     = { reverse = true }

S.CursorLine     = { bg = 'bg1' }
S.CursorColumn   = { bg = 'bg1' }
S.ColorColumn    = { bg = 'bg1' }
S.CursorLineNr   = { fg = 'ink', bg = 'bg1', bold = true }
S.CursorLineSign = { bg = 'bg1' }
S.CursorLineFold = { fg = 'faint', bg = 'bg1' }
S.LineNr         = { fg = 'faint' }
S.SignColumn     = { fg = 'soft' }
S.FoldColumn     = { fg = 'faint' }
S.Folded         = { fg = 'muted', bg = 'bg1', italic = true }

S.WinSeparator   = { fg = 'rule' }
S.VertSplit      = 'WinSeparator'
S.StatusLine     = { fg = 'bar_fg', bg = 'bar_bg', bold = true }
S.StatusLineNC   = { fg = 'muted', bg = 'bg2' }
S.StatusLineTerm = 'StatusLine'
S.StatusLineTermNC = 'StatusLineNC'
S.TabLine        = { fg = 'muted', bg = 'bg2' }
S.TabLineFill    = { bg = 'bg2' }
S.TabLineSel     = { fg = 'bar_fg', bg = 'bar_bg', bold = true }
S.WinBar         = { fg = 'ink', bold = true }
S.WinBarNC       = { fg = 'muted' }

S.Pmenu          = { fg = 'fg', bg = 'bg2' }
S.PmenuSel       = { fg = 'rev_fg', bg = 'rev_bg', bold = true }
S.PmenuKind      = { fg = 'muted', bg = 'bg2' }
S.PmenuKindSel   = { fg = 'rev_fg', bg = 'rev_bg' }
S.PmenuExtra     = { fg = 'muted', bg = 'bg2', italic = true }
S.PmenuExtraSel  = { fg = 'rev_fg', bg = 'rev_bg', italic = true }
S.PmenuSbar      = { bg = 'bg3' }
S.PmenuThumb     = { bg = 'soft' }
S.PmenuMatch     = { fg = 'ink', bg = 'bg2', bold = true }
S.PmenuMatchSel  = { fg = 'rev_fg', bg = 'rev_bg', bold = true, underline = true }
S.WildMenu       = 'PmenuSel'

S.Visual         = { bg = 'bg3' }
S.VisualNOS      = { bg = 'bg2' }
S.Search         = { fg = 'ink', bg = 'bg4' }
S.CurSearch      = { fg = 'rev_fg', bg = 'rev_bg', bold = true }
S.IncSearch      = 'CurSearch'
S.Substitute     = { fg = 'rev_fg', bg = 'dim', bold = true }
S.MatchParen     = { fg = 'ink', bg = 'bg4', bold = true }
S.QuickFixLine   = { bg = 'bg2', bold = true }

S.NonText        = { fg = 'rule' }
S.EndOfBuffer    = { fg = 'rule' }
S.Whitespace     = { fg = 'rule' }
S.SpecialKey     = { fg = 'soft' }
S.Conceal        = { fg = 'soft' }
S.Directory      = { fg = 'ink', bold = true }
S.Title          = { fg = 'ink', bold = true }

S.ErrorMsg       = { fg = 'rev_fg', bg = 'rev_bg', bold = true }
S.WarningMsg     = { fg = 'ink', bold = true }
S.MoreMsg        = { fg = 'dim', bold = true }
S.ModeMsg        = { fg = 'ink', bold = true }
S.Question       = { fg = 'dim', bold = true }
S.MsgSeparator   = { fg = 'soft', bg = 'bg2' }

-- A misspelling is underlined everywhere; the pedantic classes only where the
-- terminal can draw a dotted line, never as a plain underline.
S.SpellBad       = { undercurl = true, sp = 'ink', cterm = { underline = true } }
S.SpellCap       = { undercurl = true, sp = 'soft', cterm = {} }
S.SpellRare      = { underdotted = true, sp = 'soft', cterm = {} }
S.SpellLocal     = { underdotted = true, sp = 'soft', cterm = {} }

S.DiffAdd        = { bg = 'bg2' }
S.DiffChange     = { bg = 'bg1' }
S.DiffDelete     = { fg = 'rule', bg = 'bg1' }
S.DiffText       = { fg = 'ink', bg = 'bg4', bold = true }
S.Added          = { fg = 'ink' }
S.Changed        = { fg = 'dim' }
S.Removed        = { fg = 'muted' }

-- Syntax --------------------------------------------------------------------

S.Comment        = { fg = 'muted', italic = true }
S.SpecialComment = { fg = 'muted', italic = true, bold = true }
S.Todo           = { fg = 'rev_fg', bg = 'muted', bold = true }

S.Constant       = { fg = 'dim' }
S.String         = { fg = 'dim' }
S.Character      = 'String'
S.Number         = 'Constant'
S.Boolean        = 'Constant'
S.Float          = 'Number'

S.Identifier     = { fg = 'fg' }
S.Function       = { fg = 'ink', bold = true }

S.Statement      = { fg = 'ink', bold = true }
S.Conditional    = 'Statement'
S.Repeat         = 'Statement'
S.Label          = 'Statement'
S.Keyword        = 'Statement'
S.Exception      = 'Statement'
S.Operator       = { fg = 'fg' }

S.PreProc        = { fg = 'muted' }
S.Include        = 'PreProc'
S.Define         = 'PreProc'
S.Macro          = 'PreProc'
S.PreCondit      = { fg = 'muted', bold = true }

S.Type           = { fg = 'dim' }
S.StorageClass   = 'Type'
S.Structure      = 'Type'
S.Typedef        = 'Type'

S.Special        = { fg = 'dim' }
S.SpecialChar    = { fg = 'ink', bold = true }
S.Tag            = { fg = 'fg', underline = true }
S.Delimiter      = { fg = 'soft' }
S.Debug          = { fg = 'dim' }

S.Underlined     = { underline = true }
S.Ignore         = { fg = 'rule' }
S.Error          = { fg = 'rev_fg', bg = 'dim', bold = true }

-- Tree-sitter ---------------------------------------------------------------

S['@variable']                 = { fg = 'fg' }
S['@variable.builtin']         = { fg = 'fg', italic = true }
S['@variable.parameter']       = { fg = 'fg', italic = true }
S['@variable.member']          = { fg = 'fg' }
S['@constant']                 = 'Constant'
S['@constant.builtin']         = 'Constant'
S['@constant.macro']           = 'Constant'
S['@module']                   = { fg = 'fg' }
S['@label']                    = 'Label'

S['@string']                   = 'String'
S['@string.documentation']     = { fg = 'muted', italic = true }
S['@string.regexp']            = { fg = 'dim' }
S['@string.escape']            = 'SpecialChar'
S['@string.special']           = 'SpecialChar'
S['@string.special.url']       = { fg = 'dim', underline = true }
S['@string.special.path']      = { fg = 'dim' }
S['@character']                = 'Character'
S['@character.special']        = 'SpecialChar'
S['@boolean']                  = 'Boolean'
S['@number']                   = 'Number'
S['@number.float']             = 'Float'

S['@type']                     = 'Type'
S['@type.builtin']             = 'Type'
S['@type.definition']          = { fg = 'ink', bold = true }
S['@attribute']                = { fg = 'muted' }
S['@property']                 = { fg = 'fg' }

-- Definitions are headlines; calls are body text.
S['@function']                 = 'Function'
S['@function.call']            = { fg = 'fg' }
S['@function.builtin']         = { fg = 'fg' }
S['@function.macro']           = 'Function'
S['@function.method']          = 'Function'
S['@function.method.call']     = '@function.call'
S['@constructor']              = { fg = 'fg' }
S['@operator']                 = { fg = 'fg' }

S['@keyword']                  = 'Keyword'
S['@keyword.operator']         = 'Statement'
S['@keyword.import']           = 'Include'
S['@keyword.type']             = 'Structure'
S['@keyword.modifier']         = 'StorageClass'
S['@keyword.directive']        = 'PreCondit'
S['@keyword.directive.define'] = 'Define'
S['@keyword.conditional.ternary'] = { fg = 'fg' }

S['@punctuation.delimiter']    = 'Delimiter'
S['@punctuation.bracket']      = 'Delimiter'
S['@punctuation.special']      = 'Delimiter'

S['@comment']                  = 'Comment'
S['@comment.documentation']    = 'Comment'
S['@comment.error']            = { fg = 'rev_fg', bg = 'rev_bg', bold = true }
S['@comment.warning']          = 'Todo'
S['@comment.todo']             = 'Todo'
S['@comment.note']             = { fg = 'dim', bold = true, italic = true }

S['@markup.strong']            = { bold = true }
S['@markup.italic']            = { italic = true }
S['@markup.strikethrough']     = { strikethrough = true }
S['@markup.underline']         = { underline = true }
S['@markup.heading']           = 'Title'
S['@markup.quote']             = { fg = 'muted', italic = true }
S['@markup.math']              = { fg = 'dim', italic = true }
S['@markup.link']              = { fg = 'fg', underline = true }
S['@markup.link.label']        = { fg = 'fg', underline = true }
S['@markup.link.url']          = { fg = 'muted', underline = true }
S['@markup.raw']               = { fg = 'dim' }
S['@markup.list']              = { fg = 'soft' }
S['@markup.list.checked']      = { fg = 'muted' }
S['@markup.list.unchecked']    = { fg = 'fg' }

S['@diff.plus']                = 'Added'
S['@diff.minus']               = 'Removed'
S['@diff.delta']               = 'Changed'

S['@tag']                      = { fg = 'ink', bold = true }
S['@tag.attribute']            = { fg = 'dim', italic = true }
S['@tag.delimiter']            = 'Delimiter'

-- LSP semantic tokens: let a function *reference* stay body text, and leave
-- macros and variables to tree-sitter, which knows a constant from a call.
S['@lsp.type.function']        = '@function.call'
S['@lsp.type.method']          = '@function.method.call'
S['@lsp.typemod.function.declaration'] = '@function'
S['@lsp.typemod.function.definition']  = '@function'
S['@lsp.typemod.method.declaration']   = '@function.method'
S['@lsp.typemod.method.definition']    = '@function.method'
S['@lsp.type.macro']           = {}
S['@lsp.type.variable']        = {}
S['@lsp.type.parameter']       = {}
S['@lsp.type.comment']         = {}

-- Diagnostics: no traffic lights, just weight and the kind of underline.
S.DiagnosticError              = { fg = 'ink', bold = true }
S.DiagnosticWarn               = { fg = 'dim', bold = true }
S.DiagnosticInfo               = { fg = 'muted' }
S.DiagnosticHint               = { fg = 'muted' }
S.DiagnosticOk                 = { fg = 'muted' }
S.DiagnosticVirtualTextError   = { fg = 'ink', bg = 'bg1', italic = true }
S.DiagnosticVirtualTextWarn    = { fg = 'dim', bg = 'bg1', italic = true }
S.DiagnosticVirtualTextInfo    = { fg = 'muted', italic = true }
S.DiagnosticVirtualTextHint    = { fg = 'muted', italic = true }
S.DiagnosticVirtualTextOk      = { fg = 'muted', italic = true }
S.DiagnosticUnderlineError     = { undercurl = true, sp = 'ink' }
S.DiagnosticUnderlineWarn      = { undercurl = true, sp = 'muted' }
S.DiagnosticUnderlineInfo      = { underdotted = true, sp = 'soft' }
S.DiagnosticUnderlineHint      = { underdotted = true, sp = 'soft' }
S.DiagnosticUnderlineOk        = { underline = true, sp = 'soft' }
S.DiagnosticDeprecated         = { strikethrough = true, sp = 'muted' }
S.DiagnosticUnnecessary        = { fg = 'soft' }

S.LspReferenceText             = { bg = 'bg2' }
S.LspReferenceRead             = { bg = 'bg2' }
S.LspReferenceWrite            = { bg = 'bg2', underline = true }
S.LspInlayHint                 = { fg = 'soft', bg = 'bg1', italic = true }
S.LspCodeLens                  = { fg = 'soft', italic = true }
S.LspCodeLensSeparator         = { fg = 'rule' }
S.LspSignatureActiveParameter  = { fg = 'ink', bold = true, underline = true }

S.healthError                  = 'DiagnosticError'
S.healthWarning                = 'DiagnosticWarn'
S.healthSuccess                = { fg = 'ink', bold = true }

-- C, and the kernel ---------------------------------------------------------

-- vim-polyglot tags every `name(` as a function, calls and definitions alike;
-- calls are body text, otherwise every line of kernel code shouts.
S.cUserFunction  = { fg = 'fg' }
S.cOperator      = 'Statement'   -- sizeof, typeof, likely, unlikely
S.cUserLabel     = 'Label'       -- goto targets
S.LinuxError     = { fg = 'ink', bg = 'bg4' }     -- linuxsty.vim
S.LinuxGuard     = 'Statement'                    -- guard(), scoped_guard()
S.LeadingWS      = { bg = 'bg3' }                 -- whitespace errors

-- Patches ---------------------------------------------------------------------

-- New lines are set on a light screen, upright and readable; removed lines
-- fade to grey, like copy that didn't make the edition.
S.diffAdded      = { fg = 'ink', bg = 'bg2' }
S.diffRemoved    = { fg = 'muted' }
S.diffChanged    = { fg = 'dim' }
S.diffLine       = { fg = 'muted', italic = true }
S.diffSubname    = { fg = 'ink', bold = true }
S.diffFile       = { fg = 'ink', bold = true }
S.diffOldFile    = { fg = 'dim', bold = true }
S.diffNewFile    = { fg = 'ink', bold = true }
S.diffIndexLine  = { fg = 'muted' }
S.diffComment    = 'Comment'
S.diffNoEOL      = { fg = 'muted', italic = true }
S.diffIsA        = { fg = 'muted' }
S.diffBDiffer    = { fg = 'muted' }
S.diffDiffer     = { fg = 'muted' }
S.diffCommon     = { fg = 'muted' }
S.diffIdentical  = { fg = 'muted' }
S.diffOnly       = { fg = 'muted' }

S.gitcommitSummary       = { fg = 'ink', bold = true }
S.gitcommitOverflow      = { fg = 'muted', underline = true }
S.gitcommitBlank         = 'Error'
S.gitcommitComment       = 'Comment'
S.gitcommitHeader        = { fg = 'muted', italic = true }
S.gitcommitOnBranch      = { fg = 'muted', italic = true }
S.gitcommitBranch        = { fg = 'dim', bold = true, italic = true }
S.gitcommitArrow         = { fg = 'muted', italic = true }
S.gitcommitSelectedType  = { fg = 'dim', bold = true, italic = true }
S.gitcommitSelectedFile  = { fg = 'dim', bold = true, italic = true }
S.gitcommitDiscardedType = { fg = 'muted', italic = true }
S.gitcommitDiscardedFile = { fg = 'muted', italic = true }
S.gitcommitUntrackedFile = { fg = 'soft', italic = true }
S.gitcommitUnmergedType  = { fg = 'ink', bold = true, italic = true }
S.gitcommitUnmergedFile  = { fg = 'ink', bold = true, italic = true }
S.gitcommitTrailerToken  = { fg = 'dim', bold = true }
S.gitcommitHash          = { fg = 'dim' }

-- Mail: the subject is the headline, older quotes fade like old news.
S.mailHeader      = { fg = 'dim' }
S.mailHeaderKey   = { fg = 'ink', bold = true }
S.mailSubject     = { fg = 'ink', bold = true }
S.mailHeaderEmail = { fg = 'dim' }
S.mailEmail       = { fg = 'dim', underline = true }
S.mailURL         = { fg = 'dim', underline = true }
S.mailSignature   = { fg = 'muted', italic = true }
S.mailQuoted1     = { fg = 'dim' }
S.mailQuoted2     = { fg = 'muted', italic = true }
S.mailQuoted3     = { fg = 'soft' }
S.mailQuoted4     = { fg = 'soft', italic = true }
S.mailQuoted5     = 'mailQuoted3'
S.mailQuoted6     = 'mailQuoted4'
S.mailVerbatim    = { fg = 'dim' }

-- Help, markdown ------------------------------------------------------------

S.helpHeader         = { fg = 'ink', bold = true }
S.helpSectionDelim   = { fg = 'rule' }
S.helpHyperTextJump  = { fg = 'fg', underline = true }
S.helpHyperTextEntry = { fg = 'ink', bold = true }
S.helpExample        = { fg = 'dim' }
S.helpCommand        = { fg = 'dim' }
S.helpOption         = { fg = 'dim' }
S.helpNote           = { fg = 'ink', bold = true }
S.helpWarning        = { fg = 'ink', bold = true }

S.markdownH1 = 'Title'
S.markdownH2 = 'Title'
S.markdownH3 = 'Title'
S.markdownH4 = 'Title'
S.markdownH5 = 'Title'
S.markdownH6 = 'Title'
S.markdownHeadingDelimiter  = { fg = 'soft' }
S.markdownCode              = { fg = 'dim' }
S.markdownCodeBlock         = { fg = 'dim' }
S.markdownCodeDelimiter     = { fg = 'soft' }
S.markdownBold              = { bold = true }
S.markdownItalic            = { italic = true }
S.markdownBoldItalic        = { bold = true, italic = true }
S.markdownLinkText          = { underline = true }
S.markdownUrl               = { fg = 'muted', underline = true }
S.markdownListMarker        = { fg = 'soft' }
S.markdownOrderedListMarker = { fg = 'soft' }
S.markdownBlockquote        = { fg = 'muted', italic = true }
S.markdownRule              = { fg = 'rule' }
S.mkdHeading                = { fg = 'soft' }
S.mkdCode                   = { fg = 'dim' }
S.mkdCodeDelimiter          = { fg = 'soft' }
S.mkdLink                   = { underline = true }
S.mkdURL                    = { fg = 'muted', underline = true }
S.mkdInlineURL              = { fg = 'muted', underline = true }
S.mkdListItem               = { fg = 'soft' }
S.mkdBlockquote             = { fg = 'muted', italic = true }
S.mkdRule                   = { fg = 'rule' }
S.htmlH1 = 'Title'
S.htmlH2 = 'Title'
S.htmlH3 = 'Title'
S.htmlBold                  = { bold = true }
S.htmlItalic                = { italic = true }
S.htmlBoldItalic            = { bold = true, italic = true }
S.htmlLink                  = { underline = true }

-- Plugins -------------------------------------------------------------------

-- vim-easymotion: targets in reverse type, the rest of the page greyed out.
S.EasyMotionTarget        = { fg = 'rev_fg', bg = 'rev_bg', bold = true }
S.EasyMotionTarget2First  = { fg = 'rev_fg', bg = 'rev_bg', bold = true }
S.EasyMotionTarget2Second = { fg = 'ink', bg = 'bg4', bold = true }
S.EasyMotionShade         = { fg = 'rule' }
S.EasyMotionMoveHL        = 'Search'
S.EasyMotionIncSearch     = 'CurSearch'
S.EasyMotionIncCursor     = 'Cursor'

-- vim-fugitive
S.fugitiveHeader            = { fg = 'dim', bold = true }
S.fugitiveHeading           = { fg = 'ink', bold = true }
S.fugitiveUntrackedHeading  = { fg = 'ink', bold = true }
S.fugitiveUnstagedHeading   = { fg = 'ink', bold = true }
S.fugitiveStagedHeading     = { fg = 'ink', bold = true }
S.fugitiveModifier          = { fg = 'dim', bold = true }
S.fugitiveUntrackedModifier = { fg = 'soft', bold = true }
S.fugitiveUnstagedModifier  = { fg = 'dim', bold = true }
S.fugitiveStagedModifier    = { fg = 'ink', bold = true }
S.fugitiveInstruction       = { fg = 'dim', bold = true }
S.fugitiveStop              = 'Statement'
S.fugitiveHash              = { fg = 'muted' }
S.fugitiveSymbolicRef       = { fg = 'fg', bold = true }
S.fugitiveCount             = { fg = 'muted' }
S.FugitiveblameHash         = { fg = 'muted' }
S.FugitiveblameTime         = { fg = 'muted', italic = true }
S.FugitiveblameUncommitted  = { fg = 'soft' }
S.gitKeyword                = { fg = 'dim', bold = true }
S.gitIdentityKeyword        = { fg = 'dim', bold = true }
S.gitDate                   = { fg = 'muted' }
S.gitHash                   = { fg = 'muted' }
S.gitIdentity               = { fg = 'dim' }
S.gitEmail                  = { fg = 'dim' }

-- copilot.vim: suggestions are pencilled in, not printed.
S.CopilotSuggestion         = { fg = 'faint', italic = true }
S.CopilotAnnotation         = { fg = 'faint', italic = true }

-- Tinted inks (the `inks` option) -----------------------------------------------
--
-- A colour supplement printed on the same newsprint: a few muted inks laid
-- over the black, never bright.
--
--   'duotone'  slate for the words that steer the code (keywords), rosewood
--              for the figures (numbers, constants, escapes in strings);
--   'sunday'   ...plus sage for quoted text (strings) and ochre for the
--              preprocessor's editorial notes.
--
-- Headlines (definitions, titles, the commit summary) stay solid black.

if opt.inks == 'duotone' or opt.inks == 'sunday' then
  S.Statement   = { fg = 'slate', bold = true }
  S.Constant    = { fg = 'rosewood' }
  S.SpecialChar = { fg = 'rosewood', bold = true }
end
if opt.inks == 'sunday' then
  S.String      = { fg = 'sage' }
  S.PreProc     = { fg = 'ochre' }
  S.PreCondit   = { fg = 'ochre', bold = true }
end

-- Comments as sidebars (the `comments` option): set in a shaded box, the way
-- a paper boxes a side story, instead of as a grey caption.  The lightest
-- screen: a block comment's box also covers its indentation.
if opt.comments == 'sidebar' then
  S.Comment        = { fg = 'dim', bg = 'bg1', italic = true }
  S.SpecialComment = { fg = 'dim', bg = 'bg1', italic = true, bold = true }
  -- whatever is highlighted inside a comment keeps the box behind it
  for _, group in ipairs({
    '@comment.note', 'gitcommitHeader', 'gitcommitOnBranch', 'gitcommitBranch',
    'gitcommitArrow', 'gitcommitSelectedType', 'gitcommitSelectedFile',
    'gitcommitDiscardedType', 'gitcommitDiscardedFile', 'gitcommitUntrackedFile',
    'gitcommitUnmergedType', 'gitcommitUnmergedFile',
  }) do
    if type(S[group]) == 'table' then
      S[group] = vim.tbl_extend('force', S[group], { bg = 'bg1' })
    end
  end
end

-- Spot colour (the `accent` option) ---------------------------------------------
--
-- Off by default.  When on, colour never decorates; it only marks an event,
-- the way an editor marks up a proof:
--
--   'red'   one spot colour -- the copy editor's red pencil, for what is
--           wrong: errors, TODO/FIXME, deleted lines, whitespace errors, and
--           misspellings where the terminal can colour an undercurl;
--   'desk'  the whole editor's desk: the red pencil, plus a yellow
--           highlighter for search hits, and non-repro blue -- the pencil
--           whose marks never reach the plate -- for whatever isn't part of
--           the text: the visual selection, Copilot suggestions, hints.

local accent = opt.accent == true and 'desk' or opt.accent

if accent == 'red' or accent == 'desk' then
  S.ErrorMsg                   = { fg = 'rev_fg', bg = 'red', bold = true }
  S.Error                      = { fg = 'rev_fg', bg = 'red', bold = true }
  S.Todo                       = { fg = 'rev_fg', bg = 'red', bold = true }
  S['@comment.error']          = 'Todo'
  S.DiagnosticError            = { fg = 'red', bold = true }
  S.DiagnosticVirtualTextError = { fg = 'red', bg = 'bg1', italic = true }
  S.DiagnosticUnderlineError   = { undercurl = true, sp = 'red' }
  S.SpellBad                   = { undercurl = true, sp = 'red', cterm = { underline = true } }
  S.diffRemoved                = { fg = 'red' }
  S.Removed                    = { fg = 'red' }
  S.DiffDelete                 = { fg = 'red', bg = 'red_bg' }
  S.gitcommitOverflow          = { fg = 'red' }
  S.LeadingWS                  = { bg = 'red_bg' }
  S.LinuxError                 = { fg = 'red', bg = 'red_bg' }
end

if accent == 'desk' then
  S.Search                     = { fg = 'marker_fg', bg = 'marker' }
  S.Visual                     = { bg = 'blue_bg' }
  S.VisualNOS                  = { bg = 'blue_bg' }
  S.CopilotSuggestion          = { fg = 'blue', italic = true }
  S.CopilotAnnotation          = { fg = 'blue', italic = true }
  S.DiagnosticInfo             = { fg = 'blue' }
  S.DiagnosticHint             = { fg = 'blue' }
  S.DiagnosticVirtualTextInfo  = { fg = 'blue', italic = true }
  S.DiagnosticVirtualTextHint  = { fg = 'blue', italic = true }
  S.DiagnosticUnderlineInfo    = { underdotted = true, sp = 'blue' }
  S.DiagnosticUnderlineHint    = { underdotted = true, sp = 'blue' }
  S.LspInlayHint               = { fg = 'blue', bg = 'bg1', italic = true }
  S['@comment.note']           = { fg = 'blue', bold = true }
end

for group, spec in pairs(S) do
  hl(group, spec)
end

-- :terminal (only used with 'termguicolors'): a greyscale ANSI palette.
local ansi = {
  'fg', 'ink', 'dim', 'muted', 'fg', 'dim', 'muted', 'faint',
  'soft', 'ink', 'dim', 'muted', 'dim', 'muted', 'soft', 'bg3',
}
for i, role in ipairs(ansi) do
  vim.g['terminal_color_' .. (i - 1)] = hex(edition[role])
end

-- :NewsprintAccent [none|red|desk] switches the spot colour in place; with no
-- argument it cycles none -> red -> desk.  The choice is kept in g:newsprint
-- (your other options stay), so it survives :set background and :colorscheme.
vim.api.nvim_create_user_command('NewsprintAccent', function(cmd)
  local o = vim.g.newsprint or {}
  local now = o.accent == true and 'desk' or o.accent or 'none'
  local want = cmd.args ~= '' and cmd.args or ({ none = 'red', red = 'desk', desk = 'none' })[now]
  if not ({ none = true, red = true, desk = true })[want] then
    vim.notify('NewsprintAccent: expected none, red or desk', vim.log.levels.ERROR)
    return
  end
  o.accent = want ~= 'none' and want or false
  vim.g.newsprint = o
  local scheme = (vim.g.colors_name or ''):match('^newsprint') and vim.g.colors_name or 'newsprint'
  vim.cmd.colorscheme(scheme)
  vim.api.nvim_echo({ { 'newsprint: accent ' .. want } }, false, {})
end, {
  nargs = '?',
  complete = function()
    return { 'none', 'red', 'desk' }
  end,
  desc = 'newsprint: switch the spot colour (none, red, desk)',
})
