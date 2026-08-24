# Round 2 — State Auto-Discovery for the rest of the ecosystem

## Problem

`DevConnect` already auto-discovers state for the most popular lib per platform:

| Platform | Already covered (Round 1 / pre-existing) |
|---|---|
| Flutter | Riverpod, GetX, signals (`flutter_signals`) |
| React Native | Redux, MobX, Zustand, Jotai, Valtio, XState |
| Android | StateFlow, LiveData (via `ViewModelAutoDiscoverer`) |

The gaps are the **second-tier but still dominant** state libs in 2026 production apps:

| Platform | Missing | Why it matters |
|---|---|---|
| Flutter | **BLoC**, **Provider** | BLoC + Provider are still the 2 most-used state libs in production Flutter apps (per Flutter Pulse 2025 + State-of-Flutter survey). The SDK only ships a generic `StateObserver` that consumers must wire manually per provider. |
| React Native | **React Query / TanStack Query**, **Apollo Client** | React Query is the de-facto data-fetching lib; Apollo is the de-facto GraphQL client. Both expose observable caches whose state is invisible to DevConnect today. |
| Android | **Jetpack Compose** (`State<T>`, `MutableState<T>`) | Compose is the default UI toolkit for new Android apps. Round 1's `ViewModelAutoDiscoverer` only finds StateFlow/LiveData on ViewModels; it doesn't see `remember { mutableStateOf(...) }` inside Composables. |

Goal: bring all of the above under the same "wire once, see state on desktop" experience.

## Approach

Five independent sub-projects, shipped as separate PRs (one per platform-pair) to keep review surface small.

### Sub-project 2.1 — Flutter BLoC auto-discovery

**Wiring**. Flutter's `flutter_bloc` package exposes a `BlocObserver` global hook. `DevConnectBlocObserver` (new, in `client_sdks/devconnect_flutter/lib/src/interceptors/bloc/`) extends `BlocObserver` and overrides:
- `onCreate(bloc)` → emit `client:state_change` with `stateManager = "BLoC::${bloc.runtimeType}"`, `nextState = bloc.state.toString()`
- `onChange(bloc, change)` → emit with `previousState = change.currentState`, `nextState = change.nextState`
- `onError(bloc, error, stackTrace)` → forward to `ErrorMonitor`

Register once: `DevConnectFlutter.install(blocObserver: DevConnectBlocObserver())` (alongside the existing `install()` call).

**Opt-out**: skip calling `Bloc.observer = DevConnectBlocObserver()` if the consumer already set a custom observer. We chain by capturing the previous observer via `Bloc.observer` and forwarding.

### Sub-project 2.2 — Flutter Provider auto-discovery

`provider` package has no global hook — providers are scoped per widget tree. Approach: walk the widget tree from a `WidgetsBindingObserver` callback and on `didChangeAppLifecycleState(resume)`, walk the root element's `visitChildren` and find every `_InheritedProviderScope` descendant. Use reflection (`ProviderElement` exposes `value` getter) to read the current value and compare against a snapshot.

**Caveat**: Provider can hold any type — strings, models, services. We emit `nextState = value.toString()` for primitives and `nextState = value.runtimeType.toString()` for non-primitives (avoid sending full object graphs over WebSocket). Documented in README.

### Sub-project 2.3 — RN React Query integration

`@tanstack/react-query` exposes a `QueryCache` per `QueryClient`. Subscribing to `queryCache.subscribe(...)` gives us a stream of `QueryCacheNotifyEvent` (added/removed/updated/observerResultsUpdated). For each event we emit:
- `stateManager = "ReactQuery::${query.queryKey.joinToString(":")}"`
- `nextState = { status: query.state.fetchStatus, dataUpdatedAt: ..., isStale: ... }`

**Init**: `queryClient.getQueryCache().subscribe((event) => DevConnect.reportStateChange(...))` — called from `install()` when `QueryClient` is detected on `globalThis`.

### Sub-project 2.4 — RN Apollo Client integration

`@apollo/client`'s `InMemoryCache` exposes `cache.watch(...)` for fine-grained subscriptions, plus `cache.extract()` for a full snapshot. Approach:
- On `install()`, call `cache.watch({})` once → root-level subscription → emit on every change.
- Periodically (every 1 s while connected) emit a `cache.extract()` snapshot for the State Inspector's "View cache tree" view.

### Sub-project 2.5 — Android Compose state observer

Jetpack Compose is reactive via `MutableState<T>` (and the read-only `State<T>` view). Every `remember { mutableStateOf(...) }` is backed by a `SnapshotMutableState` object. Approach:

