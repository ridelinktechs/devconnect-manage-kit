# Round 4 — Source Maps + Mock Server

## Problem

Two recurring pain points in DevConnect-based debugging:

1. **Minified stack traces** (RN mostly). A production RN app's JS is bundled by Metro/Hermes into a single minified file. When something crashes, the stack trace reads `App.bundle:2138:42` — useless for debugging. The un-minified source is the `.map` file Metro emits, but DevConnect never sees it.

2. **Backend-dependent testing**. To reproduce a bug ("this 500 from `POST /api/orders` only happens when X"), the developer needs to either: (a) reproduce the exact backend state (often impossible), (b) wait for the backend team to add a mock, or (c) intercept the response themselves with Charles/Proxyman. None of these is fast.

Goal: kill both pain points.

## Approach

Two independent sub-projects.

### Sub-project 4.1 — Source map upload + stack-frame decoding

**SDK side (RN only; Flutter/Dart is symbolic by default, Android is dexed but round 1 already ships JVM stack traces with file:line)**. Three sub-steps:

1. **Upload at startup**. When the RN app boots and connects to DevConnect, the SDK looks for a source map file at the standard Metro path (`./main.jsbundle.map`). If present, upload it to the desktop via a new message type:
   ```
   client:source_map_upload {
     mapId: "<sha256 of .map>",
     map: <base64-encoded .map content>,
     bundleName: "main",
     buildId: "<release build id>"
   }
   ```
   If absent, no upload. If the file is > 5 MB (rare but possible), reject and log a hint that source maps should be uploaded via the desktop UI instead.

2. **Desktop side caches the map** in `<app-data>/source_maps/<deviceId>/<mapId>.map`. Lookup keyed by `deviceId + bundleName + buildId` so different devices with different builds don't collide.

3. **Stack-frame decoding**. When the desktop receives a `client:error` event with `stackTrace`, it parses the JS frames (one per line, matching the standard V8/Hermes format), looks up each frame's `(bundle, line, column)` against the cached source map, and replaces the frame with the original `(file, line, column, functionName)`. The decoded stack is what's shown in the Error Inspector UI. The raw + decoded stacks are both persisted (toggle in UI).

**Auto-invalidation**. Source maps include a `sourcesContent` field that can be large. The SDK uploads it; desktop caches it. When a new build of the app starts (new `buildId`), the old map for the same `bundleName` is GC'd after 7 days.

**Desktop UI**. New `lib/features/source_maps/presentation/pages/source_maps_page.dart`:
- List of uploaded maps per device (device name, bundle name, buildId, upload time, map size)
- Manual upload: drag-and-drop a `.map` file
- Manual delete
- Toggle "Decode stack traces": on/off (off = show raw minified stacks)

**Out of scope**: source-map auto-upload from CI (would require a build-time hook). Manual upload + startup auto-upload cover 95% of cases.

### Sub-project 4.2 — Mock server

A request to `GET /api/users/123` returning a 404 might be the *cause* of a bug, not a side effect. Reproducing it requires mocking the response. DevConnect becomes that mock.

**Architecture**:

```
┌────────────────────────────────────────────────────────────┐
│                  DevConnect desktop                        │
│                                                            │
│   ┌──────────────┐    ┌─────────────┐    ┌──────────────┐  │
│   │ Mock rules   │    │ HTTP mock   │    │ WS mock      │  │
│   │ store (JSON) │    │ interceptor │    │ interceptor  │  │
│   └──────────────┘    └─────────────┘    └──────────────┘  │
│           │                  │                   │         │
│           └──────────────────┴───────────────────┘         │
│                              │                             │
│                              ▼                             │
│                  ┌──────────────────────────┐              │
│                  │ WebSocket to app         │              │
│                  └──────────────────────────┘              │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│               Device app (RN/Flutter/Android)             │
│                                                            │
│   DevConnect SDK ◄─── "intercept this request, return X"  │
│                                                            │
│   Returns fixture instead of hitting the real network.    │
└────────────────────────────────────────────────────────────┘
```

**Desktop side**:

1. **Mock rules store**. JSON file at `<app-data>/mock_rules.json`. Each rule:
   ```json
   {
     "id": "rule-uuid",
     "enabled": true,
     "match": {
       "method": "GET",
       "url": "/api/users/.*",
       "headers": { "Authorization": "Bearer .*" }
     },
     "response": {
       "status": 404,
       "headers": { "Content-Type": "application/json" },
       "body": "{\"error\": \"Not found\"}",
       "delayMs": 100
     }
   }
   ```
   Match by regex on method + url + selected headers. First-match wins.

2. **Mock Manager UI** (new page: `lib/features/mock_server/presentation/pages/mock_server_page.dart`):
   - List of rules, toggle on/off, edit, delete, reorder
   - "New rule" wizard:
     - Step 1: pick match (method, URL regex, header constraints)
     - Step 2: pick response (status, headers, body, delay)
     - Step 3: scope (which devices? all? one specific device?)
     - Save as preset ("Use this for the next 30 min" timer)
   - "Capture from real request" button: when a request comes in matching the URL pattern, offer "use this response as the mock"

3. **Sync to device**. When the desktop rule list changes, push a `server:mock_rules_update` message with the new rules over the existing WebSocket. The device SDK stores the rules in memory and matches incoming requests against them before forwarding to the real network.

**SDK side** (all 3 platforms):

