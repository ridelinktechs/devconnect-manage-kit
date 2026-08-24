# Round 5 — Layout Inspector + AI-Assisted Debugging

## Problem

Two complementary advanced features for "next-level" debugging:

1. **Layout inspector**. Today, debugging "why is this button off-screen on the iPhone 12 mini but fine on the Pro Max?" requires writing print statements or running on the device with breakpoints. DevConnect can dump the live view tree to the desktop, let the developer click on an element in a screenshot, see the element's bounds / props / parent chain. This is the killer feature that Reactotron / Flipper users love.

2. **AI-assisted debugging**. The desktop already receives all events (network, state, errors, performance). A natural-language query like "show me the last 5 failed login requests" or "what was the state of `UserState` right before the crash?" should work without writing a query language.

Both are ambitious but valuable.

## Approach

### Sub-project 5.1 — Layout inspector

**Desktop side** (`lib/features/layout_inspector/`):
- New page mirroring the Network Inspector's structure: device list on the left, view tree on the right, element details at the bottom.
- Two view modes:
  - **Tree mode**: hierarchical view of the layout (similar to Chrome DevTools Elements tab). Click a node → element details panel.
  - **Screenshot mode**: latest device screenshot (captured via `client:screenshot_request`) with a hover-highlight overlay. Click an element → auto-selects the corresponding node in the tree.
- Element details: bounds (x/y/w/h), id (testTag / accessibilityIdentifier), parent chain, key state values (e.g. for Android View: text, contentDescription; for RN: props; for Flutter: widget debug name).
- "Pin" a node → keeps the selection sticky across tree refreshes.

**Per-platform adapter**:

**Android** (easiest). Two existing hooks:
1. `uiautomator dump` produces an XML representation of the current view hierarchy. Run via `ProcessBuilder("uiautomator", "dump")` from a `Debug.dumpHierarchy()` call (only available in debug builds — guard with `BuildConfig.DEBUG`).
2. `View.getWindowVisibleDisplayFrame()` + `View.getLocationOnScreen()` for bounds.

New `DevConnectLayoutInspector` plugin (SDK side):
- On `server:layout_inspector_ping`, walks the current top activity's view hierarchy via `Activity.window.decorView` reflection and emits `client:layout_dump { root: { ...tree..., screenshot: <base64 jpeg> } }`.
- Wired up at install time, gated on `enabled`.

**React Native**. RN's `UIManager` exposes a runtime view tree via `UIManager.getViewManagerConfig(...)` and `requireNativeComponent(...)`. The `react-native-devtools` package already implements a tree dump — we reuse its core logic. New `client:layout_dump` from a `DevConnectLayoutInspector.install()` call. Screenshot via `ViewShot` (existing RN lib) — already widely used.

**Flutter** (hardest). Flutter's widget tree is *not* the same as the render tree. The render tree (`RenderObject` hierarchy) is what determines layout. `RendererBinding.instance.renderViewElement` gives access to the root `RenderObject`. New `DevConnectLayoutInspector` walks the render tree on the UI thread (carefully — long walks can drop frames) and emits the tree. Bounds come from `RenderBox.localToGlobal(Offset.zero)` + `paintBounds`. Screenshot via `RenderRepaintBoundary.toImage()`.

**Effort ranking**: Android < RN < Flutter (Android is days, Flutter is weeks).

### Sub-project 5.2 — AI assistant

Two integration paths, both ship-side:

**Path A — On-device model** (no external dependency):
- Use a small LLM (Gemma 2 2B, Phi-3 mini) bundled with the desktop app's installer (~1.5 GB extra disk).
- Pros: works offline, no API keys, no data leaves the machine.
- Cons: large download, slow on low-end hardware, can't match frontier-model quality.

**Path B — Cloud API** (opt-in):
- User provides an OpenAI / Anthropic / Gemini API key in settings.
- Pros: best quality, fast, no extra disk.
- Cons: data leaves the machine (privacy concern), ongoing cost.

**Recommendation**: ship Path A by default with a "use cloud for better quality" toggle that unlocks Path B. Path A is the default for two reasons: (1) the network/state/error data the LLM sees is the developer's own app data, often containing PII; (2) the desktop app already runs locally, so bundling a model fits the architecture.

**Implementation**:

1. **Tool surface**. The LLM needs structured access to the desktop's event stream. Define 5 tools:
   - `query_events({ since, type, deviceId, limit })` → list of matching events
   - `get_state_snapshot({ deviceId, stateManager })` → current value
   - `get_network_requests({ url, method, status, since, limit })` → matching requests
   - `get_errors({ severity, since, limit })` → matching errors
   - `get_performance_metrics({ deviceId, type, since })` → perf samples

