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
  String get dataRetention => 'Data Retention';

  @override
  String get dataRetentionDesc =>
      'Hard cap applied to each per-feature list. When a list exceeds the limit, oldest entries are dropped FIFO. Pending async ops are preserved.';

  @override
  String get maxItems => 'Max items';

  @override
  String get dataRetentionHelper =>
      'Unlimited keeps every entry. Lower values free memory but lose history.';

  @override
  String get allEventsDisplay => 'All Events Display';

  @override
  String get allEventsDisplayDesc =>
      'View-only filter for the aggregated All Events list. The underlying logs are not deleted — flip back to Unlimited to restore.';

  @override
  String get allEventsDisplayHelper =>
      'Lower values keep the most recent N entries visible at the cost of older history.';

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
  String get captureDataJson => 'Capture data (key + value in current mode)';

  @override
  String get captureDataText => 'Capture data (key + value as text)';

  @override
  String get copyKey => 'Copy key';

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
      'An iPhone connects over Wi‑Fi: put it on the same network as this Mac. A USB cable alone can\'t connect it.';

  @override
  String get quickStart => 'Quick Start';

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
  String clearStaleButton(Object count) {
    return 'Stale ($count)';
  }

  @override
  String clearStaleTooltip(Object count) {
    return 'Clear $count pending request(s) with no response for over 10 minutes';
  }

  @override
  String clearStaleSnackbar(Object count) {
    return 'Cleared $count stale request(s) (pending > 10min)';
  }

  @override
  String memorySafetyOverflow(Object count) {
    return 'Memory safety: dropped $count stale network entry(ies) from the open-trips cache';
  }

  @override
  String get sdkTipsPill => 'Tips lib';

  @override
  String get sdkTipsHeader => 'Library compatibility';

  @override
  String get sdkTipsSubtitle =>
      'To ensure all data is fully displayed, make sure the libraries are the latest version.';

  @override
  String get sdkTipsFlutter => 'Flutter';

  @override
  String get sdkTipsReactNative => 'React Native';

  @override
  String get sdkTipsAndroid => 'Android';

  @override
  String sdkTipsVersionLabel(Object version) {
    return 'v$version';
  }

  @override
  String sdkTipsPillLatest(Object version) {
    return 'v$version · Latest';
  }

  @override
  String sdkTipsPillUpdate(Object version) {
    return 'v$version · Update';
  }

  @override
  String get sdkTipsInstalled => 'Installed';

  @override
  String get sdkTipsLatestLabel => 'Latest';

  @override
  String get sdkTipsUpdate => 'Update';

  @override
  String get sdkTipsChecking => 'Checking';

  @override
  String get sdkTipsOffline => 'Live check unavailable';

  @override
  String get sdkTipsRetry => 'Retry';

  @override
  String get sdkTipsCheckProject =>
      'Run this in your project to see the installed version:';

  @override
  String get sdkTipsInstallLatest => 'Install the latest version:';

  @override
  String get appUpdateTitle => 'DevConnect version';

  @override
  String get appUpdateAvailable => 'A new version is available.';

  @override
  String get appUpdateUpToDate => 'You\'re on the latest version.';

  @override
  String get appUpdateViewRelease => 'View release';

  @override
  String devicesConnected(Object count) {
    return '$count connected';
  }

  @override
  String get devicesAll => 'All';

  @override
  String devicesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
    );
    return '$_temp0';
  }

  @override
  String get commandsTitle => 'Custom commands';

  @override
  String get commandsNoDevice => 'Connect a device to run its commands.';

  @override
  String get commandsEmptyHint =>
      'No commands registered yet. Add one in the app with DevConnect.registerCommand(name, handler), or type a command name to run it.';

  @override
  String get commandsName => 'Command';

  @override
  String get commandsArgs => 'Arguments — JSON object, optional';

  @override
  String get commandsArgsInvalid => 'Arguments must be a JSON object.';

  @override
  String get commandsRun => 'Run';

  @override
  String commandsTarget(Object device) {
    return 'Runs on $device';
  }

  @override
  String get commandsHistoryEmpty =>
      'Results of the commands you run show up here.';

  @override
  String get commandsNoResponse =>
      'No response. Is the command registered in the app?';

  @override
  String get dbTables => 'Tables';

  @override
  String get dbRefresh => 'Reload tables';

  @override
  String get dbNoDevice => 'Connect a device to browse its databases.';

  @override
  String get dbSelectDevice =>
      'Select a device in the bottom bar to browse its databases.';

  @override
  String get dbNoDatabases =>
      'No database registered. Add one in the app with DevConnect.registerDatabase(name, query), then reload tables.';

  @override
  String get dbRun => 'Run';

  @override
  String get dbRunHint => 'Pick a table or write SQL';

  @override
  String get dbRunHintSubtitle => 'Picking a table previews its first 50 rows.';

  @override
  String dbRows(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows',
      one: '1 row',
    );
    return '$_temp0';
  }

  @override
  String dbTruncated(Object count) {
    return 'first $count only';
  }

  @override
  String get dbNoResponse =>
      'No response. Does the app register a database with DevConnect.registerDatabase? It needs the latest SDK.';

  @override
  String get stateToolsTab => 'Controls';

  @override
  String get stateNoDevice =>
      'Select a device in the bottom bar to watch, snapshot and drive its state.';

  @override
  String get stateNoState => 'This device hasn\'t reported any state yet.';

  @override
  String get stateSubscriptions => 'Subscriptions';

  @override
  String get stateSubscriptionsHint =>
      'Pin a state path to watch its live value, e.g. auth.user or cart.items[0].price.';

  @override
  String get statePinPath => 'Pin path';

  @override
  String get statePathMissing => '(not in state)';

  @override
  String get stateRemove => 'Remove';

  @override
  String get stateSnapshots => 'Snapshots';

  @override
  String get stateSnapshotsHint =>
      'Save the current state and send it back later to reproduce a bug or skip a long form. The app applies it in onStateRestore.';

  @override
  String get stateTakeSnapshot => 'Take snapshot';

  @override
  String stateKeys(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keys',
      one: '1 key',
    );
    return '$_temp0';
  }

  @override
  String get stateRestore => 'Restore';

  @override
  String get stateRestoreHere => 'Restore the app\'s state to this point';

  @override
  String get stateSaveSnapshot => 'Save as snapshot';

  @override
  String get stateSnapshotSaved => 'Snapshot saved';

  @override
  String get stateRestoreSent => 'State restore sent';

  @override
  String get stateDispatch => 'Dispatch action';

  @override
  String get stateDispatchHint =>
      'Send a Redux action to the app. Needs the store wired: connectReduxStore(store) on React Native, onReduxDispatch on Flutter and Android.';

  @override
  String get stateDispatchButton => 'Dispatch';

  @override
  String get stateDispatchSent => 'Action dispatched';

  @override
  String get stateActionInvalid => 'The action must be a JSON object.';

  @override
  String get stateRecentActions => 'Recent';

  @override
  String get jsonTreeView => 'Tree';

  @override
  String get jsonTableView => 'Table';

  @override
  String get jsonSearchHint => 'Search keys & values';

  @override
  String get jsonExportCsv => 'Download table as CSV';

  @override
  String get jsonTableNoMatch => 'No rows match';

  @override
  String get jsonPrevMatch => 'Previous match';

  @override
  String get jsonNextMatch => 'Next match';

  @override
  String get jsonExpandAll => 'Expand all';

  @override
  String get jsonCollapseAll => 'Collapse all';

  @override
  String get jsonCopyKey => 'Copy key';

  @override
  String get jsonCopyValue => 'Copy value';

  @override
  String get jsonCopyPath => 'Copy path';

  @override
  String get jsonKeyCopied => 'Key copied';

  @override
  String get jsonValueCopied => 'Value copied';

  @override
  String get jsonPathCopied => 'Path copied';

  @override
  String jsonShowMore(int count, int remaining) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return 'Show $countString more ($remainingString left)';
  }

  @override
  String jsonLongValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString characters, copy to get all';
  }

  @override
  String jsonPrettyCut(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Showing the first $shownString of $totalString lines. Copy or save to get all of them.';
  }

  @override
  String jsonTableTruncated(Object count) {
    return 'Showing the first $count rows.';
  }

  @override
  String get networkErrors => 'Errors';

  @override
  String get networkSearchBodies => 'Also search request & response bodies';

  @override
  String get networkExportHar => 'Export the listed requests as HAR';

  @override
  String get networkNothingToExport => 'No requests to export';

  @override
  String get fileSaved => 'File saved';

  @override
  String get consoleGroupRepeats => 'Group repeated logs';

  @override
  String get consoleOccurrences => 'Occurrences';

  @override
  String get consoleNoMatchTitle => 'No logs match';

  @override
  String get consoleNoMatchSubtitle => 'Drop a filter to bring them back.';

  @override
  String get consoleShowAllLevels => 'Show all levels';

  @override
  String get consoleClearSearch => 'Clear search';

  @override
  String get consoleResetFilters => 'Reset filters';

  @override
  String get consoleExport => 'Export logs';

  @override
  String get consoleExportText => 'Text (.txt)';

  @override
  String get consoleExportJson => 'JSON (.json)';

  @override
  String get consoleNothingToExport => 'No logs to export';

  @override
  String get errorSymbolicate => 'Symbolicate';

  @override
  String get errorSymbolicated => 'Mapped to source';

  @override
  String get errorSymbolicateFailed =>
      'Couldn\'t map this stack: Metro isn\'t reachable from here and no source map was uploaded for this build (uploadSourceMap in the SDK).';

  @override
  String get storageTabHistory => 'History';

  @override
  String get storageTabKeyValue => 'Key-Value';

  @override
  String get storageKvNoDevice =>
      'Select a device in the bottom bar to see and edit its storage.';

  @override
  String get storageKvEmpty =>
      'No editable storage yet. Wrap the store with the SDK (DevConnectAsyncStorage.wrap, DevConnectMMKV.wrap, DevConnectSharedPreferences.wrap…) — it needs the latest SDK.';

  @override
  String get storageKvRefresh => 'Reload';

  @override
  String get storageKvAdd => 'Add key';

  @override
  String get storageKvEdit => 'Edit value';

  @override
  String get storageKvDelete => 'Delete key';

  @override
  String get storageKvClear => 'Clear all';

  @override
  String storageKvClearConfirm(Object storage) {
    return 'Delete every key in $storage? This can\'t be undone.';
  }

  @override
  String get storageKvKey => 'Key';

  @override
  String get storageKvValue => 'Value';

  @override
  String get storageKvSave => 'Save';

  @override
  String get storageKvFilter => 'Filter keys';

  @override
  String get deepLinkTitle => 'Open a deep link';

  @override
  String get deepLinkHint =>
      'The app opens it as if one of its links was tapped.';

  @override
  String get deepLinkOpen => 'Open';

  @override
  String get deepLinkSent => 'Deep link sent';

  @override
  String get devMenu => 'Open the dev menu';

  @override
  String get networkReplay => 'Replay request';

  @override
  String get networkReplaySent =>
      'Request sent again — it shows up as a new row';

  @override
  String get networkConditions => 'Network conditions';

  @override
  String get networkPresetNormal => 'Normal';

  @override
  String get networkPresetSlow => 'Slow (+500 ms)';

  @override
  String get networkPresetSlow3g => 'Slow 3G (~2 s)';

  @override
  String get networkPresetOffline => 'Offline';

  @override
  String get networkTabHttpHint =>
      'HTTP requests the app made through fetch, XHR, axios, Dio, OkHttp…';

  @override
  String get networkTabProtocolsHint =>
      'Traffic beyond plain HTTP: GraphQL operations, WebSocket messages and gRPC calls';

  @override
  String get networkTabMockAuditHint =>
      'Requests the app answered with a Mock Server rule instead of the real network';

  @override
  String get protocolGraphqlHint =>
      'Queries and mutations sent through the SDK\'s GraphQL link / interceptor';

  @override
  String get protocolWebsocketHint =>
      'WebSocket connections and every frame sent or received';

  @override
  String get protocolGrpcHint => 'gRPC calls (Android SDK interceptor)';

  @override
  String get layoutTitle => 'Layout';

  @override
  String get layoutCapture => 'Capture';

  @override
  String get layoutHint =>
      'Capture the app\'s current screen to see its element tree. Hover the screenshot to highlight an element, click it to see its properties.';

  @override
  String get layoutNoDevice =>
      'Connect an app, or select a device, to inspect its layout.';

  @override
  String get layoutNoScreenshot =>
      'No screenshot from this app, showing element outlines only. React Native: add one with DevConnect.registerScreenshot.';

  @override
  String get layoutPickElement =>
      'Hover or click an element on the screenshot, or pick one in the tree.';

  @override
  String get layoutTree => 'Element tree';

  @override
  String get layoutProperties => 'Properties';

  @override
  String get layoutTreeError => 'Couldn\'t read the element tree';

  @override
  String get layoutSearchHint => 'Find by name or value';

  @override
  String get layoutAppOnly => 'App elements only';

  @override
  String get layoutFit => 'Fit';

  @override
  String get layoutActualSize => 'Actual size';

  @override
  String get layoutZoomIn => 'Zoom in';

  @override
  String get layoutZoomOut => 'Zoom out';

  @override
  String get layoutZoomLevel => 'Zoom level';

  @override
  String get layoutZoomToSelection => 'Zoom to selection';

  @override
  String get layoutClose => 'Close capture';

  @override
  String get layoutCopyName => 'Copy name';

  @override
  String get layoutCopyJson => 'Copy as JSON';

  @override
  String get layoutExport => 'Export';

  @override
  String get layoutSavePng => 'Save screenshot (PNG)';

  @override
  String get layoutSaveJson => 'Save snapshot (JSON)';

  @override
  String get layoutNoAnswer =>
      'The app didn\'t answer. Layout needs a DevConnect SDK with Layout support, in a debug build.';

  @override
  String get layoutTruncated => 'Large tree: only the first part was captured.';

  @override
  String get layoutState => 'State';

  @override
  String get layoutMeasureHint => '⌥ + hover: measure';

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
    return '$kb ($bytes bytes)';
  }

  @override
  String get binaryBodyHint =>
      'Identify the action via the X-Amz-Target header.';

  @override
  String get openWithDefaultApp => 'Open in default app';

  @override
  String get tipsAndShortcuts => 'Tips & Shortcuts';

  @override
  String get tipsAndShortcutsDesc =>
      'Quick guides for the most useful workflows. Click any card for details.';

  @override
  String get tipAllEventsTitle => 'All Events feed';

  @override
  String get tipAllEventsBody =>
      'One live timeline of your app\'s logs, network requests, state changes, storage operations and errors, plus display and async-operation events.';

  @override
  String get tipAllEventsSteps =>
      'Type in \"Search events...\" to match messages, URL paths, actions, storage keys or tags\nToggle the \"LOG\", \"API\", \"STATE\" and \"STORE\" chips; \"ERRORS\" keeps errors and failed requests\nClick a row for details; \"Full\" or \"Tab\" saves them as an image\nPick a device, or \"All\", in the bottom bar to choose whose events show\nUse \"Oldest first\"/\"Newest first\" to flip the order and \"Auto-scroll\" to follow new events';

  @override
  String get tipAllEventsTip =>
      '\"Clear all\" here empties every page\'s list — Console, Network, State, Storage, Errors and the rest — not just this feed.';

  @override
  String get tipNetworkTitle => 'Inspect network traffic';

  @override
  String get tipNetworkBody =>
      'HTTP requests your app makes, with headers, bodies, status and duration, plus GraphQL, WebSocket and gRPC traffic and requests answered by mock rules. gRPC comes from the Android SDK only.';

  @override
  String get tipNetworkSteps =>
      'Click a request for its \"Headers\", \"Request\", \"Response\" and \"Timing\" tabs\nFilter by method, \"2xx\"/\"3xx\"/\"Errors\", or type part of a URL in \"Filter URLs...\"\nTurn on \"Also search request & response bodies\" to search inside payloads too\nPress \"Copy cURL\" in the panel for a curl command; right-click a row for \"Replay request\"\nOpen \"Protocols\" for GraphQL, WebSocket and gRPC, or \"Mock Audit\" for mocked requests';

  @override
  String get tipNetworkTip =>
      'Connectivity checks such as generate_204 and captive.apple.com stay hidden until your search matches them.';

  @override
  String get tipConsoleTitle => 'Console logs';

  @override
  String get tipConsoleBody =>
      'Your app\'s log lines as they arrive, with level, tag and time — console calls on React Native, print and debugPrint on Flutter, println on Android.';

  @override
  String get tipConsoleSteps =>
      'Toggle \"DEBUG\", \"INFO\", \"WARN\" and \"ERROR\" to show or hide each level\nType in \"Search logs...\" to match message text or tag\nClick a row for its tag, message, metadata and stack trace, when present\nKeep \"Group repeated logs\" on to fold identical back-to-back lines into one counted row\nUse \"Export logs\" to save the filtered list as \"Text (.txt)\" or \"JSON (.json)\"';

  @override
  String get tipConsoleTip =>
      'Plain console.log, print and println lines arrive as DEBUG — switch \"DEBUG\" off to keep only info, warnings and errors.';

  @override
  String get tipStateTitle => 'State inspector';

  @override
  String get tipStateBody =>
      'Every state change your app reports, with its action and the state before and after — Redux, Zustand, MobX and more on React Native, BLoC, Riverpod and Provider on Flutter, ViewModels on Android.';

  @override
  String get tipStateSteps =>
      'Open the \"Redux\" tab — it lists changes from every state library, not only Redux\nType in \"Filter actions...\" to match an action or store name\nClick a change, then switch between \"Diff\", \"Before\" and \"After\"\nUse \"Restore the app\'s state to this point\" (needs DevConnect.onStateRestore) or \"Save as snapshot\"\nOpen \"Controls\" to pin state paths, take snapshots and dispatch Redux actions';

  @override
  String get tipStateTip =>
      '\"Diff\" fills only when the SDK sends one — Redux, Zustand and MobX do; Flutter and Android don\'t, so compare \"Before\" and \"After\".';

  @override
  String get tipStorageTitle => 'App storage';

  @override
  String get tipStorageBody =>
      'Every read, write and delete on stores you wrap with the SDK — AsyncStorage, MMKV, SharedPreferences, Hive and more — plus the current keys of supported stores, editable here.';

  @override
  String get tipStorageSteps =>
      'In \"History\", pick \"READ\", \"WRITE\" or \"DELETE\", and toggle store chips like \"AS\" or \"SP\"\nType a key in \"Filter keys...\" to see every operation on it; values match too\nClick a row to see that operation\'s value, size, store and time\nOpen \"Key-Value\" for a store\'s current keys, then \"Add key\", \"Edit value\" or \"Delete key\"\nPress \"Reload\" to fetch the latest contents from the app';

  @override
  String get tipStorageTip =>
      '\"Clear all\" in \"History\" only empties this log; \"Clear all\" in \"Key-Value\" deletes every key from the app\'s store.';

  @override
  String get tipDatabaseTitle => 'SQLite databases';

  @override
  String get tipDatabaseBody =>
      'Browse and query the SQLite databases your app registers with DevConnect.registerDatabase: tables with row counts, a SQL box and a results grid.';

  @override
  String get tipDatabaseSteps =>
      'Register the database in the app with DevConnect.registerDatabase\nClick a table to preview its first 50 rows\nEdit the SQL and press \"Run\" to run your own query\nPress \"Run\" again to re-query — results don\'t refresh on their own\nPress \"Reload tables\" to refresh the table list and row counts';

  @override
  String get tipDatabaseTip =>
      'Sort by adding ORDER BY to the query — the column headers don\'t sort.';

  @override
  String get tipPerformanceTitle => 'Performance profiler';

  @override
  String get tipPerformanceBody =>
      'Live charts of your app\'s FPS, CPU, memory and network activity, plus frame times, threads, battery, thermal state, disk I/O, startup time and ANRs when the SDK reports them.';

  @override
  String get tipPerformanceSteps =>
      'Select one device in the bottom bar — with \"All\" selected, charts mix every app\'s samples\nRead the live \"FPS\", \"MEM\", \"CPU\" and \"SLOW\" pills in the toolbar\nHover a chart to read the exact value and how long ago it arrived\nCheck \"System Status\" for startup time, battery drain, thermal state, disk I/O and ANRs\nUse \"Capture as image\" to save the charts as a PNG, and \"Clear\" to start over';

  @override
  String get tipPerformanceTip =>
      'Hover the red badge in the FPS row for average and worst slow-frame times, plus the last five slow frames.';

  @override
  String get tipLeaksTitle => 'Memory leak detection';

  @override
  String get tipLeaksBody =>
      'Leak warnings from your app: steady memory growth caught automatically by all three SDKs, more than 50 active timers on React Native, and anything you send with DevConnect.reportMemoryLeak.';

  @override
  String get tipLeaksSteps =>
      'Read the red, amber and blue counts in the toolbar: critical, warning and info\nClick a row for its \"Detail\", \"Retained Size\", \"Stack Trace\" and \"Metadata\", when reported\nCheck \"Metadata\" on memory-growth rows for each sample and the total growth in MB\nReport your own finds with DevConnect.reportMemoryLeak, such as undisposed controllers or streams\nPress \"Clear\", repeat the suspect flow and watch for new warnings';

  @override
  String get tipLeaksTip =>
      'By default memory is sampled every 10 seconds; a warning needs steady growth above 20 MB, and above 40 MB it turns critical.';

  @override
  String get tipBenchmarkTitle => 'Benchmarks';

  @override
  String get tipBenchmarkBody =>
      'Times the code you wrap with the SDK\'s benchmark calls, plus the App Startup and App Background runs every SDK records on its own.';

  @override
  String get tipBenchmarkSteps =>
      'Wrap code in DevConnect.benchmarkStart and benchmarkStop — React Native starts with benchmark\nMark phases with benchmarkStep (Flutter, React Native); Android runs have no steps\nClick a run to see its \"Start\", \"End\", \"Duration\" and a waterfall of its steps\nType in \"Search benchmarks...\" to filter the list and the stats bar\nPress \"Capture as image\" to save a run\'s panel as a PNG';

  @override
  String get tipBenchmarkTip =>
      'The stats bar covers every listed run — search one title to get \"Min\", \"Avg\" and \"P50\" for that benchmark alone.';

  @override
  String get tipErrorsTitle => 'Errors';

  @override
  String get tipErrorsBody =>
      'Lists the errors your app reports: React Native JavaScript errors and console.error calls, Flutter framework and Dart errors, and Android exceptions.';

  @override
  String get tipErrorsSteps =>
      'Flutter: start the app with DevConnect.initAndRunApp — plain init installs no error hooks\nClick the \"JS\", \"Native\", \"Android\" and \"iOS\" chips to show or hide a platform\nType in \"Search errors...\" to match the message, source or stack trace\nClick an error to open its \"Message\", \"Stack Trace\" and \"Details\" tabs\nOn a React Native stack, press \"Symbolicate\" to map frames to your source through Metro';

  @override
  String get tipErrorsTip =>
      'Flutter errors carry the Android or iOS tag of the device they ran on — there\'s no separate Flutter chip.';

  @override
  String get tipMockTitle => 'Mock Server';

  @override
  String get tipMockBody =>
      'Keeps fake API responses — method, URL regex, status, headers, body and an optional delay — and installs them on the selected device, so matching requests never reach the network.';

  @override
  String get tipMockSteps =>
      'Android: add DevConnect.mockServerInterceptor() to your OkHttpClient first\nSelect one device, press \"Add rule\", fill in the fields and press \"Save changes\"\nPress \"Push all\" — later edits, switches and deletes then reach the device on their own\nFlip a rule\'s switch to pause it, or open it and hold \"Hold to delete\" (Undo brings it back)\nPress \"Clear device\" to remove every rule from the device and stop syncing';

  @override
  String get tipMockTip =>
      'Rules live only in DevConnect\'s memory — quitting loses them, but a synced device gets them back when it reconnects.';

  @override
  String get tipHistoryTitle => 'History';

  @override
  String get tipHistoryBody =>
      'When a device disconnects and stays away 15 seconds, its logs, network calls, state changes and storage operations stay here as a read-only session until it reconnects or DevConnect quits.';

  @override
  String get tipHistorySteps =>
      'Click a session to open its \"All\", \"Logs\", \"Network\", \"State\" and \"Storage\" tabs\nRead each tile\'s disconnect time and its event counts\nPress × on a tile to remove that session\nPress \"Clear All\" to empty the list';

  @override
  String get tipHistoryTip =>
      'A session disappears as soon as the same device — or any app on the same IP — reconnects, so check it before relaunching.';

  @override
  String get tipDisplayTitle => 'Display';

  @override
  String get tipDisplayBody =>
      'Shows what your app sends with DevConnect.display() — a name, optional preview text, a JSON value and metadata. All three SDKs have it.';

  @override
  String get tipDisplaySteps =>
      'Call DevConnect.display with a name and an optional value, preview and metadata\nScan the rows, newest first: each shows the name, preview and time\nClick a row to see its \"Preview\", \"Value\" as JSON and \"Metadata\"\nPress \"Clear all\" to empty the list';

  @override
  String get tipDisplayTip =>
      'Each call adds a new row rather than replacing the last one — reuse a name to build a timeline.';

  @override
  String get tipAsyncTitle => 'Async operations';

  @override
  String get tipAsyncBody =>
      'Lists the async steps your app reports with DevConnect.reportAsyncOperation() — saga effects, tasks, background jobs — with status, duration and result or error. Nothing is tracked automatically.';

  @override
  String get tipAsyncSteps =>
      'Call reportAsyncOperation with a type, a description and the status start, resolve or reject\nOn React Native, wrap a promise in trackAsync to report it from start to finish\nRead the badge color: orange started, green resolved, red rejected\nClick a row for its details, \"Result\" and \"Metadata\"\nPress \"Clear all\" to empty the list';

  @override
  String get tipAsyncTip =>
      'Give related calls the same sagaName — selecting any of them lists the whole group under \"Saga timeline\".';

  @override
  String get tipLayoutTitle => 'Layout inspector';

  @override
  String get tipLayoutBody =>
      'Captures the app\'s current screen with its element tree — Flutter widgets, React Native components or Android views — and shows each element\'s position, size, padding, margin and props.';

  @override
  String get tipLayoutSteps =>
      'Select the device and press \"Capture\" to grab its screen and element tree\nHover the screenshot to highlight an element; click to select it\nOr pick it in the \"Element tree\", or search with \"Find by name or value\"\nTurn on \"App elements only\" to hide library widgets (Flutter, React Native)\nRead \"Properties\" — box model, position, size and props — or press \"Copy as JSON\"';

  @override
  String get tipLayoutTip =>
      'React Native sends a screenshot only after you call DevConnect.registerScreenshot() — without it you get outlines only.';

  @override
  String get settingsGroupConnection => 'Connection';

  @override
  String get settingsGroupConnectionDesc =>
      'Server, network addresses and USB.';

  @override
  String get settingsGroupDevices => 'Devices';

  @override
  String get settingsGroupDevicesDesc =>
      'Apps connected now and the ones seen before.';

  @override
  String get settingsGroupAppearance => 'Appearance';

  @override
  String get settingsGroupAppearanceDesc =>
      'Theme, language and the tabs that show.';

  @override
  String get settingsGroupData => 'Display & data';

  @override
  String get settingsGroupDataDesc =>
      'How details show, and how much history is kept.';

  @override
  String get settingsGroupGuides => 'Guides';

  @override
  String get settingsGroupGuidesDesc => 'Get started, shortcuts and tips.';

  @override
  String get settingsGroupSupport => 'Support';

  @override
  String get settingsGroupSupportDesc => 'Help keep DevConnect going.';

  @override
  String get tipsTabFeatures => 'Features';

  @override
  String get tipsTabShortcuts => 'Shortcuts';

  @override
  String get tipsTabConnect => 'Connect a device';

  @override
  String get tipsTabSdk => 'SDK setup';

  @override
  String get tipsTabAdvanced => 'Advanced';

  @override
  String get tipsSteps => 'Steps';

  @override
  String get tipsKeys => 'Keys';

  @override
  String get tipsProTip => 'Pro tip';

  @override
  String get tipsPrevious => 'Previous';

  @override
  String get tipsNext => 'Next';

  @override
  String get tipsDone => 'Done';

  @override
  String get tipsOpenPage => 'Open page';

  @override
  String get tipsCopyCode => 'Copy';

  @override
  String get tipsCodeCopied => 'Code copied';

  @override
  String get tipsClose => 'Close';

  @override
  String get pageGuide => 'How to use this page';

  @override
  String get guideReloadTitle => 'Reload the app';

  @override
  String get guideReloadSummary =>
      'Reload the inspected app from any DevConnect page, even while typing: Flutter rebuilds its widgets, React Native reloads from Metro, Android recreates the current activity.';

  @override
  String get guideReloadSteps =>
      '[⌘ R] Reload the selected app, or every connected app when none is selected\n[⇧ ⌘ R] Hot restart: runs a Flutter app\'s onHotRestartRequest, otherwise reloads like ⌘ R\nOr click the reload buttons in the bottom bar — their tooltips show the shortcut';

  @override
  String get guideReloadTip =>
      'Flutter\'s ⌘ R rebuilds the widget tree and keeps state, but doesn\'t load code edits — use your IDE\'s hot reload for that.';

  @override
  String get guideJsonSearchTitle => 'Search inside a body';

  @override
  String get guideJsonSearchSummary =>
      'Tree, JSON and the code view (TypeScript, Dart or Kotlin) each have their own search: it ignores case, highlights every match and scrolls to the current one.';

  @override
  String get guideJsonSearchSteps =>
      '[⌘ F] Jump to the view\'s search box — click inside the body first\n[↵] Go to the next match\n[⇧ ↵] Go to the previous match\n[Esc] Clear the search';

  @override
  String get guideJsonSearchTip =>
      'Tree search unfolds nodes and loads later pages to show up to 500 matches; JSON counts up to 100,000.';

  @override
  String get guideLayoutZoomTitle => 'Zoom a layout capture';

  @override
  String get guideLayoutZoomSummary =>
      'Zoom and frame a capture on the Layout page from the keyboard — the keys work as soon as a capture is shown.';

  @override
  String get guideLayoutZoomSteps =>
      '[⌘ +] Zoom in, 1.25× per press\n[⌘ −] Zoom out\n[⌘ 0] Actual size: 100% is the app\'s own screen size\n[⌘ 1] Fit the whole screen in the panel\n[⌘ 2] Zoom to the selected element';

  @override
  String get guideLayoutZoomTip =>
      'Click the zoom percentage for 50, 100, 200 or 400%; pinch to zoom and drag to pan.';

  @override
  String get guideLayoutMeasureTitle => 'Measure spacing';

  @override
  String get guideLayoutMeasureSummary =>
      'Hold Option to see the distances between the selected element and the one under the pointer, as design tools do.';

  @override
  String get guideLayoutMeasureSteps =>
      'Select an element: click it on the capture or pick it in the tree\n[⌥] Hold Option and point at another element\nRead the gaps between separate elements, or the insets when one holds the other\nRelease Option to see the hovered element\'s box model again';

  @override
  String get guideLayoutMeasureTip =>
      'Overlapping elements show no distance — measuring needs one element inside the other, or a gap between them.';

  @override
  String get guideLayoutTreeTitle => 'Walk the element tree';

  @override
  String get guideLayoutTreeSummary =>
      'Move through the captured element tree with the arrow keys once it has focus — click a row or an element on the capture.';

  @override
  String get guideLayoutTreeSteps =>
      '[↑ ↓] Move to the row above or below\n[→] Open the row; press again to step into its first child\n[←] Close the row; press again to step out to its parent\n[Esc] Clear the selection';

  @override
  String get guideLayoutTreeTip =>
      'Type in \"Find by name or value\" to search names, props and state; ↵ and ⇧ ↵ step through the matches.';

  @override
  String get guideAndroidEmulatorTitle => 'Android emulator';

  @override
  String get guideAndroidEmulatorSummary =>
      'Apps in the Android emulator reach this Mac at 10.0.2.2 (Genymotion: 10.0.3.2), so there\'s nothing to set up.';

  @override
  String get guideAndroidEmulatorSteps =>
      'Check that Settings › \"Connection\" › \"Server\" shows \"Server Running\"\nNative Android: pass enabled = BuildConfig.DEBUG to installForApp — it\'s off by default\nRun a debug build in the emulator; adb reverse isn\'t needed\nFind the app in the device bar at the bottom of the window';

  @override
  String get guideAndroidEmulatorTip =>
      'DevConnect starts on port 9090 at every launch; a port changed under \"Server\" lasts until you quit, and the SDK\'s port must match.';

  @override
  String get guideAndroidUsbTitle => 'Android phone over USB';

  @override
  String get guideAndroidUsbSummary =>
      'adb reverse points the phone\'s localhost at this Mac over the cable, so the app connects without Wi‑Fi.';

  @override
  String get guideAndroidUsbSteps =>
      'Turn on USB debugging, plug in the phone and allow this Mac when asked\nPress \"Run ADB Reverse\" in Settings › \"Connection\" › \"USB Connection\", or run the command below\nStart the app — restart a native Android app that was already running\nNot connecting? Press \"Devices\" there to check that adb sees the phone';

  @override
  String get guideAndroidUsbTip =>
      'Run it again after replugging, restarting adb or rebooting; with several devices plugged in, run adb -s with the phone\'s serial in Terminal.';

  @override
  String get guideIosSimulatorTitle => 'iOS simulator';

  @override
  String get guideIosSimulatorSummary =>
      'The simulator shares the Mac\'s network, so a debug build reaches DevConnect at localhost with no setup.';

  @override
  String get guideIosSimulatorSteps =>
      'Check that Settings › \"Connection\" › \"Server\" shows \"Server Running\"\nRun a debug build of the app in the simulator\nFind it in the device bar at the bottom of the window';

  @override
  String get guideIosSimulatorTip =>
      'Start order doesn\'t matter: React Native and Flutter apps keep retrying, so they join a few seconds after DevConnect starts.';

  @override
  String get guideIphoneTitle => 'iPhone';

  @override
  String get guideIphoneSummary =>
      'On the same Wi‑Fi as the Mac, a debug build usually finds DevConnect by itself; if it doesn\'t, set the Mac\'s address as host.';

  @override
  String get guideIphoneSteps =>
      'Put the iPhone and the Mac on the same Wi‑Fi — guest networks often block this\nRun the debug build and allow local network access when iOS asks\nWait a few seconds: React Native finds the Mac through Metro, Flutter through a broadcast\nNot listed? Copy the Mac\'s address from Settings › \"Connection\" › \"Network\"\nSet it as host in the SDK\'s init (code below), then restart the app';

  @override
  String get guideIphoneTip =>
      'A USB cable alone can\'t connect an iPhone app — the phone has to reach the Mac over the network.';

  @override
  String get guideTroubleshootTitle => 'App won\'t connect';

  @override
  String get guideTroubleshootSummary =>
      'Most connection problems come down to a few causes — check them in this order.';

  @override
  String get guideTroubleshootSteps =>
      'Settings › \"Connection\" › \"Server\" shows \"Server Running\" and no port error\nThe app is a debug build; native Android also needs enabled = BuildConfig.DEBUG\nThe SDK\'s port matches the server\'s — both start at 9090\nPhones share the Mac\'s Wi‑Fi, or Android\'s port is forwarded with adb reverse\nOn Wi‑Fi, macOS lets DevConnect accept incoming connections (System Settings › Network › Firewall)';

  @override
  String get guideTroubleshootTip =>
      'Still stuck? Set host to an address from Settings › \"Connection\" › \"Network\" and pass auto: false (Flutter: auto_: false) so reconnects keep it.';

  @override
  String get guideSdkReactNativeSummary =>
      'Install the package and call init once at startup — fetch and XHR (so axios too), console logs, errors and performance are captured from then on.';

  @override
  String get guideSdkReactNativeSteps =>
      'Add devconnect-manage-kit with yarn or npm (commands below)\nCall DevConnect.init once at startup, before the first request\nFor state, add devConnectReduxMiddleware (Redux), devConnectMiddleware (Zustand) or setupMobxSpy (MobX)\nRun a debug build — init does nothing in release unless you pass enabled: true';

  @override
  String get guideSdkReactNativeTip =>
      'init runs once per app start, so after changing host or port do a full reload — Fast Refresh keeps the old settings.';

  @override
  String get guideSdkFlutterSummary =>
      'Start the app through initAndRunApp: dart:io HTTP (http, Dio, Chopper…), print and debugPrint, errors and performance are captured with no extra code.';

  @override
  String get guideSdkFlutterSteps =>
      'Run flutter pub add devconnect_manage_kit\nStart the app with DevConnect.initAndRunApp in main(), passing an async runApp callback\nFor Riverpod or BLoC, call DevConnect.reportStateChange or reportBlocChange from your observer\nRun a debug build — profile and release builds stay off';

  @override
  String get guideSdkFlutterTip =>
      'Put Firebase and other startup code inside the runApp callback — calling ensureInitialized() before initAndRunApp causes a zone mismatch.';

  @override
  String get guideSdkAndroidSummary =>
      'Add the Maven Central dependency and call installForApp in Application.onCreate: println output, crashes, ANRs, performance and ViewModel state are captured; HTTP needs the OkHttp interceptor.';

  @override
  String get guideSdkAndroidSteps =>
      'Add io.github.buivietphi:devconnect-android:1.1.0 to app/build.gradle.kts\nCall DevConnect.installForApp in Application.onCreate with enabled = BuildConfig.DEBUG — it\'s off by default\nAdd DevConnect.okHttpInterceptor() to every OkHttpClient, Retrofit\'s included\nLog with DCLog instead of android.util.Log; for Timber, plant a Tree that calls DevConnectTimberHelper.log\nMake sure the app\'s manifest requests the INTERNET permission';

  @override
  String get guideSdkAndroidTip =>
      'The SDK looks for DevConnect once, at launch — start DevConnect (and adb reverse) first, or restart the app.';

  @override
  String get guideMockApiTitle => 'Mock an API';

  @override
  String get guideMockApiSummary =>
      'Answer matching requests with your own status, headers and body, optionally delayed, without touching the server or the app.';

  @override
  String get guideMockApiSteps =>
      'Select a device in the bottom bar, open \"Mock Server\" and press \"Add rule\"\nSet \"Method\", \"Status\", \"URL pattern\" (a regex matched anywhere in the URL) and the body\nPress \"Save changes\", then \"Push all\" — it sends the whole rule list, and later saves reach the device on their own\nCheck Network › \"Mock Audit\" for the requests a rule answered\nUse a rule\'s switch to pause it, or \"Clear device\" to remove every rule';

  @override
  String get guideMockApiTip =>
      'Android needs DevConnect.mockServerInterceptor() on OkHttp; React Native mocks fetch calls only, not axios or XMLHttpRequest.';

  @override
  String get guideNetworkConditionsTitle => 'Slow or offline network';

  @override
  String get guideNetworkConditionsSummary =>
      'Delay the apps\' HTTP requests or make them fail, without touching device settings — DevConnect\'s own connection keeps working.';

  @override
  String get guideNetworkConditionsSteps =>
      'In Network, open the gauge menu \"Network conditions\" in the toolbar\nPick \"Slow (+500 ms)\" or \"Slow 3G (~2 s)\" to delay every request\nPick \"Offline\" to make requests fail at once, like a dead network\nPick \"Normal\" when you\'re done — the icon stays highlighted until then\nOn Android only OkHttp traffic slows down, through DevConnect.okHttpInterceptor()';

  @override
  String get guideNetworkConditionsTip =>
      'It applies to every connected app, and to apps that connect later, until you pick \"Normal\".';

  @override
  String get guideReplayTitle => 'Replay a request';

  @override
  String get guideReplaySummary =>
      'Have the app send a captured request again — same method, URL, headers and body — without tapping through its screens.';

  @override
  String get guideReplaySteps =>
      'In Network, right-click a request and choose \"Replay request\"\nOr open the request and click the repeat icon in its header\nThe replay shows up as a new row in the list';

  @override
  String get guideReplayTip =>
      'Android reruns recent OkHttp calls through the app\'s own client and interceptors; Flutter and React Native resend the captured headers as they are.';

  @override
  String get guideHarExportTitle => 'Export to HAR';

  @override
  String get guideHarExportSummary =>
      'Save the requests Network lists as a standard HAR 1.2 file — headers, bodies, status and timing included — to open in other tools.';

  @override
  String get guideHarExportSteps =>
      'Narrow the \"HTTP\" list with the device, method, status and URL filters\nClick the download icon \"Export the listed requests as HAR\" in the toolbar\nChoose where to save the .har file\nOpen it in Chrome DevTools or Charles, or share it with your team';

  @override
  String get guideHarExportTip =>
      'Only what the HTTP list shows is saved, so your filters decide what\'s in the file; \"Protocols\" entries aren\'t included.';

  @override
  String get guideDatabaseQueryTitle => 'Query the app\'s database';

  @override
  String get guideDatabaseQuerySummary =>
      'Browse the tables of a SQLite database inside the app and run SQL on it, right from DevConnect.';

  @override
  String get guideDatabaseQuerySteps =>
      'Register the database in the app with DevConnect.registerDatabase (snippets below)\nOpen Database and click a table to preview its first 50 rows\nEdit the SQL and press \"Run\" — results stop at 1,000 rows\nClick \"Reload tables\" after the app changes its tables';

  @override
  String get guideDatabaseQueryTip =>
      'Queries run on the database of the last table you clicked, otherwise on the first one registered.';

  @override
  String get guideBigJsonTitle => 'Large bodies';

  @override
  String get guideBigJsonSummary =>
      'Big bodies open without freezing DevConnect: they\'re parsed in the background, and Tree and JSON build only what\'s on screen.';

  @override
  String get guideBigJsonSteps =>
      'Click \"Show … more\" under a long Tree list to load the next 200 items\nUse \"Copy value\" on long Tree strings — Tree shows their first 2,000 characters\nSwitch to JSON to scroll and search the whole document\nUse \"Copy JSON\" or \"Save as file\" there — both take the full body\nJSON lines over 20,000 characters show only their start; copy or save to get all of it';

  @override
  String get guideBigJsonTip =>
      'When the body is a list of objects, Tree offers \"Table\": it shows 500 rows, but \"Download table as CSV\" saves every matching row.';

  @override
  String get guideCustomCommandsTitle => 'Custom commands';

  @override
  String get guideCustomCommandsSummary =>
      'Run code inside the app from DevConnect — clear a cache, log out, seed test data — and see what it returns.';

  @override
  String get guideCustomCommandsSteps =>
      'Register a handler in the app with DevConnect.registerCommand (snippets below)\nOpen \"Custom commands\" and click a command the app listed, or type its name\nAdd arguments as a JSON object if the command needs any\nPress \"Run\", or ↵ in the \"Command\" field, and read the result below';

  @override
  String get guideCustomCommandsTip =>
      'Flutter and React Native handlers can be async; a thrown error shows as the result, and no answer times out after 10 seconds.';

  @override
  String get restart => 'Restart';

  @override
  String get serverAddressHint => 'Apps connect to this address.';

  @override
  String get serverStoppedHint => 'Start the server so apps can connect.';

  @override
  String get tabBenchmark => 'Benchmark';

  @override
  String get tabDisplay => 'Display';

  @override
  String get tabAsync => 'Async operations';

  @override
  String get tabLayout => 'Layout inspector';

  @override
  String get tabCommands => 'Custom commands';

  @override
  String get tabMockServer => 'Mock server';

  @override
  String get tabsAlwaysShown => 'All Events and Settings are always shown.';

  @override
  String get quickStartDesc =>
      'Install the SDK, start it in your app, then connect.';

  @override
  String get quickStartNext => 'Next — start it in your app';

  @override
  String get quickStartEmulator => 'Emulators connect on their own';

  @override
  String get quickStartWifi => 'Phone on Wi‑Fi';

  @override
  String get quickStartUsb => 'Android over USB';
}
