# Noctalia Plugins — Usage & API

How Noctalia plugins are wired in this repo and how to operate the plugins we
enable.

## How plugins are managed

Noctalia loads plugins from _sources_. `github:noctalia-dev/official-plugins` is
a default auto-seeded source, so **you do not declare a source** to use an
official plugin — declaring one replaces the default source and silently drops
every other official plugin. Just list the plugin id under `enabled`.

Plugins run on the **Launcher** and other Noctalia surfaces. They are not Nix
packages; they are fetched and executed by the Noctalia runtime on the target
host at activation time.

## How this repo enables a plugin

Plugins are enabled through the Home Manager `programs.noctalia.settings`
attrset. The Nix TOML renderer emits exactly what Noctalia's
`config_service.cpp` parser expects (`[plugins] enabled=[...]`):

```nix
# modules/home/graphical.nix  (shared home module for graphical Linux hosts)
programs.noctalia = {
  enable = true;
  settings = {
    plugins.enabled = [ "noctalia/translator" ];
    # ...
  };
};
```

The id is `<source-namespace>/<plugin-id>` — `noctalia/` is the official source
namespace. After a rebuild/switch, the plugin is live; no restart of the session
shell is required for launcher providers.

## Translator plugin (`noctalia/translator`)

Translates text from the launcher via Google Translate's public endpoint.
`plugin_api = 3`, compatible with Noctalia 5.0.

### Usage

Open the launcher and type:

```text
/tr es hello world        →  "hola mundo"   (explicit target lang first)
/tr hello world            →  translated to the configured default target
```

- First word is a recognized language (code or alias) → used as the target.
- Otherwise the whole query is translated to `target_lang` (default `en`).
- Press **Enter** on a result to copy it to the clipboard.
- Results are cached per `target|text` for the session; re-queries are instant.
- 300 ms debounce waits for typing to settle before calling Google.

Supported language aliases include
`ar cs de el en es fa fi fr he hi hu id it ja ko nl no pl pt ro ru sv tr uk vi zh`
(plus their localized names); any other 2–3 letter token is passed through to
Google as an ISO code.

### Settings

| Key           | Type   | Default | Meaning                                |
| ------------- | ------ | ------- | -------------------------------------- |
| `target_lang` | string | `en`    | Fallback target when no lang is given. |

Override per host in `hosts/<host>/users/<user>/home-configuration.nix`:
`programs.noctalia.settings.plugins.target_lang = "ja";` (exact key path depends
on how the attrset is merged — prefer setting it in the shared module or with
`mkMerge`).

### Troubleshooting

- **"Connection error — is the network up?"** — the host cannot reach
  `translate.google.com`. The plugin calls
  `https://translate.google.com/translate_a/single?client=gtx&...`. Permit
  outbound HTTPS egress to that host at the firewall/proxy layer (runtime
  concern, not a Nix build concern).
- **No `/tr` results at all** — confirm `plugins.enabled` includes
  `noctalia/translator` and that the change was switched in
  (`home-manager switch` / rebuild). Check `noctalia config validate` on the
  Linux host (the binary is Linux/Wayland only; it cannot run on macOS).
- **Wrong language** — the first word was parsed as a language. Quote/lead with
  the intended target, or rely on the default.
- **Stale translation** — the in-session cache key is `target|text`; changing
  only the target reuses the cache. Restart the shell session to clear it.

## Plugin API reference

### Manifest — `plugin.toml`

Top-level keys:

| Key            | Type     | Notes                                        |
| -------------- | -------- | -------------------------------------------- |
| `id`           | string   | `<namespace>/<id>`, unique.                  |
| `name`         | string   | Display name.                                |
| `version`      | string   | Semver.                                      |
| `plugin_api`   | int      | Framework API contract version (we use `3`). |
| `author`       | string   |                                              |
| `license`      | string   |                                              |
| `dependencies` | string[] | Other plugin ids required.                   |
| `tags`         | string[] | Search/topic tags.                           |
| `icon`         | string   | Glyph name.                                  |
| `description`  | string   |                                              |

`[[launcher_provider]]` — registers a launcher command:

| Key                        | Type   | Notes                                          |
| -------------------------- | ------ | ---------------------------------------------- |
| `id`                       | string | Provider id.                                   |
| `entry`                    | string | Lua entry file (e.g. `translator.luau`).       |
| `prefix`                   | string | Trigger token (e.g. `tr` → `/tr`).             |
| `glyph`                    | string | Icon glyph.                                    |
| `include_in_global_search` | bool   | Whether it shows in the global search results. |
| `debounce_ms`              | int    | Wait before firing `onQuery` (typing settle).  |

`[[setting]]` — user-tunable config:

| Key               | Type   | Notes                                          |
| ----------------- | ------ | ---------------------------------------------- |
| `key`             | string | Config key read via `noctalia.getConfig(key)`. |
| `type`            | string | `string` / `int` / `bool` / `enum` / …         |
| `label_key`       | string | i18n key for the label.                        |
| `description_key` | string | i18n key for the description.                  |
| `default`         | any    | Default value when unset.                      |

### Lua runtime API

A launcher provider exposes two callbacks and uses the `noctalia.*` /
`launcher.*` namespaces:

```lua
-- Called on each (debounced) query change. `query` is text after the prefix.
function onQuery(query)
  launcher.setResults(query, {
    { id = "row-id", title = "...", subtitle = "...", glyph = "language",
      presentation = "detail" }
  })
end

-- Called when a result row is activated (Enter). `id` is the row's id.
function onActivate(id)
  noctalia.copyToClipboard(id, "text/plain")
  noctalia.notify("Translator", "Copied to clipboard")
end
```

Runtime helpers used by the translator (representative of the API surface):

| Call                                   | Purpose                                     |
| -------------------------------------- | ------------------------------------------- |
| `noctalia.getConfig(key)`              | Read a `[[setting]]` value.                 |
| `noctalia.http({ url = u }, cb)`       | Async GET; `cb({ ok = bool, body = str })`. |
| `noctalia.json.decode(str)`            | Parse JSON.                                 |
| `noctalia.string.urlEncode(s)`         | URL-encode a query/path segment.            |
| `noctalia.string.trim(s)`              | Trim whitespace.                            |
| `noctalia.copyToClipboard(text, mime)` | Copy to clipboard.                          |
| `noctalia.notify(title, body)`         | Show a desktop notification.                |
| `launcher.setResults(query, rows)`     | Render result rows.                         |

Row fields: `id` (string, returned to `onActivate`), `title`, `subtitle`,
`glyph`, and optional `presentation` (`"detail"` shows the subtitle
prominently). Use a `glyph` of `"loader"` for an in-flight state and
`"alert-triangle"` for errors.

## Enabling more plugins

Enable any official plugin the same way: add the id to
`programs.noctalia.settings.plugins.enabled`. No source declaration is needed
for the default `official` repo.
