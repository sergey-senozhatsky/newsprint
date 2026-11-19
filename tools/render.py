#!/usr/bin/env python3
"""Screenshot a headless Neovim through its UI protocol.

Attaches to `nvim --embed` as an ext_linegrid UI, runs a scene, and paints the
final grid with PIL -- either the way urxvt would (256-colour palette, X11
misc-fixed bitmap font, no strikethrough, undercurl degraded to underline) or
the way a modern truecolor terminal would (gui colours, TrueType font).

    render.py SCENE.lua OUT.png [--mode cterm|gui] [--bg light|dark]
              [--font fixed7x13|fixed8x13|dejavu|liberation|courier]
              [--rows N] [--cols N] [--keys KEYS] [--post LUA] [--no-cursor]

Environment:
    NP_OPTS   vim.g.newsprint as a Lua table literal, e.g. "{ inks = 'sunday' }"
    NP_TS     1 to run the scene with tree-sitter highlighting (C scenes)
    NP_LINUX  the kernel tree the C scenes open (default /media/dev/linux-next)

Needs python3 with msgpack and Pillow.
"""

import argparse
import os
import select
import subprocess
import time

import msgpack
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))

MISC = '/usr/share/fonts/X11/misc/'
DJV = '/usr/share/fonts/truetype/dejavu/'
LIB = '/usr/share/fonts/truetype/liberation/'
MS = '/usr/share/fonts/truetype/msttcorefonts/'
FONTS = {
    'fixed7x13': dict(bitmap=True, size=13, R=MISC + '7x13.pcf.gz',
                      B=MISC + '7x13B.pcf.gz', I=MISC + '7x13O.pcf.gz',
                      BI=MISC + '7x13B.pcf.gz'),
    'fixed8x13': dict(bitmap=True, size=13, R=MISC + '8x13.pcf.gz',
                      B=MISC + '8x13B.pcf.gz', I=MISC + '8x13O.pcf.gz',
                      BI=MISC + '8x13B.pcf.gz'),
    'dejavu': dict(bitmap=False, size=15, R=DJV + 'DejaVuSansMono.ttf',
                   B=DJV + 'DejaVuSansMono-Bold.ttf',
                   I=DJV + 'DejaVuSansMono-Oblique.ttf',
                   BI=DJV + 'DejaVuSansMono-BoldOblique.ttf'),
    'liberation': dict(bitmap=False, size=15, R=LIB + 'LiberationMono-Regular.ttf',
                       B=LIB + 'LiberationMono-Bold.ttf',
                       I=LIB + 'LiberationMono-Italic.ttf',
                       BI=LIB + 'LiberationMono-BoldItalic.ttf'),
    'courier': dict(bitmap=False, size=16, R=MS + 'cour.ttf', B=MS + 'courbd.ttf',
                    I=MS + 'couri.ttf', BI=MS + 'courbi.ttf'),
}

# urxvt palette from ~/.Xdefaults (the rose-pine-dawn block comes last, wins).
ANSI = [0xf2e9de, 0xb4637a, 0x56949f, 0xea9d34, 0x286983, 0x907aa9, 0xd7827e,
        0x575279, 0x6e6a86, 0xb4637a, 0x56949f, 0xea9d34, 0x286983, 0x907aa9,
        0xd7827e, 0x575279]
TERM_FG, TERM_BG = 0x575279, 0xfaf4ed


