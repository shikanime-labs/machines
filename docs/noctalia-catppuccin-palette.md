# Using and Customizing the Catppuccin Palette in Noctalia

This guide explains how the [Catppuccin](https://catppuccin.com) color palette is
wired into Noctalia on the `ishtar` workstation, and how to use / customize it
across Noctalia's two surfaces (the **shell** and the **greeter**) plus the
broader `catppuccin-nix` Home Manager ecosystem.

> Scope note: Noctalia v5 is in beta (`README.md`). The shell theme options below
> are taken from upstream `example.toml` and from source-level verification in task
> `t_cb42e7e4`. The greeter options are taken from the `noctalia-greeter` NixOS
> module, which writes `settings` verbatim to `greeter.toml`.

## What "Catppuccin in Noctalia" Means

Noctalia ships a set of **builtin palettes**. One of them is literally named
`Catppuccin`. At the source level (Noctalia 5.0.0, `builtin_palettes.cpp:125`)
the builtin `Catppuccin` entry is defined as **Mocha** (dark) — its primary color
is `#cba6f7` (Catppuccin Mocha `mauve`). So selecting the builtin `Catppuccin`
palette gives you Catppuccin **Mocha-dark** on both Noctalia surfaces.

There are two independent places you configure it:

| Surface | Module | Config location | Effective key |
| --- | --- | --- | --- |
| Shell (bar/launcher/panels) | `programs.noctalia` | per-user Home Manager (`hosts/ishtar/users/shika/home-configuration.nix`) | `[theme] builtin = "Catppuccin"` |
| Greeter (login screen) | `programs.noctalia-greeter` | system NixOS (`modules/nixos/graphical.nix`) | `[appearance] scheme = "Catppuccin"` |

They are **not** linked — changing one does not change the other. Both must be
set if you want a consistent login-to-desktop look.

## 1. Enable Catppuccin on the Noctalia Shell

Set `theme.builtin = "Catppuccin"` in the Home Manager `programs.noctalia`
options. This is already done for `ishtar`:

```nix
# hosts/ishtar/users/shika/home-configuration.nix
programs = {
  noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell = {
        font = "JetBrainsMono Nerd Font";
      };
      theme = {
        mode = "auto";          # dark | light | auto
        source = "builtin";     # builtin | wallpaper | community
        builtin = "Catppuccin"; # Ayu | Catppuccin | Dracula | Eldritch |
                                # Gruvbox | Kanagawa | Noctalia | Nord |
                                # Rosé Pine | Tokyo-Night
      };
    };
  };
};
```

`theme.mode` controls dark vs. light:
- `dark` → Catppuccin **Mocha**
- `light` → Catppuccin **Latte**
- `auto` → follows the system time/appearance and switches Mocha↔Latte
  automatically (Noctalia's auto-mode theme engine).

Because the builtin `Catppuccin` resolves to Mocha, `mode = "dark"` gives a
static Mocha-dark desktop; `mode = "auto"` (the current `ishtar` setting)
follows the system light/dark state and switches Mocha↔Latte automatically.

## 2. Enable Catppuccin on the Noctalia Greeter

The greeter reads `programs.noctalia-greeter.settings` verbatim into
`greeter.toml`. The palette is selected under the `[appearance]` table via
`scheme`, **not** under `[theme]`.

Correct configuration:

```nix
# modules/nixos/graphical.nix
programs.noctalia-greeter = {
  enable = true;
  settings = {
    appearance = {
      scheme = "Catppuccin";   # drives the greeter palette (Mocha-dark)
    };
    cursor = {
      theme = "Adwaita";
      size = 24;
    };
    keyboard = {
      layout = "us";
    };
  };
};
```

### Pitfall: the inert `theme.mode` key

The older form below is a **silent no-op** on the greeter. The greeter's TOML
parser only accepts `scheme` (and a few others like `password_style`,
`hide_logo`) under `[appearance]`; a `[theme]` section is dropped without error.
Do not use it:

```nix
# ❌ INCORRECT — parsed but ignored by the greeter
programs.noctalia-greeter.settings = {
  theme = { mode = "dark"; };   # has no effect on the greeter palette
};
```

Source-level verification (`t_cb42e7e4`): `greeter_config_io.cpp:155` maps
`[appearance].scheme` → `config.appearanceScheme` → `prefs.scheme`, which is what
actually drives the palette. Use `appearance.scheme = "Catppuccin"`.

## 3. Customizing the Palette

### Builtin palette choice

Swap `theme.builtin` for any of the builtin palettes if you want a different look
(Ayu, Dracula, Gruvbox, Kanagawa, Nord, Rosé Pine, Tokyo-Night, …). For
Catppuccin specifically you only pick the dark/light *mode*, since the builtin
`Catppuccin` ships Mocha (dark) and Latte (light) variants.

### OLED / true-black

`pure_black_dark = true` anchors dark surfaces to true black across **every**
palette source (including the Catppuccin builtin). Add it under `[theme]`:

```nix
theme = {
  mode = "dark";
  source = "builtin";
  builtin = "Catppuccin";
  pure_black_dark = true;   # OLED-friendly true black in dark mode
};
```

### Recolor external apps (Firefox, KDE, etc.)

Noctalia can emit theme files for other apps via **templates**
(`[theme.templates]`), using the active palette's colors. The shell ships
builtin templates (`enable_builtin_templates = true`) such as a Firefox theme and
a KDE color scheme. These automatically follow the Catppuccin palette:

```nix
theme = {
  builtin = "Catppuccin";
  templates = {
    enable_builtin_templates = true;   # e.g. firefox-theme, kde-color-scheme
    builtin_ids = [];                  # opt-in list; empty = all builtins
  };
};
```

Run `noctalia theme --list-templates` to see available ids. User-defined templates
can also be declared inline (see upstream `example.toml` `[theme.templates.user.*`).

### Wallpaper-derived palettes (alternative to builtin)

If you'd rather have Noctalia derive a palette from your wallpaper instead of a
fixed builtin, set `theme.source = "wallpaper"` and choose a `wallpaper_scheme`
(e.g. `"m3-tonal-spot"`, `"vibrant"`, `"muted"`). This disables the fixed
Catppuccin look in favor of a wallpaper-matched palette.

## 4. Aligning the Rest of the System (catppuccin-nix)

Noctalia's builtin palette is self-contained — it does **not** recolor your
terminal, prompt, or other CLI tools. Those are themed separately by the
[`catppuccin/nix`](https://github.com/catppuccin/nix) Home Manager module, which
is already wired into this flake (`modules/flake/nixos.nix` →
`inputs.catppuccin.homeModules.default`).

### Set the global Catppuccin flavor

The home module default is `latte` (light):

```nix
# modules/home/workstation.nix
catppuccin = {
  enable = true;
  flavor = "latte";   # latte | frappe | macchiato | mocha
};
```

To make terminal/CLI tools match the Noctalia **Mocha** surfaces, set
`flavor = "mocha"`.

### Per-app sources (already used in this repo)

The `catppuccin` module exposes `config.catppuccin.sources.<app>` with ready-made
theme files. The repo already uses them for Ghostty and Starship:

```nix
# modules/home/ghostty.nix
programs.ghostty = {
  enable = true;
  settings = {
    # Ghostty accepts a combined dark/light expression:
    theme = "dark:catppuccin-frappe,light:catppuccin-latte";
  };
};
xdg.configFile."ghostty/themes/catppuccin-frappe".source =
  "${config.catppuccin.sources.ghostty}/catppuccin-frappe.conf";
```

```nix
# modules/home/starship.nix
let
  settings = importTOML "${config.catppuccin.sources.starship}/latte.toml";
in
{
  programs.starship = {
    enable = true;
    settings = {
      palette = "catppuccin_latte";
    } // settings;
  };
}
```

Other apps supported by `catppuccin/nix` include `k9s` (note:
`modules/home/cloud.nix` currently sets `catppuccin.k9s.enable = false`),
`helix`, `bat`, `git`, `fish`, `zsh`, and many more — enable them under the
`catppuccin` attribute set and reference `config.catppuccin.sources.<app>`.

### Cross-app consistency note

Currently the repo mixes Catppuccin **flavors** across apps:
- Noctalia shell + greeter → **Mocha** (via the builtin)
- Ghostty → **Frappe** (dark) / **Latte** (light)
- `catppuccin` home module default → **Latte**

If you want strict visual uniformity, align them: set the home module
`flavor = "mocha"`, point Ghostty at `catppuccin-mocha` for dark, and update
Starship's `palette`/`sources` to the `mocha` variant. This is optional — the
differing flavors are independent and not a regression.

## 5. Verification

After editing, confirm the configuration evaluates without option errors:

```sh
# Full NixOS eval for ishtar (no option-type errors = good)
nix eval .#nixosConfigurations.ishtar.config.system.name
# Expected: "ishtar"

# For Home Manager-only changes
home-manager build --flake .#shika@ishtar
```

Both Noctalia surfaces select a static builtin palette at startup (one-time
lookup, no runtime/shader cost) — performance impact is negligible.

## References

- Upstream Noctalia: <https://github.com/noctalia-dev/noctalia> (see `example.toml`, `nix/nixos-module.nix`)
- Upstream Noctalia Greeter: <https://github.com/noctalia-dev/noctalia-greeter> (`nix/nixos-module.nix` writes `settings` → `greeter.toml`)
- Catppuccin Nix module: <https://github.com/catppuccin/nix>
- Palette integration test (`t_cb42e7e4`): `palette-integration-test.md` in that task's workspace
- Repo config files referenced: `modules/nixos/graphical.nix`, `hosts/ishtar/users/shika/home-configuration.nix`, `modules/home/{workstation,ghostty,starship,cloud,helix}.nix`, `modules/flake/nixos.nix`
