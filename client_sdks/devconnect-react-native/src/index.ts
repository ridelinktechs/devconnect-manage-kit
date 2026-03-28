export { DevConnect } from './client';
export { devConnectReduxMiddleware } from './interceptors/reduxMiddleware';
export { setupMobxSpy } from './interceptors/mobxSpy';
export { setupAxiosInterceptor } from './interceptors/axiosInterceptor';
export { DevConnectAsyncStorage } from './interceptors/asyncStoragePlugin';
export { devConnectMiddleware } from './interceptors/zustandMiddleware';
export { devConnectAtomEffect, devConnectAtomOnMount, watchAtom } from './interceptors/jotaiPlugin';
export { watchValtio } from './interceptors/valtioPlugin';
export { devConnectXStateInspector, devConnectXStateService } from './interceptors/xstatePlugin';
export { DevConnectLogger } from './reporters/logReporter';
export { DevConnectStorage } from './reporters/storageReporter';
export { DevConnectMMKV } from './reporters/mmkvReporter';

// Auto-monitoring plugins
export { startPerformanceMonitor, stopPerformanceMonitor } from './plugins/performanceMonitor';
export { startMemoryLeakDetector, stopMemoryLeakDetector, watchCollection } from './plugins/memoryLeakDetector';
export { setupAppBenchmark, benchmarkScreen, benchmarkAsync } from './plugins/appBenchmark';
export { devConnectThunkTracker, trackAsync } from './plugins/asyncTracker';

// Logging library integrations
export {
  devConnectTransport,       // react-native-logs
  patchLoglevel,             // loglevel
  winstonDevConnectTransport,// winston
  pinoDevConnectTransport,   // pino
  bunyanDevConnectStream,    // bunyan
  wrapLogger,                // any custom logger
} from './interceptors/logLibraryPlugins';
