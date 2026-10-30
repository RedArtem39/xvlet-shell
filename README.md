# xvlet

A Material 3 Expressive desktop shell, written for [Quickshell](https://quickshell.org).
It is the GUI layer of [WynlandOS](https://github.com/RedArtem39/WynlandOS) (Zerp answers
it as Hyprland does), kept as its own project: the OS ships it, it is not part of it.

## Status

Stage 1 of the port from the browser prototype:

- the theme: M3 tonal palettes from one seed hue, computed in OKLCH (`services/Theme.qml`),
  M3 Expressive shapes that morph point by point (`components/MShape.qml`)
- the wallpaper
- the bar, "islands" style: the launcher button, six workspaces, sound and battery, the clock

Next: the dock, the launcher and the popouts; widgets and wallpapers; settings;
system bridges (brightness, battery, network -- "нет" where the machine has none).

## Running

```
quickshell -p /path/to/xvlet-shell
```

On WynlandOS: an account whose desktop is `xvlet` (`~/.config/wynland/desktop`) gets it
from `/usr/share/xvlet`.

## Fonts

`assets/fonts/RobotoFlex.ttf` -- Roboto Flex, SIL Open Font License 1.1 (`assets/fonts/OFL.txt`).
The icons are Material Symbols Rounded (`assets/fonts/MaterialSymbolsRounded.ttf`, Apache 2.0).

## Sounds

`assets/sounds/` -- from Serpantinum by Illia Miroshnichenko (AGPL-3.0-or-later), see
`assets/sounds/CREDITS`. They play through Qt Multimedia; without it only the event sounds
(notifications, the network) play, through `pw-play`.

## Login screen

`wynlogin/Greeter.qml` -- xvlet's skin for WynlandOS's login screen (wynlogin): installed as
`/usr/share/wynlogin/themes/xvlet/`, chosen with `theme = xvlet` in `/etc/wynland/login.conf`.

## License

GNU Affero General Public License v3.0 or later (`LICENSE`).
