# Noctalia Widget Capsule

How the Noctalia bar's capsule-style module cluster is enabled in this repo.

## TL;DR — the bar is config-driven, not web-component-driven

Noctalia v5's bar is a native, config-defined surface. Widgets are listed under
`[bar.<name>]` (`start` / `end` arrays) and each is either a built-in type
(`[widget.<name>]` with a `type`) or a Luau plugin entry
(`type = "<author>/<plugin>:<entry>"`). There is **no HTML/webview/iframe
surface** — a standalone `<noctalia-capsule>` Web Component cannot be loaded into
the live bar. The "capsule" pill look itself is a native bar property
(`capsule_radius`); every native widget renders as a capsule automatically.

Because this repo configures Noctalia entirely through Nix (no custom
theme-runtime code), the faithful way to "enable the widget capsule" is to
declare the bar's widget cluster + pill radius in `programs.noctalia.settings`
and let Noctalia render the capsules natively.

## What changed

`modules/home/graphical.nix` now sets:

```nix
programs.noctalia = {
  settings = {
    bar.main.reserve_space = false;
    bar.main.capsule_radius = 18;          # native pill radius (the "capsule" look)
    bar.main.start = [ "clock" "network" "battery" ];
    bar.main.end   = [ "caffeine" ];        # DND / idle-inhibit toggle
    # ...
  };
};
```

`home-manager switch` makes it live; no session restart required.

## Capsule → native widget mapping

The capsule design (DESIGN_WIDGET_CAPSULE.md) defined these modules; the live
bar maps them as:

| Capsule (design) | Native v5 widget        | Notes                                            |
| ---------------- | ----------------------- | ------------------------------------------------ |
| clock (static)   | `clock`                 | `bar.main.start`                                 |
| network (static) | `network`               | `bar.main.start`                                 |
| battery (static) | `battery`               | `bar.main.start`                                 |
| DND (toggle)     | `caffeine`              | idle-inhibitor toggle = the closest native "do not disturb" |
| calendar (popup) | —                       | **no native bar widget**; calendar is a service. Needs a Luau plugin to get a popup capsule on the bar. |

`network`/`battery` show their label by default (`show_label = true`); set them
to `false` in a `[widget.<name>]` block for glyph-only capsules.

## Reference assets (validated design, not live-loaded)

The sibling cards built a dependency-free `<noctalia-capsule>` Web Component and
a standalone `bar.html` demo. They are **validated reference implementations**
(22/22 model/data/interaction tests pass; ARIA + 8-state matrix verified), used
to pin the design contract — they are *not* loaded by the live v5 bar.

- `themes/noctalia/capsule/capsule.mjs` — `<noctalia-capsule>` + `capsuleModel()`.
- `themes/noctalia/capsule/capsule.test.mjs` — model tests (`node --test`).
- `themes/noctalia/bar/bar.mjs` / `bar.html` — data-sync contract + demo page.

If Noctalia later gains a webview/embed bar widget (or you build a Luau plugin
that reuses this capsule styling), these assets are the contract to match.

## Outstanding (needs a decision, not auto-enabled)

- **Calendar popup capsule**: requires a Luau plugin widget. Open a follow-up
  card to author `noctalia/capsule-calendar` (plugin_api 3) that reuses the
  `capsule.popup` ARIA contract from the reference assets.
- **DND semantics**: `caffeine` is an idle inhibitor, not a notification mute.
  If true DND is wanted, it also needs a plugin (or accept caffeine as the
  stand-in and note the difference).

## Validation

- Nix: `noctalia config validate` on the target host after `home-manager switch`
  (binary is Linux/Wayland only — cannot run on macOS).
- Reference assets: `node --test themes/noctalia/capsule/capsule.test.mjs themes/noctalia/bar/bar.test.mjs`.
