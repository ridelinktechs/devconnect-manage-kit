import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../state_inspector/presentation/shared/state_setup_code.dart';

/// Tabs of the Tips & Shortcuts card, in display order.
enum TipTab { features, shortcuts, connect, sdk, advanced }

/// One card of the Tips & Shortcuts card and the page of its detail modal.
class Guide {
  final TipTab tab;
  final IconData icon;
  final Color color;
  final String title;
  final String summary;

  /// One step per line. A line starting with `[⌘ R]` names the keys it uses.
  final String? steps;
  final String? tip;

  /// (label, code) snippets; `{host}` and `{port}` are filled in when shown.
  final List<(String, String)> code;

  /// Page the modal's "Open page" button goes to.
  final String? route;

  const Guide({
    required this.tab,
    required this.icon,
    required this.color,
    required this.title,
    required this.summary,
    this.steps,
    this.tip,
    this.code = const [],
    this.route,
  });
}

String tipTabLabel(S s, TipTab tab) => switch (tab) {
  TipTab.features => s.tipsTabFeatures,
  TipTab.shortcuts => s.tipsTabShortcuts,
  TipTab.connect => s.tipsTabConnect,
  TipTab.sdk => s.tipsTabSdk,
  TipTab.advanced => s.tipsTabAdvanced,
};

/// [color] darkened in light mode so text in it keeps 4.5:1 on light tints.
Color guideTone(Color color, bool isDark) =>
    isDark ? color : Color.lerp(color, Colors.black, 0.45)!;

const _blue = Color(0xFF58A6FF);
const _green = Color(0xFF3FB950);
const _purple = Color(0xFFD2A8FF);
const _amber = Color(0xFFE3B341);
const _teal = Color(0xFF14A096);
const _red = Color(0xFFF85149);
const _grey = Color(0xFF8B949E);
const _orange = Color(0xFFF0883E);

const _hostCode = [
  (
    'React Native',
    'DevConnect.init({ appName: "MyApp", host: "{host}", port: {port}, auto: false });',
  ),
  (
    'Flutter',
    'await DevConnect.initAndRunApp(\n'
        "  appName: 'MyApp',\n"
        "  host: '{host}',\n"
        '  port: {port},\n'
        '  auto_: false,\n'
        '  runApp: () async => runApp(const MyApp()),\n'
        ');',
  ),
  (
    'Android',
    'DevConnect.installForApp(\n'
        '    context = this,\n'
        '    appName = "MyApp",\n'
        '    host = "{host}",\n'
        '    port = {port},\n'
        '    enabled = BuildConfig.DEBUG,\n'
        ')',
  ),
];

