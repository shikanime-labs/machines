-- Bitwarden launcher provider: type "bw <query>" to search the vault.
-- Selecting a result copies its password to the clipboard.
--
-- Shares BW_SESSION with the service entry via pluginDataDir() and reads
-- vault status from noctalia.state["bw_status"].

local SESSION_FILE = noctalia.pluginDataDir() .. "/bw_session"
local cachedItems: { [string]: string } = {}  -- id -> name, for onActivate

local function shellQuote(s: string): string
  return "'" .. string.gsub(s, "'", [['\'']]) .. "'"
end

local function readSession(): string?
  local data = noctalia.readFile(SESSION_FILE)
  if data == nil or #data == 0 then return nil end
  return (data:gsub("\n$", ""))
end

function onQuery(text: string)
  local session = readSession()
  if session == nil or session == "" then
    launcher.setResults(text, {
      { id = "locked", title = "Bitwarden locked", subtitle = "Open settings or wait for the service to unlock" },
    })
    return
  end

  local q = text:match("^%s*(.*)%s*$") or ""
  if q == "" then
    launcher.setResults(text, {
      { id = "hint", title = "Type to search your vault", subtitle = "e.g. bw github" },
    })
    return
  end

  local cmd = "BW_SESSION=" .. shellQuote(session) .. " bw list items --search " .. shellQuote(q)
  noctalia.runAsync(cmd, function(res)
    if res.exitCode ~= 0 then
      launcher.setResults(text, {
        { id = "err", title = "Bitwarden error", subtitle = (res.stderr or "lookup failed"):gsub("\n.*", "") },
      })
      return
    end
    local ok, items = pcall(noctalia.json.decode, res.stdout)
    if not ok or type(items) ~= "table" then
      launcher.setResults(text, {})
      return
    end
    local results: {{ id: string, title: string, subtitle: string, category: string }} = {}
    cachedItems = {}
    for _, item in ipairs(items) do
      local id = item.id
      if id ~= nil then
        local name = item.name or "(unnamed)"
        local user = item.login and item.login.username or ""
        cachedItems[id] = name
        table.insert(results, {
          id = id,
          title = name,
          subtitle = user ~= "" and (item.login.uris and #item.login.uris > 0 and item.login.uris[1].uri or user) or "",
          category = "Bitwarden",
        })
      end
    end
    launcher.setResults(text, results)
  end)
end

function onActivate(id: string)
  local session = readSession()
  if session == nil or session == "" then
    noctalia.notifyError("Bitwarden", "Vault is locked")
    return
  end
  local name = cachedItems[id] or id
  local cmd = "BW_SESSION=" .. shellQuote(session) .. " bw get password " .. shellQuote(id)
  noctalia.runAsync(cmd, function(res)
    if res.exitCode ~= 0 then
      noctalia.notifyError("Bitwarden", "Could not read password")
      return
    end
    local pw = (res.stdout:gsub("\n$", ""))
    if noctalia.copyToClipboard(pw, "text/plain") then
      noctalia.notify("Bitwarden", "Copied password for " .. name)
    else
      noctalia.notifyError("Bitwarden", "Clipboard unavailable")
    end
  end)
end
