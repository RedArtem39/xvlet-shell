# xvlet

A Material 3 Expressive desktop shell, written for [Quickshell](https://quickshell.org).
It is the GUI layer of [WynlandOS](https://github.com/RedArtem39/WynlandOS) — the default
shell of its live image, on its own compositor Zerp, which answers it as Hyprland does — and
is kept as its own project: the OS ships it, it is not part of it.

It was designed as a browser prototype first and ported here piece by piece, so the shell
looks like the prototype pixel for pixel: the same palette maths, shapes, sizes and motion.

## What is in it

- **Theme** — Material 3 tonal palettes computed in OKLCH from one seed hue: taken from the
  wallpaper's own colours, chosen by hand, or a saved theme; eight schemes (tonal, vibrant,
  expressive, fidelity, neutral, monochrome, fruit salad, rainbow), dark and light, Roboto
  Flex with its variable weights, Material Symbols. Shapes that morph point by point (M3
  Expressive's cookies, flowers, the sunny shape), spring or smooth motion, or none.
- **Bar** — at any screen edge, four styles (islands, solid, flush with the screen's frame
  as in Exo, segments); modules: the logo, workspaces (pill, dots or numbers), the running
  windows, media, the tray, a system monitor, the weather, status, notifications, the
  clock, power.
- **Dock** — at any edge, attached, floating or a strip; pinned and running apps,
  magnification, labels, indicators, auto-hide.
- **Launcher** — apps by category, search, and modes: `>` the shell's actions, `=` a
  calculator, `:` emoji, `@` wallpapers.
- **Dashboard** — overview (the user, weather, calendar, media), media, system (gauges and
  graphs).
- **Quick settings** — volume, brightness, Do not disturb, theme, widgets edit mode, and
  the notification centre.
- **Notifications** — toasts at any corner, a centre, Do not disturb; the on-screen display
  for volume and brightness.
- **Desktop widgets** — clocks (lumen, cookie, digital, stretched), weather (full, round,
  compact), music (vinyl, a card), CPU, memory, disk, temperature and battery gauges, the
  user, a calendar, a note, a photo; moved and resized on a grid in edit mode, ready sets.
- **Wallpapers** — a picker with slanted cards and a colour filter; transitions (circle,
  wipe, fade, zoom, blinds).
- **Session menu**, **lock screen** (the clock, then the panel with the password, the
  weather, notifications and music), **settings** for all of the above.
- **Sounds** — clicks, switches, slider ticks, typing, the dock, notifications (a sound of
  your choice), the network coming and going; on or off, and how loud.
- **Infinite canvas** settings for Zerp (a free 2D desktop): placement of new windows, the
  feel of the motion, inertia, snapping, the ground.
- **A login screen skin** for WynlandOS's login manager (`wynlogin/Greeter.qml`).

## What it needs, and what it does without

| | from | without it |
|---|---|---|
| the compositor | Hyprland's IPC (Hyprland itself, or WynlandOS's Zerp) | workspaces, windows and shortcuts do nothing |
| sound devices and volume | PipeWire | the volume shows nothing |
| media | MPRIS | "Ничего не играет" |
| weather | `curl` to wttr.in | "нет данных" |
| brightness | `/sys/class/backlight` | the slider says the screen has no control |
| battery | `/sys/class/power_supply/BAT0` (WynlandOS has none yet) | "От сети · батареи нет" |
| sounds | Qt Multimedia | only the event sounds play, through `pw-play` |
| the lock screen | `ext-session-lock-v1` in the compositor | it cannot lock |
| the lock screen's password check | WynlandOS's `/usr/lib/wynland/chkpwd`, or PAM's `unix_chkpwd` | it cannot unlock |

Wi-Fi and Bluetooth tiles say "нет": WynlandOS has neither, and the shell does not pretend.
The lock screen is a session lock (`ext-session-lock-v1`, through Quickshell's
`WlSessionLock`): the compositor keeps the session locked — nothing else drawn, no other
window or shortcut gets a key, and if the shell dies the session stays locked. It needs a
compositor that has the protocol (Zerp, Hyprland, sway).

## Running

```
quickshell -p /path/to/xvlet-shell
```

On WynlandOS: an account whose desktop is `xvlet` (`~/.config/wynland/desktop`) gets it
from `/usr/share/xvlet`. Settings are saved in `~/.config/xvlet/config.json`;
`quickshell ipc -p /usr/share/xvlet call xvlet <function>` opens its parts (`launcher`,
`dash`, `qs`, `settings`, `wallpapers`, `session`, `lock`, `notify`, `set`, ...).

## Assets

- `assets/fonts/RobotoFlex.ttf` — Roboto Flex, SIL Open Font License 1.1
  (`assets/fonts/OFL.txt`); `assets/fonts/MaterialSymbolsRounded.ttf` — Material Symbols
  Rounded, Apache 2.0.
- `assets/walls/` — the shell's own wallpapers, generated.
- `assets/sounds/` — from Serpantinum by Illia Miroshnichenko (AGPL-3.0-or-later), see
  `assets/sounds/CREDITS`.

## Login screen

`wynlogin/Greeter.qml` — xvlet's skin for WynlandOS's login manager: installed as
`/usr/share/wynlogin/themes/xvlet/`, chosen with `theme = xvlet` in
`/etc/wynland/login.conf`. Plain QtQuick (it runs inside the compositor, without
Quickshell): the shell's colours and fonts, the big clock, the account and the password.

## License

GNU Affero General Public License v3.0 or later (`LICENSE`).
