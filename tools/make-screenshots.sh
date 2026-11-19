#!/bin/bash
# Regenerates ../screenshots with render.py.  Takes about a minute.
#
# The C scenes open drivers/block/zram from a kernel tree: set NP_LINUX if
# yours isn't /media/dev/linux-next.  screenshots/inks-brightness-compare.png
# is a one-off design comparison and is not regenerated.
set -e
cd "$(dirname "$0")"
OUT=../screenshots
R="python3 render.py"
ERR='vim.api.nvim_echo({{"E492: Not an editor command: Gpush", "ErrorMsg"}}, true, {})'

# Black & white, as installed by default
$R scenes/c_add.lua     $OUT/01-c-urxvt.png --rows 48
$R scenes/patch.lua     $OUT/02-patch.png --rows 66 --no-cursor
$R scenes/mail.lua      $OUT/03-mail.png --rows 31 --no-cursor
$R scenes/commit.lua    $OUT/04-commit.png --rows 27 --no-cursor
$R scenes/ui_pmenu.lua  $OUT/05-ui.png --rows 40 --cols 130 --keys 'ozram_d<C-n>'
$R scenes/ui_pmenu.lua  $OUT/06-ui-night.png --bg dark --rows 40 --cols 130 --keys 'ozram_d<C-n>'
NP_TS=1 $R scenes/c_write.lua $OUT/07-c-treesitter-truecolor.png --mode gui --rows 40 --cols 96 --no-cursor
$R scenes/c_add.lua     $OUT/08-c-urxvt-xft-antialiased.png --font dejavu --rows 48
$R scenes/ui_visual.lua $OUT/09-tabs-fold-visual.png --rows 30 --keys 'Vjj'
$R scenes/c_write.lua   $OUT/10-easymotion.png --rows 24 --cols 96 --keys '<Bslash><Bslash>w'

# Spot colour: accent = false / 'red' / 'desk'
desk() { NP_OPTS="$2" $R scenes/desk.lua "$OUT/accent-$1.png" --rows 36 --cols 104 --post "$ERR" --keys 'Vj' "${@:3}"; }
desk none           "{}"
desk red            "{ accent = 'red' }"
desk desk           "{ accent = 'desk' }"
desk desk-night     "{ accent = 'desk' }" --bg dark
desk desk-truecolor "{ accent = 'desk' }" --mode gui
NP_OPTS="{ accent = 'desk' }" $R scenes/patch.lua $OUT/accent-desk-patch.png --rows 66 --no-cursor

# Tinted inks: inks = 'duotone' / 'sunday', comments = 'sidebar'
inks() { NP_OPTS="$2" $R scenes/inks.lua "$OUT/inks-$1.png" --rows 62 --cols 100 --no-cursor "${@:3}"; }
inks black                "{}"
inks duotone              "{ inks = 'duotone' }"
inks duotone-sidebar      "{ inks = 'duotone', comments = 'sidebar' }"
inks sunday-sidebar       "{ inks = 'sunday', comments = 'sidebar' }"
inks sunday-sidebar-night "{ inks = 'sunday', comments = 'sidebar' }" --bg dark
NP_TS=1 NP_OPTS="{ inks = 'sunday', comments = 'sidebar' }" \
  $R scenes/inks.lua $OUT/inks-sunday-sidebar-truecolor.png --mode gui --rows 50 --cols 100 --no-cursor