- On `install()`, request the current rule list from the desktop (`client:mock_rules_request` → desktop replies with `server:mock_rules_update`).
- Maintain a `Map<url, MockRule>` of active rules.
- In the existing HTTP interceptor (`OkHttpInterceptor`, `httpInterceptor`, `fetchInterceptor`): **before** forwarding the request to the real network, check the rule list. If matched, short-circuit with the mock response (delay → emit response with synthetic latency). Emit `client:mocked_request { ruleId, url, status }` so the user knows the response was synthetic.

**Scope/limits**:
- Per-device scoping: the rule store includes a `scope.deviceIds` array. The device only receives rules whose scope matches its own `deviceId`.
- Timer presets: rules can have a `expiresAt` timestamp. The desktop removes expired rules automatically and pushes the update.

### Sub-project 4.3 — Session recording + replay

(Lower priority within Round 4 — design only, implementation maybe in Round 4.5 if time allows.)

- Desktop has a "Record session" button. All incoming events go to an in-memory ring buffer (capped at 50 MB). When stopped, the buffer is saved to `<app-data>/sessions/<timestamp>.json`.
- "Replay" button: open the saved file, replay events at original timestamps (or 1x / 2x speed). The user can scrub through the timeline.
- Useful for sharing a bug with a teammate — attach the session JSON.

## Data flow

**Source maps (4.1)**:
```
RN app startup
  └─► SDK reads main.jsbundle.map
       └─► client:source_map_upload (WebSocket)
            └─► Desktop: cache to disk
                 └─► On client:error: parse frames + decode
                      └─► Error Inspector shows decoded stack
```

**Mock server (4.2)**:
```
Desktop
  └─► User creates rule
       └─► Push server:mock_rules_update via existing WebSocket
            └─► Device SDK updates in-memory rule map
                 └─► On next HTTP request:
                      ├─► Match found → short-circuit + emit client:mocked_request
                      └─► No match → forward to real network
```

## Error handling

| Failure | Behaviour |
|---|---|
| Source map is corrupted | Decode falls back to raw stack trace; one-time WARN toast "could not decode map for <bundle>". |
| Source map > 5 MB | Reject upload; suggest manual upload via desktop UI. |
| Mock rule regex invalid | Block save with inline error message showing regex parse failure. |
| Mock rule matches but body is invalid UTF-8 | Wrap in `Content-Type: application/octet-stream` and emit `body = "<binary N bytes>"`. |
| Mock rule scope includes a device that's now offline | Rule still applies when the device reconnects (desktop re-pushes on every WebSocket hello). |
| Mock rule conflicts (two rules match same URL) | First match wins (rule ordering in UI). |
| Recording buffer fills up | Wrap and overwrite oldest events; show "recording at capacity" badge. |
| Replay on a different device than recorded | Still works — events replay against any device, the events are app-state-agnostic. |

## Out of scope

- **GraphQL/gRPC mocks** — Round 3's protocol inspectors already parse the request. The mock server can match by URL alone in Round 4; protocol-aware matching (match `GetUser` operation + variable value) is a Round 4.5 follow-up.
- **CI integration** — no GitHub Action / Fastlane plugin to auto-upload source maps. Manual upload via the desktop UI is the only path.
- **Recording encryption** — sessions are stored as plain JSON. If the user needs to share a session externally, they can gzip + password-protect it themselves.
- **Mock server authentication** — the dev tool assumes the device and desktop are on the same LAN. No auth required; if a malicious LAN peer connects, they could inject mock rules. Same threat model as Round 1's WebSocket.

## Files

**New (SDK side):**

| Sub-project | Files |
|---|---|
| 4.1 Source maps RN | `client_sdks/devconnect-react-native/src/reporters/sourceMapReporter.ts` + test |
| 4.2 Mock server RN | `client_sdks/devconnect-react-native/src/interceptors/mockServerInterceptor.ts` + test |
| 4.2 Mock server Flutter | `client_sdks/devconnect_flutter/lib/src/interceptors/mock_server_interceptor.dart` + test |
| 4.2 Mock server Android | `client_sdks/devconnect-android/src/main/java/com/devconnect/interceptors/MockServerInterceptor.kt` + test |

**New (desktop side):**
- `lib/features/source_maps/presentation/pages/source_maps_page.dart`
- `lib/features/source_maps/data/source_map_cache.dart`
- `lib/features/source_maps/data/stack_decoder.dart`
- `lib/features/mock_server/presentation/pages/mock_server_page.dart`
- `lib/features/mock_server/presentation/widgets/rule_editor_wizard.dart`
- `lib/features/mock_server/data/mock_rule_store.dart`
- `lib/features/mock_server/data/mock_rule_sync.dart` (push to devices)

**Updated:**
- `lib/features/error_inspector/presentation/pages/error_inspector_page.dart` — show decoded stacks, toggle raw/decoded
- `client_sdks/devconnect-react-native/README.md` — source map upload + mock server section
- `client_sdks/devconnect_flutter/README.md` — mock server section
- `client_sdks/devconnect-android/README.md` — mock server section

## Testing

**Source maps**:
- Unit test: parse a real Metro-generated `main.jsbundle.map`, decode 3 known frames, assert file:line match.
- Edge cases: minified frame with no source mapping → returns original (unchanged).
- UI test: upload a fake map, verify it's listed in the source maps page.

**Mock server**:
- Unit test: rule matcher with various regex patterns and header constraints.
- Integration test: device hits `GET /api/users/123` with a matching rule → receives the mock response, real network is NOT called.
- Conflict test: two overlapping rules → first-match wins.

## Non-goals

- No commits (standing instruction).
- Mock server rules are per-desktop-install; not synced across machines.
- Recording/replay is design-only this round; implementation deferred to a follow-up if requested.
