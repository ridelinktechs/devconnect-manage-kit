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

const useStore = create(
  devConnectMiddleware(
    (set) => ({
      count: 0,
      increment: () => set((s) => ({ count: s.count + 1 })),
    }),
    "CounterStore",
  ),
);
```

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

```typescript
DevConnect.reportPerformanceMetric({
  metricType: "fps",
  value: 58.5,
  label: "JS Thread FPS",
});
```

### Benchmark

```typescript
DevConnect.benchmark("loadUserData");
await fetchUser();
DevConnect.benchmarkStep("loadUserData", "fetched user");
await fetchPosts();
DevConnect.benchmarkStop("loadUserData");
```

### Custom Commands

```typescript
DevConnect.registerCommand("clearCache", () => {
  AsyncStorage.clear();
  return { success: true };
});
```

### Hot Reload from Desktop

Since **1.0.6** — let DevConnect Manage Tool trigger `server:reload`
or `server:hot_restart` on your app from the desktop. Default
delegates to `DevSettings.reload()` (the same path the dev menu's
"Reload" option uses).

```typescript
import { DevConnect, DevSettings } from "devconnect-manage-kit";

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
- [Full Documentation](https://github.com/ridelinktechs/devconnect-manage-kit#react-native-sdk)

## License

MIT - by [ridelinktechs](https://github.com/ridelinktechs)
