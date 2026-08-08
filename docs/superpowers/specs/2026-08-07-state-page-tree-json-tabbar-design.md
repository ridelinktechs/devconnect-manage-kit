# State Page — Tree/Pretty as Nested Tab Bar

## Problem

Switching the state-detail panel between Tree and JSON views is currently a
small chip toggle in the header row (one chip for both Before & After).
Per the user, this is awkward and inconsistent with how other pages in the
app let the user pick a viewer mode.

Goal: replace the chip with a proper segmented-control tab bar (matching the
existing `DetailTabBar` pattern used by Network Inspector, All Events,
Console), placed inside the Before and After tabs so the two views can be
chosen independently.

## Approach

Nested tab bar (Option A from the brainstorming):

```
┌─ Detail header ────────────────────────────┐
│  actionName              [screenshot] [×] │
├────────────────────────────────────────────┤
│  [ Diff | Before | After ]                 │  ← outer tab bar (existing)
├────────────────────────────────────────────┤
│  ┌─ Before ─────────────────────────────┐ │
│  │  [ Tree | Pretty ]                   │  ← NEW inner tab bar
│  │  ────────────────────────────────────│ │
│  │  { … JSON tree … }                    │ │
│  └────────────────────────────────────────┘ │
│  ┌─ After ──────────────────────────────┐ │
│  │  [ Tree | Pretty ]                   │  ← NEW inner tab bar
│  │  ────────────────────────────────────│ │
│  │  { … JSON tree … }                    │ │
│  └────────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

Before and After each get their own inner tab controller, so the user can
view the Before tree and the After pretty (or any combination) at the same
time.

## Architecture

### New widget

`_StateJsonTabView` (private to `state_inspector_page.dart`, replacing
`_StateJsonToggleView`):

- `final dynamic data` — the state map to render.
- Stateful — owns its own `TabController` (length 2) so Before and After
  have independent selection.
- Uses `DefaultTabController` so the inner `TabBarView` and `TabBar` wire
  up without explicit plumbing.
- Renders:
  - `_DetailTabBar(tabs: const ['Tree', 'Pretty'])` at the top.
  - `TabBarView` children:
    - Tree: `JsonViewer(data: widget.data, initiallyExpanded: true)`
      (same as current Tree mode).
    - Pretty: `JsonPrettyViewer(data: widget.data)`
      (same as current JSON mode).
- Default tab: Tree (index 0) — matches current default behaviour.

### State changes

In `_StateInspectorPageState`:

- **Remove** `bool _jsonPrettyMode = false;` field (line 521).
- **Remove** the chip toggle `GestureDetector` + `Container` block in the
  header (lines 678-721).
- **Replace** the two `_StateJsonToggleView(...)` calls inside the
  `TabBarView` (`_StateJsonToggleView(data: entry.previousState, ...)` /
  `…nextState, ...`) with `_StateJsonTabView(data: …)`.
- **Delete** the `_StateJsonToggleView` and `_StateJsonToggleViewState`
  classes (lines 779-836).

### Why nested `DefaultTabController`

The outer detail already uses a `DefaultTabController(length: 3)` for the
Diff/Before/After bar (line 651). Nested `DefaultTabController`s work in
Flutter because `TabBarView` looks up the nearest ancestor controller via
`DefaultTabController.of(...)` — a child can wrap a sub-tree in its own
`DefaultTabController` without affecting the parent. Each `_StateJsonTabView`
gets its own controller, so Before's Tree/Pretty selection is independent
of After's.

### Localisation

Use existing strings:
- `S.of(context).tree` → tab label "Tree"
- `S.of(context).pretty` → tab label "Pretty"

No new i18n keys needed.

## Trade-offs

- **Pro:** Same widget (`DetailTabBar`) as Network / All Events / Console —
  visual consistency across the app.
- **Pro:** Click target is bigger (full pill segment) instead of a 12×12
  icon chip.
- **Pro:** Per-tab independence — user can put Before in Pretty and After
  in Tree, or vice versa.
- **Con:** Nested tab bar (Diff/Before/After outside, Tree/Pretty inside).
  Recognised pattern in IDEs and code viewers; acceptable for a developer
  tool. Vertical screen real estate drops slightly because the inner tab
  bar adds ~36 px inside each tab.
- **Con:** No persistent preference — switching tabs resets Tree/Pretty to
  default (Tree). Same as current behaviour; if persistence becomes
  useful later, add via a shared preference.

## Testing

No automated tests for the state-detail UI today. Per YAGNI, skip writing
new ones for this change. Manual verification:

1. Open state detail from All Events.
2. Click "Pretty" inside Before tab → JSON pretty renders.
3. Switch to After tab → After defaults back to Tree.
4. Switch back to Before → Before still on Pretty (independent state).
5. Switch to Diff tab and back to Before → Before still on Pretty.

## Out of scope

- Persistence of Tree/Pretty preference across sessions.
- Keyboard shortcut to toggle Tree/Pretty.
- Per-state-manager-type default (e.g. Redux always starts in Pretty).