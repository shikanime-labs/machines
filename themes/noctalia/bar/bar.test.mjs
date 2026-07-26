// Bar integration data-sync tests — run with:
//   node --test themes/noctalia/bar/bar.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { buildCapsuleConfig, reduceBarEvent } from "./bar.mjs";

const baseState = {
  clock:   { time: "14:32" },
  net:     { connected: true, ssid: "home-net" },
  battery: { pct: 82, charging: false },
  dnd:     { on: false },
  cal:     { events: 3, open: false },
};

test("buildCapsuleConfig maps every bar module to a capsule", () => {
  const c = buildCapsuleConfig(baseState);
  assert.equal(c.clock.kind, "static");
  assert.equal(c.clock.decorative, true); // clock not focusable
  assert.equal(c.wifi.kind, "static");
  assert.equal(c.battery.mono, true);     // tabular nums
  assert.equal(c.dnd.kind, "toggle");
  assert.equal(c.cal.kind, "popup");
  assert.equal(c.cal.status_dot, true);   // 3 events => show dot
});

test("config reflects live data (battery%, network aria)", () => {
  const c = buildCapsuleConfig(baseState);
  assert.equal(c.battery.label, "82%");
  assert.equal(c.wifi.aria_label, "home-net connected");
  const dis = buildCapsuleConfig({ ...baseState, net: { connected: false, ssid: "Wi-Fi" } });
  assert.equal(dis.wifi.aria_label, "Wi-Fi disconnected");
});

test("config hides status dot when no events", () => {
  const c = buildCapsuleConfig({ ...baseState, cal: { events: 0, open: false } });
  assert.equal(c.cal.status_dot, false);
});

test("reduceBarEvent flips dnd.on from toggle event", () => {
  const next = reduceBarEvent(baseState, { type: "capsule-toggle", detail: { id: "dnd", on: true } });
  assert.equal(next.dnd.on, true);
  assert.equal(baseState.dnd.on, false); // pure: original untouched
});

test("reduceBarEvent tracks popup open/close", () => {
  const opened = reduceBarEvent(baseState, { type: "capsule-popup-open", detail: { id: "cal" } });
  assert.equal(opened.cal.open, true);
  const closed = reduceBarEvent(opened, { type: "capsule-popup-close", detail: { id: "cal" } });
  assert.equal(closed.cal.open, false);
});

test("reduceBarEvent ignores unrelated events", () => {
  const next = reduceBarEvent(baseState, { type: "capsule-popup-open", detail: { id: "other" } });
  assert.equal(next, baseState); // no new object for no-op
});
