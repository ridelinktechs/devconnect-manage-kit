# DevConnect Manage Kit — React Native SDK

[![npm](https://img.shields.io/npm/v/devconnect-manage-kit)](https://www.npmjs.com/package/devconnect-manage-kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../../LICENSE)
[![React Native](https://img.shields.io/badge/React%20Native-%3E%3D0.60-61DAFB?logo=react)](https://reactnative.dev)

Debug your React Native app with [DevConnect Manage Tool](https://github.com/ridelinktechs/devconnect-manage-kit) — network, state, logs, storage, performance — all in one desktop tool.

## Install

```bash
yarn add devconnect-manage-kit
# or
npm install devconnect-manage-kit
```

## Quick Start

```typescript
import { DevConnect } from "devconnect-manage-kit";

await DevConnect.init({ appName: "MyApp" });
// Done. fetch + XHR + console auto-captured.
```

## Config

```typescript
await DevConnect.init({
  appName: "MyApp",
  appVersion: "1.0.0",
  host: undefined, // undefined = auto-detect, '192.168.1.5' = manual
  port: 9090, // default: 9090
  enabled: __DEV__, // false in production
  autoInterceptFetch: true, // true = auto-capture all fetch requests
  autoInterceptXHR: true, // true = auto-capture all XHR requests
  autoInterceptConsole: true, // true = auto-capture console.log/warn/error
});
```

Disable specific auto-intercepts if you want manual control:

```typescript
await DevConnect.init({
  appName: "MyApp",
  autoInterceptFetch: false, // disable auto — use manual reportNetworkStart/Complete
  autoInterceptXHR: false, // disable auto
  autoInterceptConsole: false, // disable auto — use DevConnect.log/warn/error manually
});
```

## Features

### Network

Auto-captured: fetch, XHR, axios, got, ky, superagent, apisauce, Apollo, urql, TanStack Query, SWR, RTK Query.

```typescript
// Axios (optional, for extra tagging)
import { setupAxiosInterceptor } from "devconnect-manage-kit";
setupAxiosInterceptor(axios);
```

### WebSocket

```typescript
import { installWebSocketInterceptor } from "devconnect-manage-kit";

const uninstall = installWebSocketInterceptor(); // once, early
```

Sockets created after this call show in the desktop's **WebSocket** tab: the
open, every sent/received frame (binary frames as `<binary N bytes>`) and one
close per connection, carrying the error if there was one. Every constructor
argument (including React Native's `headers` option) reaches the real socket.
DevConnect's own connection is never captured.

### Mock Server

Rules you save in the desktop's **Mock** tab reach the app when you click
**Push all**, and apply right away, with no setup call
(`installMockServerInterceptor()` is now a no-op kept for older code). A
matching `fetch` gets the mocked response without touching the network. It
still shows in the Network tab, with an `x-devconnect-mock: <ruleId>`
response header, and in **Network › Mock Audit**.

> Only `fetch` is mocked. `XMLHttpRequest` requests (axios included) always
> go to the network.

### GraphQL (Apollo)

```typescript
import { ApolloClient, ApolloLink, HttpLink, InMemoryCache } from "@apollo/client";
import { devConnectApolloLink } from "devconnect-manage-kit";

const client = new ApolloClient({
  cache: new InMemoryCache(),
  link: ApolloLink.from([
    devConnectApolloLink(),
    new HttpLink({ uri: "https://api.example.com/graphql" }),
  ]),
});
```

Each operation shows in the desktop's **GraphQL** tab with its variables,
latency and outcome: data, GraphQL errors or the transport error. Works with
Apollo Client 3 and 4.

### Logs

Auto-captured: console.log, console.debug, console.info, console.warn, console.error, console.trace.

```typescript
DevConnect.log("User logged in");
DevConnect.debug("Debug info", "Auth");
DevConnect.warn("Warning");
DevConnect.error("Error", "Tag", stackTrace);
```

### State

Supports: Redux, Redux Toolkit, MobX, Zustand, Jotai, Valtio, XState.

```typescript
// Redux Toolkit
import { configureStore } from "@reduxjs/toolkit";
import { devConnectReduxMiddleware } from "devconnect-manage-kit";

const store = configureStore({
  reducer: rootReducer,
  middleware: (getDefault) =>
    __DEV__ ? getDefault().concat(devConnectReduxMiddleware) : getDefault(),
});
```

```typescript
// Zustand
import { devConnectMiddleware } from "devconnect-manage-kit";

const counterStore = (set) => ({
  count: 0,
  increment: () => set((s) => ({ count: s.count + 1 })),
});

const useStore = create(
  __DEV__ ? devConnectMiddleware(counterStore, "CounterStore") : counterStore,
);
```

#### Controls from the desktop

State Inspector › **Controls** watches state paths with no app code. Restoring
a snapshot and dispatching an action need the store wired:

```typescript
// Dispatch action: the desktop's action runs in this store
DevConnect.connectReduxStore(store);

// Restore: apply a snapshot sent from the desktop
DevConnect.onStateRestore((state) =>
  store.dispatch({ type: "RESTORE_STATE", payload: state }),
);
// root reducer
const rootReducer = (state, action) =>
  action.type === "RESTORE_STATE" ? action.payload : appReducer(state, action);
```

An action the store rejects, or a throw in the handler, shows in the desktop's
Console.

### Storage

Supports: AsyncStorage, MMKV, Encrypted Storage, WatermelonDB, SQLite, Realm.

Each library has 2 options: **auto** (wrap once, everything reported) or **manual** (you control what gets reported). Choose per library.

#### AsyncStorage

```typescript
// Option 1: Auto — patch once, all getItem/setItem/removeItem auto-reported
import { DevConnectAsyncStorage } from "devconnect-manage-kit";
DevConnectAsyncStorage.patchInPlace(AsyncStorage);
await AsyncStorage.setItem("token", "abc"); // auto-reported
await AsyncStorage.getItem("token"); // auto-reported

// Option 2: Manual — don't patch, report only what you want
import { DevConnectStorage } from "devconnect-manage-kit";
const storage = new DevConnectStorage("async_storage");
await AsyncStorage.setItem("token", "abc");
storage.reportWrite("token", "abc"); // only this gets reported
```

#### MMKV

```typescript
// Option 1: Auto
import { DevConnectMMKV } from "devconnect-manage-kit";
DevConnectMMKV.wrap(storage);
storage.set("token", "abc"); // auto-reported

// Option 2: Manual
import { DevConnectStorage } from "devconnect-manage-kit";
const mmkvReporter = new DevConnectStorage("mmkv");
storage.set("token", "abc");
mmkvReporter.reportWrite("token", "abc");
```

#### Encrypted Storage

```typescript
// Option 1: Auto (values masked as ***)
import { DevConnectEncryptedStorage } from "devconnect-manage-kit";
DevConnectEncryptedStorage.patchInPlace(EncryptedStorage);
await EncryptedStorage.setItem("token", "secret"); // auto-reported as ***

// Option 2: Manual — control what value is shown
import { DevConnectStorage } from "devconnect-manage-kit";
const encReporter = new DevConnectStorage("encrypted_storage");
await EncryptedStorage.setItem("token", "secret");
encReporter.reportWrite("token", "<hidden>"); // you choose what to show
```

#### WatermelonDB (manual only)

```typescript
import { DevConnectWatermelon } from "devconnect-manage-kit";
const watermelon = new DevConnectWatermelon();

const posts = await postsCollection.query().fetch();
watermelon.reportQuery("Post", posts.length);

await database.write(async () => {
  await postsCollection.create((post) => {
    post.title = "Hello";
  });
});
watermelon.reportWrite("Post", { title: "Hello" });
```

#### SQLite (manual only)

```typescript
import { DevConnectSQLite } from "devconnect-manage-kit";
const sqlite = new DevConnectSQLite();

const results = await db.executeSql("SELECT * FROM users");
sqlite.reportQuery("SELECT * FROM users", results[0].rows.raw());

await db.executeSql("INSERT INTO users (name) VALUES (?)", ["John"]);
sqlite.reportExecute("INSERT INTO users (name) VALUES (?)", { name: "John" });
```

#### Realm (manual only)

```typescript
import { DevConnectRealm } from "devconnect-manage-kit";
const realm = new DevConnectRealm();

const users = realmInstance.objects("User");
realm.reportQuery("User", users.length);

realmInstance.write(() => {
  realmInstance.create("User", { name: "John" });
});
realm.reportWrite("User", { name: "John" });
```

#### Generic (any key-value store)

```typescript
import { DevConnectStorage } from "devconnect-manage-kit";
const custom = new DevConnectStorage("my_custom_store");
custom.reportWrite("key", "value");
custom.reportRead("key", "value");
custom.reportDelete("key");
```

### Performance

With `autoPerformance` (on by default) the desktop's **Perf** tab fills in on
its own: FPS, jank frames, frame build time, memory, CPU, threads and
startup time. Report your own metrics too:

```typescript
DevConnect.reportPerformanceMetric({
  metricType: "fps",
  value: 58.5,
  label: "JS Thread FPS",
});
```

### Benchmark

With `autoBenchmark` (on by default) the desktop's **Bench** tab times the
app's startup (JS bundle loaded, first render, fully interactive) and each
stay in the background. Time your own flows step by step:

```typescript
DevConnect.benchmark("loadUserData");
await fetchUser();
DevConnect.benchmarkStep("loadUserData", "fetched user");
await fetchPosts();
DevConnect.benchmarkStop("loadUserData");
```

Or time a screen until it's laid out, or any async function:

```typescript
import { benchmarkAsync, benchmarkScreen } from "devconnect-manage-kit";

useEffect(() => benchmarkScreen("HomeScreen"), []);

const orders = await benchmarkAsync("loadOrders", () => api.getOrders());
```

### Errors

Uncaught JS errors are captured on their own (`autoError`, on by default)
through React Native's global error handler. Each shows in the desktop's
**Errors** tab with its stack trace.

### Memory Leaks

The leak detector (`autoMemoryLeak`, on by default) reports to the
desktop's **Leaks** tab. Watch a collection that shouldn't grow without
bound, or report a leak yourself:

```typescript
import { DevConnect, watchCollection } from "devconnect-manage-kit";

// Reported when it holds more than 500 items; call stop() to quit watching.
const stop = watchCollection("eventCache", () => cache.length, 500);

DevConnect.reportMemoryLeak({
  leakType: "undisposed_stream",
  severity: "warning", // info, warning or critical
  objectName: "CartSubscription",
  detail: "Listener not removed when CartScreen unmounts",
});
```

### Display

Send any value to watch in the desktop's **Display** tab; each call adds a
snapshot:

```typescript
DevConnect.display("Feature Flags", {
  value: { newCheckout: true, wishlist: false },
  preview: "newCheckout on · wishlist off",
});
```

### Async Operations

Redux Thunk actions are tracked by a middleware; wrap any other async work
with `trackAsync`. The desktop's **Async** tab shows each with its duration
and result:

```typescript
import { devConnectThunkTracker, trackAsync } from "devconnect-manage-kit";

const store = createStore(reducer, applyMiddleware(devConnectThunkTracker, thunk));

const user = await trackAsync("fetchUser", () => api.getUser(id));
```

Sagas or anything else: report the start, then the resolve or reject.

```typescript
DevConnect.reportAsyncOperation({
  operationType: "saga_call",
  description: "loadPromotions",
  status: "start",
  sagaName: "homeSaga",
});
// ...
DevConnect.reportAsyncOperation({
  operationType: "saga_call",
  description: "loadPromotions",
  status: "reject", // or "resolve", with a result
  duration: 487,
  sagaName: "homeSaga",
  error: "Request failed with status code 500",
});
```

### Custom Commands

```typescript
DevConnect.registerCommand("clearCache", () => {
  AsyncStorage.clear();
  return { success: true };
});
```

Registered commands show up in the desktop's **Commands** tab, where you
run them with optional JSON args and see what they return (async handlers
are awaited; a throw shows as the error).

### Database Browser

Let the desktop's **Database** tab browse your SQLite tables and run SQL —
pass a function that runs one statement and returns its rows:

```typescript
// op-sqlite
DevConnect.registerDatabase("app.db", async (sql) => (await db.execute(sql)).rows);
// expo-sqlite
DevConnect.registerDatabase("app.db", (sql) => db.getAllAsync(sql));
```

Results are capped at 1000 rows.

### Storage Editing

The desktop's **Storage** tab lists, edits, deletes and clears AsyncStorage
and MMKV once they're set up as above. For any other key-value store:

```typescript
DevConnect.registerStorage("prefs", {
  getAll: () => prefs.getAll(),
  set: (key, value) => prefs.set(key, value),
  remove: (key) => prefs.delete(key),
  clear: () => prefs.clear(),
});
```

### Layout Inspector

The desktop's **Layout** tab captures the current screen's component tree,
with each component's bounds, props and padding/margin (dev builds: it
reads React DevTools' hook). For the screenshot behind it, register a
capture function, e.g. with `react-native-view-shot`:

```typescript
import { captureScreen } from "react-native-view-shot";

DevConnect.registerScreenshot(() => captureScreen({ format: "png", result: "base64" }));
```

Without one the tab draws the components' outlines only. Click **Capture**
whenever you want the current screen;
[the desktop guide](https://github.com/ridelinktechs/devconnect-manage-kit#layout-inspector)
covers picking elements, zooming and measuring.

### Hot Reload from Desktop

Since **1.0.6** — let DevConnect Manage Tool trigger `server:reload`
or `server:hot_restart` on your app from the desktop. Default
delegates to `DevSettings.reload()` (the same path the dev menu's
"Reload" option uses).

```typescript
import { DevSettings } from "react-native";
import { DevConnect } from "devconnect-manage-kit";

// Optional: wipe in-memory state before the reload, then trigger reload
DevConnect.registerReloadHandler(() => {
  store.dispatch({ type: "RESET" });
  DevSettings.reload("DevConnect reload");
});
```

> Works in dev builds only — production no-ops.

## Production Safety

Disabled by default when `__DEV__` is false — zero runtime overhead. Metro bundler strips `__DEV__` blocks in production.

```typescript
// Explicitly disable
DevConnect.init({ appName: "MyApp", enabled: false });
```

## Links

- [Main Repository](https://github.com/ridelinktechs/devconnect-manage-kit)
- [Desktop App Download](https://github.com/ridelinktechs/devconnect-manage-kit/releases)
- [Full Documentation](https://github.com/ridelinktechs/devconnect-manage-kit#sdks)
- [Using the desktop app, page by page](https://github.com/ridelinktechs/devconnect-manage-kit#using-the-desktop-app)

## License

MIT - by [ridelinktechs](https://github.com/ridelinktechs)