2. **Conversation UI**. New `lib/features/ai_assistant/presentation/pages/ai_assistant_page.dart`:
   - Chat-style UI: user message at bottom, assistant responses stream in (token by token via `client:ai_stream_chunk` from the server's `server:ai_query` → `client:ai_stream_*` protocol).
   - Each response includes inline citations: "Event #1234 — 500 from `POST /api/orders`".
   - Click a citation → opens the corresponding feature page (Error Inspector, Network Inspector, etc.) with the event highlighted.

3. **Pre-canned suggestions** (no LLM needed for these). A "Quick answers" dropdown with 5 starter queries:
   - "Show the last 5 failed requests"
   - "What was the state of `<X>` right before the crash?"
   - "List ANRs in the last hour"
   - "Which endpoints are slowest?"
   - "What's eating memory?"

   These run as direct queries against the event store and are 100ms responses. They give users a feel for what the AI can do without burning tokens on the LLM.

4. **Privacy / scope controls**:
   - Settings page toggle: "Send network request bodies to AI" (default: off — bodies often contain auth tokens / PII).
   - Settings page toggle: "Send state values to AI" (default: off).
   - Toggle for "use cloud API" (off by default — uses on-device model).

5. **Caching**. Most user queries are variations of the same few questions. Cache the (query embedding → response) tuple for 30 days. Hit cache → no LLM call.

### Sub-project 5.3 — Compose / new arch / Fabric adapters (lower priority)

The base Layout Inspector covers Android (View) and RN (UIManager). New architectures need extra adapters:
- **Jetpack Compose**: walk the `Composition` via `Recomposer` reflection. Each `ComposeView` has a `CompositionContext` we can introspect.
- **RN Fabric** (new arch): different UIManager API; separate adapter.
- **Flutter RenderTree**: covered above.

Each is 1-2 weeks. Ship alongside 5.1's base or as a follow-up.

## Data flow

**Layout inspector**:
```
Desktop
  └─► user clicks "Inspect" on a device
       └─► server:layout_inspector_ping
            └─► SDK (Android/RN/Flutter)
                 └─► walk view/render tree
                      └─► client:layout_dump { tree, screenshot }
                           └─► Desktop renders tree + screenshot
```

**AI assistant**:
```
Desktop
  └─► user types query
       └─► server:ai_query { query }
            └─► desktop LLM (or cloud)
                 ├─► LLM emits tool calls
                 │    └─► desktop executes query_events(...) etc.
                 │         └─► LLM sees results, continues reasoning
                 └─► server:ai_stream_chunk { delta, citations }
                      └─► Desktop renders chat incrementally
```

## Error handling

| Failure | Behaviour |
|---|---|
| View hierarchy walk on Android takes > 200 ms (deep tree) | Truncate at depth 30 + log WARN "hierarchy truncated". |
| Render tree walk on Flutter drops frames | Throttle: only walk on explicit user request, not continuously. |
| Screenshot capture fails (ViewShot not installed) | Skip screenshot, show tree-only view. |
| LLM model file missing or corrupt | Show "Model not loaded" banner + link to download in settings. |
| Cloud API rate-limited | Fall back to on-device model automatically. |
| LLM hallucinates (cites event that doesn't exist) | Citations validated against event store before render; invalid → "evidence not available". |
| On-device model too slow (> 5 s first token) | Settings page shows hardware warning; suggest cloud API. |

## Out of scope

- **Multi-modal input** (voice, screen-share): text-only for round 5.
- **Auto-fix suggestions** ("try changing line 42 to ..."): the AI reads + cites, doesn't write code.
- **Cross-device correlation**: AI sees one device's events at a time. Multi-device queries are a follow-up.
- **Model fine-tuning** on user data: too risky privacy-wise; off-device inference only.

## Files

**New (SDK side):**

| Sub-project | Files |
|---|---|
| 5.1 Android | `client_sdks/devconnect-android/src/main/java/com/devconnect/plugins/LayoutInspector.kt` |
| 5.1 RN | `client_sdks/devconnect-react-native/src/plugins/layoutInspector.ts` |
| 5.1 Flutter | `client_sdks/devconnect_flutter/lib/src/plugins/layout_inspector.dart` |
| 5.3 Compose | `client_sdks/devconnect-android/src/main/java/com/devconnect/plugins/ComposeLayoutInspector.kt` |
| 5.3 Fabric | `client_sdks/devconnect-react-native/src/plugins/fabricLayoutInspector.ts` |

**New (desktop side):**
- `lib/features/layout_inspector/presentation/pages/layout_inspector_page.dart`
- `lib/features/layout_inspector/presentation/widgets/view_tree_widget.dart`
- `lib/features/layout_inspector/presentation/widgets/screenshot_overlay.dart`
- `lib/features/layout_inspector/data/layout_node.dart`
- `lib/features/ai_assistant/presentation/pages/ai_assistant_page.dart`
- `lib/features/ai_assistant/data/ai_client.dart` (on-device + cloud switch)
- `lib/features/ai_assistant/data/ai_tools.dart` (the 5 tool definitions)
- `lib/features/ai_assistant/data/event_query_executor.dart`
- `lib/features/ai_assistant/presentation/widgets/citation_chip.dart`

**Updated:**
- `lib/features/error_inspector/presentation/pages/error_inspector_page.dart` — "Ask AI about this error" button
- `lib/features/network_inspector/presentation/pages/network_inspector_page.dart` — same
- `lib/features/state_inspector/presentation/pages/state_inspector_page.dart` — same
- `lib/features/settings/presentation/pages/settings_page.dart` — AI settings (model path, cloud API key, privacy toggles)
- All 3 SDK READMEs — Layout Inspector section

## Testing

**Layout inspector**:
- Android: integration test with a sample app, dump hierarchy, verify tree shape.
- RN: same with a sample RN app.
- Flutter: golden test that the tree renders correctly with a fixture dump.
- Performance test: hierarchy walk on a 1000-view screen completes in < 200 ms.

**AI assistant**:
- Unit test: each of the 5 tools returns the right shape for sample input.
- Integration test: send a query, verify the LLM tool-calls execute against the test event store.
- Privacy test: verify the "send bodies" toggle actually filters bodies from the LLM context.

## Non-goals

- No commits (standing instruction).
- AI assistant ships as opt-in beta (settings toggle); default off.
- No telemetry on LLM usage (the desktop doesn't phone home about what queries users ask).
