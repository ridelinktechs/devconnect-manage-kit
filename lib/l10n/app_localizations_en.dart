// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DevConnect Manage Tool';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get clear => 'Clear';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get autoScroll => 'Auto-scroll';

  @override
  String get newestFirst => 'Newest first';

  @override
  String get oldestFirst => 'Oldest first';

  @override
  String get clearAll => 'Clear all';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get clearAllCache => 'Clear All Cache';

  @override
  String get clearAllCacheDesc =>
      'Disconnect every device and clear all in-memory data (logs, network captures, state changes, performance, etc.). Your settings (theme, language, port) are preserved.';

  @override
  String get clearAllCacheConfirm =>
      'Clear all caches?\n\nThis will disconnect every connected device and erase every in-memory log, network capture, state change, performance metric, and benchmark result.\n\nYour settings (theme, language, port) will be kept.';

  @override
  String get cacheCleared => 'All caches cleared. Settings preserved.';

  @override
  String clearAllCacheFailed(Object error) {
    return 'Failed to clear cache: $error';
  }

  @override
  String get deviceHistory => 'Cached Devices';

  @override
  String get deviceHistoryDesc =>
      'Every device that has connected to this desktop. Entries persist across restarts so you can see what was here before.';

  @override
  String get noDeviceHistory => 'No devices have connected yet';

  @override
  String get deviceHistoryEmptyHint =>
      'Connect a device via the SDK and it will appear here. Entries persist across restarts.';

  @override
  String get restarting => 'Restarting…';

  @override
  String get online => 'online';

  @override
  String get offline => 'offline';

  @override
  String get markOnline => 'Mark online';

  @override
  String get markOffline => 'Mark offline';

  @override
  String get deviceOnline => 'Online';

  @override
  String get deviceOffline => 'Offline';

  @override
  String lastSeen(Object time) {
    return 'Last seen $time';
  }

  @override
  String firstSeen(Object time) {
    return 'First seen $time';
  }

  @override
  String get forgetDevice => 'Forget';

  @override
  String get forgetAllOffline => 'Forget All Offline';

  @override
  String get forgetAllDevices => 'Forget All';

  @override
  String get forgetDeviceConfirm =>
      'Forget this device?\n\nIt will be removed from the history. The next time it connects it will appear again as a new entry.';

  @override
  String get forgetAllOfflineConfirm =>
      'Forget all offline devices?\n\nThis removes every entry that\'s not currently connected. Online devices are kept.';

  @override
  String get forgetAllDevicesConfirm =>
      'Forget all cached devices?\n\nThis wipes the entire history, including online devices. They will reappear when they (re)connect.';

  @override
  String get deviceForgotten => 'Device forgotten';

  @override
  String devicesForgotten(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices forgotten',
      one: '1 device forgotten',
      zero: 'No devices forgotten',
    );
    return '$_temp0';
  }

  @override
  String connectionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connections',
      one: '1 connection',
      zero: 'never connected',
    );
    return '$_temp0';
  }

  @override
  String get restartServer => 'Restart server';

  @override
  String portOccupied(Object port) {
    return 'Port $port occupied';
  }

  @override
  String get serverRestarted => 'Server restarted';

  @override
  String get restartFailed => 'Restart failed';

  @override
  String portStillInUse(Object port) {
    return 'Port $port is still in use';
  }

  @override
  String couldNotRestart(Object port) {
    return 'Could not restart on port $port';
  }

  @override
  String listeningOnPort(Object port) {
    return 'Listening on port $port';
  }

  @override
  String waitingForReconnect(Object port) {
    return 'Port $port · waiting for devices';
  }

  @override
  String reconnectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices reconnected',
      one: '1 device reconnected',
      zero: '0 reconnected',
    );
    return '$_temp0';
  }

  @override
  String get reloadApp => 'Reload app';

  @override
  String get reloadAppHotReload => 'Hot reload';

  @override
  String get reloadAppHotRestart => 'Hot restart';

  @override
  String get reloadAppMetro => 'Reload Metro';

  @override
  String get reloadAppNoDevices => 'No devices connected';

  @override
  String get reloadSent => 'Reload sent';

  @override
  String sentReloadTo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reload dispatched to $count devices',
      one: 'Reload dispatched to 1 device',
      zero: 'No devices targeted',
    );
    return '$_temp0';
  }

  @override
  String get screenshotSaved => 'Screenshot saved';

  @override
  String get screenshotFailed => 'Screenshot failed';

  @override
  String get reveal => 'Reveal';

  @override
  String get captureFull => 'Full';

  @override
  String get captureTab => 'Tab';

  @override
  String get captureFullTooltip => 'Capture full detail as image';

  @override
  String get captureTabTooltip => 'Capture current tab only';

  @override
  String get captureAsImage => 'Capture as image';

  @override
  String get captureDetailAsImage => 'Capture detail as image';

  @override
  String get noData => 'No data';

  @override
  String get noItems => 'No items';

  @override
  String get searchHint => 'Search...';

  @override
  String get filterHint => 'Filter...';

  @override
  String get value => 'Value';

  @override
  String get key => 'Key';

  @override
  String get metadata => 'Metadata';

  @override
  String get duration => 'Duration';

  @override
  String get error => 'Error';

  @override
  String get json => 'JSON';

  @override
  String get tree => 'Tree';

  @override
  String get code => 'Code';

  @override
  String get raw => 'Raw';

  @override
  String get format => 'Format';

  @override
  String get pretty => 'Pretty';

  @override
  String get collapse => 'Collapse';

  @override
  String get showMore => 'Show more';

  @override
  String get noHeaders => 'No headers';

  @override
  String get inProgress => 'in progress';

  @override
  String get inProgressDots => 'In Progress...';

  @override
  String hideShowTooltip(Object action, Object label) {
    return '$action $label';
  }

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get steps => 'steps';

  @override
  String get portInUse =>
      'Port is already in use. Close the other app using this port, or pick a different port in Settings.';

  @override
  String portInUseShort(Object port) {
    return 'Port $port is already in use. Close the other app using this port, or enter a different port above and press Start.';
  }

  @override
  String failedToStartServer(Object msg) {
    return 'Failed to start server: $msg';
  }

  @override
  String failedToStartServerOnPort(Object msg, Object port) {
    return 'Failed to start server on port $port: $msg';
  }

  @override
  String get settings => 'Settings';

  @override
  String get server => 'Server';

  @override
  String get serverRunning => 'Server Running';

  @override
  String get serverStopped => 'Server Stopped';

  @override
  String get port => 'Port';

  @override
  String deviceCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
      zero: '0 devices',
    );
    return '$_temp0';
  }

  @override
  String get network => 'Network';

  @override
  String get hostname => 'Hostname';

  @override
  String get noNetworkInterfaces => 'No network interfaces found';

  @override
  String copiedIp(Object ip) {
    return 'Copied $ip';
  }

  @override
  String connectedDevices(Object count) {
    return 'Connected Devices ($count)';
  }

  @override
  String get noDevicesConnected => 'No devices connected';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get bottom => 'Bottom';

  @override
  String get top => 'Top';

  @override
  String get language => 'Language';

  @override
  String get tabVisibility => 'Tab Visibility';

  @override
  String get tabVisibilityDesc =>
      'Toggle which tabs are visible. Disabled tabs show a lock icon and their data is excluded from All Events.';

  @override
  String get detailView => 'Detail View';

  @override
  String get detailViewDesc =>
      'Remembers how request/response bodies are shown and controls tab switching animation.';

  @override
  String get bodyView => 'Body view';

  @override
  String get tabAnimation => 'Tab animation';

  @override
  String get tabAnimationDuration => 'Duration';

  @override
  String get codeModeDesc =>
      'Code mode exports as TypeScript / Dart / Kotlin based on the connected SDK.';

  @override
  String get treeModeDesc =>
      'Tree mode shows the data as an expandable, collapsible node hierarchy. Best for navigating deeply nested values.';

  @override
  String get jsonModeDesc =>
      'JSON mode renders the data as a single, syntax-highlighted, copy-friendly JSON document.';

  @override
  String get usbConnection => 'USB Connection';

  @override
  String get android => 'Android';

  @override
  String get ios => 'iOS';

  @override
  String get runAdbReverse => 'Run ADB Reverse';

  @override
  String adbNotFound(Object home) {
    return 'adb not found.\nHOME=$home';
  }

  @override
  String adbReverseOk(Object path) {
    return 'adb reverse OK ($path)';
  }

  @override
  String adbError(Object error) {
    return 'adb error: $error';
  }

  @override
  String adbException(Object error) {
    return 'adb exception: $error';
  }

  @override
  String get devices => 'Devices';

  @override
  String get adbDevices => 'ADB Devices';

  @override
  String get wifiAutoConnect =>
      'WiFi auto-connects if same network. USB: install iproxy.';

  @override
  String get quickStart => 'Quick Start';

  @override
  String get quickStartDesc =>
      'Three steps to wire up your app. Click any platform tab to see the snippet for that SDK.';

  @override
  String get installSdk => 'Install SDK';

  @override
  String get initialize => 'Initialize';

  @override
  String get connect => 'Connect';

  @override
  String get supportDevConnect => 'Support DevConnect';

  @override
  String get supportDevConnectDesc =>
      'DevConnect Manage Tool is free and open source. If it helps your workflow, consider supporting development.';

  @override
  String get kofi => 'Ko-fi';

  @override
  String get paypal => 'PayPal';

  @override
  String get ethernet => 'Ethernet';

  @override
  String get wifi => 'WiFi';

  @override
  String get vpn => 'VPN';

  @override
  String get bridge => 'Bridge';

  @override
  String get loopback => 'Loopback';

  @override
  String get console => 'Console';

  @override
  String get state => 'State';

  @override
  String get storage => 'Storage';

  @override
  String get database => 'Database';

  @override
  String get performance => 'Performance';

  @override
  String get memoryLeaks => 'Memory Leaks';

  @override
  String get history => 'History';

  @override
  String get noNetworkRequests => 'No network requests';

  @override
  String get apiCallsAppearHere => 'API calls will appear here in real-time';

  @override
  String get networkTitle => 'Network';

  @override
  String get filterUrls => 'Filter URLs...';

  @override
  String get copyUrl => 'Copy URL';

  @override
  String get urlCopied => 'URL copied';

  @override
  String get copyPath => 'Copy Path';

  @override
  String get pathCopied => 'Path copied';

  @override
  String get copyCurl => 'Copy cURL';

  @override
  String get curlCopied => 'cURL copied';

  @override
  String get copyRequest => 'Copy Request';

  @override
  String get requestCopied => 'Request copied';

  @override
  String get copyResponse => 'Copy Response';

  @override
  String get responseCopied => 'Response copied';

  @override
  String get requestBody => 'Request Body';

  @override
  String get responseBody => 'Response Body';

  @override
  String get requestHeaders => 'Request Headers';

  @override
  String get responseHeaders => 'Response Headers';

  @override
  String get headers => 'Headers';

  @override
  String get request => 'Request';

  @override
  String get response => 'Response';

  @override
  String get timing => 'Timing';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String noLabel(Object label) {
    return 'No $label';
  }

  @override
  String get noStorageData => 'No storage data';

  @override
  String get storageEntriesAppearHere =>
      'SharedPreferences, AsyncStorage, and Hive entries appear here';

  @override
  String get storageTitle => 'Storage';

  @override
  String get filterKeys => 'Filter keys...';

  @override
  String get read => 'READ';

  @override
  String get write => 'WRITE';

  @override
  String get delete => 'DELETE';

  @override
  String get noEventsYet => 'No events yet';

  @override
  String get startAppToSeeEvents =>
      'Start your app with DevConnect SDK to see events';

  @override
  String get eventsAppearHere => 'Events will appear here in real-time';

  @override
  String get allEventsTitle => 'All Events';

  @override
  String get stopped => 'Stopped';

  @override
  String get searchEvents => 'Search events...';

  @override
  String get logDetail => 'Log Detail';

  @override
  String get networkDetail => 'Network Detail';

  @override
  String get stateDetail => 'State Detail';

  @override
  String get storageDetail => 'Storage Detail';

  @override
  String get displayDetail => 'Display Detail';

  @override
  String get asyncOperation => 'Async Operation';

  @override
  String get errorDetail => 'Error Detail';

  @override
  String get tag => 'Tag';

  @override
  String get message => 'Message';

  @override
  String get stackTrace => 'Stack Trace';

  @override
  String get noLogsYet => 'No logs yet';

  @override
  String get connectDeviceToSeeLogs =>
      'Connect a device and start logging to see entries here';

  @override
  String get consoleTitle => 'Console';

  @override
  String get searchLogs => 'Search logs...';

  @override
  String get clearConsole => 'Clear console';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get logCopied => 'Log copied';

  @override
  String get closePanel => 'Close panel';

  @override
  String hideShowLogs(Object action, Object label) {
    return '$action $label logs';
  }

  @override
  String get errors => 'Errors';

  @override
  String get searchErrors => 'Search errors...';

  @override
  String get clearErrors => 'Clear errors';

  @override
  String get totalErrors => 'Total Errors';

  @override
  String get fatalCrash => 'Fatal/Crash';

  @override
  String get noErrorsCaptured => 'No errors captured';

  @override
  String get errorsAppearHere =>
      'Errors from React Native and Flutter will appear here';

  @override
  String get stackTraceCopied => 'Stack trace copied';

  @override
  String get noStackTrace => 'No stack trace available';

  @override
  String get platform => 'Platform';

  @override
  String get severity => 'Severity';

  @override
  String get source => 'Source';

  @override
  String get deviceId => 'Device ID';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get details => 'Details';

  @override
  String hideShowErrors(Object action, Object label) {
    return '$action $label errors';
  }

  @override
  String get noStateChanges => 'No state changes';

  @override
  String get stateChangesAppearHere =>
      'Redux, BLoC, Riverpod, and MobX state changes appear here';

  @override
  String get stateInspectorTitle => 'State Inspector';

  @override
  String changesCount(Object count) {
    return '$count changes';
  }

  @override
  String changeCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
      zero: '0 changes',
    );
    return '$_temp0';
  }

  @override
  String get filterActions => 'Filter actions...';

  @override
  String get newestAtTop => 'Newest at top';

  @override
  String get newestAtBottom => 'Newest at bottom';

  @override
  String get noChanges => 'No changes';

  @override
  String get diff => 'Diff';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get noChangesDetected => 'No changes detected';

  @override
  String get noBenchmarks => 'No Benchmarks';

  @override
  String get useBenchmarkSdk =>
      'Use benchmarkStart/Step/Stop in your SDK to measure performance';

  @override
  String get benchmarksTitle => 'Benchmarks';

  @override
  String get searchBenchmarks => 'Search benchmarks...';

  @override
  String get total => 'Total';

  @override
  String get avg => 'Avg';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get p50 => 'P50';

  @override
  String get end => 'End';

  @override
  String stepsCount(Object count) {
    return 'Steps ($count)';
  }

  @override
  String get noIntermediateSteps => 'No intermediate steps recorded';

  @override
  String get noPerformanceData => 'No Performance Data';

  @override
  String get connectAppToProfile =>
      'Connect an app with DevConnect SDK to start profiling';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get startRecording => 'Start Recording';

  @override
  String get performanceProfiler => 'Performance Profiler';

  @override
  String slowFrames(Object count) {
    return 'Slow Frames: $count';
  }

  @override
  String get systemStatus => 'System Status';

  @override
  String get startup => 'Startup';

  @override
  String get battery => 'Battery';

  @override
  String get emulator => 'Emulator';

  @override
  String get drainRate => 'Drain Rate';

  @override
  String get thermal => 'Thermal';

  @override
  String get diskRead => 'Disk Read';

  @override
  String get diskWrite => 'Disk Write';

  @override
  String get anr => 'ANR';

  @override
  String get charging => 'Charging';

  @override
  String get normal => 'Normal';

  @override
  String get fair => 'Fair';

  @override
  String get serious => 'Serious';

  @override
  String get critical => 'Critical';

  @override
  String get reqs => 'reqs';

  @override
  String get live => 'live';

  @override
  String get reqPerSec => 'req/s';

  @override
  String get err => 'err';

  @override
  String get waitingForRequests => 'Waiting for requests...';

  @override
  String get waitingForData => 'Waiting for data...';

  @override
  String get noMemoryLeaksDetected => 'No Memory Leaks Detected';

  @override
  String get connectAppToMonitorLeaks =>
      'Connect an app with DevConnect SDK to monitor memory leaks';

  @override
  String get memoryLeakDetection => 'Memory Leak Detection';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get detail => 'Detail';

  @override
  String get retainedSize => 'Retained Size';

  @override
  String get timestamp => 'Timestamp';

  @override
  String get undisposedController => 'Undisposed Controller';

  @override
  String get undisposedStream => 'Undisposed Stream';

  @override
  String get undisposedTimer => 'Undisposed Timer';

  @override
  String get undisposedAnimation => 'Undisposed Animation';

  @override
  String get widgetLeak => 'Widget Leak';

  @override
  String get growingCollection => 'Growing Collection';

  @override
  String get custom => 'Custom';

  @override
  String get smoothScrolling => 'Smooth scroll';

  @override
  String get smoothScrollingDesc =>
      'Smooths mouse-wheel scroll events. Disable this option if you notice any lag or performance drop.';

  @override
  String get smoothScrollingDuration => 'Scroll duration';

  @override
  String get smoothScrollingDurationDesc =>
      'The duration of the smooth scroll animation in milliseconds.';

  @override
  String binaryBody(String label) {
    return '$label body is binary';
  }

  @override
  String binaryBodySize(String kb, int bytes) {
    return '$kb KB ($bytes bytes)';
  }

  @override
  String get binaryBodyHint =>
      'Identify the action via the X-Amz-Target header.';
}
