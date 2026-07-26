// Noctalia bar — capsule integration.
//
// Embeds the <noctalia-capsule> Web Component (../capsule/capsule.mjs) into the
// Noctalia bar surface. This module owns the bar's data-sync contract: it maps
// the live bar state model to per-capsule config, reduces capsule events back
// into state, and (in the browser) mounts the capsules + wires events.
//
// The DOM glue is browser-only; the data-sync logic (buildCapsuleConfig /
// reduceBarEvent) is pure and unit-tested headless in bar.test.mjs
// (ponytail: no headless DOM in this repo, mountBar is verified by opening
// bar.html).

import { NoctaliaCapsule } from "../capsule/capsule.mjs";

// --- icon markup (SVG inner paths, reused from the wireframe) ---
const ICON = {
  wifi: `<path d="M5 12h14M5 8h14M5 16h10"/>`,
  battery: `<rect x="3" y="8" width="16" height="8" rx="2"/><path d="M21 11v2"/>`,
  dnd: `<circle cx="12" cy="12" r="9"/><path d="M8 12h8"/>`,
  calendar: `<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/>`,
};

// Map the bar state model to each capsule's config. Pure: same state in,
// same config out. The capsule itself renders; this only decides *what* shows.
export function buildCapsuleConfig(s) {
  return {
    clock: {
      id: "clock", kind: "static", label: s.clock.time, mono: true, decorative: true,
    },
    wifi: {
      id: "wifi", kind: "static", label: s.net.ssid || "Wi-Fi", icon: ICON.wifi,
      aria_label: s.net.connected
        ? `${s.net.ssid || "Wi-Fi"} connected`
        : "Wi-Fi disconnected",
    },
    battery: {
      id: "battery", kind: "static", label: `${s.battery.pct}%`, mono: true, icon: ICON.battery,
      aria_label: `Battery ${s.battery.pct} percent${s.battery.charging ? ", charging" : ""}`,
    },
    dnd: {
      id: "dnd", kind: "toggle", label: "DND", icon: ICON.dnd,
      aria_label: `Do not disturb: ${s.dnd.on ? "on" : "off"}`,
    },
    cal: {
      id: "cal", kind: "popup", label: "Calendar", icon: ICON.calendar,
      status_dot: s.cal.events > 0,
      aria_label: `Calendar, ${s.cal.events} event${s.cal.events === 1 ? "" : "s"} today`,
    },
  };
}

// Reduce a capsule event back into bar state. Pure: returns a NEW state object
// (the capsule itself is the source of truth for toggle/popup visual state;
// here we persist the semantic flag so data stays synchronized on resync).
export function reduceBarEvent(state, ev) {
  if (ev.type === "capsule-toggle" && ev.detail.id === "dnd") {
    return { ...state, dnd: { ...state.dnd, on: ev.detail.on } };
  }
  if (ev.type === "capsule-popup-open" && ev.detail.id === "cal") {
    return { ...state, cal: { ...state.cal, open: true } };
  }
  if (ev.type === "capsule-popup-close" && ev.detail.id === "cal") {
    return { ...state, cal: { ...state.cal, open: false } };
  }
  return state;
}

// --- browser glue (no-op import side effects in node) ---
const WIRE = typeof document !== "undefined";

// Mount the capsules into `root` and keep them synced to `state`.
// `onState` fires after every event with the new state (for host persistence).
export function mountBar(root, initialState, { onState } = {}) {
  if (!WIRE) return null; // ponytail: browser-only surface
  let state = { ...initialState };
  const capsules = {};

  const sync = () => {
    for (const [id, cfg] of Object.entries(buildCapsuleConfig(state))) {
      capsules[id].setConfig(cfg);
    }
  };

  for (const [id, cfg] of Object.entries(buildCapsuleConfig(state))) {
    const el = document.createElement("noctalia-capsule");
    el.setConfig(cfg);
    root.appendChild(el);
    capsules[id] = el;
  }

  root.addEventListener("capsule-toggle", (e) => {
    state = reduceBarEvent(state, { type: e.type, detail: e.detail });
    onState?.(state);
    sync();
  });
  root.addEventListener("capsule-popup-open", (e) => {
    state = reduceBarEvent(state, { type: e.type, detail: e.detail });
    onState?.(state);
    sync();
  });
  root.addEventListener("capsule-popup-close", (e) => {
    state = reduceBarEvent(state, { type: e.type, detail: e.detail });
    onState?.(state);
    sync();
  });

  return { sync, getState: () => state };
}

export { NoctaliaCapsule };
