// Noctalia widget capsule — dependency-free Web Component.
//
// The capsule is the single reusable pill shell for every bar module
// (static / popup / toggle). It is pure presentation over an existing module
// entry: it reads a config + runtime state and renders the pill, wires
// keyboard/click interaction, and emits events. No framework, no build step.
//
// Tokens + the 8-state matrix follow DESIGN_WIDGET_CAPSULE.md and reuse the
// Catppuccin/OKLCH set from the calendar + backdrop specs. No new palette.

const STATES = [
  "default", "hover", "focus-visible", "active",
  "disabled", "loading", "error", "success",
];

// Pure model: derive ARIA + resolved state from a module config and the
// live runtime overrides. No DOM dependency — this is the unit under test.
export function capsuleModel(cfg = {}, runtime = {}) {
  const kind = cfg.kind || "static";
  const interactive = kind === "popup" || kind === "toggle";
  const on = kind === "toggle" ? (runtime.on ?? false) : undefined;
  const expanded = kind === "popup" ? (runtime.active ?? false) : undefined;
  const state = STATES.includes(runtime.state) ? runtime.state : "default";
  const disabled = runtime.disabled ?? false;

  const aria = {
    "aria-label": cfg.aria_label || cfg.label || cfg.id || "button",
    "tabindex": interactive && !disabled ? "0" : "-1",
    "role": interactive ? "button" : null,
  };
  if (!interactive && cfg.decorative) aria["aria-hidden"] = "true";
  if (kind === "toggle") aria["aria-pressed"] = on ? "true" : "false";
  if (kind === "popup") aria["aria-expanded"] = expanded ? "true" : "false";

  return {
    kind,
    interactive,
    on,
    expanded,
    state,
    disabled,
    attrs: Object.fromEntries(
      Object.entries(aria).filter(([, v]) => v !== null),
    ),
  };
}

const CSS = `
  :host { display: inline-flex; }
  .cap {
    display: inline-flex; align-items: center; gap: 6px;
    height: 36px; padding: 0 12px; border-radius: 18px;
    background: oklch(22% 0.014 260 / 0.55);
    border: 1px solid transparent; color: oklch(92% 0.010 260);
    font: inherit; font-size: 13px; line-height: 1; white-space: nowrap;
    transition: background .12s ease-out, border-color .12s ease-out;
  }
  .cap .ico { width: 16px; height: 16px; display: inline-block; opacity: .9; }
  .cap .dot { width: 7px; height: 7px; border-radius: 50%;
    background: oklch(72% 0.13 268); flex: none; }
  .cap .label.mono { font-family: ui-monospace, "SF Mono", Menlo, monospace;
    font-variant-numeric: tabular-nums; }
  .cap[data-kind="popup"], .cap[data-kind="toggle"] { cursor: pointer; }
  .cap[data-kind="popup"]:hover, .cap[data-kind="toggle"]:hover {
    background: oklch(26% 0.016 260 / 0.7); }
  .cap:focus-visible { outline: 2px solid oklch(72% 0.13 268); outline-offset: 2px; }
  .cap[data-active="true"] { border-color: oklch(72% 0.13 268); }
  .cap[data-state="loading"] .dot { animation: cap-pulse 1s ease-in-out infinite; }
  .cap[data-state="error"] { border-color: oklch(68% 0.16 25); }
  .cap[data-state="success"] { border-color: oklch(72% 0.14 155); }
  .cap[data-disabled="true"] { opacity: .45; pointer-events: none; }
  .cap[data-on="true"] { background: oklch(72% 0.13 268);
    color: oklch(17% 0.012 260); border-color: transparent; }
  .cap[data-on="true"] .dot { background: oklch(17% 0.012 260); }
  @keyframes cap-pulse { 0%,100% { opacity: 1 } 50% { opacity: .3 } }
  @media (prefers-reduced-motion: reduce) {
    .cap { transition: none; }
    .cap[data-state="loading"] .dot { animation: none; }
  }
`;

const ICON = (path) =>
  `<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">${path}</svg>`;

// Base is HTMLElement in the browser; a plain class in node so the model
// stays importable/testable headless (ponytail: browser-only surface, none of
// the DOM methods are touched outside connectedCallback).
const CapsuleBase = typeof HTMLElement !== "undefined" ? HTMLElement : class {};

class NoctaliaCapsule extends CapsuleBase {
  #cfg = {};
  #rt = {};

  static get observedAttributes() { return ["data-active", "data-state", "data-on", "data-disabled"]; }

  connectedCallback() {
    if (!this.shadowRoot) {
      const root = this.attachShadow({ mode: "open" });
      root.innerHTML = `<style>${CSS}</style><span class="cap" part="cap"></span>`;
    }
    this.addEventListener("click", this.#onClick);
    this.addEventListener("keydown", this.#onKey);
    this.render();
  }

  disconnectedCallback() {
    this.removeEventListener("click", this.#onClick);
    this.removeEventListener("keydown", this.#onKey);
  }

  // -- data binding: configure the module this capsule wraps --
  setConfig(cfg) { this.#cfg = cfg || {}; this.render(); return this; }

  // -- data binding: patch live runtime state (loading/error/on/active...) --
  update(partial) { this.#rt = { ...this.#rt, ...(partial || {}) }; this.render(); return this; }

  get state() { return capsuleModel(this.#cfg, this.#rt); }

  #emit(name, detail) {
    this.dispatchEvent(new CustomEvent(name, { bubbles: true, composed: true, detail }));
  }

  #activate() {
    const m = this.state;
    if (m.disabled) return;
    if (m.kind === "toggle") {
      this.#rt.on = !m.on;
      this.#emit("capsule-toggle", { id: this.#cfg.id, on: this.#rt.on });
    } else if (m.kind === "popup") {
      if (m.expanded) {
        this.#close();
      } else {
        this.#rt.active = true;
        this.#emit("capsule-popup-open", { id: this.#cfg.id });
      }
    }
    this.render();
  }

  #close() {
    const wasOpen = this.state.expanded;
    this.#rt.active = false;
    if (wasOpen) this.#emit("capsule-popup-close", { id: this.#cfg.id });
    this.render();
    this.focus();
  }

  #onClick = () => this.#activate();

  #onKey = (e) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      this.#activate();
    } else if (e.key === "Escape" && this.state.expanded) {
      this.#close();
    }
  };

  render() {
    if (!this.shadowRoot) return;
    const m = this.state;
    const el = this.shadowRoot.querySelector(".cap");
    el.dataset.kind = m.kind;
    el.dataset.state = m.state;
    el.dataset.active = m.expanded ? "true" : "false";
    if (m.kind === "toggle") el.dataset.on = m.on ? "true" : "false";
    if (m.disabled) el.dataset.disabled = "true";

    for (const [k, v] of Object.entries(m.attrs)) el.setAttribute(k, v);

    const ico = this.#cfg.icon ? ICON(this.#cfg.icon) : "";
    const label = this.#cfg.label
      ? `<span class="label${this.#cfg.mono ? " mono" : ""}">${this.#cfg.label}</span>`
      : "";
    const dot = this.#cfg.status_dot ? `<span class="dot" aria-hidden="true"></span>` : "";
    el.innerHTML = `${ico}${label}${dot}`;
    return this;
  }
}

if (typeof customElements !== "undefined" && !customElements.get("noctalia-capsule")) {
  customElements.define("noctalia-capsule", NoctaliaCapsule);
}

export { NoctaliaCapsule };