**Hook install**. `CompositionLocalProvider` can't be added globally — but we can hook `androidx.compose.runtime.tooling.ComposeTooling` (already pulled in by `compose-ui-tooling` at debug-time) and use its `Composer` instrumentation. The simpler approach for round 2: walk the slot table of every `Composable` we can reach via `Composition.setContent` extension, looking for `androidx.compose.runtime.snapshots.SnapshotStateObserver` callbacks.

**Practical compromise**: instead of full slot-table walking, hook `androidx.compose.runtime.snapshots.Snapshot.registerApplyObserver` (a public, stable API since Compose 1.0). Every state write goes through the apply observer — we filter for `MutableState` instances referenced by the apply block and emit a state-change event with the value's `toString()`.

The downside: no automatic label per state (Compose state has no name like `userState`). We label by parent Composable's name, captured via `currentComposer.getSourceInfo()`.

### Sub-project 2.6 — Desktop side: tabbed State Inspector

Already partially built (`lib/features/state_inspector/`). New work:
- Per-platform filter tabs at the top (Flutter / RN / Android / All)
- Per-state-manager grouping (collapsible tree: BLoC, Provider, Riverpod, …)
- "Diff" toggle that shows `previousState → nextState` for each event instead of just the latest value

## Data flow

```
SDK side:
  BLoC          ──►  DevConnectBlocObserver.onChange
  Provider      ──►  Widget tree walk + reflection diff
  React Query   ──►  queryCache.subscribe
  Apollo        ──►  cache.watch({}) + periodic cache.extract
  Compose       ──►  Snapshot.registerApplyObserver

  All paths ──►  DevConnect.reportStateChange(...) ──► WebSocket

Desktop side:
  WebSocket ──►  state_inspector_controller.dart ──► tab + tree UI
```

## Error handling

| Failure | Behaviour |
|---|---|
| `flutter_bloc` not on classpath | `DevConnectBlocObserver` is never instantiated; nothing to do. |
| `Provider` value throws on `toString()` | Catch, emit `nextState = "<unprintable>"`. |
| React Query `QueryCache` has 1000+ queries | Throttle per-key: max 1 emit per query per 250 ms. |
| Apollo `cache.extract()` returns > 1 MB | Truncate to first 1 MB with `…` suffix; emit `metadata.truncated = true`. |
| Compose state value contains a 10 MB bitmap | Same — truncate `toString()` to first 4 KB. |
| `Snapshot.registerApplyObserver` reflection fails | Wrap in try/catch, skip Compose observer silently. |

## Out of scope

- **Hook-based subscriptions** (e.g. Zustand selectors) — RN already covers the main ones.
- **Provider value deep-diff** — we emit `toString()` snapshots, not JSON Patch deltas. Consumers who want diff can subscribe to multiple events and compute client-side.
- **Compose non-MutableState** (`derivedStateOf`, `animateFloatAsState`) — these are computed, not state. The *underlying* `MutableState` they observe is captured.
- **Server-side render** (SSR) state — out of scope; DevConnect only sees device-side state.

## Files

**New (per sub-project):**

| Sub-project | Files |
|---|---|
| 2.1 BLoC | `client_sdks/devconnect_flutter/lib/src/interceptors/bloc/devconnect_bloc_observer.dart` + test |
| 2.2 Provider | `client_sdks/devconnect_flutter/lib/src/interceptors/provider/provider_tree_walker.dart` + test |
| 2.3 React Query | `client_sdks/devconnect-react-native/src/integrations/reactQuery.ts` + test |
| 2.4 Apollo | `client_sdks/devconnect-react-native/src/integrations/apollo.ts` + test |
| 2.5 Compose | `client_sdks/devconnect-android/src/main/java/com/devconnect/plugins/ComposeStateObserver.kt` + test |
| 2.6 Desktop | `lib/features/state_inspector/presentation/widgets/platform_filter_tabs.dart` + tree widget + test |

**Updated:**
- `lib/features/state_inspector/presentation/state_inspector_controller.dart` — add platform filter + diff toggle
- `client_sdks/devconnect_flutter/README.md` — BLoC + Provider section
- `client_sdks/devconnect-react-native/README.md` — React Query + Apollo section
- `client_sdks/devconnect-android/README.md` — Compose section

## Testing

For each sub-project:
- Unit test that the observer emits a `client:state_change` with the expected `stateManager`, `nextState`, and (where applicable) `previousState`
- For BLoC + Apollo: integration test that creates a bloc/cache, mutates it, asserts the event arrives at the WebSocket mock
- For Provider + Compose: harder — requires widget/Composition tree. Use Flutter's widget tester / Compose UI test framework with a test composable that mounts an observed state.

## Non-goals

- No commits (standing instruction).
- No breaking change to existing state-discovery API.
- No SDK release until the desktop side (sub-project 2.6) ships.
