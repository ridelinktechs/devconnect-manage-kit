import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DevConnect Manage Tool'**
  String get appTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @autoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get autoScroll;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get oldestFirst;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @clearAllCache.
  ///
  /// In en, this message translates to:
  /// **'Clear All Cache'**
  String get clearAllCache;

  /// No description provided for @clearAllCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Disconnect every device and clear all in-memory data (logs, network captures, state changes, performance, etc.). Your settings (theme, language, port) are preserved.'**
  String get clearAllCacheDesc;

  /// No description provided for @clearAllCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all caches?\n\nThis will disconnect every connected device and erase every in-memory log, network capture, state change, performance metric, and benchmark result.\n\nYour settings (theme, language, port) will be kept.'**
  String get clearAllCacheConfirm;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'All caches cleared. Settings preserved.'**
  String get cacheCleared;

  /// No description provided for @clearAllCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear cache: {error}'**
  String clearAllCacheFailed(Object error);

  /// No description provided for @deviceHistory.
  ///
  /// In en, this message translates to:
  /// **'Cached Devices'**
  String get deviceHistory;

  /// No description provided for @deviceHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Every device that has connected to this desktop. Entries persist across restarts so you can see what was here before.'**
  String get deviceHistoryDesc;

  /// No description provided for @noDeviceHistory.
  ///
  /// In en, this message translates to:
  /// **'No devices have connected yet'**
  String get noDeviceHistory;

  /// No description provided for @deviceHistoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Connect a device via the SDK and it will appear here. Entries persist across restarts.'**
  String get deviceHistoryEmptyHint;

  /// No description provided for @restarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting…'**
  String get restarting;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get offline;

  /// No description provided for @markOnline.
  ///
  /// In en, this message translates to:
  /// **'Mark online'**
  String get markOnline;

  /// No description provided for @markOffline.
  ///
  /// In en, this message translates to:
  /// **'Mark offline'**
  String get markOffline;

  /// No description provided for @deviceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get deviceOnline;

  /// No description provided for @deviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get deviceOffline;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String lastSeen(Object time);

  /// No description provided for @firstSeen.
  ///
  /// In en, this message translates to:
  /// **'First seen {time}'**
  String firstSeen(Object time);

  /// No description provided for @forgetDevice.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forgetDevice;

  /// No description provided for @forgetAllOffline.
  ///
  /// In en, this message translates to:
  /// **'Forget All Offline'**
  String get forgetAllOffline;

  /// No description provided for @forgetAllDevices.
  ///
  /// In en, this message translates to:
  /// **'Forget All'**
  String get forgetAllDevices;

  /// No description provided for @forgetDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget this device?\n\nIt will be removed from the history. The next time it connects it will appear again as a new entry.'**
  String get forgetDeviceConfirm;

  /// No description provided for @forgetAllOfflineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget all offline devices?\n\nThis removes every entry that\'s not currently connected. Online devices are kept.'**
  String get forgetAllOfflineConfirm;

  /// No description provided for @forgetAllDevicesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget all cached devices?\n\nThis wipes the entire history, including online devices. They will reappear when they (re)connect.'**
  String get forgetAllDevicesConfirm;

  /// No description provided for @deviceForgotten.
  ///
  /// In en, this message translates to:
  /// **'Device forgotten'**
  String get deviceForgotten;

  /// No description provided for @devicesForgotten.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No devices forgotten} =1{1 device forgotten} other{{count} devices forgotten}}'**
  String devicesForgotten(num count);

  /// No description provided for @connectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{never connected} =1{1 connection} other{{count} connections}}'**
  String connectionCount(num count);

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @portOccupied.
  ///
  /// In en, this message translates to:
  /// **'Port {port} occupied'**
  String portOccupied(Object port);

  /// No description provided for @serverRestarted.
  ///
  /// In en, this message translates to:
  /// **'Server restarted'**
  String get serverRestarted;

  /// No description provided for @restartFailed.
  ///
  /// In en, this message translates to:
  /// **'Restart failed'**
  String get restartFailed;

  /// No description provided for @portStillInUse.
  ///
  /// In en, this message translates to:
  /// **'Port {port} is still in use'**
  String portStillInUse(Object port);

  /// No description provided for @couldNotRestart.
  ///
  /// In en, this message translates to:
  /// **'Could not restart on port {port}'**
  String couldNotRestart(Object port);

  /// No description provided for @listeningOnPort.
  ///
  /// In en, this message translates to:
  /// **'Listening on port {port}'**
  String listeningOnPort(Object port);

  /// No description provided for @waitingForReconnect.
  ///
  /// In en, this message translates to:
  /// **'Port {port} · waiting for devices'**
  String waitingForReconnect(Object port);

  /// No description provided for @reconnectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 reconnected} =1{1 device reconnected} other{{count} devices reconnected}}'**
  String reconnectedCount(num count);

  /// No description provided for @screenshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Screenshot saved'**
  String get screenshotSaved;

  /// No description provided for @screenshotFailed.
  ///
  /// In en, this message translates to:
  /// **'Screenshot failed'**
  String get screenshotFailed;

  /// No description provided for @reveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get reveal;

  /// No description provided for @captureFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get captureFull;

  /// No description provided for @captureTab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get captureTab;

  /// No description provided for @captureFullTooltip.
  ///
  /// In en, this message translates to:
  /// **'Capture full detail as image'**
  String get captureFullTooltip;

  /// No description provided for @captureTabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Capture current tab only'**
  String get captureTabTooltip;

  /// No description provided for @captureAsImage.
  ///
  /// In en, this message translates to:
  /// **'Capture as image'**
  String get captureAsImage;

  /// No description provided for @captureDetailAsImage.
  ///
  /// In en, this message translates to:
  /// **'Capture detail as image'**
  String get captureDetailAsImage;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @filterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter...'**
  String get filterHint;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get key;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @json.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get json;

  /// No description provided for @tree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get tree;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @raw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get raw;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @pretty.
  ///
  /// In en, this message translates to:
  /// **'Pretty'**
  String get pretty;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @noHeaders.
  ///
  /// In en, this message translates to:
  /// **'No headers'**
  String get noHeaders;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get inProgress;

  /// No description provided for @inProgressDots.
  ///
  /// In en, this message translates to:
  /// **'In Progress...'**
  String get inProgressDots;

  /// No description provided for @hideShowTooltip.
  ///
  /// In en, this message translates to:
  /// **'{action} {label}'**
  String hideShowTooltip(Object action, Object label);

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get steps;

  /// No description provided for @portInUse.
  ///
  /// In en, this message translates to:
  /// **'Port is already in use. Close the other app using this port, or pick a different port in Settings.'**
  String get portInUse;

  /// No description provided for @portInUseShort.
  ///
  /// In en, this message translates to:
  /// **'Port {port} is already in use. Close the other app using this port, or enter a different port above and press Start.'**
  String portInUseShort(Object port);

  /// No description provided for @failedToStartServer.
  ///
  /// In en, this message translates to:
  /// **'Failed to start server: {msg}'**
  String failedToStartServer(Object msg);

  /// No description provided for @failedToStartServerOnPort.
  ///
  /// In en, this message translates to:
  /// **'Failed to start server on port {port}: {msg}'**
  String failedToStartServerOnPort(Object msg, Object port);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @serverRunning.
  ///
  /// In en, this message translates to:
  /// **'Server Running'**
  String get serverRunning;

  /// No description provided for @serverStopped.
  ///
  /// In en, this message translates to:
  /// **'Server Stopped'**
  String get serverStopped;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @deviceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 devices} =1{1 device} other{{count} devices}}'**
  String deviceCount(num count);

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @hostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get hostname;

  /// No description provided for @noNetworkInterfaces.
  ///
  /// In en, this message translates to:
  /// **'No network interfaces found'**
  String get noNetworkInterfaces;

  /// No description provided for @copiedIp.
  ///
  /// In en, this message translates to:
  /// **'Copied {ip}'**
  String copiedIp(Object ip);

  /// No description provided for @connectedDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected Devices ({count})'**
  String connectedDevices(Object count);

  /// No description provided for @noDevicesConnected.
  ///
  /// In en, this message translates to:
  /// **'No devices connected'**
  String get noDevicesConnected;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @bottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get bottom;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @tabVisibility.
  ///
  /// In en, this message translates to:
  /// **'Tab Visibility'**
  String get tabVisibility;

  /// No description provided for @tabVisibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle which tabs are visible. Disabled tabs show a lock icon and their data is excluded from All Events.'**
  String get tabVisibilityDesc;

  /// No description provided for @detailView.
  ///
  /// In en, this message translates to:
  /// **'Detail View'**
  String get detailView;

  /// No description provided for @detailViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Remembers how request/response bodies are shown and controls tab switching animation.'**
  String get detailViewDesc;

  /// No description provided for @bodyView.
  ///
  /// In en, this message translates to:
  /// **'Body view'**
  String get bodyView;

  /// No description provided for @tabAnimation.
  ///
  /// In en, this message translates to:
  /// **'Tab animation'**
  String get tabAnimation;

  /// No description provided for @tabAnimationDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tabAnimationDuration;

  /// No description provided for @codeModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Code mode exports as TypeScript / Dart / Kotlin based on the connected SDK.'**
  String get codeModeDesc;

  /// No description provided for @usbConnection.
  ///
  /// In en, this message translates to:
  /// **'USB Connection'**
  String get usbConnection;

  /// No description provided for @android.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get android;

  /// No description provided for @ios.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get ios;

  /// No description provided for @runAdbReverse.
  ///
  /// In en, this message translates to:
  /// **'Run ADB Reverse'**
  String get runAdbReverse;

  /// No description provided for @adbNotFound.
  ///
  /// In en, this message translates to:
  /// **'adb not found.\nHOME={home}'**
  String adbNotFound(Object home);

  /// No description provided for @adbReverseOk.
  ///
  /// In en, this message translates to:
  /// **'adb reverse OK ({path})'**
  String adbReverseOk(Object path);

  /// No description provided for @adbError.
  ///
  /// In en, this message translates to:
  /// **'adb error: {error}'**
  String adbError(Object error);

  /// No description provided for @adbException.
  ///
  /// In en, this message translates to:
  /// **'adb exception: {error}'**
  String adbException(Object error);

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @adbDevices.
  ///
  /// In en, this message translates to:
  /// **'ADB Devices'**
  String get adbDevices;

  /// No description provided for @wifiAutoConnect.
  ///
  /// In en, this message translates to:
  /// **'WiFi auto-connects if same network. USB: install iproxy.'**
  String get wifiAutoConnect;

  /// No description provided for @quickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStart;

  /// No description provided for @quickStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Three steps to wire up your app. Click any platform tab to see the snippet for that SDK.'**
  String get quickStartDesc;

  /// No description provided for @installSdk.
  ///
  /// In en, this message translates to:
  /// **'Install SDK'**
  String get installSdk;

  /// No description provided for @initialize.
  ///
  /// In en, this message translates to:
  /// **'Initialize'**
  String get initialize;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @supportDevConnect.
  ///
  /// In en, this message translates to:
  /// **'Support DevConnect'**
  String get supportDevConnect;

  /// No description provided for @supportDevConnectDesc.
  ///
  /// In en, this message translates to:
  /// **'DevConnect Manage Tool is free and open source. If it helps your workflow, consider supporting development.'**
  String get supportDevConnectDesc;

  /// No description provided for @kofi.
  ///
  /// In en, this message translates to:
  /// **'Ko-fi'**
  String get kofi;

  /// No description provided for @paypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get paypal;

  /// No description provided for @ethernet.
  ///
  /// In en, this message translates to:
  /// **'Ethernet'**
  String get ethernet;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get wifi;

  /// No description provided for @vpn.
  ///
  /// In en, this message translates to:
  /// **'VPN'**
  String get vpn;

  /// No description provided for @bridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get bridge;

  /// No description provided for @loopback.
  ///
  /// In en, this message translates to:
  /// **'Loopback'**
  String get loopback;

  /// No description provided for @console.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get console;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @memoryLeaks.
  ///
  /// In en, this message translates to:
  /// **'Memory Leaks'**
  String get memoryLeaks;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noNetworkRequests.
  ///
  /// In en, this message translates to:
  /// **'No network requests'**
  String get noNetworkRequests;

  /// No description provided for @apiCallsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'API calls will appear here in real-time'**
  String get apiCallsAppearHere;

  /// No description provided for @networkTitle.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkTitle;

  /// No description provided for @filterUrls.
  ///
  /// In en, this message translates to:
  /// **'Filter URLs...'**
  String get filterUrls;

  /// No description provided for @copyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get copyUrl;

  /// No description provided for @urlCopied.
  ///
  /// In en, this message translates to:
  /// **'URL copied'**
  String get urlCopied;

  /// No description provided for @copyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Path'**
  String get copyPath;

  /// No description provided for @pathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get pathCopied;

  /// No description provided for @copyCurl.
  ///
  /// In en, this message translates to:
  /// **'Copy cURL'**
  String get copyCurl;

  /// No description provided for @curlCopied.
  ///
  /// In en, this message translates to:
  /// **'cURL copied'**
  String get curlCopied;

  /// No description provided for @copyRequest.
  ///
  /// In en, this message translates to:
  /// **'Copy Request'**
  String get copyRequest;

  /// No description provided for @requestCopied.
  ///
  /// In en, this message translates to:
  /// **'Request copied'**
  String get requestCopied;

  /// No description provided for @copyResponse.
  ///
  /// In en, this message translates to:
  /// **'Copy Response'**
  String get copyResponse;

  /// No description provided for @responseCopied.
  ///
  /// In en, this message translates to:
  /// **'Response copied'**
  String get responseCopied;

  /// No description provided for @requestBody.
  ///
  /// In en, this message translates to:
  /// **'Request Body'**
  String get requestBody;

  /// No description provided for @responseBody.
  ///
  /// In en, this message translates to:
  /// **'Response Body'**
  String get responseBody;

  /// No description provided for @requestHeaders.
  ///
  /// In en, this message translates to:
  /// **'Request Headers'**
  String get requestHeaders;

  /// No description provided for @responseHeaders.
  ///
  /// In en, this message translates to:
  /// **'Response Headers'**
  String get responseHeaders;

  /// No description provided for @headers.
  ///
  /// In en, this message translates to:
  /// **'Headers'**
  String get headers;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get response;

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timing;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No {label}'**
  String noLabel(Object label);

  /// No description provided for @noStorageData.
  ///
  /// In en, this message translates to:
  /// **'No storage data'**
  String get noStorageData;

  /// No description provided for @storageEntriesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'SharedPreferences, AsyncStorage, and Hive entries appear here'**
  String get storageEntriesAppearHere;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// No description provided for @filterKeys.
  ///
  /// In en, this message translates to:
  /// **'Filter keys...'**
  String get filterKeys;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'READ'**
  String get read;

  /// No description provided for @write.
  ///
  /// In en, this message translates to:
  /// **'WRITE'**
  String get write;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get noEventsYet;

  /// No description provided for @startAppToSeeEvents.
  ///
  /// In en, this message translates to:
  /// **'Start your app with DevConnect SDK to see events'**
  String get startAppToSeeEvents;

  /// No description provided for @eventsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Events will appear here in real-time'**
  String get eventsAppearHere;

  /// No description provided for @allEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Events'**
  String get allEventsTitle;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @searchEvents.
  ///
  /// In en, this message translates to:
  /// **'Search events...'**
  String get searchEvents;

  /// No description provided for @logDetail.
  ///
  /// In en, this message translates to:
  /// **'Log Detail'**
  String get logDetail;

  /// No description provided for @networkDetail.
  ///
  /// In en, this message translates to:
  /// **'Network Detail'**
  String get networkDetail;

  /// No description provided for @stateDetail.
  ///
  /// In en, this message translates to:
  /// **'State Detail'**
  String get stateDetail;

  /// No description provided for @storageDetail.
  ///
  /// In en, this message translates to:
  /// **'Storage Detail'**
  String get storageDetail;

  /// No description provided for @displayDetail.
  ///
  /// In en, this message translates to:
  /// **'Display Detail'**
  String get displayDetail;

  /// No description provided for @asyncOperation.
  ///
  /// In en, this message translates to:
  /// **'Async Operation'**
  String get asyncOperation;

  /// No description provided for @errorDetail.
  ///
  /// In en, this message translates to:
  /// **'Error Detail'**
  String get errorDetail;

  /// No description provided for @tag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tag;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @stackTrace.
  ///
  /// In en, this message translates to:
  /// **'Stack Trace'**
  String get stackTrace;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get noLogsYet;

  /// No description provided for @connectDeviceToSeeLogs.
  ///
  /// In en, this message translates to:
  /// **'Connect a device and start logging to see entries here'**
  String get connectDeviceToSeeLogs;

  /// No description provided for @consoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get consoleTitle;

  /// No description provided for @searchLogs.
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get searchLogs;

  /// No description provided for @clearConsole.
  ///
  /// In en, this message translates to:
  /// **'Clear console'**
  String get clearConsole;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get copyMessage;

  /// No description provided for @logCopied.
  ///
  /// In en, this message translates to:
  /// **'Log copied'**
  String get logCopied;

  /// No description provided for @closePanel.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get closePanel;

  /// No description provided for @hideShowLogs.
  ///
  /// In en, this message translates to:
  /// **'{action} {label} logs'**
  String hideShowLogs(Object action, Object label);

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @searchErrors.
  ///
  /// In en, this message translates to:
  /// **'Search errors...'**
  String get searchErrors;

  /// No description provided for @clearErrors.
  ///
  /// In en, this message translates to:
  /// **'Clear errors'**
  String get clearErrors;

  /// No description provided for @totalErrors.
  ///
  /// In en, this message translates to:
  /// **'Total Errors'**
  String get totalErrors;

  /// No description provided for @fatalCrash.
  ///
  /// In en, this message translates to:
  /// **'Fatal/Crash'**
  String get fatalCrash;

  /// No description provided for @noErrorsCaptured.
  ///
  /// In en, this message translates to:
  /// **'No errors captured'**
  String get noErrorsCaptured;

  /// No description provided for @errorsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Errors from React Native and Flutter will appear here'**
  String get errorsAppearHere;

  /// No description provided for @stackTraceCopied.
  ///
  /// In en, this message translates to:
  /// **'Stack trace copied'**
  String get stackTraceCopied;

  /// No description provided for @noStackTrace.
  ///
  /// In en, this message translates to:
  /// **'No stack trace available'**
  String get noStackTrace;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfo;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @hideShowErrors.
  ///
  /// In en, this message translates to:
  /// **'{action} {label} errors'**
  String hideShowErrors(Object action, Object label);

  /// No description provided for @noStateChanges.
  ///
  /// In en, this message translates to:
  /// **'No state changes'**
  String get noStateChanges;

  /// No description provided for @stateChangesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Redux, BLoC, Riverpod, and MobX state changes appear here'**
  String get stateChangesAppearHere;

  /// No description provided for @stateInspectorTitle.
  ///
  /// In en, this message translates to:
  /// **'State Inspector'**
  String get stateInspectorTitle;

  /// No description provided for @changesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} changes'**
  String changesCount(Object count);

  /// No description provided for @changeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 changes} =1{1 change} other{{count} changes}}'**
  String changeCount(num count);

  /// No description provided for @filterActions.
  ///
  /// In en, this message translates to:
  /// **'Filter actions...'**
  String get filterActions;

  /// No description provided for @newestAtTop.
  ///
  /// In en, this message translates to:
  /// **'Newest at top'**
  String get newestAtTop;

  /// No description provided for @newestAtBottom.
  ///
  /// In en, this message translates to:
  /// **'Newest at bottom'**
  String get newestAtBottom;

  /// No description provided for @noChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get noChanges;

  /// No description provided for @diff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get diff;

  /// No description provided for @before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// No description provided for @after.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// No description provided for @noChangesDetected.
  ///
  /// In en, this message translates to:
  /// **'No changes detected'**
  String get noChangesDetected;

  /// No description provided for @noBenchmarks.
  ///
  /// In en, this message translates to:
  /// **'No Benchmarks'**
  String get noBenchmarks;

  /// No description provided for @useBenchmarkSdk.
  ///
  /// In en, this message translates to:
  /// **'Use benchmarkStart/Step/Stop in your SDK to measure performance'**
  String get useBenchmarkSdk;

  /// No description provided for @benchmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Benchmarks'**
  String get benchmarksTitle;

  /// No description provided for @searchBenchmarks.
  ///
  /// In en, this message translates to:
  /// **'Search benchmarks...'**
  String get searchBenchmarks;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @avg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avg;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @p50.
  ///
  /// In en, this message translates to:
  /// **'P50'**
  String get p50;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'Steps ({count})'**
  String stepsCount(Object count);

  /// No description provided for @noIntermediateSteps.
  ///
  /// In en, this message translates to:
  /// **'No intermediate steps recorded'**
  String get noIntermediateSteps;

  /// No description provided for @noPerformanceData.
  ///
  /// In en, this message translates to:
  /// **'No Performance Data'**
  String get noPerformanceData;

  /// No description provided for @connectAppToProfile.
  ///
  /// In en, this message translates to:
  /// **'Connect an app with DevConnect SDK to start profiling'**
  String get connectAppToProfile;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// No description provided for @performanceProfiler.
  ///
  /// In en, this message translates to:
  /// **'Performance Profiler'**
  String get performanceProfiler;

  /// No description provided for @slowFrames.
  ///
  /// In en, this message translates to:
  /// **'Slow Frames: {count}'**
  String slowFrames(Object count);

  /// No description provided for @systemStatus.
  ///
  /// In en, this message translates to:
  /// **'System Status'**
  String get systemStatus;

  /// No description provided for @startup.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get startup;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @emulator.
  ///
  /// In en, this message translates to:
  /// **'Emulator'**
  String get emulator;

  /// No description provided for @drainRate.
  ///
  /// In en, this message translates to:
  /// **'Drain Rate'**
  String get drainRate;

  /// No description provided for @thermal.
  ///
  /// In en, this message translates to:
  /// **'Thermal'**
  String get thermal;

  /// No description provided for @diskRead.
  ///
  /// In en, this message translates to:
  /// **'Disk Read'**
  String get diskRead;

  /// No description provided for @diskWrite.
  ///
  /// In en, this message translates to:
  /// **'Disk Write'**
  String get diskWrite;

  /// No description provided for @anr.
  ///
  /// In en, this message translates to:
  /// **'ANR'**
  String get anr;

  /// No description provided for @charging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get charging;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @serious.
  ///
  /// In en, this message translates to:
  /// **'Serious'**
  String get serious;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @reqs.
  ///
  /// In en, this message translates to:
  /// **'reqs'**
  String get reqs;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'live'**
  String get live;

  /// No description provided for @reqPerSec.
  ///
  /// In en, this message translates to:
  /// **'req/s'**
  String get reqPerSec;

  /// No description provided for @err.
  ///
  /// In en, this message translates to:
  /// **'err'**
  String get err;

  /// No description provided for @waitingForRequests.
  ///
  /// In en, this message translates to:
  /// **'Waiting for requests...'**
  String get waitingForRequests;

  /// No description provided for @waitingForData.
  ///
  /// In en, this message translates to:
  /// **'Waiting for data...'**
  String get waitingForData;

  /// No description provided for @noMemoryLeaksDetected.
  ///
  /// In en, this message translates to:
  /// **'No Memory Leaks Detected'**
  String get noMemoryLeaksDetected;

  /// No description provided for @connectAppToMonitorLeaks.
  ///
  /// In en, this message translates to:
  /// **'Connect an app with DevConnect SDK to monitor memory leaks'**
  String get connectAppToMonitorLeaks;

  /// No description provided for @memoryLeakDetection.
  ///
  /// In en, this message translates to:
  /// **'Memory Leak Detection'**
  String get memoryLeakDetection;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// No description provided for @retainedSize.
  ///
  /// In en, this message translates to:
  /// **'Retained Size'**
  String get retainedSize;

  /// No description provided for @timestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get timestamp;

  /// No description provided for @undisposedController.
  ///
  /// In en, this message translates to:
  /// **'Undisposed Controller'**
  String get undisposedController;

  /// No description provided for @undisposedStream.
  ///
  /// In en, this message translates to:
  /// **'Undisposed Stream'**
  String get undisposedStream;

  /// No description provided for @undisposedTimer.
  ///
  /// In en, this message translates to:
  /// **'Undisposed Timer'**
  String get undisposedTimer;

  /// No description provided for @undisposedAnimation.
  ///
  /// In en, this message translates to:
  /// **'Undisposed Animation'**
  String get undisposedAnimation;

  /// No description provided for @widgetLeak.
  ///
  /// In en, this message translates to:
  /// **'Widget Leak'**
  String get widgetLeak;

  /// No description provided for @growingCollection.
  ///
  /// In en, this message translates to:
  /// **'Growing Collection'**
  String get growingCollection;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'ja', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return SZhCn();
          case 'TW':
            return SZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'fr':
      return SFr();
    case 'ja':
      return SJa();
    case 'vi':
      return SVi();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
