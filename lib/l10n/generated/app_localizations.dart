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
/// import 'generated/app_localizations.dart';
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

  /// No description provided for @restartServer.
  ///
  /// In en, this message translates to:
  /// **'Restart server'**
  String get restartServer;

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

  /// No description provided for @reloadApp.
  ///
  /// In en, this message translates to:
  /// **'Reload app'**
  String get reloadApp;

  /// No description provided for @reloadAppHotReload.
  ///
  /// In en, this message translates to:
  /// **'Hot reload'**
  String get reloadAppHotReload;

  /// No description provided for @reloadAppHotRestart.
  ///
  /// In en, this message translates to:
  /// **'Hot restart'**
  String get reloadAppHotRestart;

  /// No description provided for @reloadAppMetro.
  ///
  /// In en, this message translates to:
  /// **'Reload Metro'**
  String get reloadAppMetro;

  /// No description provided for @reloadAppNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices connected'**
  String get reloadAppNoDevices;

  /// No description provided for @reloadSent.
  ///
  /// In en, this message translates to:
  /// **'Reload sent'**
  String get reloadSent;

  /// No description provided for @sentReloadTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No devices targeted} =1{Reload dispatched to 1 device} other{Reload dispatched to {count} devices}}'**
  String sentReloadTo(num count);

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

  /// No description provided for @dataRetention.
  ///
  /// In en, this message translates to:
  /// **'Data Retention'**
  String get dataRetention;

  /// No description provided for @dataRetentionDesc.
  ///
  /// In en, this message translates to:
  /// **'Hard cap applied to each per-feature list. When a list exceeds the limit, oldest entries are dropped FIFO. Pending async ops are preserved.'**
  String get dataRetentionDesc;

  /// No description provided for @maxItems.
  ///
  /// In en, this message translates to:
  /// **'Max items'**
  String get maxItems;

  /// No description provided for @dataRetentionHelper.
  ///
  /// In en, this message translates to:
  /// **'Unlimited keeps every entry. Lower values free memory but lose history.'**
  String get dataRetentionHelper;

  /// No description provided for @allEventsDisplay.
  ///
  /// In en, this message translates to:
  /// **'All Events Display'**
  String get allEventsDisplay;

  /// No description provided for @allEventsDisplayDesc.
  ///
  /// In en, this message translates to:
  /// **'View-only filter for the aggregated All Events list. The underlying logs are not deleted — flip back to Unlimited to restore.'**
  String get allEventsDisplayDesc;

  /// No description provided for @allEventsDisplayHelper.
  ///
  /// In en, this message translates to:
  /// **'Lower values keep the most recent N entries visible at the cost of older history.'**
  String get allEventsDisplayHelper;

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

  /// No description provided for @treeModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Tree mode shows the data as an expandable, collapsible node hierarchy. Best for navigating deeply nested values.'**
  String get treeModeDesc;

  /// No description provided for @jsonModeDesc.
  ///
  /// In en, this message translates to:
  /// **'JSON mode renders the data as a single, syntax-highlighted, copy-friendly JSON document.'**
  String get jsonModeDesc;

  /// No description provided for @captureDataJson.
  ///
  /// In en, this message translates to:
  /// **'Capture data (key + value in current mode)'**
  String get captureDataJson;

  /// No description provided for @captureDataText.
  ///
  /// In en, this message translates to:
  /// **'Capture data (key + value as text)'**
  String get captureDataText;

  /// No description provided for @copyKey.
  ///
  /// In en, this message translates to:
  /// **'Copy key'**
  String get copyKey;

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
  /// **'An iPhone connects over Wi‑Fi: put it on the same network as this Mac. A USB cable alone can\'t connect it.'**
  String get wifiAutoConnect;

  /// No description provided for @quickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStart;

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

  /// No description provided for @clearStaleButton.
  ///
  /// In en, this message translates to:
  /// **'Stale ({count})'**
  String clearStaleButton(Object count);

  /// No description provided for @clearStaleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear {count} pending request(s) with no response for over 10 minutes'**
  String clearStaleTooltip(Object count);

  /// No description provided for @clearStaleSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count} stale request(s) (pending > 10min)'**
  String clearStaleSnackbar(Object count);

  /// No description provided for @memorySafetyOverflow.
  ///
  /// In en, this message translates to:
  /// **'Memory safety: dropped {count} stale network entry(ies) from the open-trips cache'**
  String memorySafetyOverflow(Object count);

  /// No description provided for @sdkTipsPill.
  ///
  /// In en, this message translates to:
  /// **'Tips lib'**
  String get sdkTipsPill;

  /// No description provided for @sdkTipsHeader.
  ///
  /// In en, this message translates to:
  /// **'Library compatibility'**
  String get sdkTipsHeader;

  /// No description provided for @sdkTipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To ensure all data is fully displayed, make sure the libraries are the latest version.'**
  String get sdkTipsSubtitle;

  /// No description provided for @sdkTipsFlutter.
  ///
  /// In en, this message translates to:
  /// **'Flutter'**
  String get sdkTipsFlutter;

  /// No description provided for @sdkTipsReactNative.
  ///
  /// In en, this message translates to:
  /// **'React Native'**
  String get sdkTipsReactNative;

  /// No description provided for @sdkTipsAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get sdkTipsAndroid;

  /// No description provided for @sdkTipsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String sdkTipsVersionLabel(Object version);

  /// No description provided for @sdkTipsPillLatest.
  ///
  /// In en, this message translates to:
  /// **'v{version} · Latest'**
  String sdkTipsPillLatest(Object version);

  /// No description provided for @sdkTipsPillUpdate.
  ///
  /// In en, this message translates to:
  /// **'v{version} · Update'**
  String sdkTipsPillUpdate(Object version);

  /// No description provided for @sdkTipsInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get sdkTipsInstalled;

  /// No description provided for @sdkTipsLatestLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get sdkTipsLatestLabel;

  /// No description provided for @sdkTipsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get sdkTipsUpdate;

  /// No description provided for @sdkTipsChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get sdkTipsChecking;

  /// No description provided for @sdkTipsOffline.
  ///
  /// In en, this message translates to:
  /// **'Live check unavailable'**
  String get sdkTipsOffline;

  /// No description provided for @sdkTipsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get sdkTipsRetry;

  /// No description provided for @sdkTipsCheckProject.
  ///
  /// In en, this message translates to:
  /// **'Run this in your project to see the installed version:'**
  String get sdkTipsCheckProject;

  /// No description provided for @sdkTipsInstallLatest.
  ///
  /// In en, this message translates to:
  /// **'Install the latest version:'**
  String get sdkTipsInstallLatest;

  /// No description provided for @appUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'DevConnect version'**
  String get appUpdateTitle;

  /// No description provided for @appUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available.'**
  String get appUpdateAvailable;

  /// No description provided for @appUpdateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version.'**
  String get appUpdateUpToDate;

  /// No description provided for @appUpdateViewRelease.
  ///
  /// In en, this message translates to:
  /// **'View release'**
  String get appUpdateViewRelease;

  /// No description provided for @devicesConnected.
  ///
  /// In en, this message translates to:
  /// **'{count} connected'**
  String devicesConnected(Object count);

  /// No description provided for @devicesAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get devicesAll;

  /// No description provided for @devicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 device} other{{count} devices}}'**
  String devicesCount(num count);

  /// No description provided for @commandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom commands'**
  String get commandsTitle;

  /// No description provided for @commandsNoDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect a device to run its commands.'**
  String get commandsNoDevice;

  /// No description provided for @commandsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No commands registered yet. Add one in the app with DevConnect.registerCommand(name, handler), or type a command name to run it.'**
  String get commandsEmptyHint;

  /// No description provided for @commandsName.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get commandsName;

  /// No description provided for @commandsArgs.
  ///
  /// In en, this message translates to:
  /// **'Arguments — JSON object, optional'**
  String get commandsArgs;

  /// No description provided for @commandsArgsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Arguments must be a JSON object.'**
  String get commandsArgsInvalid;

  /// No description provided for @commandsRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get commandsRun;

  /// No description provided for @commandsTarget.
  ///
  /// In en, this message translates to:
  /// **'Runs on {device}'**
  String commandsTarget(Object device);

  /// No description provided for @commandsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Results of the commands you run show up here.'**
  String get commandsHistoryEmpty;

  /// No description provided for @commandsNoResponse.
  ///
  /// In en, this message translates to:
  /// **'No response. Is the command registered in the app?'**
  String get commandsNoResponse;

  /// No description provided for @dbTables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get dbTables;

  /// No description provided for @dbRefresh.
  ///
  /// In en, this message translates to:
  /// **'Reload tables'**
  String get dbRefresh;

  /// No description provided for @dbNoDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect a device to browse its databases.'**
  String get dbNoDevice;

  /// No description provided for @dbSelectDevice.
  ///
  /// In en, this message translates to:
  /// **'Select a device in the bottom bar to browse its databases.'**
  String get dbSelectDevice;

  /// No description provided for @dbNoDatabases.
  ///
  /// In en, this message translates to:
  /// **'No database registered. Add one in the app with DevConnect.registerDatabase(name, query), then reload tables.'**
  String get dbNoDatabases;

  /// No description provided for @dbRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get dbRun;

  /// No description provided for @dbRunHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a table or write SQL'**
  String get dbRunHint;

  /// No description provided for @dbRunHintSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Picking a table previews its first 50 rows.'**
  String get dbRunHintSubtitle;

  /// No description provided for @dbRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row} other{{count} rows}}'**
  String dbRows(num count);

  /// No description provided for @dbTruncated.
  ///
  /// In en, this message translates to:
  /// **'first {count} only'**
  String dbTruncated(Object count);

  /// No description provided for @dbNoResponse.
  ///
  /// In en, this message translates to:
  /// **'No response. Does the app register a database with DevConnect.registerDatabase? It needs the latest SDK.'**
  String get dbNoResponse;

  /// No description provided for @stateToolsTab.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get stateToolsTab;

  /// No description provided for @stateNoDevice.
  ///
  /// In en, this message translates to:
  /// **'Select a device in the bottom bar to watch, snapshot and drive its state.'**
  String get stateNoDevice;

  /// No description provided for @stateNoState.
  ///
  /// In en, this message translates to:
  /// **'This device hasn\'t reported any state yet.'**
  String get stateNoState;

  /// No description provided for @stateSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get stateSubscriptions;

  /// No description provided for @stateSubscriptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Pin a path to watch its live value, e.g. auth.user.name or cart.items[0].price. Works on every platform with no app code; it reads the state of the latest change: the whole store with Redux, the store or provider that changed last with Zustand, MobX, Riverpod or a ViewModel.'**
  String get stateSubscriptionsHint;

  /// No description provided for @statePinPath.
  ///
  /// In en, this message translates to:
  /// **'Pin path'**
  String get statePinPath;

  /// No description provided for @statePathMissing.
  ///
  /// In en, this message translates to:
  /// **'(not in state)'**
  String get statePathMissing;

  /// No description provided for @stateRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get stateRemove;

  /// No description provided for @stateSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Snapshots'**
  String get stateSnapshots;

  /// No description provided for @stateSnapshotsHint.
  ///
  /// In en, this message translates to:
  /// **'Save the latest state, then send it back to reproduce a bug or skip a long form. Saving works everywhere; Restore needs the app to apply the state with onStateRestore on React Native, Flutter and Android.'**
  String get stateSnapshotsHint;

  /// No description provided for @stateTakeSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Take snapshot'**
  String get stateTakeSnapshot;

  /// No description provided for @stateKeys.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 key} other{{count} keys}}'**
  String stateKeys(num count);

  /// No description provided for @stateRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get stateRestore;

  /// No description provided for @stateRestoreHere.
  ///
  /// In en, this message translates to:
  /// **'Restore the app\'s state to this point'**
  String get stateRestoreHere;

  /// No description provided for @stateSaveSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Save as snapshot'**
  String get stateSaveSnapshot;

  /// No description provided for @stateSnapshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Snapshot saved'**
  String get stateSnapshotSaved;

  /// No description provided for @stateRestoreSent.
  ///
  /// In en, this message translates to:
  /// **'State restore sent'**
  String get stateRestoreSent;

  /// No description provided for @stateDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch action'**
  String get stateDispatch;

  /// No description provided for @stateDispatchHint.
  ///
  /// In en, this message translates to:
  /// **'Send an action, a JSON object with a \"type\" such as \"LOGOUT\", to the app. React Native runs it in the Redux store wired with connectReduxStore(store); Flutter and Android pass it to onReduxDispatch.'**
  String get stateDispatchHint;

  /// No description provided for @stateDispatchButton.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get stateDispatchButton;

  /// No description provided for @stateDispatchSent.
  ///
  /// In en, this message translates to:
  /// **'Action dispatched'**
  String get stateDispatchSent;

  /// No description provided for @stateSetupIn.
  ///
  /// In en, this message translates to:
  /// **'Set up in your {platform} app'**
  String stateSetupIn(String platform);

  /// No description provided for @stateActionInvalid.
  ///
  /// In en, this message translates to:
  /// **'The action must be a JSON object.'**
  String get stateActionInvalid;

  /// No description provided for @stateRecentActions.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get stateRecentActions;

  /// No description provided for @jsonTreeView.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get jsonTreeView;

  /// No description provided for @jsonTableView.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get jsonTableView;

  /// No description provided for @jsonSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search keys & values'**
  String get jsonSearchHint;

  /// No description provided for @jsonExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Download table as CSV'**
  String get jsonExportCsv;

  /// No description provided for @jsonTableNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No rows match'**
  String get jsonTableNoMatch;

  /// No description provided for @jsonPrevMatch.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get jsonPrevMatch;

  /// No description provided for @jsonNextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get jsonNextMatch;

  /// No description provided for @jsonExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get jsonExpandAll;

  /// No description provided for @jsonCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get jsonCollapseAll;

  /// No description provided for @jsonCopyKey.
  ///
  /// In en, this message translates to:
  /// **'Copy key'**
  String get jsonCopyKey;

  /// No description provided for @jsonCopyValue.
  ///
  /// In en, this message translates to:
  /// **'Copy value'**
  String get jsonCopyValue;

  /// No description provided for @jsonCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get jsonCopyPath;

  /// No description provided for @jsonKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Key copied'**
  String get jsonKeyCopied;

  /// No description provided for @jsonValueCopied.
  ///
  /// In en, this message translates to:
  /// **'Value copied'**
  String get jsonValueCopied;

  /// No description provided for @jsonPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get jsonPathCopied;

  /// No description provided for @jsonShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show {count} more ({remaining} left)'**
  String jsonShowMore(int count, int remaining);

  /// No description provided for @jsonLongValue.
  ///
  /// In en, this message translates to:
  /// **'{count} characters, copy to get all'**
  String jsonLongValue(int count);

  /// No description provided for @jsonPrettyCut.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {shown} of {total} lines. Copy or save to get all of them.'**
  String jsonPrettyCut(int shown, int total);

  /// No description provided for @jsonTableTruncated.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {count} rows.'**
  String jsonTableTruncated(Object count);

  /// No description provided for @networkErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get networkErrors;

  /// No description provided for @networkSearchBodies.
  ///
  /// In en, this message translates to:
  /// **'Also search request & response bodies'**
  String get networkSearchBodies;

  /// No description provided for @networkExportHar.
  ///
  /// In en, this message translates to:
  /// **'Export the listed requests as HAR'**
  String get networkExportHar;

  /// No description provided for @networkNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'No requests to export'**
  String get networkNothingToExport;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get fileSaved;

  /// No description provided for @consoleGroupRepeats.
  ///
  /// In en, this message translates to:
  /// **'Group repeated logs'**
  String get consoleGroupRepeats;

  /// No description provided for @consoleOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Occurrences'**
  String get consoleOccurrences;

  /// No description provided for @consoleNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No logs match'**
  String get consoleNoMatchTitle;

  /// No description provided for @consoleNoMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drop a filter to bring them back.'**
  String get consoleNoMatchSubtitle;

  /// No description provided for @consoleShowAllLevels.
  ///
  /// In en, this message translates to:
  /// **'Show all levels'**
  String get consoleShowAllLevels;

  /// No description provided for @consoleClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get consoleClearSearch;

  /// No description provided for @consoleResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get consoleResetFilters;

  /// No description provided for @consoleExport.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get consoleExport;

  /// No description provided for @consoleExportText.
  ///
  /// In en, this message translates to:
  /// **'Text (.txt)'**
  String get consoleExportText;

  /// No description provided for @consoleExportJson.
  ///
  /// In en, this message translates to:
  /// **'JSON (.json)'**
  String get consoleExportJson;

  /// No description provided for @consoleNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'No logs to export'**
  String get consoleNothingToExport;

  /// No description provided for @errorSymbolicate.
  ///
  /// In en, this message translates to:
  /// **'Symbolicate'**
  String get errorSymbolicate;

  /// No description provided for @errorSymbolicated.
  ///
  /// In en, this message translates to:
  /// **'Mapped to source'**
  String get errorSymbolicated;

  /// No description provided for @errorSymbolicateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t map this stack: Metro isn\'t reachable from here and no source map was uploaded for this build (uploadSourceMap in the SDK).'**
  String get errorSymbolicateFailed;

  /// No description provided for @storageTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get storageTabHistory;

  /// No description provided for @storageTabKeyValue.
  ///
  /// In en, this message translates to:
  /// **'Key-Value'**
  String get storageTabKeyValue;

  /// No description provided for @storageKvNoDevice.
  ///
  /// In en, this message translates to:
  /// **'Select a device in the bottom bar to see and edit its storage.'**
  String get storageKvNoDevice;

  /// No description provided for @storageKvEmpty.
  ///
  /// In en, this message translates to:
  /// **'No editable storage yet. Wrap the store with the SDK (DevConnectAsyncStorage.wrap, DevConnectMMKV.wrap, DevConnectSharedPreferences.wrap…) — it needs the latest SDK.'**
  String get storageKvEmpty;

  /// No description provided for @storageKvRefresh.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get storageKvRefresh;

  /// No description provided for @storageKvAdd.
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get storageKvAdd;

  /// No description provided for @storageKvEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit value'**
  String get storageKvEdit;

  /// No description provided for @storageKvDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get storageKvDelete;

  /// No description provided for @storageKvClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get storageKvClear;

  /// No description provided for @storageKvClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete every key in {storage}? This can\'t be undone.'**
  String storageKvClearConfirm(Object storage);

  /// No description provided for @storageKvKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get storageKvKey;

  /// No description provided for @storageKvValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get storageKvValue;

  /// No description provided for @storageKvSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get storageKvSave;

  /// No description provided for @storageKvFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter keys'**
  String get storageKvFilter;

  /// No description provided for @deepLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Open a deep link'**
  String get deepLinkTitle;

  /// No description provided for @deepLinkHint.
  ///
  /// In en, this message translates to:
  /// **'The app opens it as if one of its links was tapped.'**
  String get deepLinkHint;

  /// No description provided for @deepLinkOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get deepLinkOpen;

  /// No description provided for @deepLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Deep link sent'**
  String get deepLinkSent;

  /// No description provided for @devMenu.
  ///
  /// In en, this message translates to:
  /// **'Open the dev menu'**
  String get devMenu;

  /// No description provided for @networkReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay request'**
  String get networkReplay;

  /// No description provided for @networkReplaySent.
  ///
  /// In en, this message translates to:
  /// **'Request sent again — it shows up as a new row'**
  String get networkReplaySent;

  /// No description provided for @networkConditions.
  ///
  /// In en, this message translates to:
  /// **'Network conditions'**
  String get networkConditions;

  /// No description provided for @networkPresetNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get networkPresetNormal;

  /// No description provided for @networkPresetSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow (+500 ms)'**
  String get networkPresetSlow;

  /// No description provided for @networkPresetSlow3g.
  ///
  /// In en, this message translates to:
  /// **'Slow 3G (~2 s)'**
  String get networkPresetSlow3g;

  /// No description provided for @networkPresetOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get networkPresetOffline;

  /// No description provided for @networkTabHttpHint.
  ///
  /// In en, this message translates to:
  /// **'HTTP requests the app made through fetch, XHR, axios, Dio, OkHttp…'**
  String get networkTabHttpHint;

  /// No description provided for @networkTabProtocolsHint.
  ///
  /// In en, this message translates to:
  /// **'Traffic beyond plain HTTP: GraphQL operations, WebSocket messages and gRPC calls'**
  String get networkTabProtocolsHint;

  /// No description provided for @networkTabMockAuditHint.
  ///
  /// In en, this message translates to:
  /// **'Requests the app answered with a Mock Server rule instead of the real network'**
  String get networkTabMockAuditHint;

  /// No description provided for @protocolGraphqlHint.
  ///
  /// In en, this message translates to:
  /// **'Queries and mutations sent through the SDK\'s GraphQL link / interceptor'**
  String get protocolGraphqlHint;

  /// No description provided for @protocolWebsocketHint.
  ///
  /// In en, this message translates to:
  /// **'WebSocket connections and every frame sent or received'**
  String get protocolWebsocketHint;

  /// No description provided for @protocolGrpcHint.
  ///
  /// In en, this message translates to:
  /// **'gRPC calls (Android SDK interceptor)'**
  String get protocolGrpcHint;

  /// No description provided for @layoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layoutTitle;

  /// No description provided for @layoutCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get layoutCapture;

  /// No description provided for @layoutHint.
  ///
  /// In en, this message translates to:
  /// **'Capture the app\'s current screen to see its element tree. Hover the screenshot to highlight an element, click it to see its properties.'**
  String get layoutHint;

  /// No description provided for @layoutNoDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect an app, or select a device, to inspect its layout.'**
  String get layoutNoDevice;

  /// No description provided for @layoutNoScreenshot.
  ///
  /// In en, this message translates to:
  /// **'No screenshot from this app, showing element outlines only. React Native: add one with DevConnect.registerScreenshot.'**
  String get layoutNoScreenshot;

  /// No description provided for @layoutPickElement.
  ///
  /// In en, this message translates to:
  /// **'Hover or click an element on the screenshot, or pick one in the tree.'**
  String get layoutPickElement;

  /// No description provided for @layoutTree.
  ///
  /// In en, this message translates to:
  /// **'Element tree'**
  String get layoutTree;

  /// No description provided for @layoutProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get layoutProperties;

  /// No description provided for @layoutTreeError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the element tree'**
  String get layoutTreeError;

  /// No description provided for @layoutSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find by name or value'**
  String get layoutSearchHint;

  /// No description provided for @layoutAppOnly.
  ///
  /// In en, this message translates to:
  /// **'App elements only'**
  String get layoutAppOnly;

  /// No description provided for @layoutFit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get layoutFit;

  /// No description provided for @layoutActualSize.
  ///
  /// In en, this message translates to:
  /// **'Actual size'**
  String get layoutActualSize;

  /// No description provided for @layoutZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get layoutZoomIn;

  /// No description provided for @layoutZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get layoutZoomOut;

  /// No description provided for @layoutZoomLevel.
  ///
  /// In en, this message translates to:
  /// **'Zoom level'**
  String get layoutZoomLevel;

  /// No description provided for @layoutZoomToSelection.
  ///
  /// In en, this message translates to:
  /// **'Zoom to selection'**
  String get layoutZoomToSelection;

  /// No description provided for @layoutClose.
  ///
  /// In en, this message translates to:
  /// **'Close capture'**
  String get layoutClose;

  /// No description provided for @layoutCopyName.
  ///
  /// In en, this message translates to:
  /// **'Copy name'**
  String get layoutCopyName;

  /// No description provided for @layoutCopyJson.
  ///
  /// In en, this message translates to:
  /// **'Copy as JSON'**
  String get layoutCopyJson;

  /// No description provided for @layoutExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get layoutExport;

  /// No description provided for @layoutSavePng.
  ///
  /// In en, this message translates to:
  /// **'Save screenshot (PNG)'**
  String get layoutSavePng;

  /// No description provided for @layoutSaveJson.
  ///
  /// In en, this message translates to:
  /// **'Save snapshot (JSON)'**
  String get layoutSaveJson;

  /// No description provided for @layoutNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'The app didn\'t answer. Layout needs a DevConnect SDK with Layout support, in a debug build.'**
  String get layoutNoAnswer;

  /// No description provided for @layoutTruncated.
  ///
  /// In en, this message translates to:
  /// **'Large tree: only the first part was captured.'**
  String get layoutTruncated;

  /// No description provided for @layoutState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get layoutState;

  /// No description provided for @layoutMeasureHint.
  ///
  /// In en, this message translates to:
  /// **'⌥ + hover: measure'**
  String get layoutMeasureHint;

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

  /// No description provided for @smoothScrolling.
  ///
  /// In en, this message translates to:
  /// **'Smooth scroll'**
  String get smoothScrolling;

  /// No description provided for @smoothScrollingDesc.
  ///
  /// In en, this message translates to:
  /// **'Smooths mouse-wheel scroll events. Disable this option if you notice any lag or performance drop.'**
  String get smoothScrollingDesc;

  /// No description provided for @smoothScrollingDuration.
  ///
  /// In en, this message translates to:
  /// **'Scroll duration'**
  String get smoothScrollingDuration;

  /// No description provided for @smoothScrollingDurationDesc.
  ///
  /// In en, this message translates to:
  /// **'The duration of the smooth scroll animation in milliseconds.'**
  String get smoothScrollingDurationDesc;

  /// No description provided for @binaryBody.
  ///
  /// In en, this message translates to:
  /// **'{label} body is binary'**
  String binaryBody(String label);

  /// No description provided for @binaryBodySize.
  ///
  /// In en, this message translates to:
  /// **'{kb} ({bytes} bytes)'**
  String binaryBodySize(String kb, int bytes);

  /// No description provided for @binaryBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Identify the action via the X-Amz-Target header.'**
  String get binaryBodyHint;

  /// No description provided for @openWithDefaultApp.
  ///
  /// In en, this message translates to:
  /// **'Open in default app'**
  String get openWithDefaultApp;

  /// No description provided for @tipsAndShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Tips & Shortcuts'**
  String get tipsAndShortcuts;

  /// No description provided for @tipsAndShortcutsDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick guides for the most useful workflows. Click any card for details.'**
  String get tipsAndShortcutsDesc;

  /// No description provided for @tipAllEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Events feed'**
  String get tipAllEventsTitle;

  /// No description provided for @tipAllEventsBody.
  ///
  /// In en, this message translates to:
  /// **'One live timeline of your app\'s logs, network requests, state changes, storage operations and errors, plus display and async-operation events.'**
  String get tipAllEventsBody;

  /// No description provided for @tipAllEventsSteps.
  ///
  /// In en, this message translates to:
  /// **'Type in \"Search events...\" to match messages, URL paths, actions, storage keys or tags\nToggle the \"LOG\", \"API\", \"STATE\" and \"STORE\" chips; \"ERRORS\" keeps errors and failed requests\nClick a row for details; \"Full\" or \"Tab\" saves them as an image\nPick a device, or \"All\", in the bottom bar to choose whose events show\nUse \"Oldest first\"/\"Newest first\" to flip the order and \"Auto-scroll\" to follow new events'**
  String get tipAllEventsSteps;

  /// No description provided for @tipAllEventsTip.
  ///
  /// In en, this message translates to:
  /// **'\"Clear all\" here empties every page\'s list — Console, Network, State, Storage, Errors and the rest — not just this feed.'**
  String get tipAllEventsTip;

  /// No description provided for @tipNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect network traffic'**
  String get tipNetworkTitle;

  /// No description provided for @tipNetworkBody.
  ///
  /// In en, this message translates to:
  /// **'HTTP requests your app makes, with headers, bodies, status and duration, plus GraphQL, WebSocket and gRPC traffic and requests answered by mock rules. gRPC comes from the Android SDK only.'**
  String get tipNetworkBody;

  /// No description provided for @tipNetworkSteps.
  ///
  /// In en, this message translates to:
  /// **'Click a request for its \"Headers\", \"Request\", \"Response\" and \"Timing\" tabs\nFilter by method, \"2xx\"/\"3xx\"/\"Errors\", or type part of a URL in \"Filter URLs...\"\nTurn on \"Also search request & response bodies\" to search inside payloads too\nPress \"Copy cURL\" in the panel for a curl command; right-click a row for \"Replay request\"\nOpen \"Protocols\" for GraphQL, WebSocket and gRPC, or \"Mock Audit\" for mocked requests'**
  String get tipNetworkSteps;

  /// No description provided for @tipNetworkTip.
  ///
  /// In en, this message translates to:
  /// **'Connectivity checks such as generate_204 and captive.apple.com stay hidden until your search matches them.'**
  String get tipNetworkTip;

  /// No description provided for @tipConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Console logs'**
  String get tipConsoleTitle;

  /// No description provided for @tipConsoleBody.
  ///
  /// In en, this message translates to:
  /// **'Your app\'s log lines as they arrive, with level, tag and time — console calls on React Native, print and debugPrint on Flutter, println on Android.'**
  String get tipConsoleBody;

  /// No description provided for @tipConsoleSteps.
  ///
  /// In en, this message translates to:
  /// **'Toggle \"DEBUG\", \"INFO\", \"WARN\" and \"ERROR\" to show or hide each level\nType in \"Search logs...\" to match message text or tag\nClick a row for its tag, message, metadata and stack trace, when present\nKeep \"Group repeated logs\" on to fold identical back-to-back lines into one counted row\nUse \"Export logs\" to save the filtered list as \"Text (.txt)\" or \"JSON (.json)\"'**
  String get tipConsoleSteps;

  /// No description provided for @tipConsoleTip.
  ///
  /// In en, this message translates to:
  /// **'Plain console.log, print and println lines arrive as DEBUG — switch \"DEBUG\" off to keep only info, warnings and errors.'**
  String get tipConsoleTip;

  /// No description provided for @tipStateTitle.
  ///
  /// In en, this message translates to:
  /// **'State inspector'**
  String get tipStateTitle;

  /// No description provided for @tipStateBody.
  ///
  /// In en, this message translates to:
  /// **'Every state change your app reports, with its action and the state before and after — Redux, Zustand, MobX and more on React Native, BLoC, Riverpod and Provider on Flutter, ViewModels on Android.'**
  String get tipStateBody;

  /// No description provided for @tipStateSteps.
  ///
  /// In en, this message translates to:
  /// **'Open the \"Timeline\" tab — it lists changes from every state library; the chips in the header show or hide each one\nType in \"Filter actions...\" to match an action or store name\nClick a change, then switch between \"Diff\", \"Before\" and \"After\"\nUse \"Restore the app\'s state to this point\" (needs DevConnect.onStateRestore) or \"Save as snapshot\"\nOpen \"Controls\" to pin state paths, take snapshots and dispatch Redux actions'**
  String get tipStateSteps;

  /// No description provided for @tipStateTip.
  ///
  /// In en, this message translates to:
  /// **'\"Diff\" fills only when the SDK sends one — Redux, Zustand and MobX do; Flutter and Android don\'t, so compare \"Before\" and \"After\".'**
  String get tipStateTip;

  /// No description provided for @tipStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'App storage'**
  String get tipStorageTitle;

  /// No description provided for @tipStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Every read, write and delete on stores you wrap with the SDK — AsyncStorage, MMKV, SharedPreferences, Hive and more — plus the current keys of supported stores, editable here.'**
  String get tipStorageBody;

  /// No description provided for @tipStorageSteps.
  ///
  /// In en, this message translates to:
  /// **'In \"History\", pick \"READ\", \"WRITE\" or \"DELETE\", and toggle store chips like \"AS\" or \"SP\"\nType a key in \"Filter keys...\" to see every operation on it; values match too\nClick a row to see that operation\'s value, size, store and time\nOpen \"Key-Value\" for a store\'s current keys, then \"Add key\", \"Edit value\" or \"Delete key\"\nPress \"Reload\" to fetch the latest contents from the app'**
  String get tipStorageSteps;

  /// No description provided for @tipStorageTip.
  ///
  /// In en, this message translates to:
  /// **'\"Clear all\" in \"History\" only empties this log; \"Clear all\" in \"Key-Value\" deletes every key from the app\'s store.'**
  String get tipStorageTip;

  /// No description provided for @tipDatabaseTitle.
  ///
  /// In en, this message translates to:
  /// **'SQLite databases'**
  String get tipDatabaseTitle;

  /// No description provided for @tipDatabaseBody.
  ///
  /// In en, this message translates to:
  /// **'Browse and query the SQLite databases your app registers with DevConnect.registerDatabase: tables with row counts, a SQL box and a results grid.'**
  String get tipDatabaseBody;

  /// No description provided for @tipDatabaseSteps.
  ///
  /// In en, this message translates to:
  /// **'Register the database in the app with DevConnect.registerDatabase\nClick a table to preview its first 50 rows\nEdit the SQL and press \"Run\" to run your own query\nPress \"Run\" again to re-query — results don\'t refresh on their own\nPress \"Reload tables\" to refresh the table list and row counts'**
  String get tipDatabaseSteps;

  /// No description provided for @tipDatabaseTip.
  ///
  /// In en, this message translates to:
  /// **'Sort by adding ORDER BY to the query — the column headers don\'t sort.'**
  String get tipDatabaseTip;

  /// No description provided for @tipPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance profiler'**
  String get tipPerformanceTitle;

  /// No description provided for @tipPerformanceBody.
  ///
  /// In en, this message translates to:
  /// **'Live charts of your app\'s FPS, CPU, memory and network activity, plus frame times, threads, battery, thermal state, disk I/O, startup time and ANRs when the SDK reports them.'**
  String get tipPerformanceBody;

  /// No description provided for @tipPerformanceSteps.
  ///
  /// In en, this message translates to:
  /// **'Select one device in the bottom bar — with \"All\" selected, charts mix every app\'s samples\nRead the live \"FPS\", \"MEM\", \"CPU\" and \"SLOW\" pills in the toolbar\nHover a chart to read the exact value and how long ago it arrived\nCheck \"System Status\" for startup time, battery drain, thermal state, disk I/O and ANRs\nUse \"Capture as image\" to save the charts as a PNG, and \"Clear\" to start over'**
  String get tipPerformanceSteps;

  /// No description provided for @tipPerformanceTip.
  ///
  /// In en, this message translates to:
  /// **'Hover the red badge in the FPS row for average and worst slow-frame times, plus the last five slow frames.'**
  String get tipPerformanceTip;

  /// No description provided for @tipLeaksTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory leak detection'**
  String get tipLeaksTitle;

  /// No description provided for @tipLeaksBody.
  ///
  /// In en, this message translates to:
  /// **'Leak warnings from your app: steady memory growth caught automatically by all three SDKs, more than 50 active timers on React Native, and anything you send with DevConnect.reportMemoryLeak.'**
  String get tipLeaksBody;

  /// No description provided for @tipLeaksSteps.
  ///
  /// In en, this message translates to:
  /// **'Read the red, amber and blue counts in the toolbar: critical, warning and info\nClick a row for its \"Detail\", \"Retained Size\", \"Stack Trace\" and \"Metadata\", when reported\nCheck \"Metadata\" on memory-growth rows for each sample and the total growth in MB\nReport your own finds with DevConnect.reportMemoryLeak, such as undisposed controllers or streams\nPress \"Clear\", repeat the suspect flow and watch for new warnings'**
  String get tipLeaksSteps;

  /// No description provided for @tipLeaksTip.
  ///
  /// In en, this message translates to:
  /// **'By default memory is sampled every 10 seconds; a warning needs steady growth above 20 MB, and above 40 MB it turns critical.'**
  String get tipLeaksTip;

  /// No description provided for @tipBenchmarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Benchmarks'**
  String get tipBenchmarkTitle;

  /// No description provided for @tipBenchmarkBody.
  ///
  /// In en, this message translates to:
  /// **'Times the code you wrap with the SDK\'s benchmark calls, plus the App Startup and App Background runs every SDK records on its own.'**
  String get tipBenchmarkBody;

  /// No description provided for @tipBenchmarkSteps.
  ///
  /// In en, this message translates to:
  /// **'Wrap code in DevConnect.benchmarkStart and benchmarkStop — React Native starts with benchmark\nMark phases with benchmarkStep (Flutter, React Native); Android runs have no steps\nClick a run to see its \"Start\", \"End\", \"Duration\" and a waterfall of its steps\nType in \"Search benchmarks...\" to filter the list and the stats bar\nPress \"Capture as image\" to save a run\'s panel as a PNG'**
  String get tipBenchmarkSteps;

  /// No description provided for @tipBenchmarkTip.
  ///
  /// In en, this message translates to:
  /// **'The stats bar covers every listed run — search one title to get \"Min\", \"Avg\" and \"P50\" for that benchmark alone.'**
  String get tipBenchmarkTip;

  /// No description provided for @tipErrorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get tipErrorsTitle;

  /// No description provided for @tipErrorsBody.
  ///
  /// In en, this message translates to:
  /// **'Lists the errors your app reports: React Native JavaScript errors and console.error calls, Flutter framework and Dart errors, and Android exceptions.'**
  String get tipErrorsBody;

  /// No description provided for @tipErrorsSteps.
  ///
  /// In en, this message translates to:
  /// **'Flutter: start the app with DevConnect.initAndRunApp — plain init installs no error hooks\nClick the \"JS\", \"Native\", \"Android\" and \"iOS\" chips to show or hide a platform\nType in \"Search errors...\" to match the message, source or stack trace\nClick an error to open its \"Message\", \"Stack Trace\" and \"Details\" tabs\nOn a React Native stack, press \"Symbolicate\" to map frames to your source through Metro'**
  String get tipErrorsSteps;

  /// No description provided for @tipErrorsTip.
  ///
  /// In en, this message translates to:
  /// **'Flutter errors carry the Android or iOS tag of the device they ran on — there\'s no separate Flutter chip.'**
  String get tipErrorsTip;

  /// No description provided for @tipMockTitle.
  ///
  /// In en, this message translates to:
  /// **'Mock Server'**
  String get tipMockTitle;

  /// No description provided for @tipMockBody.
  ///
  /// In en, this message translates to:
  /// **'Keeps fake API responses — method, URL regex, status, headers, body and an optional delay — and installs them on the selected device, so matching requests never reach the network.'**
  String get tipMockBody;

  /// No description provided for @tipMockSteps.
  ///
  /// In en, this message translates to:
  /// **'Android: add DevConnect.mockServerInterceptor() to your OkHttpClient first\nSelect one device, press \"Add rule\", fill in the fields and press \"Save changes\"\nPress \"Push all\" — later edits, switches and deletes then reach the device on their own\nFlip a rule\'s switch to pause it, or open it and hold \"Hold to delete\" (Undo brings it back)\nPress \"Clear device\" to remove every rule from the device and stop syncing'**
  String get tipMockSteps;

  /// No description provided for @tipMockTip.
  ///
  /// In en, this message translates to:
  /// **'Rules live only in DevConnect\'s memory — quitting loses them, but a synced device gets them back when it reconnects.'**
  String get tipMockTip;

  /// No description provided for @tipHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tipHistoryTitle;

  /// No description provided for @tipHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'When a device disconnects and stays away 15 seconds, its logs, network calls, state changes and storage operations stay here as a read-only session until it reconnects or DevConnect quits.'**
  String get tipHistoryBody;

  /// No description provided for @tipHistorySteps.
  ///
  /// In en, this message translates to:
  /// **'Click a session to open its \"All\", \"Logs\", \"Network\", \"State\" and \"Storage\" tabs\nRead each tile\'s disconnect time and its event counts\nPress × on a tile to remove that session\nPress \"Clear All\" to empty the list'**
  String get tipHistorySteps;

  /// No description provided for @tipHistoryTip.
  ///
  /// In en, this message translates to:
  /// **'A session disappears as soon as the same device — or any app on the same IP — reconnects, so check it before relaunching.'**
  String get tipHistoryTip;

  /// No description provided for @tipDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get tipDisplayTitle;

  /// No description provided for @tipDisplayBody.
  ///
  /// In en, this message translates to:
  /// **'Shows what your app sends with DevConnect.display() — a name, optional preview text, a JSON value and metadata. All three SDKs have it.'**
  String get tipDisplayBody;

  /// No description provided for @tipDisplaySteps.
  ///
  /// In en, this message translates to:
  /// **'Call DevConnect.display with a name and an optional value, preview and metadata\nScan the rows, newest first: each shows the name, preview and time\nClick a row to see its \"Preview\", \"Value\" as JSON and \"Metadata\"\nPress \"Clear all\" to empty the list'**
  String get tipDisplaySteps;

  /// No description provided for @tipDisplayTip.
  ///
  /// In en, this message translates to:
  /// **'Each call adds a new row rather than replacing the last one — reuse a name to build a timeline.'**
  String get tipDisplayTip;

  /// No description provided for @tipAsyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Async operations'**
  String get tipAsyncTitle;

  /// No description provided for @tipAsyncBody.
  ///
  /// In en, this message translates to:
  /// **'Lists the async steps your app reports with DevConnect.reportAsyncOperation() — saga effects, tasks, background jobs — with status, duration and result or error. Nothing is tracked automatically.'**
  String get tipAsyncBody;

  /// No description provided for @tipAsyncSteps.
  ///
  /// In en, this message translates to:
  /// **'Call reportAsyncOperation with a type, a description and the status start, resolve or reject\nOn React Native, wrap a promise in trackAsync to report it from start to finish\nRead the badge color: orange started, green resolved, red rejected\nClick a row for its details, \"Result\" and \"Metadata\"\nPress \"Clear all\" to empty the list'**
  String get tipAsyncSteps;

  /// No description provided for @tipAsyncTip.
  ///
  /// In en, this message translates to:
  /// **'Give related calls the same sagaName — selecting any of them lists the whole group under \"Saga timeline\".'**
  String get tipAsyncTip;

  /// No description provided for @tipLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Layout inspector'**
  String get tipLayoutTitle;

  /// No description provided for @tipLayoutBody.
  ///
  /// In en, this message translates to:
  /// **'Captures the app\'s current screen with its element tree — Flutter widgets, React Native components or Android views — and shows each element\'s position, size, padding, margin and props.'**
  String get tipLayoutBody;

  /// No description provided for @tipLayoutSteps.
  ///
  /// In en, this message translates to:
  /// **'Select the device and press \"Capture\" to grab its screen and element tree\nHover the screenshot to highlight an element; click to select it\nOr pick it in the \"Element tree\", or search with \"Find by name or value\"\nTurn on \"App elements only\" to hide library widgets (Flutter, React Native)\nRead \"Properties\" — box model, position, size and props — or press \"Copy as JSON\"'**
  String get tipLayoutSteps;

  /// No description provided for @tipLayoutTip.
  ///
  /// In en, this message translates to:
  /// **'React Native sends a screenshot only after you call DevConnect.registerScreenshot() — without it you get outlines only.'**
  String get tipLayoutTip;

  /// No description provided for @settingsGroupConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsGroupConnection;

  /// No description provided for @settingsGroupConnectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Server, network addresses and USB.'**
  String get settingsGroupConnectionDesc;

  /// No description provided for @settingsGroupDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get settingsGroupDevices;

  /// No description provided for @settingsGroupDevicesDesc.
  ///
  /// In en, this message translates to:
  /// **'Apps connected now and the ones seen before.'**
  String get settingsGroupDevicesDesc;

  /// No description provided for @settingsGroupAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsGroupAppearance;

  /// No description provided for @settingsGroupAppearanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Theme, language and the tabs that show.'**
  String get settingsGroupAppearanceDesc;

  /// No description provided for @settingsGroupData.
  ///
  /// In en, this message translates to:
  /// **'Display & data'**
  String get settingsGroupData;

  /// No description provided for @settingsGroupDataDesc.
  ///
  /// In en, this message translates to:
  /// **'How details show, and how much history is kept.'**
  String get settingsGroupDataDesc;

  /// No description provided for @settingsGroupGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get settingsGroupGuides;

  /// No description provided for @settingsGroupGuidesDesc.
  ///
  /// In en, this message translates to:
  /// **'Get started, shortcuts and tips.'**
  String get settingsGroupGuidesDesc;

  /// No description provided for @settingsGroupSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsGroupSupport;

  /// No description provided for @settingsGroupSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Help keep DevConnect going.'**
  String get settingsGroupSupportDesc;

  /// No description provided for @tipsTabFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get tipsTabFeatures;

  /// No description provided for @tipsTabShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get tipsTabShortcuts;

  /// No description provided for @tipsTabConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect a device'**
  String get tipsTabConnect;

  /// No description provided for @tipsTabSdk.
  ///
  /// In en, this message translates to:
  /// **'SDK setup'**
  String get tipsTabSdk;

  /// No description provided for @tipsTabAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get tipsTabAdvanced;

  /// No description provided for @tipsSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get tipsSteps;

  /// No description provided for @tipsKeys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get tipsKeys;

  /// No description provided for @tipsProTip.
  ///
  /// In en, this message translates to:
  /// **'Pro tip'**
  String get tipsProTip;

  /// No description provided for @tipsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tipsPrevious;

  /// No description provided for @tipsNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tipsNext;

  /// No description provided for @tipsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tipsDone;

  /// No description provided for @tipsOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Open page'**
  String get tipsOpenPage;

  /// No description provided for @tipsCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get tipsCopyCode;

  /// No description provided for @tipsCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get tipsCodeCopied;

  /// No description provided for @tipsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tipsClose;

  /// No description provided for @pageGuide.
  ///
  /// In en, this message translates to:
  /// **'How to use this page'**
  String get pageGuide;

  /// No description provided for @guideReloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Reload the app'**
  String get guideReloadTitle;

  /// No description provided for @guideReloadSummary.
  ///
  /// In en, this message translates to:
  /// **'Reload the inspected app from any DevConnect page, even while typing: Flutter rebuilds its widgets, React Native reloads from Metro, Android recreates the current activity.'**
  String get guideReloadSummary;

  /// No description provided for @guideReloadSteps.
  ///
  /// In en, this message translates to:
  /// **'[⌘ R] Reload the selected app, or every connected app when none is selected\n[⇧ ⌘ R] Hot restart: runs a Flutter app\'s onHotRestartRequest, otherwise reloads like ⌘ R\nOr click the reload buttons in the bottom bar — their tooltips show the shortcut'**
  String get guideReloadSteps;

  /// No description provided for @guideReloadTip.
  ///
  /// In en, this message translates to:
  /// **'Flutter\'s ⌘ R rebuilds the widget tree and keeps state, but doesn\'t load code edits — use your IDE\'s hot reload for that.'**
  String get guideReloadTip;

  /// No description provided for @guideJsonSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search inside a body'**
  String get guideJsonSearchTitle;

  /// No description provided for @guideJsonSearchSummary.
  ///
  /// In en, this message translates to:
  /// **'Tree, JSON and the code view (TypeScript, Dart or Kotlin) each have their own search: it ignores case, highlights every match and scrolls to the current one.'**
  String get guideJsonSearchSummary;

  /// No description provided for @guideJsonSearchSteps.
  ///
  /// In en, this message translates to:
  /// **'[⌘ F] Jump to the view\'s search box — click inside the body first\n[↵] Go to the next match\n[⇧ ↵] Go to the previous match\n[Esc] Clear the search'**
  String get guideJsonSearchSteps;

  /// No description provided for @guideJsonSearchTip.
  ///
  /// In en, this message translates to:
  /// **'Tree search unfolds nodes and loads later pages to show up to 500 matches; JSON counts up to 100,000.'**
  String get guideJsonSearchTip;

  /// No description provided for @guideLayoutZoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Zoom a layout capture'**
  String get guideLayoutZoomTitle;

  /// No description provided for @guideLayoutZoomSummary.
  ///
  /// In en, this message translates to:
  /// **'Zoom and frame a capture on the Layout page from the keyboard — the keys work as soon as a capture is shown.'**
  String get guideLayoutZoomSummary;

  /// No description provided for @guideLayoutZoomSteps.
  ///
  /// In en, this message translates to:
  /// **'[⌘ +] Zoom in, 1.25× per press\n[⌘ −] Zoom out\n[⌘ 0] Actual size: 100% is the app\'s own screen size\n[⌘ 1] Fit the whole screen in the panel\n[⌘ 2] Zoom to the selected element'**
  String get guideLayoutZoomSteps;

  /// No description provided for @guideLayoutZoomTip.
  ///
  /// In en, this message translates to:
  /// **'Click the zoom percentage for 50, 100, 200 or 400%; pinch to zoom and drag to pan.'**
  String get guideLayoutZoomTip;

  /// No description provided for @guideLayoutMeasureTitle.
  ///
  /// In en, this message translates to:
  /// **'Measure spacing'**
  String get guideLayoutMeasureTitle;

  /// No description provided for @guideLayoutMeasureSummary.
  ///
  /// In en, this message translates to:
  /// **'Hold Option to see the distances between the selected element and the one under the pointer, as design tools do.'**
  String get guideLayoutMeasureSummary;

  /// No description provided for @guideLayoutMeasureSteps.
  ///
  /// In en, this message translates to:
  /// **'Select an element: click it on the capture or pick it in the tree\n[⌥] Hold Option and point at another element\nRead the gaps between separate elements, or the insets when one holds the other\nRelease Option to see the hovered element\'s box model again'**
  String get guideLayoutMeasureSteps;

  /// No description provided for @guideLayoutMeasureTip.
  ///
  /// In en, this message translates to:
  /// **'Overlapping elements show no distance — measuring needs one element inside the other, or a gap between them.'**
  String get guideLayoutMeasureTip;

  /// No description provided for @guideLayoutTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk the element tree'**
  String get guideLayoutTreeTitle;

  /// No description provided for @guideLayoutTreeSummary.
  ///
  /// In en, this message translates to:
  /// **'Move through the captured element tree with the arrow keys once it has focus — click a row or an element on the capture.'**
  String get guideLayoutTreeSummary;

  /// No description provided for @guideLayoutTreeSteps.
  ///
  /// In en, this message translates to:
  /// **'[↑ ↓] Move to the row above or below\n[→] Open the row; press again to step into its first child\n[←] Close the row; press again to step out to its parent\n[Esc] Clear the selection'**
  String get guideLayoutTreeSteps;

  /// No description provided for @guideLayoutTreeTip.
  ///
  /// In en, this message translates to:
  /// **'Type in \"Find by name or value\" to search names, props and state; ↵ and ⇧ ↵ step through the matches.'**
  String get guideLayoutTreeTip;

  /// No description provided for @guideAndroidEmulatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Android emulator'**
  String get guideAndroidEmulatorTitle;

  /// No description provided for @guideAndroidEmulatorSummary.
  ///
  /// In en, this message translates to:
  /// **'Apps in the Android emulator reach this Mac at 10.0.2.2 (Genymotion: 10.0.3.2), so there\'s nothing to set up.'**
  String get guideAndroidEmulatorSummary;

  /// No description provided for @guideAndroidEmulatorSteps.
  ///
  /// In en, this message translates to:
  /// **'Check that Settings › \"Connection\" › \"Server\" shows \"Server Running\"\nNative Android: pass enabled = BuildConfig.DEBUG to installForApp — it\'s off by default\nRun a debug build in the emulator; adb reverse isn\'t needed\nFind the app in the device bar at the bottom of the window'**
  String get guideAndroidEmulatorSteps;

  /// No description provided for @guideAndroidEmulatorTip.
  ///
  /// In en, this message translates to:
  /// **'DevConnect starts on port 9090 at every launch; a port changed under \"Server\" lasts until you quit, and the SDK\'s port must match.'**
  String get guideAndroidEmulatorTip;

  /// No description provided for @guideAndroidUsbTitle.
  ///
  /// In en, this message translates to:
  /// **'Android phone over USB'**
  String get guideAndroidUsbTitle;

  /// No description provided for @guideAndroidUsbSummary.
  ///
  /// In en, this message translates to:
  /// **'adb reverse points the phone\'s localhost at this Mac over the cable, so the app connects without Wi‑Fi.'**
  String get guideAndroidUsbSummary;

  /// No description provided for @guideAndroidUsbSteps.
  ///
  /// In en, this message translates to:
  /// **'Turn on USB debugging, plug in the phone and allow this Mac when asked\nPress \"Run ADB Reverse\" in Settings › \"Connection\" › \"USB Connection\", or run the command below\nStart the app — restart a native Android app that was already running\nNot connecting? Press \"Devices\" there to check that adb sees the phone'**
  String get guideAndroidUsbSteps;

  /// No description provided for @guideAndroidUsbTip.
  ///
  /// In en, this message translates to:
  /// **'Run it again after replugging, restarting adb or rebooting; with several devices plugged in, run adb -s with the phone\'s serial in Terminal.'**
  String get guideAndroidUsbTip;

  /// No description provided for @guideIosSimulatorTitle.
  ///
  /// In en, this message translates to:
  /// **'iOS simulator'**
  String get guideIosSimulatorTitle;

  /// No description provided for @guideIosSimulatorSummary.
  ///
  /// In en, this message translates to:
  /// **'The simulator shares the Mac\'s network, so a debug build reaches DevConnect at localhost with no setup.'**
  String get guideIosSimulatorSummary;

  /// No description provided for @guideIosSimulatorSteps.
  ///
  /// In en, this message translates to:
  /// **'Check that Settings › \"Connection\" › \"Server\" shows \"Server Running\"\nRun a debug build of the app in the simulator\nFind it in the device bar at the bottom of the window'**
  String get guideIosSimulatorSteps;

  /// No description provided for @guideIosSimulatorTip.
  ///
  /// In en, this message translates to:
  /// **'Start order doesn\'t matter: React Native and Flutter apps keep retrying, so they join a few seconds after DevConnect starts.'**
  String get guideIosSimulatorTip;

  /// No description provided for @guideIphoneTitle.
  ///
  /// In en, this message translates to:
  /// **'iPhone'**
  String get guideIphoneTitle;

  /// No description provided for @guideIphoneSummary.
  ///
  /// In en, this message translates to:
  /// **'On the same Wi‑Fi as the Mac, a debug build usually finds DevConnect by itself; if it doesn\'t, set the Mac\'s address as host.'**
  String get guideIphoneSummary;

  /// No description provided for @guideIphoneSteps.
  ///
  /// In en, this message translates to:
  /// **'Put the iPhone and the Mac on the same Wi‑Fi — guest networks often block this\nRun the debug build and allow local network access when iOS asks\nWait a few seconds: React Native finds the Mac through Metro, Flutter through a broadcast\nNot listed? Copy the Mac\'s address from Settings › \"Connection\" › \"Network\"\nSet it as host in the SDK\'s init (code below), then restart the app'**
  String get guideIphoneSteps;

  /// No description provided for @guideIphoneTip.
  ///
  /// In en, this message translates to:
  /// **'A USB cable alone can\'t connect an iPhone app — the phone has to reach the Mac over the network.'**
  String get guideIphoneTip;

  /// No description provided for @guideTroubleshootTitle.
  ///
  /// In en, this message translates to:
  /// **'App won\'t connect'**
  String get guideTroubleshootTitle;

  /// No description provided for @guideTroubleshootSummary.
  ///
  /// In en, this message translates to:
  /// **'Most connection problems come down to a few causes — check them in this order.'**
  String get guideTroubleshootSummary;

  /// No description provided for @guideTroubleshootSteps.
  ///
  /// In en, this message translates to:
  /// **'Settings › \"Connection\" › \"Server\" shows \"Server Running\" and no port error\nThe app is a debug build; native Android also needs enabled = BuildConfig.DEBUG\nThe SDK\'s port matches the server\'s — both start at 9090\nPhones share the Mac\'s Wi‑Fi, or Android\'s port is forwarded with adb reverse\nOn Wi‑Fi, macOS lets DevConnect accept incoming connections (System Settings › Network › Firewall)'**
  String get guideTroubleshootSteps;

  /// No description provided for @guideTroubleshootTip.
  ///
  /// In en, this message translates to:
  /// **'Still stuck? Set host to an address from Settings › \"Connection\" › \"Network\" and pass auto: false (Flutter: auto_: false) so reconnects keep it.'**
  String get guideTroubleshootTip;

  /// No description provided for @guideSdkReactNativeSummary.
  ///
  /// In en, this message translates to:
  /// **'Install the package and call init once at startup — fetch and XHR (so axios too), console logs, errors and performance are captured from then on.'**
  String get guideSdkReactNativeSummary;

  /// No description provided for @guideSdkReactNativeSteps.
  ///
  /// In en, this message translates to:
  /// **'Add devconnect-manage-kit with yarn or npm (commands below)\nCall DevConnect.init once at startup, before the first request\nFor state, add devConnectReduxMiddleware (Redux), devConnectMiddleware (Zustand) or setupMobxSpy (MobX)\nRun a debug build — init does nothing in release unless you pass enabled: true'**
  String get guideSdkReactNativeSteps;

  /// No description provided for @guideSdkReactNativeTip.
  ///
  /// In en, this message translates to:
  /// **'init runs once per app start, so after changing host or port do a full reload — Fast Refresh keeps the old settings.'**
  String get guideSdkReactNativeTip;

  /// No description provided for @guideSdkFlutterSummary.
  ///
  /// In en, this message translates to:
  /// **'Start the app through initAndRunApp: dart:io HTTP (http, Dio, Chopper…), print and debugPrint, errors and performance are captured with no extra code.'**
  String get guideSdkFlutterSummary;

  /// No description provided for @guideSdkFlutterSteps.
  ///
  /// In en, this message translates to:
  /// **'Run flutter pub add devconnect_manage_kit\nStart the app with DevConnect.initAndRunApp in main(), passing an async runApp callback\nFor Riverpod or BLoC, call DevConnect.reportStateChange or reportBlocChange from your observer\nRun a debug build — profile and release builds stay off'**
  String get guideSdkFlutterSteps;

  /// No description provided for @guideSdkFlutterTip.
  ///
  /// In en, this message translates to:
  /// **'Put Firebase and other startup code inside the runApp callback — calling ensureInitialized() before initAndRunApp causes a zone mismatch.'**
  String get guideSdkFlutterTip;

  /// No description provided for @guideSdkAndroidSummary.
  ///
  /// In en, this message translates to:
  /// **'Add the Maven Central dependency and call installForApp in Application.onCreate: println output, crashes, ANRs, performance and ViewModel state are captured; HTTP needs the OkHttp interceptor.'**
  String get guideSdkAndroidSummary;

  /// No description provided for @guideSdkAndroidSteps.
  ///
  /// In en, this message translates to:
  /// **'Add io.github.buivietphi:devconnect-android:1.1.0 to app/build.gradle.kts\nCall DevConnect.installForApp in Application.onCreate with enabled = BuildConfig.DEBUG — it\'s off by default\nAdd DevConnect.okHttpInterceptor() to every OkHttpClient, Retrofit\'s included\nLog with DCLog instead of android.util.Log; for Timber, plant a Tree that calls DevConnectTimberHelper.log\nMake sure the app\'s manifest requests the INTERNET permission'**
  String get guideSdkAndroidSteps;

  /// No description provided for @guideSdkAndroidTip.
  ///
  /// In en, this message translates to:
  /// **'The SDK looks for DevConnect once, at launch — start DevConnect (and adb reverse) first, or restart the app.'**
  String get guideSdkAndroidTip;

  /// No description provided for @guideMockApiTitle.
  ///
  /// In en, this message translates to:
  /// **'Mock an API'**
  String get guideMockApiTitle;

  /// No description provided for @guideMockApiSummary.
  ///
  /// In en, this message translates to:
  /// **'Answer matching requests with your own status, headers and body, optionally delayed, without touching the server or the app.'**
  String get guideMockApiSummary;

  /// No description provided for @guideMockApiSteps.
  ///
  /// In en, this message translates to:
  /// **'Select a device in the bottom bar, open \"Mock Server\" and press \"Add rule\"\nSet \"Method\", \"Status\", \"URL pattern\" (a regex matched anywhere in the URL) and the body\nPress \"Save changes\", then \"Push all\" — it sends the whole rule list, and later saves reach the device on their own\nCheck Network › \"Mock Audit\" for the requests a rule answered\nUse a rule\'s switch to pause it, or \"Clear device\" to remove every rule'**
  String get guideMockApiSteps;

  /// No description provided for @guideMockApiTip.
  ///
  /// In en, this message translates to:
  /// **'Android needs DevConnect.mockServerInterceptor() on OkHttp; React Native mocks fetch calls only, not axios or XMLHttpRequest.'**
  String get guideMockApiTip;

  /// No description provided for @guideStateControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Control state from the desktop'**
  String get guideStateControlsTitle;

  /// No description provided for @guideStateControlsSummary.
  ///
  /// In en, this message translates to:
  /// **'The State Inspector\'s Controls tab watches state paths, saves snapshots to send back, and dispatches actions into the app.'**
  String get guideStateControlsSummary;

  /// No description provided for @guideStateControlsSteps.
  ///
  /// In en, this message translates to:
  /// **'Pick one device in the bottom bar, open State Inspector and switch to \"Controls\"\nSubscriptions: pin a path such as auth.user.name; works on every platform with no app code\nSnapshots: \"Take snapshot\" saves the latest state; \"Restore\" sends it back once the app handles onStateRestore\nDispatch action: type a JSON object with a \"type\" such as \"LOGOUT\" and press \"Dispatch\"; React Native needs connectReduxStore(store), Flutter and Android need onReduxDispatch\nChanges they cause show in \"Timeline\" when the app\'s state library reports them'**
  String get guideStateControlsSteps;

  /// No description provided for @guideStateControlsTip.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions read the latest reported state: the whole store with Redux, but only the store or provider that changed last with Zustand, MobX, Riverpod or a ViewModel. If Restore or Dispatch does nothing, the app hasn\'t set its handler; a handler that throws shows in the Console.'**
  String get guideStateControlsTip;

  /// No description provided for @guideNetworkConditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Slow or offline network'**
  String get guideNetworkConditionsTitle;

  /// No description provided for @guideNetworkConditionsSummary.
  ///
  /// In en, this message translates to:
  /// **'Delay the apps\' HTTP requests or make them fail, without touching device settings — DevConnect\'s own connection keeps working.'**
  String get guideNetworkConditionsSummary;

  /// No description provided for @guideNetworkConditionsSteps.
  ///
  /// In en, this message translates to:
  /// **'In Network, open the gauge menu \"Network conditions\" in the toolbar\nPick \"Slow (+500 ms)\" or \"Slow 3G (~2 s)\" to delay every request\nPick \"Offline\" to make requests fail at once, like a dead network\nPick \"Normal\" when you\'re done — the icon stays highlighted until then\nOn Android only OkHttp traffic slows down, through DevConnect.okHttpInterceptor()'**
  String get guideNetworkConditionsSteps;

  /// No description provided for @guideNetworkConditionsTip.
  ///
  /// In en, this message translates to:
  /// **'It applies to every connected app, and to apps that connect later, until you pick \"Normal\".'**
  String get guideNetworkConditionsTip;

  /// No description provided for @guideReplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay a request'**
  String get guideReplayTitle;

  /// No description provided for @guideReplaySummary.
  ///
  /// In en, this message translates to:
  /// **'Have the app send a captured request again — same method, URL, headers and body — without tapping through its screens.'**
  String get guideReplaySummary;

  /// No description provided for @guideReplaySteps.
  ///
  /// In en, this message translates to:
  /// **'In Network, right-click a request and choose \"Replay request\"\nOr open the request and click the repeat icon in its header\nThe replay shows up as a new row in the list'**
  String get guideReplaySteps;

  /// No description provided for @guideReplayTip.
  ///
  /// In en, this message translates to:
  /// **'Android reruns recent OkHttp calls through the app\'s own client and interceptors; Flutter and React Native resend the captured headers as they are.'**
  String get guideReplayTip;

  /// No description provided for @guideHarExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export to HAR'**
  String get guideHarExportTitle;

  /// No description provided for @guideHarExportSummary.
  ///
  /// In en, this message translates to:
  /// **'Save the requests Network lists as a standard HAR 1.2 file — headers, bodies, status and timing included — to open in other tools.'**
  String get guideHarExportSummary;

  /// No description provided for @guideHarExportSteps.
  ///
  /// In en, this message translates to:
  /// **'Narrow the \"HTTP\" list with the device, method, status and URL filters\nClick the download icon \"Export the listed requests as HAR\" in the toolbar\nChoose where to save the .har file\nOpen it in Chrome DevTools or Charles, or share it with your team'**
  String get guideHarExportSteps;

  /// No description provided for @guideHarExportTip.
  ///
  /// In en, this message translates to:
  /// **'Only what the HTTP list shows is saved, so your filters decide what\'s in the file; \"Protocols\" entries aren\'t included.'**
  String get guideHarExportTip;

  /// No description provided for @guideDatabaseQueryTitle.
  ///
  /// In en, this message translates to:
  /// **'Query the app\'s database'**
  String get guideDatabaseQueryTitle;

  /// No description provided for @guideDatabaseQuerySummary.
  ///
  /// In en, this message translates to:
  /// **'Browse the tables of a SQLite database inside the app and run SQL on it, right from DevConnect.'**
  String get guideDatabaseQuerySummary;

  /// No description provided for @guideDatabaseQuerySteps.
  ///
  /// In en, this message translates to:
  /// **'Register the database in the app with DevConnect.registerDatabase (snippets below)\nOpen Database and click a table to preview its first 50 rows\nEdit the SQL and press \"Run\" — results stop at 1,000 rows\nClick \"Reload tables\" after the app changes its tables'**
  String get guideDatabaseQuerySteps;

  /// No description provided for @guideDatabaseQueryTip.
  ///
  /// In en, this message translates to:
  /// **'Queries run on the database of the last table you clicked, otherwise on the first one registered.'**
  String get guideDatabaseQueryTip;

  /// No description provided for @guideBigJsonTitle.
  ///
  /// In en, this message translates to:
  /// **'Large bodies'**
  String get guideBigJsonTitle;

  /// No description provided for @guideBigJsonSummary.
  ///
  /// In en, this message translates to:
  /// **'Big bodies open without freezing DevConnect: they\'re parsed in the background, and Tree and JSON build only what\'s on screen.'**
  String get guideBigJsonSummary;

  /// No description provided for @guideBigJsonSteps.
  ///
  /// In en, this message translates to:
  /// **'Click \"Show … more\" under a long Tree list to load the next 200 items\nUse \"Copy value\" on long Tree strings — Tree shows their first 2,000 characters\nSwitch to JSON to scroll and search the whole document\nUse \"Copy JSON\" or \"Save as file\" there — both take the full body\nJSON lines over 20,000 characters show only their start; copy or save to get all of it'**
  String get guideBigJsonSteps;

  /// No description provided for @guideBigJsonTip.
  ///
  /// In en, this message translates to:
  /// **'When the body is a list of objects, Tree offers \"Table\": it shows 500 rows, but \"Download table as CSV\" saves every matching row.'**
  String get guideBigJsonTip;

  /// No description provided for @guideCustomCommandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom commands'**
  String get guideCustomCommandsTitle;

  /// No description provided for @guideCustomCommandsSummary.
  ///
  /// In en, this message translates to:
  /// **'Run code inside the app from DevConnect — clear a cache, log out, seed test data — and see what it returns.'**
  String get guideCustomCommandsSummary;

  /// No description provided for @guideCustomCommandsSteps.
  ///
  /// In en, this message translates to:
  /// **'Register a handler in the app with DevConnect.registerCommand (snippets below)\nOpen \"Custom commands\" and click a command the app listed, or type its name\nAdd arguments as a JSON object if the command needs any\nPress \"Run\", or ↵ in the \"Command\" field, and read the result below'**
  String get guideCustomCommandsSteps;

  /// No description provided for @guideCustomCommandsTip.
  ///
  /// In en, this message translates to:
  /// **'Flutter and React Native handlers can be async; a thrown error shows as the result, and no answer times out after 10 seconds.'**
  String get guideCustomCommandsTip;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @serverAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Apps connect to this address.'**
  String get serverAddressHint;

  /// No description provided for @serverStoppedHint.
  ///
  /// In en, this message translates to:
  /// **'Start the server so apps can connect.'**
  String get serverStoppedHint;

  /// No description provided for @tabBenchmark.
  ///
  /// In en, this message translates to:
  /// **'Benchmark'**
  String get tabBenchmark;

  /// No description provided for @tabDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get tabDisplay;

  /// No description provided for @tabAsync.
  ///
  /// In en, this message translates to:
  /// **'Async operations'**
  String get tabAsync;

  /// No description provided for @tabLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout inspector'**
  String get tabLayout;

  /// No description provided for @tabCommands.
  ///
  /// In en, this message translates to:
  /// **'Custom commands'**
  String get tabCommands;

  /// No description provided for @tabMockServer.
  ///
  /// In en, this message translates to:
  /// **'Mock server'**
  String get tabMockServer;

  /// No description provided for @tabsAlwaysShown.
  ///
  /// In en, this message translates to:
  /// **'All Events and Settings are always shown.'**
  String get tabsAlwaysShown;

  /// No description provided for @quickStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Install the SDK, start it in your app, then connect.'**
  String get quickStartDesc;

  /// No description provided for @quickStartNext.
  ///
  /// In en, this message translates to:
  /// **'Next — start it in your app'**
  String get quickStartNext;

  /// No description provided for @quickStartEmulator.
  ///
  /// In en, this message translates to:
  /// **'Emulators connect on their own'**
  String get quickStartEmulator;

  /// No description provided for @quickStartWifi.
  ///
  /// In en, this message translates to:
  /// **'Phone on Wi‑Fi'**
  String get quickStartWifi;

  /// No description provided for @quickStartUsb.
  ///
  /// In en, this message translates to:
  /// **'Android over USB'**
  String get quickStartUsb;
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