def xterm(i):
    if i < 16:
        return ANSI[i]
    if i < 232:
        i -= 16
        lv = (0, 95, 135, 175, 215, 255)
        return lv[i // 36] << 16 | lv[i // 6 % 6] << 8 | lv[i % 6]
    v = 8 + 10 * (i - 232)
    return v << 16 | v << 8 | v


class Nvim:
    def __init__(self, argv, env):
        self.p = subprocess.Popen(argv, stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, env=env)
        self.up = msgpack.Unpacker(raw=False, strict_map_key=False)
        self.mid = 0
        self.notes = []

    def _feed(self, timeout):
        r, _, _ = select.select([self.p.stdout], [], [], timeout)
        if not r:
            return False
        data = os.read(self.p.stdout.fileno(), 1 << 20)
        if not data:
            raise EOFError('nvim exited')
        self.up.feed(data)
        return True

    def _send(self, obj):
        self.p.stdin.write(msgpack.packb(obj, use_bin_type=True))
        self.p.stdin.flush()

    def _handle(self, msg):
        if msg[0] == 2:
            self.notes.append(msg)
        elif msg[0] == 0:  # a request from nvim: answer with nil
            self._send([1, msg[1], None, None])

    def request(self, method, *args):
        self.mid += 1
        mid = self.mid
        self._send([0, mid, method, list(args)])
        while True:
            for msg in self.up:
                if msg[0] == 1 and msg[1] == mid:
                    if msg[2] is not None:
                        raise RuntimeError('%s: %s' % (method, msg[2]))
                    return msg[3]
                self._handle(msg)
            if not self._feed(20):
                raise TimeoutError(method)

    def pump(self, idle=0.4, limit=10.0):
        t0 = time.time()
        while time.time() - t0 < limit:
            got = self._feed(idle)
            for msg in self.up:
                self._handle(msg)
            if not got:
                break
        notes, self.notes = self.notes, []
        return notes


class Screen:
    def __init__(self):
        self.w = self.h = 0
        self.cells = []
        self.hl = {0: ({}, {})}
        self.defaults = (0, 0xffffff, 0xff0000, -1, -1)
        self.cursor = (0, 0)
        self.mode = 'normal'

    def feed(self, notes):
        for msg in notes:
            if msg[1] != 'redraw':
                continue
            for batch in msg[2]:
                fn = getattr(self, 'ev_' + batch[0], None)
                if fn:
                    for args in batch[1:]:
                        fn(*args)

    def ev_grid_resize(self, grid, w, h):
        self.w, self.h = w, h
        self.cells = [[[' ', 0] for _ in range(w)] for _ in range(h)]

    def ev_default_colors_set(self, fg, bg, sp, cfg, cbg):
        self.defaults = (fg, bg, sp, cfg, cbg)

    def ev_hl_attr_define(self, hid, rgb, cterm, info):
        self.hl[hid] = (rgb, cterm)

    def ev_grid_line(self, grid, row, col, cells, *rest):
        hid = 0
        for c in cells:
            if len(c) > 1:
                hid = c[1]
            for _ in range(c[2] if len(c) > 2 else 1):
                if col < self.w:
                    self.cells[row][col] = [c[0], hid]
                col += 1

    def ev_grid_clear(self, grid):
        for row in self.cells:
            for c in row:
                c[0], c[1] = ' ', 0

    def ev_grid_cursor_goto(self, grid, row, col):
        self.cursor = (row, col)

    def ev_grid_scroll(self, grid, top, bot, left, right, rows, cols):
        rng = range(top, bot - rows) if rows > 0 else range(bot - 1, top - rows - 1, -1)
        for r in rng:
            self.cells[r][left:right] = [list(x) for x in self.cells[r + rows][left:right]]

    def ev_mode_change(self, mode, idx):
        self.mode = mode


def paint(scr, out, font, mode, scale, pad=10, show_cursor=True):
    F = FONTS[font]
    fonts = {k: ImageFont.truetype(F[k], F['size']) for k in ('R', 'B', 'I', 'BI')}
    asc, desc = fonts['R'].getmetrics()
    cw = int(round(fonts['R'].getlength('M')))
    ch = asc + desc + (0 if F['bitmap'] else 2)
    urxvt = mode == 'cterm'

    rgb_fg, rgb_bg, rgb_sp, cfg, cbg = scr.defaults
    if urxvt:
        # default_colors_set passes cterm colours 1-based; 0 is "terminal default"
        dfg = xterm(cfg - 1) if cfg > 0 else TERM_FG
        dbg = xterm(cbg - 1) if cbg > 0 else TERM_BG
        dsp = None
    else:
        dfg, dbg, dsp = rgb_fg, rgb_bg, rgb_sp

    def colours(hid):
        rgb, cterm = scr.hl.get(hid, ({}, {}))
        a = cterm if urxvt else rgb
        conv = xterm if urxvt else (lambda x: x)
        fg = conv(a['foreground']) if 'foreground' in a else dfg
        bg = conv(a['background']) if 'background' in a else dbg
        sp = rgb.get('special', dsp) if not urxvt else None
        if a.get('reverse'):
            fg, bg = bg, fg
        return a, fg, bg, (sp if sp is not None else fg)

    W, H = scr.w * cw + 2 * pad, scr.h * ch + 2 * pad
    img = Image.new('RGB', (W, H), '#%06x' % dbg)
    d = ImageDraw.Draw(img)
    hexc = lambda c: '#%06x' % c

    def wide(r, c):
        return c + 1 < scr.w and scr.cells[r][c + 1][0] == ''

    for r, row in enumerate(scr.cells):  # backgrounds first, so italics overhang
        for c, (text, hid) in enumerate(row):
            if text == '':
                continue
            a, fg, bg, sp = colours(hid)
            x, y = pad + c * cw, pad + r * ch
            w = cw * (2 if wide(r, c) else 1)
            if (r, c) == scr.cursor and show_cursor and scr.mode.startswith('normal'):
                bg = 0x262626
            if bg != dbg:
                d.rectangle([x, y, x + w - 1, y + ch - 1], fill=hexc(bg))

    for r, row in enumerate(scr.cells):
        for c, (text, hid) in enumerate(row):
            if text == '':
                continue
            a, fg, bg, sp = colours(hid)
            x, y = pad + c * cw, pad + r * ch
            w = cw * (2 if wide(r, c) else 1)
            if (r, c) == scr.cursor and show_cursor and scr.mode.startswith('normal'):
                fg = 0xeeeeee
            if text != ' ':
                key = ('B' if a.get('bold') else '') + ('I' if a.get('italic') else '')
                d.text((x, y + asc), text, font=fonts[key or 'R'], fill=hexc(fg), anchor='ls')
            base = y + asc + 1
            under = a.get('underline') or a.get('underdouble')
            if urxvt and (a.get('undercurl') or a.get('underdotted') or a.get('underdashed')):
                under = True
            if under:
                d.line([(x, base), (x + w - 1, base)], fill=hexc(sp))
            elif a.get('undercurl'):
                pts = [(x + i, base + (1 if (x + i) % 4 < 2 else 0)) for i in range(w)]
                d.line(pts, fill=hexc(sp))
            elif a.get('underdotted') or a.get('underdashed'):
                step = 2 if a.get('underdotted') else 4
                for i in range(0, w, step * 2):
                    d.line([(x + i, base), (x + min(i + step - 1, w - 1), base)], fill=hexc(sp))
            if a.get('strikethrough') and not urxvt:
                sy = y + asc - asc // 3
                d.line([(x, sy), (x + w - 1, sy)], fill=hexc(fg))

    if show_cursor and scr.mode.startswith('insert'):
        r, c = scr.cursor
        x, y = pad + c * cw, pad + r * ch
        d.rectangle([x, y, x + (0 if F['bitmap'] else 1), y + ch - 1], fill='#262626')

    if scale != 1:
        img = img.resize((W * scale, H * scale), Image.NEAREST if F['bitmap'] else Image.LANCZOS)
    img.save(out)
    return img.size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('scene')
    ap.add_argument('out')
    ap.add_argument('--mode', default='cterm', choices=('cterm', 'gui'))
    ap.add_argument('--font', default=None)
    ap.add_argument('--scale', type=int, default=None)
    ap.add_argument('--cols', type=int, default=100)
    ap.add_argument('--rows', type=int, default=42)
    ap.add_argument('--keys', default='')
    ap.add_argument('--post', default='', help='Lua run (not silenced) after the scene')
    ap.add_argument('--bg', default='light')
    ap.add_argument('--no-cursor', action='store_true')
    ap.add_argument('--dump-defaults', action='store_true')
    args = ap.parse_args()

    font = args.font or ('fixed7x13' if args.mode == 'cterm' else 'dejavu')
    scale = args.scale or (2 if FONTS[font]['bitmap'] else 1)

    env = dict(os.environ)
    for k in ('STATE', 'CACHE', 'DATA', 'CONFIG'):
        env['XDG_%s_HOME' % k] = '/tmp/np/' + k.lower()
        os.makedirs('/tmp/np/' + k.lower(), exist_ok=True)
    env['NP_ROOT'] = os.path.dirname(HERE)
    env['NP_BG'] = args.bg
    env['NP_TGC'] = '1' if args.mode == 'gui' else '0'
    argv = ['nvim', '--embed', '-i', 'NONE', '-n', '-u', os.path.join(HERE, 'init.lua')]

    nv = Nvim(argv, env)
    scr = Screen()
    nv.request('nvim_ui_attach', args.cols, args.rows, {'rgb': True, 'ext_linegrid': True})
    scr.feed(nv.pump())
    # :silent, so a burst of file-info messages can't park us at a hit-enter prompt
    nv.request('nvim_exec2', 'silent luafile ' + os.path.abspath(args.scene), {})
    scr.feed(nv.pump())
    if args.post:
        nv.request('nvim_exec_lua', args.post, [])
        scr.feed(nv.pump())
    if args.keys:
        nv.request('nvim_input', args.keys)
        scr.feed(nv.pump(idle=0.6))
    if args.dump_defaults:
        print('defaults', scr.defaults)
    size = paint(scr, args.out, font, args.mode, scale, show_cursor=not args.no_cursor)
    print('%s %dx%d' % (args.out, size[0], size[1]))
    try:
        nv.request('nvim_command', 'qa!')
    except Exception:
        pass
    nv.p.kill()


if __name__ == '__main__':
    main()
