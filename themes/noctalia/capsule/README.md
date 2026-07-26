# Noctalia Widget Capsule

The single reusable pill container for every Noctalia bar module. Implements
`DESIGN_WIDGET_CAPSULE.md` (static / popup / toggle kinds + grouped cluster)
with zero dependencies and no build step. Pure presentation over an existing
module entry — no new theme palette or Nix key.

## Files

- `capsule.mjs` — the `<noctalia-capsule>` Web Component + the pure
  `capsuleModel()` helper (the unit under test).
- `capsule.test.mjs` — model tests: `node --test capsule.test.mjs`.
- `index.html` — standalone demo (open in a browser).

## Data binding

```js
import { NoctaliaCapsule } from "./capsule.mjs";

const cal = document.querySelector("#cal");
cal.setConfig({
  kind: "popup",            // static | popup | toggle
  id: "cal",
  icon: "<rect .../>",      // optional SVG inner markup
  label: "Calendar",
  mono: false,              // tabular-nums for clock/counters
  aria_label: "Calendar, 3 events today",
  status_dot: true,         // optional signal dot (hidden when no signal)
  decorative: false,        // static + true => aria-hidden, skip tab order
});

// live state patch (loading/error/success/on/active/disabled)
cal.update({ state: "loading" });
```

## Event handling

The capsule wires click / `Enter` / `Space` (activate) and `Escape` (close +
return focus for popups). It emits:

- `capsule-toggle` `{ id, on }` — toggle flipped.
- `capsule-popup-open` `{ id }` — popup capsule activated.
- `capsule-popup-close` `{ id }` — popup closed via Esc/click.

## ARIA contract (per design spec)

- Interactive capsules: `role="button"`, `aria-label` required, `tabindex="0"`.
- Toggle: `aria-pressed` reflects on/off.
- Popup: `aria-expanded` reflects open state.
- Static capsules: `tabindex="-1"`; decorative ones get `aria-hidden`.
- `:focus-visible` ring never removed; `prefers-reduced-motion` honored.

## Bar integration

Positioning/embedding into the live Noctalia bar is tracked separately (capsule
integration card). The component consumes the same `module` config contract the
bar already exposes; a host/plugin reads `noctalia.getConfig(...)` for
`state_source` and routes the emitted events to the bar surface.
