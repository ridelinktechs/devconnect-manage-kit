export { DevConnect } from './client';
export type { DatabaseQuery, StorageAdapter } from './client';
export { devConnectReduxMiddleware } from './interceptors/state/reduxMiddleware';
export { setupMobxSpy } from './interceptors/state/mobxSpy';
export { setupAxiosInterceptor } from './interceptors/network/axiosInterceptor';
export { DevConnectAsyncStorage } from './interceptors/storage/asyncStoragePlugin';
export { devConnectMiddleware } from './interceptors/state/zustandMiddleware';
export { devConnectAtomEffect, devConnectAtomOnMount, watchAtom } from './interceptors/state/jotaiPlugin';
export { watchValtio } from './interceptors/state/valtioPlugin';
export { devConnectXStateInspector, devConnectXStateService } from './interceptors/state/xstatePlugin';
export { DevConnectLogger } from './reporters/logging/logReporter';
export { DevConnectStorage } from './reporters/storage/storageReporter';
export { DevConnectMMKV } from './reporters/storage/mmkvReporter';
export { DevConnectEncryptedStorage } from './reporters/storage/encryptedStorageReporter';
export { DevConnectWatermelon } from './reporters/storage/watermelonReporter';
export { DevConnectSQLite } from './reporters/storage/sqliteReporter';
export { DevConnectRealm } from './reporters/storage/realmReporter';

// Auto-monitoring plugins
export { startPerformanceMonitor, stopPerformanceMonitor } from './plugins/performance/performanceMonitor';
export { startMemoryLeakDetector, stopMemoryLeakDetector, watchCollection } from './plugins/performance/memoryLeakDetector';
export { startErrorMonitor } from './plugins/errors/errorMonitor';
export { setupAppBenchmark, benchmarkScreen, benchmarkAsync } from './plugins/performance/appBenchmark';
export { devConnectThunkTracker, trackAsync } from './plugins/state/asyncTracker';

// Logging library integrations
export {
  devConnectTransport,       // react-native-logs
  patchLoglevel,             // loglevel
  winstonDevConnectTransport,// winston
  pinoDevConnectTransport,   // pino
  bunyanDevConnectStream,    // bunyan
  wrapLogger,                // any custom logger
} from './interceptors/logging/logLibraryPlugins';

// Round 2: State auto-discovery (React Query + Apollo)
export { setupReactQueryDevConnect } from './integrations/reactQuery';
export { setupApolloDevConnect } from './integrations/apollo';

// Round 3: Protocol inspectors
export { installWebSocketInterceptor } from './interceptors/network/webSocketInterceptor';
export { devConnectApolloLink } from './interceptors/network/apollo/devConnectApolloLink';

// Round 4: Source maps + mock server
export { uploadSourceMap } from './reporters/errors/sourceMapReporter';
export {
  setMockRules,
  findMockMatch,
  buildMockResponse,
  installMockServerInterceptor,
} from './interceptors/network/mockServerInterceptor';
