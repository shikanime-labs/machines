-- Bitwarden service entry: owns the bw auth lifecycle.
-- Runs headless; publishes vault status to noctalia.state["bw_status"] so the
-- lookup entry and widgets can read it without re-authenticating.
--
-- Secret hygiene:
--   * BW_SESSION is cached in pluginDataDir() (survives plugin updates), never pluginDir().
--   * The master password is read from a file path in config, never logged or passed on argv.
--   * We never print the session key or any vault secret.

local SESSION_FILE = noctalia.pluginDataDir() .. "/bw_session"
local STATUS_KEY = "bw_status"

local function setStatus(status: string, detail: string?)
  noctalia.state.set(STATUS_KEY, { status = status, detail = detail or "" })
end

local function shellQuote(s: string): string
  return "'" .. string.gsub(s, "'", [['\'']]) .. "'"
end

-- Read the cached session key from disk (nil if absent).
local function readSession(): string?
  local data, err = noctalia.readFile(SESSION_FILE)
  if data == nil or #data == 0 then
    return nil
  end
  -- trim trailing newline
  return (data:gsub("\n$", ""))
end

local function writeSession(key: string)
  noctalia.mkdirAll(noctalia.pluginDataDir())
  noctalia.writeFile(SESSION_FILE, key)
end

local function removeSession()
  noctalia.removeFile(SESSION_FILE)
end

-- Run a bw command, feeding BW_SESSION via env (never argv). cb(err, stdout)
local function bw(args: string, cb: (string?, string?) -> ())
  local cmd = "BW_SESSION=" .. shellQuote(readSession() or "") .. " bw " .. args
  noctalia.runAsync(cmd, function(res)
    if res.exitCode ~= 0 then
      cb(res.stderr or res.stdout or "bw failed", nil)
      return
    end
    cb(nil, res.stdout)
  end)
end

local function ensureServer()
  local url = noctalia.getConfig("server_url")
  if url == nil or url == "" or url == "https://vault.bitwarden.com" then
    return
  end
  -- idempotent: bw config server is harmless to re-run
  noctalia.runAsync("bw config server " .. shellQuote(url), function(_) end)
end

-- One-time API-key login (persistent after first success).
local function loginIfNeeded(thenUnlock: () -> ())
  noctalia.runAsync("bw login --apikey --check", function(res)
    if res.exitCode == 0 then
      thenUnlock()
      return
    end
    local cid = noctalia.getConfig("client_id")
    local csec = noctalia.getConfig("client_secret")
    if cid == nil or cid == "" or csec == nil or csec == "" then
      setStatus("needs-auth", "Set client_id/client_secret in plugin settings")
      return
    end
    local env = "BW_CLIENTID=" .. shellQuote(cid) .. " BW_CLIENTSECRET=" .. shellQuote(csec)
    noctalia.runAsync(env .. " bw login --apikey", function(r)
      if r.exitCode ~= 0 then
        setStatus("needs-auth", (r.stderr or "login failed"):gsub("\n.*", ""))
        return
      end
      thenUnlock()
    end)
  end)
end

-- Unlock using the master password file, cache BW_SESSION.
local function unlock()
  local pwFile = noctalia.getConfig("master_password_file")
  if pwFile == nil or pwFile == "" then
    setStatus("needs-auth", "Set master_password_file in plugin settings")
    return
  end
  local expanded = noctalia.expandPath(pwFile)
  noctalia.runAsync("bw unlock --passwordfile " .. shellQuote(expanded), function(res)
    if res.exitCode ~= 0 then
      setStatus("locked", (res.stderr or "unlock failed"):gsub("\n.*", ""))
      removeSession()
      return
    end
    -- bw prints: "BW_SESSION=\"<key>\"" — extract the key.
    local key = res.stdout:match('BW_SESSION="([^"]+)"')
    if key == nil then
      setStatus("locked", "unlock produced no session")
      return
    end
    writeSession(key)
    setStatus("unlocked")
  end)
end

-- Ensure we are unlocked; if not, transparently login + unlock.
local function ensureUnlocked()
  local session = readSession()
  if session == nil or session == "" then
    setStatus("locked")
    loginIfNeeded(unlock)
    return
  end
  -- Verify the cache is still valid.
  bw("status", function(err, out)
    if err ~= nil then
      setStatus("locked", "session invalid")
      removeSession()
      loginIfNeeded(unlock)
      return
    end
    if out:find("unlocked") then
      setStatus("unlocked")
    else
      setStatus("locked")
      loginIfNeeded(unlock)
    end
  end)
end

function update()
  ensureServer()
  ensureUnlocked()
end

-- Kick off immediately on load.
ensureServer()
ensureUnlocked()
