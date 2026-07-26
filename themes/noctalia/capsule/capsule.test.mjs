// Pure model test — run with: node --test themes/noctalia/capsule/capsule.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { capsuleModel } from "./capsule.mjs";

test("static capsule is non-interactive, not in tab order", () => {
  const m = capsuleModel({ kind: "static", id: "clock", label: "14:32" });
  assert.equal(m.interactive, false);
  assert.equal(m.attrs["tabindex"], "-1");
  assert.equal(m.attrs["role"], undefined);
});

test("decorative static capsule gets aria-hidden", () => {
  const m = capsuleModel({ kind: "static", id: "spacer", decorative: true });
  assert.equal(m.attrs["aria-hidden"], "true");
});

test("popup capsule exposes aria-expanded + button role", () => {
  const closed = capsuleModel({ kind: "popup", id: "cal", aria_label: "Calendar" });
  assert.equal(closed.interactive, true);
  assert.equal(closed.attrs["role"], "button");
  assert.equal(closed.attrs["aria-expanded"], "false");
  assert.equal(closed.attrs["tabindex"], "0");

  const open = capsuleModel({ kind: "popup", id: "cal" }, { active: true });
  assert.equal(open.expanded, true);
  assert.equal(open.attrs["aria-expanded"], "true");
});

test("toggle capsule reflects on-state via aria-pressed", () => {
  const off = capsuleModel({ kind: "toggle", id: "dnd", aria_label: "DND" });
  assert.equal(off.attrs["aria-pressed"], "false");
  const on = capsuleModel({ kind: "toggle", id: "dnd" }, { on: true });
  assert.equal(on.on, true);
  assert.equal(on.attrs["aria-pressed"], "true");
});

test("disabled interactive capsule drops out of tab order", () => {
  const m = capsuleModel({ kind: "toggle", id: "dnd" }, { disabled: true });
  assert.equal(m.disabled, true);
  assert.equal(m.attrs["tabindex"], "-1");
});

test("unknown runtime state falls back to default", () => {
  const m = capsuleModel({ kind: "popup", id: "cal" }, { state: "bogus" });
  assert.equal(m.state, "default");
  const ok = capsuleModel({ kind: "popup", id: "cal" }, { state: "error" });
  assert.equal(ok.state, "error");
});
