#!/usr/bin/env lua
-- Standalone harness: stub the Noctalia runtime globals, load the plugin
-- entries, and exercise their callbacks to catch logic/type errors without a
-- real bw binary or a running Noctalia. Run with: luau test/run.luau <repo-root>

local captured = { results = nil, state = nil, cmds = {} }

local stub_src = [[
captured = ...
noctalia = {
  pluginDataDir = function() return "/tmp/bw-test-data" end,
  expandPath = function(p) return p end,
  getConfig = function(k)
    local cfg = {
      server_url = "https://vault.bitwarden.com",
      allow_insecure_tls = false,
      client_id = "cid",
      client_secret = "csec",
      master_password_file = "/tmp/bw-pw",
    }
    return cfg[k]
  end,
  readFile = function(_) return nil end,
  writeFile = function() return true end,
  removeFile = function() return true end,
  mkdirAll = function() return true end,
  state = { set = function(_, v) captured.state = v end },
  copyToClipboard = function() return true end,
  notify = function() end,
  notifyError = function() end,
  json = { decode = function(s) return load("return " .. s)() end },
  runAsync = function(cmd, cb)
    table.insert(captured.cmds, cmd)
    if cmd:find("bw status") then
      cb({ exitCode = 0, stdout = "unlocked", stderr = "" })
    elseif cmd:find("bw list items") then
      cb({ exitCode = 0, stdout = '[{"id":"i1","name":"github","login":{"username":"me@x.io","uris":[{"uri":"https://github.com"}]}}]', stderr = "" })
    elseif cmd:find("bw get password") then
      cb({ exitCode = 0, stdout = "s3cr3t", stderr = "" })
    else
      cb({ exitCode = 0, stdout = "", stderr = "" })
    end
    return true
  end,
}
launcher = { setResults = function(q, r) captured.results = r end }
]]

local root = arg[1] or "."
local function load_entry(path)
  local f = io.open(path, "r")
  if not f then error("cannot open " .. path) end
  local body = f:read("*a")
  f:close()
  local combined = stub_src .. "\n" .. body
  local chunk = load(combined, path, "t")
  if not chunk then error("load failed: " .. path) end
  chunk(captured)
end

load_entry(root .. "/plugins/official/bitwarden/service.luau")
load_entry(root .. "/plugins/official/bitwarden/lookup.luau")

captured.cmds = {}
update()
assert(captured.state and captured.state.status == "unlocked", "service should report unlocked")
onQuery("github")
assert(captured.results and #captured.results > 0, "lookup should return results")
assert(captured.results[1].id == "i1", "lookup result id mismatch")
onActivate("i1")
assert(#captured.cmds > 0, "activate should shell out to bw get password")

print("OK: service unlocked, lookup returned " .. #captured.results .. " result(s), activate issued bw command")
