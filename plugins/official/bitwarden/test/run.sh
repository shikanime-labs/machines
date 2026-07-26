#!/usr/bin/env bash
# Run the Bitwarden plugin test harness under the real Luau runtime.
# Assembles stub + real entry-source + assertions into one script (the Luau CLI
# has no io/require-from-toplevel), then executes it.
#
# Usage: bash plugins/official/bitwarden/test/run.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
PLUGIN=plugins/official/bitwarden

HEADER='
local state, last_results, cmds, vfs, config, clipboard, mock
local SESSION_PATH = "/virtual/bw_session"
noctalia = {}
launcher = {}
local function reset()
  state = nil; last_results = nil; cmds = {}; vfs = {}; config = {}; clipboard = { calls = 0, last = nil }; mock = { plan = nil }
  noctalia.pluginDataDir = function() return "/virtual" end
  noctalia.expandPath = function(p) return p end
  noctalia.getConfig = function(k) return config[k] end
  noctalia.readFile = function(p) return vfs[p] end
  noctalia.writeFile = function(p, d) vfs[p] = d; return true end
  noctalia.removeFile = function(p) vfs[p] = nil; return true end
  noctalia.mkdirAll = function() return true end
  noctalia.state = { set = function(_, v) state = v end }
  noctalia.copyToClipboard = function(d) clipboard.calls = clipboard.calls + 1; clipboard.last = d; return true end
  noctalia.notify = function() end
  noctalia.notifyError = function() end
  noctalia.json = { decode = json_decode }
  noctalia.runAsync = function(cmd, cb)
    table.insert(cmds, cmd)
    local r = (mock.plan and mock.plan(cmd)) or { exitCode = 0, stdout = "", stderr = "" }
    cb(r)
  end
  launcher.setResults = function(_, r) last_results = r end
end
'