/// Every guide, in tab order.
List<Guide> buildGuides(S s) => [
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.layoutDashboard,
    color: _blue,
    title: s.tipAllEventsTitle,
    summary: s.tipAllEventsBody,
    steps: s.tipAllEventsSteps,
    tip: s.tipAllEventsTip,
    route: '/all',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.globe,
    color: _green,
    title: s.tipNetworkTitle,
    summary: s.tipNetworkBody,
    steps: s.tipNetworkSteps,
    tip: s.tipNetworkTip,
    route: '/network',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.terminal,
    color: _blue,
    title: s.tipConsoleTitle,
    summary: s.tipConsoleBody,
    steps: s.tipConsoleSteps,
    tip: s.tipConsoleTip,
    route: '/console',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.layers,
    color: _purple,
    title: s.tipStateTitle,
    summary: s.tipStateBody,
    steps: s.tipStateSteps,
    tip: s.tipStateTip,
    route: '/state',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.slidersHorizontal,
    color: _purple,
    title: s.guideStateControlsTitle,
    summary: s.guideStateControlsSummary,
    steps: s.guideStateControlsSteps,
    tip: s.guideStateControlsTip,
    code: [
      for (final platform in ['react_native', 'flutter', 'android'])
        (
          '${platformName(platform)} · ${stateRestoreSetup[platform]!.$1}',
          stateControlsSetup(platform),
        ),
    ],
    route: '/state',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.database,
    color: _amber,
    title: s.tipStorageTitle,
    summary: s.tipStorageBody,
    steps: s.tipStorageSteps,
    tip: s.tipStorageTip,
    route: '/storage',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.hardDrive,
    color: _purple,
    title: s.tipDatabaseTitle,
    summary: s.tipDatabaseBody,
    steps: s.tipDatabaseSteps,
    tip: s.tipDatabaseTip,
    route: '/database',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.gauge,
    color: _green,
    title: s.tipPerformanceTitle,
    summary: s.tipPerformanceBody,
    steps: s.tipPerformanceSteps,
    tip: s.tipPerformanceTip,
    route: '/performance',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.bug,
    color: _red,
    title: s.tipLeaksTitle,
    summary: s.tipLeaksBody,
    steps: s.tipLeaksSteps,
    tip: s.tipLeaksTip,
    route: '/memory-leaks',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.timer,
    color: _grey,
    title: s.tipBenchmarkTitle,
    summary: s.tipBenchmarkBody,
    steps: s.tipBenchmarkSteps,
    tip: s.tipBenchmarkTip,
    route: '/benchmark',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.alertTriangle,
    color: _amber,
    title: s.tipErrorsTitle,
    summary: s.tipErrorsBody,
    steps: s.tipErrorsSteps,
    tip: s.tipErrorsTip,
    route: '/errors',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.eye,
    color: const Color(0xFF79C0FF),
    title: s.tipDisplayTitle,
    summary: s.tipDisplayBody,
    steps: s.tipDisplaySteps,
    tip: s.tipDisplayTip,
    route: '/display',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.workflow,
    color: const Color(0xFFA371F7),
    title: s.tipAsyncTitle,
    summary: s.tipAsyncBody,
    steps: s.tipAsyncSteps,
    tip: s.tipAsyncTip,
    route: '/async',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.scanSearch,
    color: _orange,
    title: s.tipLayoutTitle,
    summary: s.tipLayoutBody,
    steps: s.tipLayoutSteps,
    tip: s.tipLayoutTip,
    route: '/layout',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.server,
    color: _teal,
    title: s.tipMockTitle,
    summary: s.tipMockBody,
    steps: s.tipMockSteps,
    tip: s.tipMockTip,
    route: '/mock-server',
  ),
  Guide(
    tab: TipTab.features,
    icon: LucideIcons.history,
    color: _grey,
    title: s.tipHistoryTitle,
    summary: s.tipHistoryBody,
    steps: s.tipHistorySteps,
    tip: s.tipHistoryTip,
    route: '/history',
  ),
  Guide(
    tab: TipTab.shortcuts,
    icon: LucideIcons.rotateCw,
    color: _green,
    title: s.guideReloadTitle,
    summary: s.guideReloadSummary,
    steps: s.guideReloadSteps,
    tip: s.guideReloadTip,
  ),
  Guide(
    tab: TipTab.shortcuts,
    icon: LucideIcons.search,
    color: _blue,
    title: s.guideJsonSearchTitle,
    summary: s.guideJsonSearchSummary,
    steps: s.guideJsonSearchSteps,
    tip: s.guideJsonSearchTip,
    route: '/network',
  ),
  Guide(
    tab: TipTab.shortcuts,
    icon: LucideIcons.zoomIn,
    color: _purple,
    title: s.guideLayoutZoomTitle,
    summary: s.guideLayoutZoomSummary,
    steps: s.guideLayoutZoomSteps,
    tip: s.guideLayoutZoomTip,
    route: '/layout',
  ),
  Guide(
    tab: TipTab.shortcuts,
    icon: LucideIcons.ruler,
    color: _amber,
    title: s.guideLayoutMeasureTitle,
    summary: s.guideLayoutMeasureSummary,
    steps: s.guideLayoutMeasureSteps,
    tip: s.guideLayoutMeasureTip,
    route: '/layout',
  ),
  Guide(
    tab: TipTab.shortcuts,
    icon: LucideIcons.listTree,
    color: _teal,
    title: s.guideLayoutTreeTitle,
    summary: s.guideLayoutTreeSummary,
    steps: s.guideLayoutTreeSteps,
    tip: s.guideLayoutTreeTip,
    route: '/layout',
  ),
  Guide(
    tab: TipTab.connect,
    icon: LucideIcons.monitorSmartphone,
    color: _green,
    title: s.guideAndroidEmulatorTitle,
    summary: s.guideAndroidEmulatorSummary,
    steps: s.guideAndroidEmulatorSteps,
    tip: s.guideAndroidEmulatorTip,
  ),
  Guide(
    tab: TipTab.connect,
    icon: LucideIcons.usb,
    color: _amber,
    title: s.guideAndroidUsbTitle,
    summary: s.guideAndroidUsbSummary,
    steps: s.guideAndroidUsbSteps,
    tip: s.guideAndroidUsbTip,
    code: const [('Terminal', 'adb reverse tcp:{port} tcp:{port}')],
  ),
  Guide(
    tab: TipTab.connect,
    icon: LucideIcons.tabletSmartphone,
    color: _blue,
    title: s.guideIosSimulatorTitle,
    summary: s.guideIosSimulatorSummary,
    steps: s.guideIosSimulatorSteps,
    tip: s.guideIosSimulatorTip,
  ),
  Guide(
    tab: TipTab.connect,
    icon: LucideIcons.smartphone,
    color: _purple,
    title: s.guideIphoneTitle,
    summary: s.guideIphoneSummary,
    steps: s.guideIphoneSteps,
    tip: s.guideIphoneTip,
    code: _hostCode,
  ),
  Guide(
    tab: TipTab.connect,
    icon: LucideIcons.lifeBuoy,
    color: _red,
    title: s.guideTroubleshootTitle,
    summary: s.guideTroubleshootSummary,
    steps: s.guideTroubleshootSteps,
    tip: s.guideTroubleshootTip,
    code: _hostCode,
  ),
  Guide(
    tab: TipTab.sdk,
    icon: LucideIcons.atom,
    color: const Color(0xFF61DAFB),
    title: 'React Native',
    summary: s.guideSdkReactNativeSummary,
    steps: s.guideSdkReactNativeSteps,
    tip: s.guideSdkReactNativeTip,
    code: const [
      ('yarn', 'yarn add devconnect-manage-kit'),
      ('npm', 'npm install devconnect-manage-kit'),
      (
        'App.tsx',
        'import { DevConnect } from "devconnect-manage-kit";\n\n'
            'DevConnect.init({ appName: "MyApp" });',
      ),
    ],
  ),
  Guide(
    tab: TipTab.sdk,
    icon: LucideIcons.feather,
    color: const Color(0xFF54C5F8),
    title: 'Flutter',
    summary: s.guideSdkFlutterSummary,
    steps: s.guideSdkFlutterSteps,
    tip: s.guideSdkFlutterTip,
    code: const [
      ('Terminal', 'flutter pub add devconnect_manage_kit'),
      (
        'main.dart',
        "import 'package:devconnect_manage_kit/devconnect_manage_kit.dart';\n\n"
            'void main() async {\n'
            '  await DevConnect.initAndRunApp(\n'
            "    appName: 'MyApp',\n"
            '    runApp: () async => runApp(const MyApp()),\n'
            '  );\n'
            '}',
      ),
    ],
  ),
  Guide(
    tab: TipTab.sdk,
    icon: LucideIcons.bot,
    color: const Color(0xFF3DDC84),
    title: 'Android',
    summary: s.guideSdkAndroidSummary,
    steps: s.guideSdkAndroidSteps,
    tip: s.guideSdkAndroidTip,
    code: const [
      (
        'app/build.gradle.kts',
        'implementation("io.github.buivietphi:devconnect-android:1.1.0")',
      ),
      (
        'MyApp.kt',
        'class MyApp : Application() {\n'
            '    override fun onCreate() {\n'
            '        super.onCreate()\n'
            '        DevConnect.installForApp(\n'
            '            context = this,\n'
            '            appName = "MyApp",\n'
            '            enabled = BuildConfig.DEBUG,\n'
            '        )\n'
            '    }\n'
            '}',
      ),
      (
        'OkHttp',
        'OkHttpClient.Builder()\n'
            '    .addInterceptor(DevConnect.okHttpInterceptor())\n'
            '    .build()',
      ),
    ],
  ),
  Guide(
    tab: TipTab.advanced,
    icon: LucideIcons.server,
    color: _teal,
    title: s.guideMockApiTitle,
    summary: s.guideMockApiSummary,
    steps: s.guideMockApiSteps,
    tip: s.guideMockApiTip,
    route: '/mock-server',
  ),
  Guide(
    tab: TipTab.advanced,
    icon: LucideIcons.signal,
    color: _amber,
    title: s.guideNetworkConditionsTitle,
    summary: s.guideNetworkConditionsSummary,
    steps: s.guideNetworkConditionsSteps,
    tip: s.guideNetworkConditionsTip,
    route: '/network',
  ),
  Guide(
    tab: TipTab.advanced,
    icon: LucideIcons.repeat,
    color: _blue,
    title: s.guideReplayTitle,
    summary: s.guideReplaySummary,
    steps: s.guideReplaySteps,
    tip: s.guideReplayTip,
    route: '/network',
  ),
  Guide(
    tab: TipTab.advanced,
    icon: LucideIcons.fileDown,
    color: _purple,
    title: s.guideHarExportTitle,
    summary: s.guideHarExportSummary,
    steps: s.guideHarExportSteps,
    tip: s.guideHarExportTip,
    route: '/network',
  ),
  Guide(
    tab: TipTab.advanced,
    icon: LucideIcons.database,
    color: const Color(0xFFA371F7),
    title: s.guideDatabaseQueryTitle,
    summary: s.guideDatabaseQuerySummary,
    steps: s.guideDatabaseQuerySteps,
    tip: s.guideDatabaseQueryTip,
    route: '/database',
    code: const [
      (
        'React Native',
        'DevConnect.registerDatabase("app.db", (sql) => db.getAllAsync(sql));',
      ),
      ('Flutter', "DevConnect.registerDatabase('app.db', db.rawQuery);"),
      (
        'Android',
        'DevConnect.registerDatabase("app.db") { sql -> db.rawQuery(sql, null) }',
      ),
    ],
  ),
  Guide(
    tab: TipTab.advanced,
    icon: LucideIcons.braces,
    color: _orange,
    title: s.guideBigJsonTitle,
    summary: s.guideBigJsonSummary,
    steps: s.guideBigJsonSteps,
    tip: s.guideBigJsonTip,
    route: '/network',
  ),
  Guide(
    tab: TipTab.advanced,
    icon: LucideIcons.squareTerminal,
    color: _green,
    title: s.guideCustomCommandsTitle,
    summary: s.guideCustomCommandsSummary,
    steps: s.guideCustomCommandsSteps,
    tip: s.guideCustomCommandsTip,
    route: '/commands',
    code: const [
      (
        'React Native',
        'DevConnect.registerCommand("clearCache", () => {\n'
            '  return { cleared: true };\n'
            '});',
      ),
      (
        'Flutter',
        "DevConnect.registerCommand('clearCache', (args) {\n"
            "  return {'cleared': true};\n"
            '});',
      ),
      (
        'Android',
        'DevConnect.registerCommand("clearCache") { args ->\n'
            '    mapOf("cleared" to true)\n'
            '}',
      ),
    ],
  ),
];