# minimal JSON parser (bw emits JSON; entries depend on decoding it)
JSON='
local function json_decode(s)
  local i = 1
  local function ws()
    while i <= #s do local c = s:sub(i, i)
      if c == " " or c == "\n" or c == "\t" or c == "\r" then i = i + 1 else break end end
  end
  local function str()
    i = i + 1; local buf = {}
    while i <= #s do local c = s:sub(i, i)
      if c == "\"" then i = i + 1; return table.concat(buf) end
      if c == "\\" then i = i + 1; local e = s:sub(i, i)
        if e == "u" then local hex = s:sub(i + 1, i + 4); i = i + 4; buf[#buf + 1] = string.char(tonumber(hex, 16) or 63)
        else local map = { ["\""] = "\"", ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }; buf[#buf + 1] = map[e] or e; i = i + 1 end
      else buf[#buf + 1] = c; i = i + 1 end
    end
    error("json: unterminated string")
  end
  local function num()
    local j = i; while j <= #s and s:sub(j, j):match("[%d%.%+%-eE]") do j = j + 1 end
    local n = tonumber(s:sub(i, j - 1)); i = j; return n
  end
  local function arr()
    i = i + 1; local t = {}; ws()
    if s:sub(i, i) == "]" then i = i + 1; return t end
    while true do ws(); t[#t + 1] = val(); ws()
      local c = s:sub(i, i)
      if c == "," then i = i + 1 elseif c == "]" then i = i + 1; return t else error("json array") end
    end
  end
  local function obj()
    i = i + 1; local t = {}; ws()
    if s:sub(i, i) == "}" then i = i + 1; return t end
    while true do ws(); local key = str(); ws()
      if s:sub(i, i) ~= ":" then error("json object :") end
      i = i + 1; ws(); t[key] = val(); ws()
      local c = s:sub(i, i)
      if c == "," then i = i + 1 elseif c == "}" then i = i + 1; return t else error("json object }") end
    end
  end
  function val()
    ws(); local c = s:sub(i, i)
    if c == "{" then return obj() end
    if c == "[" then return arr() end
    if c == "\"" then return str() end
    if c == "t" then i = i + 4; return true end
    if c == "f" then i = i + 5; return false end
    if c == "n" then i = i + 4; return nil end
    if c:match("[%-%d]") then return num() end
    error("json char " .. c)
  end
  return val()
end
'

BODY='
local passed, failed = 0, 0
local function ok(cond, msg)
  if cond then passed = passed + 1; print("  ok   " .. msg)
  else failed = failed + 1; print("  FAIL " .. msg) end
end
local ITEMS = "[{\"id\":\"i1\",\"name\":\"github\",\"login\":{\"username\":\"me@x.io\",\"uris\":[{\"uri\":\"https://github.com\"}]}},{\"id\":\"i2\",\"name\":\"nologin\"}]"

-- T1: config validation — missing API creds -> needs-auth
reset()
config = { server_url = "https://vault.bitwarden.com", client_id = "", client_secret = "", master_password_file = "" }
mock.plan = function(cmd)
  if cmd:find("bw login %-%-apikey %-%-check") then return { exitCode = 1 } end
  return { exitCode = 0 }
end
SERVICE
ok(state and state.status == "needs-auth", "missing client_id/secret -> needs-auth")

-- T2: full auth happy path (apikey login + unlock)
reset()
config = { server_url = "https://vault.bitwarden.com", client_id = "cid", client_secret = "csec", master_password_file = "/tmp/pw" }
mock.plan = function(cmd)
  if cmd:find("bw login %-%-apikey %-%-check") then return { exitCode = 1 } end
  if cmd:find("BW_CLIENTID=") then return { exitCode = 0 } end
  if cmd:find("bw unlock") then return { exitCode = 0, stdout = "BW_SESSION=\"sess-999\"" } end
  if cmd:find("bw status") then return { exitCode = 0, stdout = "unlocked" } end
  return { exitCode = 0 }
end
SERVICE
ok(state and state.status == "unlocked", "apikey login + unlock -> unlocked")
ok(vfs[SESSION_PATH] == "sess-999", "session key cached in pluginDataDir")

-- T3: credential retrieval + clipboard copy on activate
reset()
config = { server_url = "https://vault.bitwarden.com", client_id = "cid", client_secret = "csec", master_password_file = "/tmp/pw" }
vfs[SESSION_PATH] = "sess-999"
mock.plan = function(cmd)
  if cmd:find("bw list items") then return { exitCode = 0, stdout = ITEMS } end
  if cmd:find("bw get password") then return { exitCode = 0, stdout = "pw123" } end
  if cmd:find("bw status") then return { exitCode = 0, stdout = "unlocked" } end
  return { exitCode = 0 }
end
SERVICE
LOOKUP
onQuery("github")
ok(last_results and #last_results == 2, "lookup returns 2 parsed items")
ok(last_results and last_results[1].id == "i1", "lookup result id preserved")
ok(last_results and last_results[1].subtitle:find("github.com"), "subtitle derives from login uri")
onQuery("")
ok(last_results and last_results[1].id == "hint", "empty query -> hint result")
onActivate("i1")
ok(clipboard.calls == 1 and clipboard.last == "pw123", "activate copies password to clipboard")

-- T4: error handling — network failure on list + get
reset()
config = { server_url = "https://vault.bitwarden.com", client_id = "cid", client_secret = "csec", master_password_file = "/tmp/pw" }
vfs[SESSION_PATH] = "sess-999"
mock.plan = function(cmd)
  if cmd:find("bw list items") then return { exitCode = 1, stderr = "Couldn'"'"'t connect to server" } end
  if cmd:find("bw get password") then return { exitCode = 1, stderr = "timeout" } end
  if cmd:find("bw status") then return { exitCode = 0, stdout = "unlocked" } end
  return { exitCode = 0 }
end
SERVICE
LOOKUP
onQuery("github")
ok(last_results and last_results[1].id == "err", "list network failure -> error result")
clipboard.calls = 0
onActivate("i1")
ok(clipboard.calls == 0, "get failure -> no clipboard write")

-- T5: invalid token — stale session, unlock rejected
reset()
config = { server_url = "https://vault.bitwarden.com", client_id = "cid", client_secret = "csec", master_password_file = "/tmp/pw" }
vfs[SESSION_PATH] = "stale"
mock.plan = function(cmd)
  if cmd:find("bw status") then return { exitCode = 0, stdout = "locked" } end
  if cmd:find("bw login %-%-apikey %-%-check") then return { exitCode = 1 } end
  if cmd:find("BW_CLIENTID=") then return { exitCode = 0 } end
  if cmd:find("bw unlock") then return { exitCode = 1, stderr = "invalid master password" } end
  return { exitCode = 0 }
end
SERVICE
ok(state and state.status == "locked", "invalid token -> locked")
ok(vfs[SESSION_PATH] == nil, "invalid token -> cached session removed")

-- T6: session reuse — valid cache, no re-login
reset()
config = { server_url = "https://vault.bitwarden.com", client_id = "cid", client_secret = "csec", master_password_file = "/tmp/pw" }
vfs[SESSION_PATH] = "sess-999"
mock.plan = function(cmd)
  if cmd:find("bw status") then return { exitCode = 0, stdout = "unlocked" } end
  return { exitCode = 0 }
end
SERVICE
ok(state and state.status == "unlocked", "valid cached session -> unlocked")
local relogin = false
for _, c in ipairs(cmds) do if c:find("bw login") then relogin = true end end
ok(not relogin, "no re-login when session valid")

print("")
print(passed .. " passed, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
'

# Substitute the real entry sources into the markers, then drop the markers.
BODY=${BODY//SERVICE/$(cat "$PLUGIN/service.luau")}
BODY=${BODY//LOOKUP/$(cat "$PLUGIN/lookup.luau")}

# Assemble: JSON parser (defines json_decode) FIRST, then stub header that
# references it, then the test body (which embeds the real entry sources).
TMP=$(mktemp /tmp/bw_test.XXXXXX.luau)
printf '%s%s%s' "$JSON" "$HEADER" "$BODY" > "$TMP"
nix shell nixpkgs#luau -c luau "$TMP"
rm -f "$TMP"
