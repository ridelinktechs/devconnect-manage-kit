// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DevConnect 管理工具';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get clear => '清除';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get start => '启动';

  @override
  String get stop => '停止';

  @override
  String get on => '开启';

  @override
  String get off => '关闭';

  @override
  String get autoScroll => '自动滚动';

  @override
  String get newestFirst => '最新优先';

  @override
  String get oldestFirst => '最旧优先';

  @override
  String get clearAll => '全部清除';

  @override
  String get maintenance => '维护';

  @override
  String get clearAllCache => '清除所有缓存';

  @override
  String get clearAllCacheDesc =>
      '断开所有设备并清除所有内存数据（日志、网络捕获、状态、性能等）。您的设置（主题、语言、端口）将被保留。';

  @override
  String get clearAllCacheConfirm =>
      '清除所有缓存？\n\n这将断开所有已连接的设备并清除内存中的所有日志、网络捕获、状态变更、性能指标和基准测试结果。\n\n您的设置（主题、语言、端口）将被保留。';

  @override
  String get cacheCleared => '已清除所有缓存。设置已保留。';

  @override
  String clearAllCacheFailed(Object error) {
    return '清除缓存失败：$error';
  }

  @override
  String get deviceHistory => '已缓存的设备';

  @override
  String get deviceHistoryDesc => '所有曾连接到此桌面端的设备。条目跨重启持久保存,您可以查看之前有哪些设备连接过。';

  @override
  String get noDeviceHistory => '尚无设备连接';

  @override
  String get deviceHistoryEmptyHint => '通过 SDK 连接设备后,设备将显示在此处。条目跨重启持久保存。';

  @override
  String get restarting => '正在重启…';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get markOnline => '标记为在线';

  @override
  String get markOffline => '标记为离线';

  @override
  String get deviceOnline => '在线';

  @override
  String get deviceOffline => '离线';

  @override
  String lastSeen(Object time) {
    return '最后在线 $time';
  }

  @override
  String firstSeen(Object time) {
    return '首次连接 $time';
  }

  @override
  String get forgetDevice => '忘记';

  @override
  String get forgetAllOffline => '忘记所有离线';

  @override
  String get forgetAllDevices => '全部忘记';

  @override
  String get forgetDeviceConfirm => '忘记此设备?\n\n将从历史记录中删除。下次连接时会作为新条目重新出现。';

  @override
  String get forgetAllOfflineConfirm => '忘记所有离线设备?\n\n将删除所有未连接的条目。在线设备会保留。';

  @override
  String get forgetAllDevicesConfirm =>
      '忘记所有已缓存的设备?\n\n将清除整个历史记录,包括在线设备。它们会在重新连接时再次出现。';

  @override
  String get deviceForgotten => '设备已忘记';

  @override
  String devicesForgotten(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已忘记 $count 台设备',
      one: '已忘记 1 台设备',
      zero: '未忘记任何设备',
    );
    return '$_temp0';
  }

  @override
  String connectionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连接 $count 次',
      one: '连接 1 次',
      zero: '从未连接',
    );
    return '$_temp0';
  }

  @override
  String get restartServer => '重启服务器';

  @override
  String portOccupied(Object port) {
    return '端口 $port 已被占用';
  }

  @override
  String get serverRestarted => '服务器已重启';

  @override
  String get restartFailed => '重启失败';

  @override
  String portStillInUse(Object port) {
    return '端口 $port 仍被其他进程占用';
  }

  @override
  String couldNotRestart(Object port) {
    return '无法在端口 $port 重启';
  }

  @override
  String listeningOnPort(Object port) {
    return '正在监听端口 $port';
  }

  @override
  String waitingForReconnect(Object port) {
    return '端口 $port · 等待设备重新连接';
  }

  @override
  String reconnectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台设备已重连',
      one: '1 台设备已重连',
      zero: '0 已重连',
    );
    return '$_temp0';
  }

  @override
  String get reloadApp => '重新加载应用';

  @override
  String get reloadAppHotReload => '热重载';

  @override
  String get reloadAppHotRestart => '热重启';

  @override
  String get reloadAppMetro => '重载 Metro';

  @override
  String get reloadAppNoDevices => '无设备连接';

  @override
  String get reloadSent => '已发送重新加载';

  @override
  String sentReloadTo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已向 $count 台设备发送重新加载',
      one: '已向 1 台设备发送重新加载',
      zero: '未指定任何设备',
    );
    return '$_temp0';
  }

  @override
  String get screenshotSaved => '截图已保存';

  @override
  String get screenshotFailed => '截图失败';

  @override
  String get reveal => '打开';

  @override
  String get captureFull => '完整';

  @override
  String get captureTab => '标签页';

  @override
  String get captureFullTooltip => '将完整详细信息截图';

  @override
  String get captureTabTooltip => '仅截图当前标签页';

  @override
  String get captureAsImage => '截图';

  @override
  String get captureDetailAsImage => '将详细信息截图';

  @override
  String get noData => '无数据';

  @override
  String get noItems => '无项目';

  @override
  String get searchHint => '搜索...';

  @override
  String get filterHint => '筛选...';

  @override
  String get value => '值';

  @override
  String get key => '键';

  @override
  String get metadata => '元数据';

  @override
  String get duration => '持续时间';

  @override
  String get error => '错误';

  @override
  String get json => 'JSON';

  @override
  String get tree => 'Tree';

  @override
  String get code => 'Code';

  @override
  String get raw => '原始';

  @override
  String get format => '格式';

  @override
  String get pretty => '美化';

  @override
  String get collapse => '折叠';

  @override
  String get showMore => '显示更多';

  @override
  String get noHeaders => '无标头';

  @override
  String get inProgress => '处理中';

  @override
  String get inProgressDots => '处理中...';

  @override
  String hideShowTooltip(Object action, Object label) {
    return '$action $label';
  }

  @override
  String get hide => '隐藏';

  @override
  String get show => '显示';

  @override
  String get steps => '步骤';

  @override
  String get portInUse => '端口已被占用。请关闭使用此端口的其他应用，或在设置中选择其他端口。';

  @override
  String portInUseShort(Object port) {
    return '端口 $port 已被占用。请关闭使用此端口的其他应用，或在上方输入其他端口并按启动。';
  }

  @override
  String failedToStartServer(Object msg) {
    return '无法启动服务器：$msg';
  }

  @override
  String failedToStartServerOnPort(Object msg, Object port) {
    return '无法在端口 $port 上启动服务器：$msg';
  }

  @override
  String get settings => '设置';

  @override
  String get server => '服务器';

  @override
  String get serverRunning => '服务器运行中';

  @override
  String get serverStopped => '服务器已停止';

  @override
  String get port => '端口';

  @override
  String deviceCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台设备',
      one: '1 台设备',
      zero: '0 台设备',
    );
    return '$_temp0';
  }

  @override
  String get network => '网络';

  @override
  String get hostname => '主机名';

  @override
  String get noNetworkInterfaces => '未找到网络接口';

  @override
  String copiedIp(Object ip) {
    return '已复制 $ip';
  }

  @override
  String connectedDevices(Object count) {
    return '已连接设备 ($count)';
  }

  @override
  String get noDevicesConnected => '无设备连接';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get dark => '深色';

  @override
  String get light => '浅色';

  @override
  String get bottom => '底部';

  @override
  String get top => '顶部';

  @override
  String get language => '语言';

  @override
  String get tabVisibility => '标签页可见性';

  @override
  String get tabVisibilityDesc => '切换标签页的可见性。禁用的标签页会显示锁定图标，其数据将从所有事件中排除。';

  @override
  String get detailView => '详细视图';

  @override
  String get detailViewDesc => '记住请求/响应内容的显示方式并控制标签页切换动画。';

  @override
  String get dataRetention => '数据保留';

  @override
  String get dataRetentionDesc =>
      '应用于每个功能列表的硬上限。当列表超过上限时,最早的条目将按 FIFO 顺序删除。待处理的异步操作将被保留。';

  @override
  String get maxItems => '最大条目数';

  @override
  String get dataRetentionHelper => '无限制保留所有条目。较低的值可释放内存,但会丢失历史记录。';

  @override
  String get allEventsDisplay => '所有事件显示';

  @override
  String get allEventsDisplayDesc => '聚合的所有事件列表的仅查看过滤器。底层日志不会被删除 — 切换回无限制即可恢复。';

  @override
  String get allEventsDisplayHelper => '较低的值仅保留最近的 N 条记录,代价是较早的历史记录。';

  @override
  String get bodyView => '内容视图';

  @override
  String get tabAnimation => '标签页动画';

  @override
  String get tabAnimationDuration => '持续时间';

  @override
  String get codeModeDesc => '代码模式根据已连接的 SDK 导出为 TypeScript / Dart / Kotlin。';

  @override
  String get treeModeDesc => '树形模式以可展开/折叠的节点层级显示数据,适合浏览深度嵌套的值。';

  @override
  String get jsonModeDesc => 'JSON 模式将数据呈现为单一、带语法高亮、易于复制的 JSON 文档。';

  @override
  String get captureDataJson => '截图数据(当前模式下的键 + 值)';

  @override
  String get captureDataText => '截图数据(键 + 值作为文本)';

  @override
  String get copyKey => '复制键';

  @override
  String get usbConnection => 'USB 连接';

  @override
  String get android => 'Android';

  @override
  String get ios => 'iOS';

  @override
  String get runAdbReverse => '运行 ADB Reverse';

  @override
  String adbNotFound(Object home) {
    return '找不到 adb。\nHOME=$home';
  }

  @override
  String adbReverseOk(Object path) {
    return 'adb reverse OK ($path)';
  }

  @override
  String adbError(Object error) {
    return 'adb 错误：$error';
  }

  @override
  String adbException(Object error) {
    return 'adb 异常：$error';
  }

  @override
  String get devices => '设备';

  @override
  String get adbDevices => 'ADB 设备';

  @override
  String get wifiAutoConnect =>
      'iPhone 通过 Wi‑Fi 连接：请让它与这台 Mac 处于同一网络。只插 USB 数据线无法连接。';

  @override
  String get quickStart => '快速入门';

  @override
  String get installSdk => '安装 SDK';

  @override
  String get initialize => '初始化';

  @override
  String get connect => '连接';

  @override
  String get supportDevConnect => '支持 DevConnect';

  @override
  String get supportDevConnectDesc =>
      'DevConnect 管理工具是免费且开源的。如果它对您的工作流程有帮助，请考虑支持开发。';

  @override
  String get kofi => 'Ko-fi';

  @override
  String get paypal => 'PayPal';

  @override
  String get ethernet => '以太网';

  @override
  String get wifi => 'WiFi';

  @override
  String get vpn => 'VPN';

  @override
  String get bridge => '桥接';

  @override
  String get loopback => '回环';

  @override
  String get console => '控制台';

  @override
  String get state => '状态';

  @override
  String get storage => '存储';

  @override
  String get database => '数据库';

  @override
  String get performance => '性能';

  @override
  String get memoryLeaks => '内存泄漏';

  @override
  String get history => '历史记录';

  @override
  String get noNetworkRequests => '无网络请求';

  @override
  String get apiCallsAppearHere => 'API 调用将实时显示在这里';

  @override
  String clearStaleButton(Object count) {
    return '过期 ($count)';
  }

  @override
  String clearStaleTooltip(Object count) {
    return '清除 $count 个超过 10 分钟未响应的挂起请求';
  }

  @override
  String clearStaleSnackbar(Object count) {
    return '已清除 $count 个过期请求 (挂起 > 10 分钟)';
  }

  @override
  String memorySafetyOverflow(Object count) {
    return '内存安全: 已从 open-trips 缓存中丢弃 $count 个过期网络条目';
  }

  @override
  String get sdkTipsPill => 'Tips lib';

  @override
  String get sdkTipsHeader => '库兼容性';

  @override
  String get sdkTipsSubtitle => '为确保所有数据完整显示,请确保使用的是最新版本的库。';

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
    return 'v$version · 最新';
  }

  @override
  String sdkTipsPillUpdate(Object version) {
    return 'v$version · 更新';
  }

  @override
  String get sdkTipsInstalled => '当前';

  @override
  String get sdkTipsLatestLabel => '最新';

  @override
  String get sdkTipsUpdate => '更新';

  @override
  String get sdkTipsChecking => '检查中';

  @override
  String get sdkTipsOffline => '无法检查';

  @override
  String get sdkTipsRetry => '重试';

  @override
  String get sdkTipsCheckProject => '在项目中运行此命令，查看当前版本：';

  @override
  String get sdkTipsInstallLatest => '安装最新版本：';

  @override
  String get appUpdateTitle => 'DevConnect 版本';

  @override
  String get appUpdateAvailable => '有新版本可用。';

  @override
  String get appUpdateUpToDate => '已是最新版本。';

  @override
  String get appUpdateViewRelease => '查看发布说明';

  @override
  String devicesConnected(Object count) {
    return '已连接 $count 台';
  }

  @override
  String get devicesAll => '全部';

  @override
  String devicesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台设备',
    );
    return '$_temp0';
  }

  @override
  String get commandsTitle => '自定义命令';

  @override
  String get commandsNoDevice => '连接设备后即可运行其命令。';

  @override
  String get commandsEmptyHint =>
      '应用尚未注册命令。可在应用中用 DevConnect.registerCommand(name, handler) 添加，或输入命令名直接运行。';

  @override
  String get commandsName => '命令';

  @override
  String get commandsArgs => '参数 — JSON 对象（可选）';

  @override
  String get commandsArgsInvalid => '参数必须是 JSON 对象。';

  @override
  String get commandsRun => '运行';

  @override
  String commandsTarget(Object device) {
    return '在 $device 上运行';
  }

  @override
  String get commandsHistoryEmpty => '运行的命令结果会显示在这里。';

  @override
  String get commandsNoResponse => '无响应。应用是否注册了该命令？';

  @override
  String get dbTables => '表';

  @override
  String get dbRefresh => '重新加载表';

  @override
  String get dbNoDevice => '连接设备后即可浏览其数据库。';

  @override
  String get dbSelectDevice => '在底部栏选择设备以浏览其数据库。';

  @override
  String get dbNoDatabases =>
      '应用尚未注册数据库。可用 DevConnect.registerDatabase(name, query) 添加，然后重新加载表。';

  @override
  String get dbRun => '运行';

  @override
  String get dbRunHint => '选择一个表或编写 SQL';

  @override
  String get dbRunHintSubtitle => '选择表即可预览前 50 行。';

  @override
  String dbRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 行',
    );
    return '$_temp0';
  }

  @override
  String dbTruncated(Object count) {
    return '仅前 $count 行';
  }

  @override
  String get dbFilterTables => '筛选表';

  @override
  String get dbData => '数据';

  @override
  String get dbStructure => '结构';

  @override
  String dbColumnCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 列',
    );
    return '$_temp0';
  }

  @override
  String get dbNoResponse =>
      '无响应。应用是否用 DevConnect.registerDatabase 注册了数据库？需要最新的 SDK。';

  @override
  String get stateToolsTab => '控制';

  @override
  String get stateNoDevice => '在底部栏选择设备，以监视、快照并操控其状态。';

  @override
  String get stateNoState => '该设备尚未上报任何状态。';

  @override
  String get stateSubscriptions => '订阅';

  @override
  String get stateSubscriptionsHint =>
      '固定一个路径以实时查看它的值，例如 auth.user.name 或 cart.items[0].price。所有平台都可用，无需在应用中写代码；读取的是最新一次变更的 state：Redux 为整个 store，Zustand、MobX、Riverpod 或 ViewModel 则是最后变更的 store 或 provider。';

  @override
  String get statePinPath => '固定路径';

  @override
  String get statePathMissing => '（状态中不存在）';

  @override
  String get stateRemove => '移除';

  @override
  String get stateSnapshots => '快照';

  @override
  String get stateSnapshotsHint =>
      '保存最新的 state，之后再发回应用以复现问题或跳过冗长的表单。保存在所有平台都可用；Restore 需要应用通过 onStateRestore 应用该 state（React Native、Flutter 和 Android）。';

  @override
  String get stateTakeSnapshot => '拍摄快照';

  @override
  String stateKeys(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个键',
    );
    return '$_temp0';
  }

  @override
  String get stateRestore => '恢复';

  @override
  String get stateRestoreHere => '将应用状态恢复到此时';

  @override
  String get stateSaveSnapshot => '保存为快照';

  @override
  String get stateSnapshotSaved => '快照已保存';

  @override
  String get stateRestoreSent => '已发送状态恢复';

  @override
  String get stateDispatch => '派发 action';

  @override
  String get stateDispatchHint =>
      '向应用发送一个 action（带 \"type\" 的 JSON 对象，例如 \"LOGOUT\"）。React Native 会在通过 connectReduxStore(store) 接入的 Redux store 中执行；Flutter 和 Android 会把它交给 onReduxDispatch。';

  @override
  String get stateDispatchButton => '派发';

  @override
  String get stateDispatchSent => 'action 已派发';

  @override
  String stateSetupIn(String platform) {
    return '在 $platform 应用中设置';
  }

  @override
  String get stateActionInvalid => 'action 必须是 JSON 对象。';

  @override
  String get stateRecentActions => '最近';

  @override
  String get jsonTreeView => '树';

  @override
  String get jsonTableView => '表格';

  @override
  String get jsonSearchHint => '搜索键和值';

  @override
  String get jsonExportCsv => '下载表格 (CSV)';

  @override
  String get jsonTableNoMatch => '没有匹配的行';

  @override
  String get jsonPrevMatch => '上一个匹配';

  @override
  String get jsonNextMatch => '下一个匹配';

  @override
  String get jsonExpandAll => '全部展开';

  @override
  String get jsonCollapseAll => '全部折叠';

  @override
  String get jsonCopyKey => '复制键';

  @override
  String get jsonCopyValue => '复制值';

  @override
  String get jsonCopyPath => '复制路径';

  @override
  String get jsonKeyCopied => '已复制键';

  @override
  String get jsonValueCopied => '已复制值';

  @override
  String get jsonPathCopied => '已复制路径';

  @override
  String jsonShowMore(int count, int remaining) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return '再显示 $countString 项（剩余 $remainingString 项）';
  }

  @override
  String jsonLongValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '共 $countString 个字符，复制可获取全部';
  }

  @override
  String jsonPrettyCut(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '显示前 $shownString 行，共 $totalString 行。复制或保存可获取全部内容。';
  }

  @override
  String jsonTableTruncated(Object count) {
    return '仅显示前 $count 行。';
  }

  @override
  String get networkErrors => '错误';

  @override
  String get networkSearchBodies => '同时搜索请求和响应正文';

  @override
  String get networkExportHar => '将列出的请求导出为 HAR';

  @override
  String get networkNothingToExport => '没有可导出的请求';

  @override
  String get fileSaved => '文件已保存';

  @override
  String get consoleGroupRepeats => '合并重复日志';

  @override
  String get consoleOccurrences => '重复记录';

  @override
  String get consoleNoMatchTitle => '没有匹配的日志';

  @override
  String get consoleNoMatchSubtitle => '移除筛选条件即可重新显示。';

  @override
  String get consoleShowAllLevels => '显示所有级别';

  @override
  String get consoleClearSearch => '清除搜索';

  @override
  String get consoleResetFilters => '重置筛选';

  @override
  String get consoleExport => '导出日志';

  @override
  String get consoleExportText => '文本 (.txt)';

  @override
  String get consoleExportJson => 'JSON (.json)';

  @override
  String get consoleNothingToExport => '没有可导出的日志';

  @override
  String get errorSymbolicate => '符号化';

  @override
  String get errorSymbolicated => '已映射到源码';

  @override
  String get errorSymbolicateFailed =>
      '无法解析此堆栈：无法连接 Metro，且此构建未上传 source map（SDK 中的 uploadSourceMap）。';

  @override
  String get storageTabHistory => '历史';

  @override
  String get storageTabKeyValue => '键值';

  @override
  String get storageKvNoDevice => '在底部栏选择设备以查看和编辑其存储。';

  @override
  String get storageKvEmpty =>
      '暂无可编辑的存储。请用 SDK 包装存储（DevConnectAsyncStorage.wrap、DevConnectMMKV.wrap、DevConnectSharedPreferences.wrap…）— 需要最新的 SDK。';

  @override
  String get storageKvRefresh => '重新加载';

  @override
  String get storageKvAdd => '添加键';

  @override
  String get storageKvEdit => '编辑值';

  @override
  String get storageKvDelete => '删除键';

  @override
  String get storageKvClear => '全部清除';

  @override
  String storageKvClearConfirm(Object storage) {
    return '删除 $storage 中的所有键？此操作无法撤销。';
  }

  @override
  String get storageKvKey => '键';

  @override
  String get storageKvValue => '值';

  @override
  String get storageKvSave => '保存';

  @override
  String get storageKvFilter => '筛选键';

  @override
  String get storageNoMatchTitle => '没有匹配的操作';

  @override
  String get storageNoMatchSubtitle => '移除筛选条件即可重新显示。';

  @override
  String get storageShowAllOps => '显示所有操作';

  @override
  String get storageShowAllTypes => '显示所有存储类型';

  @override
  String get storageCopyValue => '复制值';

  @override
  String get storageKvNoMatch => '没有匹配的键';

  @override
  String storageFilterHide(String name) {
    return '隐藏 $name';
  }

  @override
  String storageFilterShow(String name) {
    return '显示 $name';
  }

  @override
  String get deepLinkTitle => '打开深层链接';

  @override
  String get deepLinkHint => '应用会像点击了其链接一样打开它。';

  @override
  String get deepLinkOpen => '打开';

  @override
  String get deepLinkSent => '已发送深层链接';

  @override
  String get devMenu => '打开开发菜单';

  @override
  String get networkReplay => '重放请求';

  @override
  String get networkReplaySent => '已重新发送请求 — 将显示为新的一行';

  @override
  String get networkConditions => '网络条件';

  @override
  String get networkPresetNormal => '正常';

  @override
  String get networkPresetSlow => '慢速 (+500 ms)';

  @override
  String get networkPresetSlow3g => '慢速 3G (~2 秒)';

  @override
  String get networkPresetOffline => '离线';

  @override
  String get networkTabHttpHint =>
      '应用通过 fetch、XHR、axios、Dio、OkHttp… 发出的 HTTP 请求';

  @override
  String get networkTabProtocolsHint =>
      '普通 HTTP 之外的流量：GraphQL 操作、WebSocket 消息和 gRPC 调用';

  @override
  String get networkTabMockAuditHint => '由 Mock Server 规则代替真实网络响应的请求';

  @override
  String get protocolGraphqlHint => '通过 SDK 的 GraphQL link / 拦截器发送的查询和变更';

  @override
  String get protocolWebsocketHint => 'WebSocket 连接及每个收发的帧';

  @override
  String get protocolGrpcHint => 'gRPC 调用（Android SDK 拦截器）';

  @override
  String get layoutTitle => '布局';

  @override
  String get layoutCapture => '捕获';

  @override
  String get layoutHint => '捕获应用当前屏幕以查看其元素树。将鼠标悬停在截图上可高亮元素，点击可查看其属性。';

  @override
  String get layoutNoDevice => '连接应用或选择设备以检查其布局。';

  @override
  String get layoutNoScreenshot =>
      '该应用未提供截图，仅显示元素轮廓。React Native：使用 DevConnect.registerScreenshot 添加。';

  @override
  String get layoutPickElement => '悬停或点击截图上的元素，或在树中选择一个。';

  @override
  String get layoutTree => '元素树';

  @override
  String get layoutProperties => '属性';

  @override
  String get layoutTreeError => '无法读取元素树';

  @override
  String get layoutSearchHint => '按名称或值查找';

  @override
  String get layoutAppOnly => '仅显示应用元素';

  @override
  String get layoutFit => '适应窗口';

  @override
  String get layoutActualSize => '实际大小';

  @override
  String get layoutZoomIn => '放大';

  @override
  String get layoutZoomOut => '缩小';

  @override
  String get layoutZoomLevel => '缩放比例';

  @override
  String get layoutZoomToSelection => '缩放到所选元素';

  @override
  String get layoutClose => '关闭截图';

  @override
  String get layoutCopyName => '复制名称';

  @override
  String get layoutCopyJson => '复制为 JSON';

  @override
  String get layoutExport => '导出';

  @override
  String get layoutSavePng => '保存截图 (PNG)';

  @override
  String get layoutSaveJson => '保存快照 (JSON)';

  @override
  String get layoutNoAnswer => '应用没有响应。布局功能需要支持布局的 DevConnect SDK，并以调试版本运行。';

  @override
  String get layoutTruncated => '树过大：仅捕获了前一部分。';

  @override
  String get layoutState => '状态';

  @override
  String get layoutMeasureHint => '⌥ + 悬停：测量距离';

  @override
  String get networkTitle => '网络';

  @override
  String get filterUrls => '筛选 URL...';

  @override
  String get copyUrl => '复制 URL';

  @override
  String get urlCopied => '已复制 URL';

  @override
  String get copyPath => '复制路径';

  @override
  String get pathCopied => '已复制路径';

  @override
  String get copyCurl => '复制 cURL';

  @override
  String get curlCopied => '已复制 cURL';

  @override
  String get copyRequest => '复制请求';

  @override
  String get requestCopied => '已复制请求';

  @override
  String get copyResponse => '复制响应';

  @override
  String get responseCopied => '已复制响应';

  @override
  String get requestBody => '请求内容';

  @override
  String get responseBody => '响应内容';

  @override
  String get requestHeaders => '请求标头';

  @override
  String get responseHeaders => '响应标头';

  @override
  String get headers => '标头';

  @override
  String get request => '请求';

  @override
  String get response => '响应';

  @override
  String get timing => '计时';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String noLabel(Object label) {
    return '无$label';
  }

  @override
  String get noStorageData => '无存储数据';

  @override
  String get storageEntriesAppearHere =>
      'SharedPreferences、AsyncStorage 和 Hive 条目将显示在这里';

  @override
  String get storageTitle => '存储';

  @override
  String get filterKeys => '筛选键...';

  @override
  String get read => '读取';

  @override
  String get write => '写入';

  @override
  String get delete => '删除';

  @override
  String get noEventsYet => '暂无事件';

  @override
  String get startAppToSeeEvents => '使用 DevConnect SDK 启动应用以查看事件';

  @override
  String get eventsAppearHere => '事件将实时显示在这里';

  @override
  String get allEventsTitle => '所有事件';

  @override
  String get stopped => '已停止';

  @override
  String get searchEvents => '搜索事件...';

  @override
  String get logDetail => '日志详细信息';

  @override
  String get networkDetail => '网络详细信息';

  @override
  String get stateDetail => '状态详细信息';

  @override
  String get storageDetail => '存储详细信息';

  @override
  String get displayDetail => '显示详细信息';

  @override
  String get asyncOperation => '异步操作';

  @override
  String get errorDetail => '错误详细信息';

  @override
  String get tag => '标签';

  @override
  String get message => '消息';

  @override
  String get stackTrace => '堆栈跟踪';

  @override
  String get noLogsYet => '暂无日志';

  @override
  String get connectDeviceToSeeLogs => '连接设备并开始记录以在此处查看条目';

  @override
  String get consoleTitle => '控制台';

  @override
  String get searchLogs => '搜索日志...';

  @override
  String get clearConsole => '清除控制台';

  @override
  String get copyMessage => '复制消息';

  @override
  String get logCopied => '已复制日志';

  @override
  String get closePanel => '关闭面板';

  @override
  String hideShowLogs(Object action, Object label) {
    return '$action $label 日志';
  }

  @override
  String get errors => '错误';

  @override
  String get searchErrors => '搜索错误...';

  @override
  String get clearErrors => '清除错误';

  @override
  String get totalErrors => '错误总数';

  @override
  String get fatalCrash => '致命/崩溃';

  @override
  String get noErrorsCaptured => '未捕获到错误';

  @override
  String get errorsAppearHere => '来自 React Native 和 Flutter 的错误将显示在这里';

  @override
  String get stackTraceCopied => '已复制堆栈跟踪';

  @override
  String get noStackTrace => '无堆栈跟踪';

  @override
  String get platform => '平台';

  @override
  String get severity => '严重程度';

  @override
  String get source => '来源';

  @override
  String get deviceId => '设备 ID';

  @override
  String get deviceInfo => '设备信息';

  @override
  String get details => '详细信息';

  @override
  String hideShowErrors(Object action, Object label) {
    return '$action $label 错误';
  }

  @override
  String get noStateChanges => '无状态变更';

  @override
  String get stateChangesAppearHere => 'Redux、BLoC、Riverpod 和 MobX 状态变更将显示在这里';

  @override
  String get stateInspectorTitle => '状态检查器';

  @override
  String changesCount(Object count) {
    return '$count 个变更';
  }

  @override
  String changeCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个变更',
      one: '1 个变更',
      zero: '0 个变更',
    );
    return '$_temp0';
  }

  @override
  String get filterActions => '筛选操作...';

  @override
  String get newestAtTop => '最新在顶部';

  @override
  String get newestAtBottom => '最新在底部';

  @override
  String get noChanges => '无变更';

  @override
  String get diff => '差异';

  @override
  String get before => '之前';

  @override
  String get after => '之后';

  @override
  String get noChangesDetected => '未检测到变更';

  @override
  String get noBenchmarks => '无基准测试';

  @override
  String get useBenchmarkSdk => '在 SDK 中使用 benchmarkStart/Step/Stop 来衡量性能';

  @override
  String get benchmarksTitle => '基准测试';

  @override
  String get searchBenchmarks => '搜索基准测试...';

  @override
  String get total => '总计';

  @override
  String get avg => '平均';

  @override
  String get min => '最小';

  @override
  String get max => '最大';

  @override
  String get p50 => 'P50';

  @override
  String get end => '结束';

  @override
  String stepsCount(Object count) {
    return '步骤 ($count)';
  }

  @override
  String get noIntermediateSteps => '未记录中间步骤';

  @override
  String get noPerformanceData => '无性能数据';

  @override
  String get connectAppToProfile => '连接应用与 DevConnect SDK 以开始分析';

  @override
  String get stopRecording => '停止录制';

  @override
  String get startRecording => '开始录制';

  @override
  String get performanceProfiler => '性能分析器';

  @override
  String slowFrames(Object count) {
    return '慢帧数：$count';
  }

  @override
  String get systemStatus => '系统状态';

  @override
  String get startup => '启动';

  @override
  String get battery => '电池';

  @override
  String get emulator => '模拟器';

  @override
  String get drainRate => '耗电速率';

  @override
  String get thermal => '温度';

  @override
  String get diskRead => '磁盘读取';

  @override
  String get diskWrite => '磁盘写入';

  @override
  String get anr => 'ANR';

  @override
  String get charging => '充电中';

  @override
  String get normal => '正常';

  @override
  String get fair => '一般';

  @override
  String get serious => '严重';

  @override
  String get critical => '危急';

  @override
  String get reqs => '请求';

  @override
  String get live => '实时';

  @override
  String get reqPerSec => '请求/秒';

  @override
  String get err => '错误';

  @override
  String get waitingForRequests => '等待请求...';

  @override
  String get waitingForData => '等待数据...';

  @override
  String get noMemoryLeaksDetected => '未检测到内存泄漏';

  @override
  String get connectAppToMonitorLeaks => '连接应用与 DevConnect SDK 以监控内存泄漏';

  @override
  String get memoryLeakDetection => '内存泄漏检测';

  @override
  String get warning => '警告';

  @override
  String get info => '信息';

  @override
  String get detail => '详细信息';

  @override
  String get retainedSize => '保留大小';

  @override
  String get timestamp => '时间戳';

  @override
  String get undisposedController => '未释放的 Controller';

  @override
  String get undisposedStream => '未释放的 Stream';

  @override
  String get undisposedTimer => '未释放的 Timer';

  @override
  String get undisposedAnimation => '未释放的 Animation';

  @override
  String get widgetLeak => 'Widget 泄漏';

  @override
  String get growingCollection => '增长中的集合';

  @override
  String get custom => '自定义';

  @override
  String get smoothScrolling => '平滑滚动';

  @override
  String get smoothScrollingDesc => '为鼠标滚轮事件添加平滑动画。如果遇到卡顿或性能下降，请关闭此选项。';

  @override
  String get smoothScrollingDuration => '滚动持续时间';

  @override
  String get smoothScrollingDurationDesc => '滚动动画的持续时间（毫秒）。';

  @override
  String binaryBody(String label) {
    return '$label 正文为二进制';
  }

  @override
  String binaryBodySize(String kb, int bytes) {
    return '$kb ($bytes 字节)';
  }

  @override
  String get binaryBodyHint => '通过 X-Amz-Target 请求头识别操作。';

  @override
  String get openWithDefaultApp => '用默认应用打开';

  @override
  String get tipsAndShortcuts => '提示与快捷方式';

  @override
  String get tipsAndShortcutsDesc => '最常用工作流程的快速指南。点击任意卡片查看详情。';

  @override
  String get tipAllEventsTitle => '所有事件流';

  @override
  String get tipAllEventsBody =>
      '一条实时时间线，汇集应用的日志、网络请求、state 变更、存储操作和错误，另含 display 和异步操作事件。';

  @override
  String get tipAllEventsSteps =>
      '在\"搜索事件...\"中输入，匹配消息、URL 路径、action、存储键或标签\n切换\"LOG\"、\"API\"、\"STATE\"和\"STORE\"筛选按钮；\"ERRORS\"只保留错误和失败的请求\n点击某一行查看详情；\"完整\"或\"Tab\"可将详情保存为图片\n在底部栏选择一台设备或\"全部\"，决定显示哪台设备的事件\n用\"最旧优先\"/\"最新优先\"切换顺序，用\"自动滚动\"跟随新事件';

  @override
  String get tipAllEventsTip =>
      '此处的\"全部清除\"会清空所有页面的列表——Console、Network、State、Storage、Errors 等——而不只是这个事件流。';

  @override
  String get tipNetworkTitle => '检查网络流量';

  @override
  String get tipNetworkBody =>
      '应用发出的 HTTP 请求，含标头、正文、状态和耗时，另有 GraphQL、WebSocket、gRPC 流量，以及被模拟规则响应的请求。gRPC 仅来自 Android SDK。';

  @override
  String get tipNetworkSteps =>
      '点击某个请求，查看其\"Headers\"、\"Request\"、\"Response\"和\"Timing\"标签页\n按方法、\"2xx\"/\"3xx\"/\"错误\"筛选，或在\"筛选 URL...\"中输入部分 URL\n开启\"同时搜索请求和响应正文\"，即可在 payload 内部一并搜索\n点击面板中的\"复制 cURL\"获取 curl 命令；右键点击某一行可选择\"重放请求\"\n打开\"Protocols\"查看 GraphQL、WebSocket 和 gRPC，或打开\"Mock Audit\"查看被模拟的请求';

  @override
  String get tipNetworkTip =>
      'generate_204、captive.apple.com 等连通性检测请求默认隐藏，直到搜索内容匹配到它们才会显示。';

  @override
  String get tipConsoleTitle => 'Console 日志';

  @override
  String get tipConsoleBody =>
      '应用的日志行会实时显示，并附带级别、标签和时间——包括 React Native 的 console 调用、Flutter 的 print 和 debugPrint，以及 Android 的 println。';

  @override
  String get tipConsoleSteps =>
      '切换\"DEBUG\"、\"INFO\"、\"WARN\"和\"ERROR\"，显示或隐藏对应级别\n在\"搜索日志...\"中输入，匹配消息文本或标签\n点击某一行，查看其标签、消息、元数据和堆栈跟踪（如有）\n保持\"合并重复日志\"开启，可把连续相同的日志行折叠成一行并计数\n用\"导出日志\"把筛选后的列表保存为\"文本 (.txt)\"或\"JSON (.json)\"';

  @override
  String get tipConsoleTip =>
      '普通的 console.log、print 和 println 日志都以 DEBUG 级别到达——关闭\"DEBUG\"即可只保留信息、警告和错误。';

  @override
  String get tipStateTitle => 'State 检查器';

  @override
  String get tipStateBody =>
      '应用上报的每一次 state 变更，附带对应的 action 以及变更前后的 state——React Native 上的 Redux、Zustand、MobX 等，Flutter 上的 BLoC、Riverpod 和 Provider，Android 上的 ViewModel。';

  @override
  String get tipStateSteps =>
      '打开\"Timeline\"标签页——它会列出所有 state 库的变更；用标题栏的标签可逐个显示或隐藏\n在\"筛选操作...\"中输入，匹配 action 或 store 名称\n点击某次变更，再在\"差异\"、\"之前\"和\"之后\"之间切换\n使用\"将应用状态恢复到此时\"（需要 DevConnect.onStateRestore）或\"保存为快照\"\n打开\"控制\"，可固定 state 路径、创建快照并分发 Redux action';

  @override
  String get tipStateTip =>
      '\"差异\"仅在 SDK 发送了差异数据时才有内容——Redux、Zustand 和 MobX 会发送；Flutter 和 Android 不会，此时请对比\"之前\"和\"之后\"。';

  @override
  String get tipStorageTitle => '应用存储';

  @override
  String get tipStorageBody =>
      '显示你用 SDK 包装的存储（AsyncStorage、MMKV、SharedPreferences、Hive 等）上的每一次读取、写入和删除，以及受支持存储的当前键——可直接在此编辑。';

  @override
  String get tipStorageSteps =>
      '在\"历史记录\"中选择\"读取\"、\"写入\"或\"删除\"，并切换\"AS\"、\"SP\"等存储筛选按钮\n在\"筛选键...\"中输入一个键，查看对它的所有操作；值也会被匹配\n点击某一行，查看该操作的值、大小、存储和时间\n打开\"Key-Value\"查看某个存储的当前键，再使用\"添加键\"、\"编辑值\"或\"删除键\"\n点击\"重新加载\"，从应用获取最新内容';

  @override
  String get tipStorageTip =>
      '在\"历史记录\"中，\"全部清除\"只清空这份日志；在\"Key-Value\"中，\"全部清除\"会删除应用存储中的所有键。';

  @override
  String get tipDatabaseTitle => 'SQLite 数据库';

  @override
  String get tipDatabaseBody =>
      '浏览并查询应用通过 DevConnect.registerDatabase 注册的 SQLite 数据库：表（含行数）、SQL 输入框和结果表格。';

  @override
  String get tipDatabaseSteps =>
      '在应用中用 DevConnect.registerDatabase 注册数据库\n点击某个表，预览它的前 50 行\n编辑 SQL，点击\"运行\"执行你自己的查询\n再次点击\"运行\"重新查询——结果不会自动刷新\n点击\"重新加载表\"，刷新表列表和行数';

  @override
  String get tipDatabaseTip => '要排序，请在查询中加入 ORDER BY——点击列标题不会排序。';

  @override
  String get tipPerformanceTitle => '性能分析器';

  @override
  String get tipPerformanceBody =>
      '实时图表，展示应用的 FPS、CPU、内存和网络活动，以及 SDK 上报的帧耗时、线程、电池、温度状态、磁盘 I/O、启动时间和 ANR。';

  @override
  String get tipPerformanceSteps =>
      '在底部栏选择一台设备——选择\"全部\"时，图表会混合所有应用的采样数据\n查看工具栏中实时的\"FPS\"、\"MEM\"、\"CPU\"和\"SLOW\"指标\n将鼠标悬停在图表上，查看精确数值以及它是多久之前收到的\n在\"系统状态\"中查看启动时间、电池消耗、温度状态、磁盘 I/O 和 ANR\n用\"截图\"把图表保存为 PNG，用\"清除\"重新开始';

  @override
  String get tipPerformanceTip =>
      '将鼠标悬停在 FPS 行的红色徽章上，可查看慢帧的平均耗时和最差耗时，以及最近 5 个慢帧。';

  @override
  String get tipLeaksTitle => '内存泄漏检测';

  @override
  String get tipLeaksBody =>
      '来自应用的泄漏警告：三个 SDK 都会自动检测到的内存持续增长、React Native 上超过 50 个活跃的 timer，以及你用 DevConnect.reportMemoryLeak 上报的任何内容。';

  @override
  String get tipLeaksSteps =>
      '查看工具栏中红色、黄色和蓝色的计数：严重、警告和信息\n点击某一行，查看其\"详细信息\"、\"保留大小\"、\"堆栈跟踪\"和\"元数据\"（如有上报）\n在内存增长的行中查看\"元数据\"，了解每次采样以及总增长量（单位 MB）\n用 DevConnect.reportMemoryLeak 上报你自己发现的泄漏，例如未 dispose 的 controller 或 stream\n点击\"清除\"，重复可疑的操作流程，留意是否出现新警告';

  @override
  String get tipLeaksTip => '内存默认每 10 秒采样一次；持续增长超过 20 MB 才会警告，超过 40 MB 则升级为严重。';

  @override
  String get tipBenchmarkTitle => '基准测试';

  @override
  String get tipBenchmarkBody =>
      '对你用 SDK 的 benchmark 调用包裹的代码计时，另有每个 SDK 自行记录的 App Startup 和 App Background 运行。';

  @override
  String get tipBenchmarkSteps =>
      '用 DevConnect.benchmarkStart 和 benchmarkStop 包裹代码——React Native 则以 benchmark 开始\n用 benchmarkStep 标记各个阶段（Flutter、React Native）；Android 的运行没有步骤\n点击某次运行，查看其\"启动\"、\"结束\"、\"持续时间\"以及各步骤的瀑布图\n在\"搜索基准测试...\"中输入，筛选列表和统计栏\n点击\"截图\"，把该次运行的面板保存为 PNG';

  @override
  String get tipBenchmarkTip =>
      '统计栏统计的是列表中的所有运行——搜索某一个标题，即可只看该基准测试的\"最小\"、\"平均\"和\"P50\"。';

  @override
  String get tipErrorsTitle => '错误';

  @override
  String get tipErrorsBody =>
      '列出应用上报的错误：React Native 的 JavaScript 错误和 console.error 调用、Flutter 的框架错误和 Dart 错误，以及 Android 的异常。';

  @override
  String get tipErrorsSteps =>
      'Flutter：用 DevConnect.initAndRunApp 启动应用——仅调用 init 不会安装错误捕获钩子\n点击\"JS\"、\"Native\"、\"Android\"和\"iOS\"按钮，显示或隐藏对应平台\n在\"搜索错误...\"中输入，匹配消息、来源或堆栈跟踪\n点击某个错误，打开其\"Message\"、\"Stack Trace\"和\"Details\"标签页\n对于 React Native 的堆栈，点击\"符号化\"，通过 Metro 把堆栈帧映射到你的源码';

  @override
  String get tipErrorsTip =>
      'Flutter 错误带有其所在设备的 Android 或 iOS 标签——没有单独的 Flutter 按钮。';

  @override
  String get tipMockTitle => 'Mock Server';

  @override
  String get tipMockBody =>
      '保存模拟的 API 响应——方法、URL 正则、状态、标头、正文以及可选的延迟——并安装到所选设备上，让匹配的请求根本不会到达网络。';

  @override
  String get tipMockSteps =>
      'Android：先把 DevConnect.mockServerInterceptor() 添加到你的 OkHttpClient\n选择一台设备，点击\"Add rule\"，填写各字段，再点击\"Save changes\"\n点击\"Push all\"——此后的编辑、开关切换和删除会自动同步到设备\n拨动规则的开关可暂停它，或打开规则并按住\"Hold to delete\"删除它（Undo 可恢复）\n点击\"Clear device\"，移除设备上的所有规则并停止同步';

  @override
  String get tipMockTip =>
      '规则只保存在 DevConnect 的内存中——退出后就会丢失，但已同步的设备重新连接时会把规则拿回来。';

  @override
  String get tipHistoryTitle => '会话历史';

  @override
  String get tipHistoryBody =>
      '设备断开连接并持续 15 秒未重新连接后，它的日志、网络调用、state 变更和存储操作会作为只读会话保留在这里，直到它重新连接或 DevConnect 退出。';

  @override
  String get tipHistorySteps =>
      '点击某个会话，打开其\"All\"、\"Logs\"、\"Network\"、\"State\"和\"Storage\"标签页\n查看每张卡片上的断开时间和事件数量\n点击卡片上的 × 即可移除该会话\n点击\"Clear All\"清空列表';

  @override
  String get tipHistoryTip =>
      '同一台设备——或同一 IP 上的任何应用——一重新连接，会话就会消失，所以请在重新启动应用之前先查看。';

  @override
  String get tipDisplayTitle => 'Display';

  @override
  String get tipDisplayBody =>
      '显示应用通过 DevConnect.display() 发送的内容——名称、可选的预览文本、JSON 值和元数据。三个 SDK 都支持。';

  @override
  String get tipDisplaySteps =>
      '调用 DevConnect.display，传入名称，以及可选的值、预览和元数据\n浏览各行，最新的在最前：每行显示名称、预览和时间\n点击某一行，查看其\"Preview\"、JSON 格式的\"Value\"和\"Metadata\"\n点击\"Clear all\"清空列表';

  @override
  String get tipDisplayTip => '每次调用都会新增一行，而不是替换上一行——重复使用同一个名称即可形成时间线。';

  @override
  String get tipAsyncTitle => '异步操作';

  @override
  String get tipAsyncBody =>
      '列出应用通过 DevConnect.reportAsyncOperation() 上报的异步步骤——saga effect、任务、后台作业——并附带状态、耗时以及结果或错误。不会自动跟踪任何内容。';

  @override
  String get tipAsyncSteps =>
      '调用 reportAsyncOperation，传入类型、描述以及状态 start、resolve 或 reject\n在 React Native 上，用 trackAsync 包裹 promise，即可从开始到结束自动上报\n看徽章颜色：橙色表示已开始，绿色表示已 resolve，红色表示已 reject\n点击某一行，查看其详情、\"Result\"和\"Metadata\"\n点击\"Clear all\"清空列表';

  @override
  String get tipAsyncTip =>
      '给相关的调用设置相同的 sagaName——选中其中任何一个，整组调用都会列在\"Saga timeline\"下。';

  @override
  String get tipLayoutTitle => 'Layout 检查器';

  @override
  String get tipLayoutBody =>
      '捕获应用当前的屏幕及其元素树——Flutter widget、React Native 组件或 Android view——并显示每个元素的位置、大小、padding、margin 和 props。';

  @override
  String get tipLayoutSteps =>
      '选择设备并点击\"捕获\"，获取它的屏幕和元素树\n将鼠标悬停在截图上可高亮元素；点击即可选中\n也可以在\"元素树\"中选择，或用\"按名称或值查找\"搜索\n开启\"仅显示应用元素\"，隐藏库中的 widget（Flutter、React Native）\n查看\"属性\"——box model、位置、大小和 props——或点击\"复制为 JSON\"';

  @override
  String get tipLayoutTip =>
      'React Native 只有在你调用 DevConnect.registerScreenshot() 之后才会发送截图——否则只能看到元素轮廓。';

  @override
  String get settingsGroupConnection => '连接';

  @override
  String get settingsGroupConnectionDesc => '服务器、网络地址与 USB。';

  @override
  String get settingsGroupDevices => '设备';

  @override
  String get settingsGroupDevicesDesc => '当前连接的应用与以前连接过的设备。';

  @override
  String get settingsGroupAppearance => '外观';

  @override
  String get settingsGroupAppearanceDesc => '主题、语言与显示的标签页。';

  @override
  String get settingsGroupData => '显示与数据';

  @override
  String get settingsGroupDataDesc => '详情的显示方式与保留的历史量。';

  @override
  String get settingsGroupGuides => '指南';

  @override
  String get settingsGroupGuidesDesc => '快速开始、快捷键与使用技巧。';

  @override
  String get settingsGroupSupport => '支持';

  @override
  String get settingsGroupSupportDesc => '支持 DevConnect 持续发展。';

  @override
  String get tipsTabFeatures => '功能';

  @override
  String get tipsTabShortcuts => '快捷键';

  @override
  String get tipsTabConnect => '连接设备';

  @override
  String get tipsTabSdk => '集成 SDK';

  @override
  String get tipsTabAdvanced => '进阶';

  @override
  String get tipsSteps => '步骤';

  @override
  String get tipsKeys => '按键';

  @override
  String get tipsProTip => '小技巧';

  @override
  String get tipsPrevious => '上一个';

  @override
  String get tipsNext => '下一个';

  @override
  String get tipsDone => '完成';

  @override
  String get tipsOpenPage => '打开页面';

  @override
  String get tipsCopyCode => '复制';

  @override
  String get tipsCodeCopied => '已复制代码';

  @override
  String get tipsClose => '关闭';

  @override
  String get pageGuide => '如何使用此页面';

  @override
  String get guideReloadTitle => '重新加载应用';

  @override
  String get guideReloadSummary =>
      '在 DevConnect 的任意页面都能重新加载正在调试的应用，即使正在输入也行：Flutter 会重建 widget，React Native 会从 Metro 重新加载，Android 会重新创建当前 activity。';

  @override
  String get guideReloadSteps =>
      '[⌘ R] 重新加载所选应用；未选择应用时，重新加载所有已连接的应用\n[⇧ ⌘ R] 热重启：运行 Flutter 应用的 onHotRestartRequest，否则与 ⌘ R 一样重新加载\n也可以点击底部栏中的重新加载按钮——它们的工具提示会显示快捷键';

  @override
  String get guideReloadTip =>
      'Flutter 的 ⌘ R 会重建 widget 树并保留 state，但不会加载代码改动——这要用 IDE 的热重载。';

  @override
  String get guideJsonSearchTitle => '在正文中搜索';

  @override
  String get guideJsonSearchSummary =>
      'Tree、JSON 和代码视图（TypeScript、Dart 或 Kotlin）各有自己的搜索：不区分大小写，高亮所有匹配项，并滚动到当前匹配项。';

  @override
  String get guideJsonSearchSteps =>
      '[⌘ F] 跳到该视图的搜索框——请先点击正文内部\n[↵] 跳到下一个匹配项\n[⇧ ↵] 跳到上一个匹配项\n[Esc] 清除搜索';

  @override
  String get guideJsonSearchTip =>
      'Tree 搜索会展开节点并加载后续分页，最多显示 500 个匹配项；JSON 最多可统计 100,000 个。';

  @override
  String get guideLayoutZoomTitle => '缩放布局截图';

  @override
  String get guideLayoutZoomSummary =>
      '在 Layout 页面用键盘缩放截图并调整显示范围——截图一显示，这些按键立即生效。';

  @override
  String get guideLayoutZoomSteps =>
      '[⌘ +] 放大，每按一次 1.25×\n[⌘ −] 缩小\n[⌘ 0] 实际大小：100% 即应用自身的屏幕尺寸\n[⌘ 1] 让整个屏幕适应面板\n[⌘ 2] 缩放到所选元素';

  @override
  String get guideLayoutZoomTip => '点击缩放百分比可选择 50、100、200 或 400%；双指捏合缩放，拖动平移。';

  @override
  String get guideLayoutMeasureTitle => '测量间距';

  @override
  String get guideLayoutMeasureSummary =>
      '按住 Option，查看所选元素与指针下方元素之间的距离，就像设计工具那样。';

  @override
  String get guideLayoutMeasureSteps =>
      '选择一个元素：在截图上点击它，或在元素树中选择它\n[⌥] 按住 Option，指向另一个元素\n读取分开的元素之间的间隙；若其中一个元素包含另一个，则读取边距\n松开 Option，重新查看悬停元素的 box model';

  @override
  String get guideLayoutMeasureTip => '重叠的元素不显示距离——测量需要一个元素在另一个元素内部，或者两者之间有间隙。';

  @override
  String get guideLayoutTreeTitle => '浏览元素树';

  @override
  String get guideLayoutTreeSummary =>
      '点击某一行，或点击截图上的某个元素，让元素树获得焦点，然后用方向键在已捕获的元素树中移动。';

  @override
  String get guideLayoutTreeSteps =>
      '[↑ ↓] 移到上一行或下一行\n[→] 展开该行；再按一次进入它的第一个子元素\n[←] 收起该行；再按一次退到它的父元素\n[Esc] 取消选择';

  @override
  String get guideLayoutTreeTip =>
      '在\"按名称或值查找\"中输入，可搜索名称、props 和 state；用 ↵ 和 ⇧ ↵ 逐个跳转匹配项。';

  @override
  String get guideAndroidEmulatorTitle => 'Android 模拟器';

  @override
  String get guideAndroidEmulatorSummary =>
      'Android 模拟器中的应用通过 10.0.2.2（Genymotion：10.0.3.2）访问这台 Mac，所以无需任何设置。';

  @override
  String get guideAndroidEmulatorSteps =>
      '确认设置 › \"连接\" › \"服务器\"显示\"服务器运行中\"\n原生 Android：把 enabled = BuildConfig.DEBUG 传给 installForApp——默认是关闭的\n在模拟器中运行调试版本；不需要 adb reverse\n在窗口底部的设备栏中找到该应用';

  @override
  String get guideAndroidEmulatorTip =>
      'DevConnect 每次启动都使用端口 9090；在\"服务器\"中修改的端口在退出前一直有效，且 SDK 的端口必须与之一致。';

  @override
  String get guideAndroidUsbTitle => '通过 USB 连接 Android 手机';

  @override
  String get guideAndroidUsbSummary =>
      'adb reverse 通过数据线把手机的 localhost 指向这台 Mac，所以应用无需 Wi‑Fi 就能连接。';

  @override
  String get guideAndroidUsbSteps =>
      '开启 USB 调试，插上手机，并在提示时允许这台 Mac\n在设置 › \"连接\" › \"USB 连接\"中点击\"运行 ADB Reverse\"，或运行下方的命令\n启动应用——已在运行的原生 Android 应用需要重启\n连不上？在同一位置点击\"设备\"，检查 adb 能否识别到手机';

  @override
  String get guideAndroidUsbTip =>
      '重新插拔、重启 adb 或重新开机后需要再运行一次；插着多台设备时，请在终端中用 adb -s 加手机的序列号运行。';

  @override
  String get guideIosSimulatorTitle => 'iOS 模拟器';

  @override
  String get guideIosSimulatorSummary =>
      '模拟器与 Mac 共用网络，所以调试版本无需任何设置，就能通过 localhost 连到 DevConnect。';

  @override
  String get guideIosSimulatorSteps =>
      '确认设置 › \"连接\" › \"服务器\"显示\"服务器运行中\"\n在模拟器中运行应用的调试版本\n在窗口底部的设备栏中找到它';

  @override
  String get guideIosSimulatorTip =>
      '启动顺序无所谓：React Native 和 Flutter 应用会不断重试，所以在 DevConnect 启动几秒后就会连上。';

  @override
  String get guideIphoneTitle => 'iPhone';

  @override
  String get guideIphoneSummary =>
      '与 Mac 处于同一 Wi‑Fi 时，调试版本通常能自动找到 DevConnect；如果找不到，就把 Mac 的地址设为 host。';

  @override
  String get guideIphoneSteps =>
      '让 iPhone 和 Mac 连上同一个 Wi‑Fi——访客网络通常会阻止这一点\n运行调试版本，iOS 询问时允许访问本地网络\n等待几秒：React Native 通过 Metro 找到 Mac，Flutter 通过广播找到\n没有出现？从设置 › \"连接\" › \"网络\"中复制 Mac 的地址\n在 SDK 的 init 中把它设为 host（代码见下方），然后重启应用';

  @override
  String get guideIphoneTip => '只插 USB 数据线无法让 iPhone 上的应用连接——手机必须通过网络访问 Mac。';

  @override
  String get guideTroubleshootTitle => '应用连不上';

  @override
  String get guideTroubleshootSummary => '大多数连接问题都出在几个原因上——请按以下顺序检查。';

  @override
  String get guideTroubleshootSteps =>
      '设置 › \"连接\" › \"服务器\"显示\"服务器运行中\"，且没有端口错误\n应用是调试版本；原生 Android 还需要 enabled = BuildConfig.DEBUG\nSDK 的端口与服务器的端口一致——两者默认都是 9090\n手机与 Mac 在同一个 Wi‑Fi 下，或 Android 的端口已通过 adb reverse 转发\n使用 Wi‑Fi 时，macOS 允许 DevConnect 接受传入连接（系统设置 › 网络 › 防火墙）';

  @override
  String get guideTroubleshootTip =>
      '还是不行？从设置 › \"连接\" › \"网络\"中选一个地址作为 host，并传入 auto: false（Flutter：auto_: false），这样重新连接时仍会使用它。';

  @override
  String get guideSdkReactNativeSummary =>
      '安装该包并在启动时调用一次 init——此后 fetch 和 XHR（因此 axios 也在内）、console 日志、错误和性能都会被捕获。';

  @override
  String get guideSdkReactNativeSteps =>
      '用 yarn 或 npm 添加 devconnect-manage-kit（命令见下方）\n在启动时、第一个请求之前调用一次 DevConnect.init\n要捕获 state，请添加 devConnectReduxMiddleware（Redux）、devConnectMiddleware（Zustand）或 setupMobxSpy（MobX）\n运行调试版本——在发布版本中 init 不会执行任何操作，除非传入 enabled: true';

  @override
  String get guideSdkReactNativeTip =>
      'init 每次应用启动只运行一次，所以修改 host 或端口后要完整重新加载——Fast Refresh 会保留旧设置。';

  @override
  String get guideSdkFlutterSummary =>
      '通过 initAndRunApp 启动应用：基于 dart:io 的 HTTP（http、Dio、Chopper……）、print 和 debugPrint、错误和性能都会被捕获，无需额外代码。';

  @override
  String get guideSdkFlutterSteps =>
      '运行 flutter pub add devconnect_manage_kit\n在 main() 中用 DevConnect.initAndRunApp 启动应用，并传入异步的 runApp 回调\n使用 Riverpod 或 BLoC 时，在你的 observer 中调用 DevConnect.reportStateChange 或 reportBlocChange\n运行调试版本——profile 和 release 版本保持关闭';

  @override
  String get guideSdkFlutterTip =>
      '把 Firebase 和其他启动代码放进 runApp 回调里——在 initAndRunApp 之前调用 ensureInitialized() 会导致 zone 不匹配。';

  @override
  String get guideSdkAndroidSummary =>
      '添加 Maven Central 依赖，并在 Application.onCreate 中调用 installForApp：println 输出、崩溃、ANR、性能和 ViewModel state 都会被捕获；HTTP 则需要 OkHttp 拦截器。';

  @override
  String get guideSdkAndroidSteps =>
      '把 io.github.buivietphi:devconnect-android:1.1.0 添加到 app/build.gradle.kts\n在 Application.onCreate 中调用 DevConnect.installForApp，并传入 enabled = BuildConfig.DEBUG——默认是关闭的\n把 DevConnect.okHttpInterceptor() 添加到每个 OkHttpClient，Retrofit 使用的也不例外\n用 DCLog 代替 android.util.Log 打日志；使用 Timber 时，plant 一个调用 DevConnectTimberHelper.log 的 Tree\n确保应用的 manifest 声明了 INTERNET 权限';

  @override
  String get guideSdkAndroidTip =>
      'SDK 只在启动时查找一次 DevConnect——请先启动 DevConnect（以及 adb reverse），或重启应用。';

  @override
  String get guideMockApiTitle => '模拟 API';

  @override
  String get guideMockApiSummary => '用你自己的状态、标头和正文响应匹配的请求，还可以设置延迟，无需改动服务器或应用。';

  @override
  String get guideMockApiSteps =>
      '在底部栏选择一台设备，打开\"Mock Server\"，点击\"Add rule\"\n设置\"Method\"、\"Status\"、\"URL pattern\"（在 URL 任意位置匹配的正则表达式）和正文\n点击\"Save changes\"，再点击\"Push all\"——会发送完整的规则列表，之后的保存会自动同步到设备\n在 Network › \"Mock Audit\"中查看被规则响应的请求\n用规则的开关暂停它，或用\"Clear device\"移除所有规则';

  @override
  String get guideMockApiTip =>
      'Android 需要在 OkHttp 上添加 DevConnect.mockServerInterceptor()；React Native 只模拟 fetch 调用，不模拟 axios 或 XMLHttpRequest。';

  @override
  String get guideStateControlsTitle => '从桌面控制 state';

  @override
  String get guideStateControlsSummary =>
      'State Inspector 的 Controls 标签页可以监视 state 路径、保存可发回的快照，并向应用发送 action。';

  @override
  String get guideStateControlsSteps =>
      '在底部栏选择一台设备，打开 State Inspector 并切换到\"Controls\"标签页\nSubscriptions：固定 auth.user.name 这样的路径；所有平台都可用，无需在应用中写代码\nSnapshots：\"Take snapshot\"保存最新的 state；应用处理 onStateRestore 后，\"Restore\"即可把它发回\nDispatch action：输入带 \"type\"（例如 \"LOGOUT\"）的 JSON 对象并点击\"Dispatch\"；React Native 需要 connectReduxStore(store)，Flutter 和 Android 需要 onReduxDispatch\n它们引起的变更会在应用的 state 库上报后出现在\"Timeline\"中';

  @override
  String get guideStateControlsTip =>
      'Subscriptions 读取最后上报的 state：Redux 为整个 store，而 Zustand、MobX、Riverpod 或 ViewModel 只是最后变更的 store 或 provider。如果 Restore 或 Dispatch 没有效果，说明应用还没设置处理函数；处理函数抛出的错误会显示在 Console 中。';

  @override
  String get guideNetworkConditionsTitle => '慢速或离线网络';

  @override
  String get guideNetworkConditionsSummary =>
      '延迟应用的 HTTP 请求或让请求失败，无需改动设备设置——DevConnect 自身的连接不受影响。';

  @override
  String get guideNetworkConditionsSteps =>
      '在 Network 中，打开工具栏里的仪表图标菜单\"网络条件\"\n选择\"慢速 (+500 ms)\"或\"慢速 3G (~2 秒)\"，延迟每个请求\n选择\"离线\"，让请求立即失败，就像网络断了一样\n用完后选择\"正常\"——在此之前图标会一直高亮\n在 Android 上，只有通过 DevConnect.okHttpInterceptor() 的 OkHttp 流量会变慢';

  @override
  String get guideNetworkConditionsTip =>
      '它对所有已连接的应用生效，也对之后连接的应用生效，直到你选择\"正常\"。';

  @override
  String get guideReplayTitle => '重放请求';

  @override
  String get guideReplaySummary =>
      '让应用再次发送一个已捕获的请求——方法、URL、请求头和正文都相同——无需在应用界面里一步步点击。';

  @override
  String get guideReplaySteps =>
      '在 Network 中，右键点击某个请求并选择\"重放请求\"\n或者打开该请求，点击面板顶部的重复图标\n重放的请求会作为新的一行出现在列表中';

  @override
  String get guideReplayTip =>
      'Android 会通过应用自己的客户端和拦截器重新执行最近的 OkHttp 调用；Flutter 和 React Native 则原样重发已捕获的请求头。';

  @override
  String get guideHarExportTitle => '导出为 HAR';

  @override
  String get guideHarExportSummary =>
      '把 Network 列出的请求保存为标准的 HAR 1.2 文件——包含标头、正文、状态和耗时——以便用其他工具打开。';

  @override
  String get guideHarExportSteps =>
      '用设备、方法、状态和 URL 筛选器缩小\"HTTP\"列表的范围\n点击工具栏中的下载图标\"将列出的请求导出为 HAR\"\n选择 .har 文件的保存位置\n用 Chrome DevTools 或 Charles 打开它，或分享给你的团队';

  @override
  String get guideHarExportTip =>
      '只会保存 HTTP 列表中显示的内容，所以筛选条件决定文件内容；\"Protocols\"中的条目不包含在内。';

  @override
  String get guideDatabaseQueryTitle => '查询应用的数据库';

  @override
  String get guideDatabaseQuerySummary =>
      '直接在 DevConnect 中浏览应用内 SQLite 数据库的表，并对其执行 SQL。';

  @override
  String get guideDatabaseQuerySteps =>
      '在应用中用 DevConnect.registerDatabase 注册数据库（代码片段见下方）\n打开 Database，点击某个表，预览它的前 50 行\n编辑 SQL 并点击\"运行\"——结果最多显示 1,000 行\n应用修改了表之后，点击\"重新加载表\"';

  @override
  String get guideDatabaseQueryTip =>
      '查询会在你最近点击的那个表所属的数据库上运行；如果没点击过，则在第一个注册的数据库上运行。';

  @override
  String get guideBigJsonTitle => '大型正文';

  @override
  String get guideBigJsonSummary =>
      '大型正文打开时不会卡住 DevConnect：它们在后台解析，Tree 和 JSON 只构建屏幕上可见的部分。';

  @override
  String get guideBigJsonSteps =>
      '点击长 Tree 列表下方的\"再显示 … 项\"，加载接下来的 200 项\n对 Tree 中的长字符串使用\"复制值\"——Tree 只显示其前 2,000 个字符\n切换到 JSON，即可滚动和搜索整个文档\n在 JSON 中使用\"Copy JSON\"或\"Save as file\"——两者都会包含完整的正文\n超过 20,000 个字符的 JSON 行只显示开头；复制或保存即可获取全部内容';

  @override
  String get guideBigJsonTip =>
      '当正文是对象列表时，Tree 提供\"表格\"：它显示 500 行，但\"下载表格 (CSV)\"会保存所有匹配的行。';

  @override
  String get guideCustomCommandsTitle => '自定义命令';

  @override
  String get guideCustomCommandsSummary =>
      '从 DevConnect 运行应用内的代码——清除缓存、退出登录、生成测试数据——并查看它的返回结果。';

  @override
  String get guideCustomCommandsSteps =>
      '在应用中用 DevConnect.registerCommand 注册 handler（代码片段见下方）\n打开\"自定义命令\"，点击应用列出的某个命令，或输入它的名称\n如果命令需要参数，以 JSON 对象的形式添加\n点击\"运行\"，或在\"命令\"字段中按 ↵，然后在下方查看结果';

  @override
  String get guideCustomCommandsTip =>
      'Flutter 和 React Native 的 handler 可以是异步的；抛出的错误会作为结果显示，超过 10 秒没有回应则超时。';

  @override
  String get restart => '重启';

  @override
  String get serverAddressHint => '应用会连接到这个地址。';

  @override
  String get serverStoppedHint => '启动服务器后应用才能连接。';

  @override
  String get tabBenchmark => '基准测试';

  @override
  String get tabDisplay => '显示';

  @override
  String get tabAsync => '异步操作';

  @override
  String get tabLayout => '布局检查';

  @override
  String get tabCommands => '自定义命令';

  @override
  String get tabMockServer => '模拟服务器';

  @override
  String get tabsAlwaysShown => '所有事件和设置始终显示。';

  @override
  String get quickStartDesc => '安装 SDK，在应用中启动，然后连接。';

  @override
  String get quickStartNext => '下一步 — 在应用中启动';

  @override
  String get quickStartEmulator => '模拟器自动连接';

  @override
  String get quickStartWifi => 'Wi‑Fi 真机';

  @override
  String get quickStartUsb => 'USB 连接 Android';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class SZhCn extends SZh {
  SZhCn() : super('zh_CN');

  @override
  String get appTitle => 'DevConnect 管理工具';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get clear => '清除';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get start => '启动';

  @override
  String get stop => '停止';

  @override
  String get on => '开启';

  @override
  String get off => '关闭';

  @override
  String get autoScroll => '自动滚动';

  @override
  String get newestFirst => '最新优先';

  @override
  String get oldestFirst => '最旧优先';

  @override
  String get clearAll => '全部清除';

  @override
  String get maintenance => '维护';

  @override
  String get clearAllCache => '清除所有缓存';

  @override
  String get clearAllCacheDesc =>
      '断开所有设备并清除所有内存数据（日志、网络捕获、状态、性能等）。您的设置（主题、语言、端口）将被保留。';

  @override
  String get clearAllCacheConfirm =>
      '清除所有缓存？\n\n这将断开所有已连接的设备并清除内存中的所有日志、网络捕获、状态变更、性能指标和基准测试结果。\n\n您的设置（主题、语言、端口）将被保留。';

  @override
  String get cacheCleared => '已清除所有缓存。设置已保留。';

  @override
  String clearAllCacheFailed(Object error) {
    return '清除缓存失败：$error';
  }

  @override
  String get deviceHistory => '已缓存的设备';

  @override
  String get deviceHistoryDesc => '所有曾连接到此桌面端的设备。条目跨重启持久保存,您可以查看之前有哪些设备连接过。';

  @override
  String get noDeviceHistory => '尚无设备连接';

  @override
  String get deviceHistoryEmptyHint => '通过 SDK 连接设备后,设备将显示在此处。条目跨重启持久保存。';

  @override
  String get restarting => '正在重启…';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get markOnline => '标记为在线';

  @override
  String get markOffline => '标记为离线';

  @override
  String get deviceOnline => '在线';

  @override
  String get deviceOffline => '离线';

  @override
  String lastSeen(Object time) {
    return '最后在线 $time';
  }

  @override
  String firstSeen(Object time) {
    return '首次连接 $time';
  }

  @override
  String get forgetDevice => '忘记';

  @override
  String get forgetAllOffline => '忘记所有离线';

  @override
  String get forgetAllDevices => '全部忘记';

  @override
  String get forgetDeviceConfirm => '忘记此设备?\n\n将从历史记录中删除。下次连接时会作为新条目重新出现。';

  @override
  String get forgetAllOfflineConfirm => '忘记所有离线设备?\n\n将删除所有未连接的条目。在线设备会保留。';

  @override
  String get forgetAllDevicesConfirm =>
      '忘记所有已缓存的设备?\n\n将清除整个历史记录,包括在线设备。它们会在重新连接时再次出现。';

  @override
  String get deviceForgotten => '设备已忘记';

  @override
  String devicesForgotten(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已忘记 $count 台设备',
      one: '已忘记 1 台设备',
      zero: '未忘记任何设备',
    );
    return '$_temp0';
  }

  @override
  String connectionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连接 $count 次',
      one: '连接 1 次',
      zero: '从未连接',
    );
    return '$_temp0';
  }

  @override
  String get restartServer => '重启服务器';

  @override
  String portOccupied(Object port) {
    return '端口 $port 已被占用';
  }

  @override
  String get serverRestarted => '服务器已重启';

  @override
  String get restartFailed => '重启失败';

  @override
  String portStillInUse(Object port) {
    return '端口 $port 仍被其他进程占用';
  }

  @override
  String couldNotRestart(Object port) {
    return '无法在端口 $port 重启';
  }

  @override
  String listeningOnPort(Object port) {
    return '正在监听端口 $port';
  }

  @override
  String waitingForReconnect(Object port) {
    return '端口 $port · 等待设备重新连接';
  }

  @override
  String reconnectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台设备已重连',
      one: '1 台设备已重连',
      zero: '0 已重连',
    );
    return '$_temp0';
  }

  @override
  String get reloadApp => '重新加载应用';

  @override
  String get reloadAppHotReload => '热重载';

  @override
  String get reloadAppHotRestart => '热重启';

  @override
  String get reloadAppMetro => '重载 Metro';

  @override
  String get reloadAppNoDevices => '无设备连接';

  @override
  String get reloadSent => '已发送重新加载';

  @override
  String sentReloadTo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已向 $count 台设备发送重新加载',
      one: '已向 1 台设备发送重新加载',
      zero: '未指定任何设备',
    );
    return '$_temp0';
  }

  @override
  String get screenshotSaved => '截图已保存';

  @override
  String get screenshotFailed => '截图失败';

  @override
  String get reveal => '打开';

  @override
  String get captureFull => '完整';

  @override
  String get captureTab => '标签页';

  @override
  String get captureFullTooltip => '将完整详细信息截图';

  @override
  String get captureTabTooltip => '仅截图当前标签页';

  @override
  String get captureAsImage => '截图';

  @override
  String get captureDetailAsImage => '将详细信息截图';

  @override
  String get noData => '无数据';

  @override
  String get noItems => '无项目';

  @override
  String get searchHint => '搜索...';

  @override
  String get filterHint => '筛选...';

  @override
  String get value => '值';

  @override
  String get key => '键';

  @override
  String get metadata => '元数据';

  @override
  String get duration => '持续时间';

  @override
  String get error => '错误';

  @override
  String get json => 'JSON';

  @override
  String get tree => 'Tree';

  @override
  String get code => 'Code';

  @override
  String get raw => '原始';

  @override
  String get format => '格式';

  @override
  String get pretty => '美化';

  @override
  String get collapse => '折叠';

  @override
  String get showMore => '显示更多';

  @override
  String get noHeaders => '无标头';

  @override
  String get inProgress => '处理中';

  @override
  String get inProgressDots => '处理中...';

  @override
  String hideShowTooltip(Object action, Object label) {
    return '$action $label';
  }

  @override
  String get hide => '隐藏';

  @override
  String get show => '显示';

  @override
  String get steps => '步骤';

  @override
  String get portInUse => '端口已被占用。请关闭使用此端口的其他应用，或在设置中选择其他端口。';

  @override
  String portInUseShort(Object port) {
    return '端口 $port 已被占用。请关闭使用此端口的其他应用，或在上方输入其他端口并按启动。';
  }

  @override
  String failedToStartServer(Object msg) {
    return '无法启动服务器：$msg';
  }

  @override
  String failedToStartServerOnPort(Object msg, Object port) {
    return '无法在端口 $port 上启动服务器：$msg';
  }

  @override
  String get settings => '设置';

  @override
  String get server => '服务器';

  @override
  String get serverRunning => '服务器运行中';

  @override
  String get serverStopped => '服务器已停止';

  @override
  String get port => '端口';

  @override
  String deviceCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台设备',
      one: '1 台设备',
      zero: '0 台设备',
    );
    return '$_temp0';
  }

  @override
  String get network => '网络';

  @override
  String get hostname => '主机名';

  @override
  String get noNetworkInterfaces => '未找到网络接口';

  @override
  String copiedIp(Object ip) {
    return '已复制 $ip';
  }

  @override
  String connectedDevices(Object count) {
    return '已连接设备 ($count)';
  }

  @override
  String get noDevicesConnected => '无设备连接';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get dark => '深色';

  @override
  String get light => '浅色';

  @override
  String get bottom => '底部';

  @override
  String get top => '顶部';

  @override
  String get language => '语言';

  @override
  String get tabVisibility => '标签页可见性';

  @override
  String get tabVisibilityDesc => '切换标签页的可见性。禁用的标签页会显示锁定图标，其数据将从所有事件中排除。';

  @override
  String get detailView => '详细视图';

  @override
  String get detailViewDesc => '记住请求/响应内容的显示方式并控制标签页切换动画。';

  @override
  String get dataRetention => '数据保留';

  @override
  String get dataRetentionDesc =>
      '应用于每个功能列表的硬上限。当列表超过上限时,最早的条目将按 FIFO 顺序删除。待处理的异步操作将被保留。';

  @override
  String get maxItems => '最大条目数';

  @override
  String get dataRetentionHelper => '无限制保留所有条目。较低的值可释放内存,但会丢失历史记录。';

  @override
  String get allEventsDisplay => '所有事件显示';

  @override
  String get allEventsDisplayDesc => '聚合的所有事件列表的仅查看过滤器。底层日志不会被删除 — 切换回无限制即可恢复。';

  @override
  String get allEventsDisplayHelper => '较低的值仅保留最近的 N 条记录,代价是较早的历史记录。';

  @override
  String get bodyView => '内容视图';

  @override
  String get tabAnimation => '标签页动画';

  @override
  String get tabAnimationDuration => '持续时间';

  @override
  String get codeModeDesc => '代码模式根据已连接的 SDK 导出为 TypeScript / Dart / Kotlin。';

  @override
  String get treeModeDesc => '树形模式以可展开/折叠的节点层级显示数据,适合浏览深度嵌套的值。';

  @override
  String get jsonModeDesc => 'JSON 模式将数据呈现为单一、带语法高亮、易于复制的 JSON 文档。';

  @override
  String get captureDataJson => '截图数据(当前模式下的键 + 值)';

  @override
  String get captureDataText => '截图数据(键 + 值作为文本)';

  @override
  String get copyKey => '复制键';

  @override
  String get usbConnection => 'USB 连接';

  @override
  String get android => 'Android';

  @override
  String get ios => 'iOS';

  @override
  String get runAdbReverse => '运行 ADB Reverse';

  @override
  String adbNotFound(Object home) {
    return '找不到 adb。\nHOME=$home';
  }

  @override
  String adbReverseOk(Object path) {
    return 'adb reverse OK ($path)';
  }

  @override
  String adbError(Object error) {
    return 'adb 错误：$error';
  }

  @override
  String adbException(Object error) {
    return 'adb 异常：$error';
  }

  @override
  String get devices => '设备';

  @override
  String get adbDevices => 'ADB 设备';

  @override
  String get wifiAutoConnect =>
      'iPhone 通过 Wi‑Fi 连接：请让它与这台 Mac 处于同一网络。只插 USB 数据线无法连接。';

  @override
  String get quickStart => '快速入门';

  @override
  String get installSdk => '安装 SDK';

  @override
  String get initialize => '初始化';

  @override
  String get connect => '连接';

  @override
  String get supportDevConnect => '支持 DevConnect';

  @override
  String get supportDevConnectDesc =>
      'DevConnect 管理工具是免费且开源的。如果它对您的工作流程有帮助，请考虑支持开发。';

  @override
  String get kofi => 'Ko-fi';

  @override
  String get paypal => 'PayPal';

  @override
  String get ethernet => '以太网';

  @override
  String get wifi => 'WiFi';

  @override
  String get vpn => 'VPN';

  @override
  String get bridge => '桥接';

  @override
  String get loopback => '回环';

  @override
  String get console => '控制台';

  @override
  String get state => '状态';

  @override
  String get storage => '存储';

  @override
  String get database => '数据库';

  @override
  String get performance => '性能';

  @override
  String get memoryLeaks => '内存泄漏';

  @override
  String get history => '历史记录';

  @override
  String get noNetworkRequests => '无网络请求';

  @override
  String get apiCallsAppearHere => 'API 调用将实时显示在这里';

  @override
  String clearStaleButton(Object count) {
    return '过期 ($count)';
  }

  @override
  String clearStaleTooltip(Object count) {
    return '清除 $count 个超过 10 分钟未响应的挂起请求';
  }

  @override
  String clearStaleSnackbar(Object count) {
    return '已清除 $count 个过期请求 (挂起 > 10 分钟)';
  }

  @override
  String memorySafetyOverflow(Object count) {
    return '内存安全: 已从 open-trips 缓存中丢弃 $count 个过期网络条目';
  }

  @override
  String get sdkTipsPill => 'Tips lib';

  @override
  String get sdkTipsHeader => '库兼容性';

  @override
  String get sdkTipsSubtitle => '为确保所有数据完整显示,请确保使用的是最新版本的库。';

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
    return 'v$version · 最新';
  }

  @override
  String sdkTipsPillUpdate(Object version) {
    return 'v$version · 更新';
  }

  @override
  String get sdkTipsInstalled => '当前';

  @override
  String get sdkTipsLatestLabel => '最新';

  @override
  String get sdkTipsUpdate => '更新';

  @override
  String get sdkTipsChecking => '检查中';

  @override
  String get sdkTipsOffline => '无法检查';

  @override
  String get sdkTipsRetry => '重试';

  @override
  String get sdkTipsCheckProject => '在项目中运行此命令，查看当前版本：';

  @override
  String get sdkTipsInstallLatest => '安装最新版本：';

  @override
  String get appUpdateTitle => 'DevConnect 版本';

  @override
  String get appUpdateAvailable => '有新版本可用。';

  @override
  String get appUpdateUpToDate => '已是最新版本。';

  @override
  String get appUpdateViewRelease => '查看发布说明';

  @override
  String devicesConnected(Object count) {
    return '已连接 $count 台';
  }

  @override
  String get devicesAll => '全部';

  @override
  String devicesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台设备',
    );
    return '$_temp0';
  }

  @override
  String get commandsTitle => '自定义命令';

  @override
  String get commandsNoDevice => '连接设备后即可运行其命令。';

  @override
  String get commandsEmptyHint =>
      '应用尚未注册命令。可在应用中用 DevConnect.registerCommand(name, handler) 添加，或输入命令名直接运行。';

  @override
  String get commandsName => '命令';

  @override
  String get commandsArgs => '参数 — JSON 对象（可选）';

  @override
  String get commandsArgsInvalid => '参数必须是 JSON 对象。';

  @override
  String get commandsRun => '运行';

  @override
  String commandsTarget(Object device) {
    return '在 $device 上运行';
  }

  @override
  String get commandsHistoryEmpty => '运行的命令结果会显示在这里。';

  @override
  String get commandsNoResponse => '无响应。应用是否注册了该命令？';

  @override
  String get dbTables => '表';

  @override
  String get dbRefresh => '重新加载表';

  @override
  String get dbNoDevice => '连接设备后即可浏览其数据库。';

  @override
  String get dbSelectDevice => '在底部栏选择设备以浏览其数据库。';

  @override
  String get dbNoDatabases =>
      '应用尚未注册数据库。可用 DevConnect.registerDatabase(name, query) 添加，然后重新加载表。';

  @override
  String get dbRun => '运行';

  @override
  String get dbRunHint => '选择一个表或编写 SQL';

  @override
  String get dbRunHintSubtitle => '选择表即可预览前 50 行。';

  @override
  String dbRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 行',
    );
    return '$_temp0';
  }

  @override
  String dbTruncated(Object count) {
    return '仅前 $count 行';
  }

  @override
  String get dbFilterTables => '筛选表';

  @override
  String get dbData => '数据';

  @override
  String get dbStructure => '结构';

  @override
  String dbColumnCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 列',
    );
    return '$_temp0';
  }

  @override
  String get dbNoResponse =>
      '无响应。应用是否用 DevConnect.registerDatabase 注册了数据库？需要最新的 SDK。';

  @override
  String get stateToolsTab => '控制';

  @override
  String get stateNoDevice => '在底部栏选择设备，以监视、快照并操控其状态。';

  @override
  String get stateNoState => '该设备尚未上报任何状态。';

  @override
  String get stateSubscriptions => '订阅';

  @override
  String get stateSubscriptionsHint =>
      '固定一个路径以实时查看它的值，例如 auth.user.name 或 cart.items[0].price。所有平台都可用，无需在应用中写代码；读取的是最新一次变更的 state：Redux 为整个 store，Zustand、MobX、Riverpod 或 ViewModel 则是最后变更的 store 或 provider。';

  @override
  String get statePinPath => '固定路径';

  @override
  String get statePathMissing => '（状态中不存在）';

  @override
  String get stateRemove => '移除';

  @override
  String get stateSnapshots => '快照';

  @override
  String get stateSnapshotsHint =>
      '保存最新的 state，之后再发回应用以复现问题或跳过冗长的表单。保存在所有平台都可用；Restore 需要应用通过 onStateRestore 应用该 state（React Native、Flutter 和 Android）。';

  @override
  String get stateTakeSnapshot => '拍摄快照';

  @override
  String stateKeys(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个键',
    );
    return '$_temp0';
  }

  @override
  String get stateRestore => '恢复';

  @override
  String get stateRestoreHere => '将应用状态恢复到此时';

  @override
  String get stateSaveSnapshot => '保存为快照';

  @override
  String get stateSnapshotSaved => '快照已保存';

  @override
  String get stateRestoreSent => '已发送状态恢复';

  @override
  String get stateDispatch => '派发 action';

  @override
  String get stateDispatchHint =>
      '向应用发送一个 action（带 \"type\" 的 JSON 对象，例如 \"LOGOUT\"）。React Native 会在通过 connectReduxStore(store) 接入的 Redux store 中执行；Flutter 和 Android 会把它交给 onReduxDispatch。';

  @override
  String get stateDispatchButton => '派发';

  @override
  String get stateDispatchSent => 'action 已派发';

  @override
  String stateSetupIn(String platform) {
    return '在 $platform 应用中设置';
  }

  @override
  String get stateActionInvalid => 'action 必须是 JSON 对象。';

  @override
  String get stateRecentActions => '最近';

  @override
  String get jsonTreeView => '树';

  @override
  String get jsonTableView => '表格';

  @override
  String get jsonSearchHint => '搜索键和值';

  @override
  String get jsonExportCsv => '下载表格 (CSV)';

  @override
  String get jsonTableNoMatch => '没有匹配的行';

  @override
  String get jsonPrevMatch => '上一个匹配';

  @override
  String get jsonNextMatch => '下一个匹配';

  @override
  String get jsonExpandAll => '全部展开';

  @override
  String get jsonCollapseAll => '全部折叠';

  @override
  String get jsonCopyKey => '复制键';

  @override
  String get jsonCopyValue => '复制值';

  @override
  String get jsonCopyPath => '复制路径';

  @override
  String get jsonKeyCopied => '已复制键';

  @override
  String get jsonValueCopied => '已复制值';

  @override
  String get jsonPathCopied => '已复制路径';

  @override
  String jsonShowMore(int count, int remaining) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return '再显示 $countString 项（剩余 $remainingString 项）';
  }

  @override
  String jsonLongValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '共 $countString 个字符，复制可获取全部';
  }

  @override
  String jsonPrettyCut(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '显示前 $shownString 行，共 $totalString 行。复制或保存可获取全部内容。';
  }

  @override
  String jsonTableTruncated(Object count) {
    return '仅显示前 $count 行。';
  }

  @override
  String get networkErrors => '错误';

  @override
  String get networkSearchBodies => '同时搜索请求和响应正文';

  @override
  String get networkExportHar => '将列出的请求导出为 HAR';

  @override
  String get networkNothingToExport => '没有可导出的请求';

  @override
  String get fileSaved => '文件已保存';

  @override
  String get consoleGroupRepeats => '合并重复日志';

  @override
  String get consoleOccurrences => '重复记录';

  @override
  String get consoleNoMatchTitle => '没有匹配的日志';

  @override
  String get consoleNoMatchSubtitle => '移除筛选条件即可重新显示。';

  @override
  String get consoleShowAllLevels => '显示所有级别';

  @override
  String get consoleClearSearch => '清除搜索';

  @override
  String get consoleResetFilters => '重置筛选';

  @override
  String get consoleExport => '导出日志';

  @override
  String get consoleExportText => '文本 (.txt)';

  @override
  String get consoleExportJson => 'JSON (.json)';

  @override
  String get consoleNothingToExport => '没有可导出的日志';

  @override
  String get errorSymbolicate => '符号化';

  @override
  String get errorSymbolicated => '已映射到源码';

  @override
  String get errorSymbolicateFailed =>
      '无法解析此堆栈：无法连接 Metro，且此构建未上传 source map（SDK 中的 uploadSourceMap）。';

  @override
  String get storageTabHistory => '历史';

  @override
  String get storageTabKeyValue => '键值';

  @override
  String get storageKvNoDevice => '在底部栏选择设备以查看和编辑其存储。';

  @override
  String get storageKvEmpty =>
      '暂无可编辑的存储。请用 SDK 包装存储（DevConnectAsyncStorage.wrap、DevConnectMMKV.wrap、DevConnectSharedPreferences.wrap…）— 需要最新的 SDK。';

  @override
  String get storageKvRefresh => '重新加载';

  @override
  String get storageKvAdd => '添加键';

  @override
  String get storageKvEdit => '编辑值';

  @override
  String get storageKvDelete => '删除键';

  @override
  String get storageKvClear => '全部清除';

  @override
  String storageKvClearConfirm(Object storage) {
    return '删除 $storage 中的所有键？此操作无法撤销。';
  }

  @override
  String get storageKvKey => '键';

  @override
  String get storageKvValue => '值';

  @override
  String get storageKvSave => '保存';

  @override
  String get storageKvFilter => '筛选键';

  @override
  String get storageNoMatchTitle => '没有匹配的操作';

  @override
  String get storageNoMatchSubtitle => '移除筛选条件即可重新显示。';

  @override
  String get storageShowAllOps => '显示所有操作';

  @override
  String get storageShowAllTypes => '显示所有存储类型';

  @override
  String get storageCopyValue => '复制值';

  @override
  String get storageKvNoMatch => '没有匹配的键';

  @override
  String storageFilterHide(String name) {
    return '隐藏 $name';
  }

  @override
  String storageFilterShow(String name) {
    return '显示 $name';
  }

  @override
  String get deepLinkTitle => '打开深层链接';

  @override
  String get deepLinkHint => '应用会像点击了其链接一样打开它。';

  @override
  String get deepLinkOpen => '打开';

  @override
  String get deepLinkSent => '已发送深层链接';

  @override
  String get devMenu => '打开开发菜单';

  @override
  String get networkReplay => '重放请求';

  @override
  String get networkReplaySent => '已重新发送请求 — 将显示为新的一行';

  @override
  String get networkConditions => '网络条件';

  @override
  String get networkPresetNormal => '正常';

  @override
  String get networkPresetSlow => '慢速 (+500 ms)';

  @override
  String get networkPresetSlow3g => '慢速 3G (~2 秒)';

  @override
  String get networkPresetOffline => '离线';

  @override
  String get networkTabHttpHint =>
      '应用通过 fetch、XHR、axios、Dio、OkHttp… 发出的 HTTP 请求';

  @override
  String get networkTabProtocolsHint =>
      '普通 HTTP 之外的流量：GraphQL 操作、WebSocket 消息和 gRPC 调用';

  @override
  String get networkTabMockAuditHint => '由 Mock Server 规则代替真实网络响应的请求';

  @override
  String get protocolGraphqlHint => '通过 SDK 的 GraphQL link / 拦截器发送的查询和变更';

  @override
  String get protocolWebsocketHint => 'WebSocket 连接及每个收发的帧';

  @override
  String get protocolGrpcHint => 'gRPC 调用（Android SDK 拦截器）';

  @override
  String get layoutTitle => '布局';

  @override
  String get layoutCapture => '捕获';

  @override
  String get layoutHint => '捕获应用当前屏幕以查看其元素树。将鼠标悬停在截图上可高亮元素，点击可查看其属性。';

  @override
  String get layoutNoDevice => '连接应用或选择设备以检查其布局。';

  @override
  String get layoutNoScreenshot =>
      '该应用未提供截图，仅显示元素轮廓。React Native：使用 DevConnect.registerScreenshot 添加。';

  @override
  String get layoutPickElement => '悬停或点击截图上的元素，或在树中选择一个。';

  @override
  String get layoutTree => '元素树';

  @override
  String get layoutProperties => '属性';

  @override
  String get layoutTreeError => '无法读取元素树';

  @override
  String get layoutSearchHint => '按名称或值查找';

  @override
  String get layoutAppOnly => '仅显示应用元素';

  @override
  String get layoutFit => '适应窗口';

  @override
  String get layoutActualSize => '实际大小';

  @override
  String get layoutZoomIn => '放大';

  @override
  String get layoutZoomOut => '缩小';

  @override
  String get layoutZoomLevel => '缩放比例';

  @override
  String get layoutZoomToSelection => '缩放到所选元素';

  @override
  String get layoutClose => '关闭截图';

  @override
  String get layoutCopyName => '复制名称';

  @override
  String get layoutCopyJson => '复制为 JSON';

  @override
  String get layoutExport => '导出';

  @override
  String get layoutSavePng => '保存截图 (PNG)';

  @override
  String get layoutSaveJson => '保存快照 (JSON)';

  @override
  String get layoutNoAnswer => '应用没有响应。布局功能需要支持布局的 DevConnect SDK，并以调试版本运行。';

  @override
  String get layoutTruncated => '树过大：仅捕获了前一部分。';

  @override
  String get layoutState => '状态';

  @override
  String get layoutMeasureHint => '⌥ + 悬停：测量距离';

  @override
  String get networkTitle => '网络';

  @override
  String get filterUrls => '筛选 URL...';

  @override
  String get copyUrl => '复制 URL';

  @override
  String get urlCopied => '已复制 URL';

  @override
  String get copyPath => '复制路径';

  @override
  String get pathCopied => '已复制路径';

  @override
  String get copyCurl => '复制 cURL';

  @override
  String get curlCopied => '已复制 cURL';

  @override
  String get copyRequest => '复制请求';

  @override
  String get requestCopied => '已复制请求';

  @override
  String get copyResponse => '复制响应';

  @override
  String get responseCopied => '已复制响应';

  @override
  String get requestBody => '请求内容';

  @override
  String get responseBody => '响应内容';

  @override
  String get requestHeaders => '请求标头';

  @override
  String get responseHeaders => '响应标头';

  @override
  String get headers => '标头';

  @override
  String get request => '请求';

  @override
  String get response => '响应';

  @override
  String get timing => '计时';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String noLabel(Object label) {
    return '无$label';
  }

  @override
  String get noStorageData => '无存储数据';

  @override
  String get storageEntriesAppearHere =>
      'SharedPreferences、AsyncStorage 和 Hive 条目将显示在这里';

  @override
  String get storageTitle => '存储';

  @override
  String get filterKeys => '筛选键...';

  @override
  String get read => '读取';

  @override
  String get write => '写入';

  @override
  String get delete => '删除';

  @override
  String get noEventsYet => '暂无事件';

  @override
  String get startAppToSeeEvents => '使用 DevConnect SDK 启动应用以查看事件';

  @override
  String get eventsAppearHere => '事件将实时显示在这里';

  @override
  String get allEventsTitle => '所有事件';

  @override
  String get stopped => '已停止';

  @override
  String get searchEvents => '搜索事件...';

  @override
  String get logDetail => '日志详细信息';

  @override
  String get networkDetail => '网络详细信息';

  @override
  String get stateDetail => '状态详细信息';

  @override
  String get storageDetail => '存储详细信息';

  @override
  String get displayDetail => '显示详细信息';

  @override
  String get asyncOperation => '异步操作';

  @override
  String get errorDetail => '错误详细信息';

  @override
  String get tag => '标签';

  @override
  String get message => '消息';

  @override
  String get stackTrace => '堆栈跟踪';

  @override
  String get noLogsYet => '暂无日志';

  @override
  String get connectDeviceToSeeLogs => '连接设备并开始记录以在此处查看条目';

  @override
  String get consoleTitle => '控制台';

  @override
  String get searchLogs => '搜索日志...';

  @override
  String get clearConsole => '清除控制台';

  @override
  String get copyMessage => '复制消息';

  @override
  String get logCopied => '已复制日志';

  @override
  String get closePanel => '关闭面板';

  @override
  String hideShowLogs(Object action, Object label) {
    return '$action $label 日志';
  }

  @override
  String get errors => '错误';

  @override
  String get searchErrors => '搜索错误...';

  @override
  String get clearErrors => '清除错误';

  @override
  String get totalErrors => '错误总数';

  @override
  String get fatalCrash => '致命/崩溃';

  @override
  String get noErrorsCaptured => '未捕获到错误';

  @override
  String get errorsAppearHere => '来自 React Native 和 Flutter 的错误将显示在这里';

  @override
  String get stackTraceCopied => '已复制堆栈跟踪';

  @override
  String get noStackTrace => '无堆栈跟踪';

  @override
  String get platform => '平台';

  @override
  String get severity => '严重程度';

  @override
  String get source => '来源';

  @override
  String get deviceId => '设备 ID';

  @override
  String get deviceInfo => '设备信息';

  @override
  String get details => '详细信息';

  @override
  String hideShowErrors(Object action, Object label) {
    return '$action $label 错误';
  }

  @override
  String get noStateChanges => '无状态变更';

  @override
  String get stateChangesAppearHere => 'Redux、BLoC、Riverpod 和 MobX 状态变更将显示在这里';

  @override
  String get stateInspectorTitle => '状态检查器';

  @override
  String changesCount(Object count) {
    return '$count 个变更';
  }

  @override
  String changeCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个变更',
      one: '1 个变更',
      zero: '0 个变更',
    );
    return '$_temp0';
  }

  @override
  String get filterActions => '筛选操作...';

  @override
  String get newestAtTop => '最新在顶部';

  @override
  String get newestAtBottom => '最新在底部';

  @override
  String get noChanges => '无变更';

  @override
  String get diff => '差异';

  @override
  String get before => '之前';

  @override
  String get after => '之后';

  @override
  String get noChangesDetected => '未检测到变更';

  @override
  String get noBenchmarks => '无基准测试';

  @override
  String get useBenchmarkSdk => '在 SDK 中使用 benchmarkStart/Step/Stop 来衡量性能';

  @override
  String get benchmarksTitle => '基准测试';

  @override
  String get searchBenchmarks => '搜索基准测试...';

  @override
  String get total => '总计';

  @override
  String get avg => '平均';

  @override
  String get min => '最小';

  @override
  String get max => '最大';

  @override
  String get p50 => 'P50';

  @override
  String get end => '结束';

  @override
  String stepsCount(Object count) {
    return '步骤 ($count)';
  }

  @override
  String get noIntermediateSteps => '未记录中间步骤';

  @override
  String get noPerformanceData => '无性能数据';

  @override
  String get connectAppToProfile => '连接应用与 DevConnect SDK 以开始分析';

  @override
  String get stopRecording => '停止录制';

  @override
  String get startRecording => '开始录制';

  @override
  String get performanceProfiler => '性能分析器';

  @override
  String slowFrames(Object count) {
    return '慢帧数：$count';
  }

  @override
  String get systemStatus => '系统状态';

  @override
  String get startup => '启动';

  @override
  String get battery => '电池';

  @override
  String get emulator => '模拟器';

  @override
  String get drainRate => '耗电速率';

  @override
  String get thermal => '温度';

  @override
  String get diskRead => '磁盘读取';

  @override
  String get diskWrite => '磁盘写入';

  @override
  String get anr => 'ANR';

  @override
  String get charging => '充电中';

  @override
  String get normal => '正常';

  @override
  String get fair => '一般';

  @override
  String get serious => '严重';

  @override
  String get critical => '危急';

  @override
  String get reqs => '请求';

  @override
  String get live => '实时';

  @override
  String get reqPerSec => '请求/秒';

  @override
  String get err => '错误';

  @override
  String get waitingForRequests => '等待请求...';

  @override
  String get waitingForData => '等待数据...';

  @override
  String get noMemoryLeaksDetected => '未检测到内存泄漏';

  @override
  String get connectAppToMonitorLeaks => '连接应用与 DevConnect SDK 以监控内存泄漏';

  @override
  String get memoryLeakDetection => '内存泄漏检测';

  @override
  String get warning => '警告';

  @override
  String get info => '信息';

  @override
  String get detail => '详细信息';

  @override
  String get retainedSize => '保留大小';

  @override
  String get timestamp => '时间戳';

  @override
  String get undisposedController => '未释放的 Controller';

  @override
  String get undisposedStream => '未释放的 Stream';

  @override
  String get undisposedTimer => '未释放的 Timer';

  @override
  String get undisposedAnimation => '未释放的 Animation';

  @override
  String get widgetLeak => 'Widget 泄漏';

  @override
  String get growingCollection => '增长中的集合';

  @override
  String get custom => '自定义';

  @override
  String get smoothScrolling => '平滑滚动';

  @override
  String get smoothScrollingDesc => '为鼠标滚轮事件添加平滑动画。如果遇到卡顿或性能下降，请关闭此选项。';

  @override
  String get smoothScrollingDuration => '滚动持续时间';

  @override
  String get smoothScrollingDurationDesc => '滚动动画的持续时间（毫秒）。';

  @override
  String binaryBody(String label) {
    return '$label 正文为二进制';
  }

  @override
  String binaryBodySize(String kb, int bytes) {
    return '$kb ($bytes 字节)';
  }

  @override
  String get binaryBodyHint => '通过 X-Amz-Target 请求头识别操作。';

  @override
  String get openWithDefaultApp => '用默认应用打开';

  @override
  String get tipsAndShortcuts => '提示与快捷方式';

  @override
  String get tipsAndShortcutsDesc => '最常用工作流程的快速指南。点击任意卡片查看详情。';

  @override
  String get tipAllEventsTitle => '所有事件流';

  @override
  String get tipAllEventsBody =>
      '一条实时时间线，汇集应用的日志、网络请求、state 变更、存储操作和错误，另含 display 和异步操作事件。';

  @override
  String get tipAllEventsSteps =>
      '在\"搜索事件...\"中输入，匹配消息、URL 路径、action、存储键或标签\n切换\"LOG\"、\"API\"、\"STATE\"和\"STORE\"筛选按钮；\"ERRORS\"只保留错误和失败的请求\n点击某一行查看详情；\"完整\"或\"Tab\"可将详情保存为图片\n在底部栏选择一台设备或\"全部\"，决定显示哪台设备的事件\n用\"最旧优先\"/\"最新优先\"切换顺序，用\"自动滚动\"跟随新事件';

  @override
  String get tipAllEventsTip =>
      '此处的\"全部清除\"会清空所有页面的列表——Console、Network、State、Storage、Errors 等——而不只是这个事件流。';

  @override
  String get tipNetworkTitle => '检查网络流量';

  @override
  String get tipNetworkBody =>
      '应用发出的 HTTP 请求，含标头、正文、状态和耗时，另有 GraphQL、WebSocket、gRPC 流量，以及被模拟规则响应的请求。gRPC 仅来自 Android SDK。';

  @override
  String get tipNetworkSteps =>
      '点击某个请求，查看其\"Headers\"、\"Request\"、\"Response\"和\"Timing\"标签页\n按方法、\"2xx\"/\"3xx\"/\"错误\"筛选，或在\"筛选 URL...\"中输入部分 URL\n开启\"同时搜索请求和响应正文\"，即可在 payload 内部一并搜索\n点击面板中的\"复制 cURL\"获取 curl 命令；右键点击某一行可选择\"重放请求\"\n打开\"Protocols\"查看 GraphQL、WebSocket 和 gRPC，或打开\"Mock Audit\"查看被模拟的请求';

  @override
  String get tipNetworkTip =>
      'generate_204、captive.apple.com 等连通性检测请求默认隐藏，直到搜索内容匹配到它们才会显示。';

  @override
  String get tipConsoleTitle => 'Console 日志';

  @override
  String get tipConsoleBody =>
      '应用的日志行会实时显示，并附带级别、标签和时间——包括 React Native 的 console 调用、Flutter 的 print 和 debugPrint，以及 Android 的 println。';

  @override
  String get tipConsoleSteps =>
      '切换\"DEBUG\"、\"INFO\"、\"WARN\"和\"ERROR\"，显示或隐藏对应级别\n在\"搜索日志...\"中输入，匹配消息文本或标签\n点击某一行，查看其标签、消息、元数据和堆栈跟踪（如有）\n保持\"合并重复日志\"开启，可把连续相同的日志行折叠成一行并计数\n用\"导出日志\"把筛选后的列表保存为\"文本 (.txt)\"或\"JSON (.json)\"';

  @override
  String get tipConsoleTip =>
      '普通的 console.log、print 和 println 日志都以 DEBUG 级别到达——关闭\"DEBUG\"即可只保留信息、警告和错误。';

  @override
  String get tipStateTitle => 'State 检查器';

  @override
  String get tipStateBody =>
      '应用上报的每一次 state 变更，附带对应的 action 以及变更前后的 state——React Native 上的 Redux、Zustand、MobX 等，Flutter 上的 BLoC、Riverpod 和 Provider，Android 上的 ViewModel。';

  @override
  String get tipStateSteps =>
      '打开\"Timeline\"标签页——它会列出所有 state 库的变更；用标题栏的标签可逐个显示或隐藏\n在\"筛选操作...\"中输入，匹配 action 或 store 名称\n点击某次变更，再在\"差异\"、\"之前\"和\"之后\"之间切换\n使用\"将应用状态恢复到此时\"（需要 DevConnect.onStateRestore）或\"保存为快照\"\n打开\"控制\"，可固定 state 路径、创建快照并分发 Redux action';

  @override
  String get tipStateTip =>
      '\"差异\"仅在 SDK 发送了差异数据时才有内容——Redux、Zustand 和 MobX 会发送；Flutter 和 Android 不会，此时请对比\"之前\"和\"之后\"。';

  @override
  String get tipStorageTitle => '应用存储';

  @override
  String get tipStorageBody =>
      '显示你用 SDK 包装的存储（AsyncStorage、MMKV、SharedPreferences、Hive 等）上的每一次读取、写入和删除，以及受支持存储的当前键——可直接在此编辑。';

  @override
  String get tipStorageSteps =>
      '在\"历史记录\"中选择\"读取\"、\"写入\"或\"删除\"，并切换\"AS\"、\"SP\"等存储筛选按钮\n在\"筛选键...\"中输入一个键，查看对它的所有操作；值也会被匹配\n点击某一行，查看该操作的值、大小、存储和时间\n打开\"Key-Value\"查看某个存储的当前键，再使用\"添加键\"、\"编辑值\"或\"删除键\"\n点击\"重新加载\"，从应用获取最新内容';

  @override
  String get tipStorageTip =>
      '在\"历史记录\"中，\"全部清除\"只清空这份日志；在\"Key-Value\"中，\"全部清除\"会删除应用存储中的所有键。';

  @override
  String get tipDatabaseTitle => 'SQLite 数据库';

  @override
  String get tipDatabaseBody =>
      '浏览并查询应用通过 DevConnect.registerDatabase 注册的 SQLite 数据库：表（含行数）、SQL 输入框和结果表格。';

  @override
  String get tipDatabaseSteps =>
      '在应用中用 DevConnect.registerDatabase 注册数据库\n点击某个表，预览它的前 50 行\n编辑 SQL，点击\"运行\"执行你自己的查询\n再次点击\"运行\"重新查询——结果不会自动刷新\n点击\"重新加载表\"，刷新表列表和行数';

  @override
  String get tipDatabaseTip => '要排序，请在查询中加入 ORDER BY——点击列标题不会排序。';

  @override
  String get tipPerformanceTitle => '性能分析器';

  @override
  String get tipPerformanceBody =>
      '实时图表，展示应用的 FPS、CPU、内存和网络活动，以及 SDK 上报的帧耗时、线程、电池、温度状态、磁盘 I/O、启动时间和 ANR。';

  @override
  String get tipPerformanceSteps =>
      '在底部栏选择一台设备——选择\"全部\"时，图表会混合所有应用的采样数据\n查看工具栏中实时的\"FPS\"、\"MEM\"、\"CPU\"和\"SLOW\"指标\n将鼠标悬停在图表上，查看精确数值以及它是多久之前收到的\n在\"系统状态\"中查看启动时间、电池消耗、温度状态、磁盘 I/O 和 ANR\n用\"截图\"把图表保存为 PNG，用\"清除\"重新开始';

  @override
  String get tipPerformanceTip =>
      '将鼠标悬停在 FPS 行的红色徽章上，可查看慢帧的平均耗时和最差耗时，以及最近 5 个慢帧。';

  @override
  String get tipLeaksTitle => '内存泄漏检测';

  @override
  String get tipLeaksBody =>
      '来自应用的泄漏警告：三个 SDK 都会自动检测到的内存持续增长、React Native 上超过 50 个活跃的 timer，以及你用 DevConnect.reportMemoryLeak 上报的任何内容。';

  @override
  String get tipLeaksSteps =>
      '查看工具栏中红色、黄色和蓝色的计数：严重、警告和信息\n点击某一行，查看其\"详细信息\"、\"保留大小\"、\"堆栈跟踪\"和\"元数据\"（如有上报）\n在内存增长的行中查看\"元数据\"，了解每次采样以及总增长量（单位 MB）\n用 DevConnect.reportMemoryLeak 上报你自己发现的泄漏，例如未 dispose 的 controller 或 stream\n点击\"清除\"，重复可疑的操作流程，留意是否出现新警告';

  @override
  String get tipLeaksTip => '内存默认每 10 秒采样一次；持续增长超过 20 MB 才会警告，超过 40 MB 则升级为严重。';

  @override
  String get tipBenchmarkTitle => '基准测试';

  @override
  String get tipBenchmarkBody =>
      '对你用 SDK 的 benchmark 调用包裹的代码计时，另有每个 SDK 自行记录的 App Startup 和 App Background 运行。';

  @override
  String get tipBenchmarkSteps =>
      '用 DevConnect.benchmarkStart 和 benchmarkStop 包裹代码——React Native 则以 benchmark 开始\n用 benchmarkStep 标记各个阶段（Flutter、React Native）；Android 的运行没有步骤\n点击某次运行，查看其\"启动\"、\"结束\"、\"持续时间\"以及各步骤的瀑布图\n在\"搜索基准测试...\"中输入，筛选列表和统计栏\n点击\"截图\"，把该次运行的面板保存为 PNG';

  @override
  String get tipBenchmarkTip =>
      '统计栏统计的是列表中的所有运行——搜索某一个标题，即可只看该基准测试的\"最小\"、\"平均\"和\"P50\"。';

  @override
  String get tipErrorsTitle => '错误';

  @override
  String get tipErrorsBody =>
      '列出应用上报的错误：React Native 的 JavaScript 错误和 console.error 调用、Flutter 的框架错误和 Dart 错误，以及 Android 的异常。';

  @override
  String get tipErrorsSteps =>
      'Flutter：用 DevConnect.initAndRunApp 启动应用——仅调用 init 不会安装错误捕获钩子\n点击\"JS\"、\"Native\"、\"Android\"和\"iOS\"按钮，显示或隐藏对应平台\n在\"搜索错误...\"中输入，匹配消息、来源或堆栈跟踪\n点击某个错误，打开其\"Message\"、\"Stack Trace\"和\"Details\"标签页\n对于 React Native 的堆栈，点击\"符号化\"，通过 Metro 把堆栈帧映射到你的源码';

  @override
  String get tipErrorsTip =>
      'Flutter 错误带有其所在设备的 Android 或 iOS 标签——没有单独的 Flutter 按钮。';

  @override
  String get tipMockTitle => 'Mock Server';

  @override
  String get tipMockBody =>
      '保存模拟的 API 响应——方法、URL 正则、状态、标头、正文以及可选的延迟——并安装到所选设备上，让匹配的请求根本不会到达网络。';

  @override
  String get tipMockSteps =>
      'Android：先把 DevConnect.mockServerInterceptor() 添加到你的 OkHttpClient\n选择一台设备，点击\"Add rule\"，填写各字段，再点击\"Save changes\"\n点击\"Push all\"——此后的编辑、开关切换和删除会自动同步到设备\n拨动规则的开关可暂停它，或打开规则并按住\"Hold to delete\"删除它（Undo 可恢复）\n点击\"Clear device\"，移除设备上的所有规则并停止同步';

  @override
  String get tipMockTip =>
      '规则只保存在 DevConnect 的内存中——退出后就会丢失，但已同步的设备重新连接时会把规则拿回来。';

  @override
  String get tipHistoryTitle => '会话历史';

  @override
  String get tipHistoryBody =>
      '设备断开连接并持续 15 秒未重新连接后，它的日志、网络调用、state 变更和存储操作会作为只读会话保留在这里，直到它重新连接或 DevConnect 退出。';

  @override
  String get tipHistorySteps =>
      '点击某个会话，打开其\"All\"、\"Logs\"、\"Network\"、\"State\"和\"Storage\"标签页\n查看每张卡片上的断开时间和事件数量\n点击卡片上的 × 即可移除该会话\n点击\"Clear All\"清空列表';

  @override
  String get tipHistoryTip =>
      '同一台设备——或同一 IP 上的任何应用——一重新连接，会话就会消失，所以请在重新启动应用之前先查看。';

  @override
  String get tipDisplayTitle => 'Display';

  @override
  String get tipDisplayBody =>
      '显示应用通过 DevConnect.display() 发送的内容——名称、可选的预览文本、JSON 值和元数据。三个 SDK 都支持。';

  @override
  String get tipDisplaySteps =>
      '调用 DevConnect.display，传入名称，以及可选的值、预览和元数据\n浏览各行，最新的在最前：每行显示名称、预览和时间\n点击某一行，查看其\"Preview\"、JSON 格式的\"Value\"和\"Metadata\"\n点击\"Clear all\"清空列表';

  @override
  String get tipDisplayTip => '每次调用都会新增一行，而不是替换上一行——重复使用同一个名称即可形成时间线。';

  @override
  String get tipAsyncTitle => '异步操作';

  @override
  String get tipAsyncBody =>
      '列出应用通过 DevConnect.reportAsyncOperation() 上报的异步步骤——saga effect、任务、后台作业——并附带状态、耗时以及结果或错误。不会自动跟踪任何内容。';

  @override
  String get tipAsyncSteps =>
      '调用 reportAsyncOperation，传入类型、描述以及状态 start、resolve 或 reject\n在 React Native 上，用 trackAsync 包裹 promise，即可从开始到结束自动上报\n看徽章颜色：橙色表示已开始，绿色表示已 resolve，红色表示已 reject\n点击某一行，查看其详情、\"Result\"和\"Metadata\"\n点击\"Clear all\"清空列表';

  @override
  String get tipAsyncTip =>
      '给相关的调用设置相同的 sagaName——选中其中任何一个，整组调用都会列在\"Saga timeline\"下。';

  @override
  String get tipLayoutTitle => 'Layout 检查器';

  @override
  String get tipLayoutBody =>
      '捕获应用当前的屏幕及其元素树——Flutter widget、React Native 组件或 Android view——并显示每个元素的位置、大小、padding、margin 和 props。';

  @override
  String get tipLayoutSteps =>
      '选择设备并点击\"捕获\"，获取它的屏幕和元素树\n将鼠标悬停在截图上可高亮元素；点击即可选中\n也可以在\"元素树\"中选择，或用\"按名称或值查找\"搜索\n开启\"仅显示应用元素\"，隐藏库中的 widget（Flutter、React Native）\n查看\"属性\"——box model、位置、大小和 props——或点击\"复制为 JSON\"';

  @override
  String get tipLayoutTip =>
      'React Native 只有在你调用 DevConnect.registerScreenshot() 之后才会发送截图——否则只能看到元素轮廓。';

  @override
  String get settingsGroupConnection => '连接';

  @override
  String get settingsGroupConnectionDesc => '服务器、网络地址与 USB。';

  @override
  String get settingsGroupDevices => '设备';

  @override
  String get settingsGroupDevicesDesc => '当前连接的应用与以前连接过的设备。';

  @override
  String get settingsGroupAppearance => '外观';

  @override
  String get settingsGroupAppearanceDesc => '主题、语言与显示的标签页。';

  @override
  String get settingsGroupData => '显示与数据';

  @override
  String get settingsGroupDataDesc => '详情的显示方式与保留的历史量。';

  @override
  String get settingsGroupGuides => '指南';

  @override
  String get settingsGroupGuidesDesc => '快速开始、快捷键与使用技巧。';

  @override
  String get settingsGroupSupport => '支持';

  @override
  String get settingsGroupSupportDesc => '支持 DevConnect 持续发展。';

  @override
  String get tipsTabFeatures => '功能';

  @override
  String get tipsTabShortcuts => '快捷键';

  @override
  String get tipsTabConnect => '连接设备';

  @override
  String get tipsTabSdk => '集成 SDK';

  @override
  String get tipsTabAdvanced => '进阶';

  @override
  String get tipsSteps => '步骤';

  @override
  String get tipsKeys => '按键';

  @override
  String get tipsProTip => '小技巧';

  @override
  String get tipsPrevious => '上一个';

  @override
  String get tipsNext => '下一个';

  @override
  String get tipsDone => '完成';

  @override
  String get tipsOpenPage => '打开页面';

  @override
  String get tipsCopyCode => '复制';

  @override
  String get tipsCodeCopied => '已复制代码';

  @override
  String get tipsClose => '关闭';

  @override
  String get pageGuide => '如何使用此页面';

  @override
  String get guideReloadTitle => '重新加载应用';

  @override
  String get guideReloadSummary =>
      '在 DevConnect 的任意页面都能重新加载正在调试的应用，即使正在输入也行：Flutter 会重建 widget，React Native 会从 Metro 重新加载，Android 会重新创建当前 activity。';

  @override
  String get guideReloadSteps =>
      '[⌘ R] 重新加载所选应用；未选择应用时，重新加载所有已连接的应用\n[⇧ ⌘ R] 热重启：运行 Flutter 应用的 onHotRestartRequest，否则与 ⌘ R 一样重新加载\n也可以点击底部栏中的重新加载按钮——它们的工具提示会显示快捷键';

  @override
  String get guideReloadTip =>
      'Flutter 的 ⌘ R 会重建 widget 树并保留 state，但不会加载代码改动——这要用 IDE 的热重载。';

  @override
  String get guideJsonSearchTitle => '在正文中搜索';

  @override
  String get guideJsonSearchSummary =>
      'Tree、JSON 和代码视图（TypeScript、Dart 或 Kotlin）各有自己的搜索：不区分大小写，高亮所有匹配项，并滚动到当前匹配项。';

  @override
  String get guideJsonSearchSteps =>
      '[⌘ F] 跳到该视图的搜索框——请先点击正文内部\n[↵] 跳到下一个匹配项\n[⇧ ↵] 跳到上一个匹配项\n[Esc] 清除搜索';

  @override
  String get guideJsonSearchTip =>
      'Tree 搜索会展开节点并加载后续分页，最多显示 500 个匹配项；JSON 最多可统计 100,000 个。';

  @override
  String get guideLayoutZoomTitle => '缩放布局截图';

  @override
  String get guideLayoutZoomSummary =>
      '在 Layout 页面用键盘缩放截图并调整显示范围——截图一显示，这些按键立即生效。';

  @override
  String get guideLayoutZoomSteps =>
      '[⌘ +] 放大，每按一次 1.25×\n[⌘ −] 缩小\n[⌘ 0] 实际大小：100% 即应用自身的屏幕尺寸\n[⌘ 1] 让整个屏幕适应面板\n[⌘ 2] 缩放到所选元素';

  @override
  String get guideLayoutZoomTip => '点击缩放百分比可选择 50、100、200 或 400%；双指捏合缩放，拖动平移。';

  @override
  String get guideLayoutMeasureTitle => '测量间距';

  @override
  String get guideLayoutMeasureSummary =>
      '按住 Option，查看所选元素与指针下方元素之间的距离，就像设计工具那样。';

  @override
  String get guideLayoutMeasureSteps =>
      '选择一个元素：在截图上点击它，或在元素树中选择它\n[⌥] 按住 Option，指向另一个元素\n读取分开的元素之间的间隙；若其中一个元素包含另一个，则读取边距\n松开 Option，重新查看悬停元素的 box model';

  @override
  String get guideLayoutMeasureTip => '重叠的元素不显示距离——测量需要一个元素在另一个元素内部，或者两者之间有间隙。';

  @override
  String get guideLayoutTreeTitle => '浏览元素树';

  @override
  String get guideLayoutTreeSummary =>
      '点击某一行，或点击截图上的某个元素，让元素树获得焦点，然后用方向键在已捕获的元素树中移动。';

  @override
  String get guideLayoutTreeSteps =>
      '[↑ ↓] 移到上一行或下一行\n[→] 展开该行；再按一次进入它的第一个子元素\n[←] 收起该行；再按一次退到它的父元素\n[Esc] 取消选择';

  @override
  String get guideLayoutTreeTip =>
      '在\"按名称或值查找\"中输入，可搜索名称、props 和 state；用 ↵ 和 ⇧ ↵ 逐个跳转匹配项。';

  @override
  String get guideAndroidEmulatorTitle => 'Android 模拟器';

  @override
  String get guideAndroidEmulatorSummary =>
      'Android 模拟器中的应用通过 10.0.2.2（Genymotion：10.0.3.2）访问这台 Mac，所以无需任何设置。';

  @override
  String get guideAndroidEmulatorSteps =>
      '确认设置 › \"连接\" › \"服务器\"显示\"服务器运行中\"\n原生 Android：把 enabled = BuildConfig.DEBUG 传给 installForApp——默认是关闭的\n在模拟器中运行调试版本；不需要 adb reverse\n在窗口底部的设备栏中找到该应用';

  @override
  String get guideAndroidEmulatorTip =>
      'DevConnect 每次启动都使用端口 9090；在\"服务器\"中修改的端口在退出前一直有效，且 SDK 的端口必须与之一致。';

  @override
  String get guideAndroidUsbTitle => '通过 USB 连接 Android 手机';

  @override
  String get guideAndroidUsbSummary =>
      'adb reverse 通过数据线把手机的 localhost 指向这台 Mac，所以应用无需 Wi‑Fi 就能连接。';

  @override
  String get guideAndroidUsbSteps =>
      '开启 USB 调试，插上手机，并在提示时允许这台 Mac\n在设置 › \"连接\" › \"USB 连接\"中点击\"运行 ADB Reverse\"，或运行下方的命令\n启动应用——已在运行的原生 Android 应用需要重启\n连不上？在同一位置点击\"设备\"，检查 adb 能否识别到手机';

  @override
  String get guideAndroidUsbTip =>
      '重新插拔、重启 adb 或重新开机后需要再运行一次；插着多台设备时，请在终端中用 adb -s 加手机的序列号运行。';

  @override
  String get guideIosSimulatorTitle => 'iOS 模拟器';

  @override
  String get guideIosSimulatorSummary =>
      '模拟器与 Mac 共用网络，所以调试版本无需任何设置，就能通过 localhost 连到 DevConnect。';

  @override
  String get guideIosSimulatorSteps =>
      '确认设置 › \"连接\" › \"服务器\"显示\"服务器运行中\"\n在模拟器中运行应用的调试版本\n在窗口底部的设备栏中找到它';

  @override
  String get guideIosSimulatorTip =>
      '启动顺序无所谓：React Native 和 Flutter 应用会不断重试，所以在 DevConnect 启动几秒后就会连上。';

  @override
  String get guideIphoneTitle => 'iPhone';

  @override
  String get guideIphoneSummary =>
      '与 Mac 处于同一 Wi‑Fi 时，调试版本通常能自动找到 DevConnect；如果找不到，就把 Mac 的地址设为 host。';

  @override
  String get guideIphoneSteps =>
      '让 iPhone 和 Mac 连上同一个 Wi‑Fi——访客网络通常会阻止这一点\n运行调试版本，iOS 询问时允许访问本地网络\n等待几秒：React Native 通过 Metro 找到 Mac，Flutter 通过广播找到\n没有出现？从设置 › \"连接\" › \"网络\"中复制 Mac 的地址\n在 SDK 的 init 中把它设为 host（代码见下方），然后重启应用';

  @override
  String get guideIphoneTip => '只插 USB 数据线无法让 iPhone 上的应用连接——手机必须通过网络访问 Mac。';

  @override
  String get guideTroubleshootTitle => '应用连不上';

  @override
  String get guideTroubleshootSummary => '大多数连接问题都出在几个原因上——请按以下顺序检查。';

  @override
  String get guideTroubleshootSteps =>
      '设置 › \"连接\" › \"服务器\"显示\"服务器运行中\"，且没有端口错误\n应用是调试版本；原生 Android 还需要 enabled = BuildConfig.DEBUG\nSDK 的端口与服务器的端口一致——两者默认都是 9090\n手机与 Mac 在同一个 Wi‑Fi 下，或 Android 的端口已通过 adb reverse 转发\n使用 Wi‑Fi 时，macOS 允许 DevConnect 接受传入连接（系统设置 › 网络 › 防火墙）';

  @override
  String get guideTroubleshootTip =>
      '还是不行？从设置 › \"连接\" › \"网络\"中选一个地址作为 host，并传入 auto: false（Flutter：auto_: false），这样重新连接时仍会使用它。';

  @override
  String get guideSdkReactNativeSummary =>
      '安装该包并在启动时调用一次 init——此后 fetch 和 XHR（因此 axios 也在内）、console 日志、错误和性能都会被捕获。';

  @override
  String get guideSdkReactNativeSteps =>
      '用 yarn 或 npm 添加 devconnect-manage-kit（命令见下方）\n在启动时、第一个请求之前调用一次 DevConnect.init\n要捕获 state，请添加 devConnectReduxMiddleware（Redux）、devConnectMiddleware（Zustand）或 setupMobxSpy（MobX）\n运行调试版本——在发布版本中 init 不会执行任何操作，除非传入 enabled: true';

  @override
  String get guideSdkReactNativeTip =>
      'init 每次应用启动只运行一次，所以修改 host 或端口后要完整重新加载——Fast Refresh 会保留旧设置。';

  @override
  String get guideSdkFlutterSummary =>
      '通过 initAndRunApp 启动应用：基于 dart:io 的 HTTP（http、Dio、Chopper……）、print 和 debugPrint、错误和性能都会被捕获，无需额外代码。';

  @override
  String get guideSdkFlutterSteps =>
      '运行 flutter pub add devconnect_manage_kit\n在 main() 中用 DevConnect.initAndRunApp 启动应用，并传入异步的 runApp 回调\n使用 Riverpod 或 BLoC 时，在你的 observer 中调用 DevConnect.reportStateChange 或 reportBlocChange\n运行调试版本——profile 和 release 版本保持关闭';

  @override
  String get guideSdkFlutterTip =>
      '把 Firebase 和其他启动代码放进 runApp 回调里——在 initAndRunApp 之前调用 ensureInitialized() 会导致 zone 不匹配。';

  @override
  String get guideSdkAndroidSummary =>
      '添加 Maven Central 依赖，并在 Application.onCreate 中调用 installForApp：println 输出、崩溃、ANR、性能和 ViewModel state 都会被捕获；HTTP 则需要 OkHttp 拦截器。';

  @override
  String get guideSdkAndroidSteps =>
      '把 io.github.buivietphi:devconnect-android:1.1.0 添加到 app/build.gradle.kts\n在 Application.onCreate 中调用 DevConnect.installForApp，并传入 enabled = BuildConfig.DEBUG——默认是关闭的\n把 DevConnect.okHttpInterceptor() 添加到每个 OkHttpClient，Retrofit 使用的也不例外\n用 DCLog 代替 android.util.Log 打日志；使用 Timber 时，plant 一个调用 DevConnectTimberHelper.log 的 Tree\n确保应用的 manifest 声明了 INTERNET 权限';

  @override
  String get guideSdkAndroidTip =>
      'SDK 只在启动时查找一次 DevConnect——请先启动 DevConnect（以及 adb reverse），或重启应用。';

  @override
  String get guideMockApiTitle => '模拟 API';

  @override
  String get guideMockApiSummary => '用你自己的状态、标头和正文响应匹配的请求，还可以设置延迟，无需改动服务器或应用。';

  @override
  String get guideMockApiSteps =>
      '在底部栏选择一台设备，打开\"Mock Server\"，点击\"Add rule\"\n设置\"Method\"、\"Status\"、\"URL pattern\"（在 URL 任意位置匹配的正则表达式）和正文\n点击\"Save changes\"，再点击\"Push all\"——会发送完整的规则列表，之后的保存会自动同步到设备\n在 Network › \"Mock Audit\"中查看被规则响应的请求\n用规则的开关暂停它，或用\"Clear device\"移除所有规则';

  @override
  String get guideMockApiTip =>
      'Android 需要在 OkHttp 上添加 DevConnect.mockServerInterceptor()；React Native 只模拟 fetch 调用，不模拟 axios 或 XMLHttpRequest。';

  @override
  String get guideStateControlsTitle => '从桌面控制 state';

  @override
  String get guideStateControlsSummary =>
      'State Inspector 的 Controls 标签页可以监视 state 路径、保存可发回的快照，并向应用发送 action。';

  @override
  String get guideStateControlsSteps =>
      '在底部栏选择一台设备，打开 State Inspector 并切换到\"Controls\"标签页\nSubscriptions：固定 auth.user.name 这样的路径；所有平台都可用，无需在应用中写代码\nSnapshots：\"Take snapshot\"保存最新的 state；应用处理 onStateRestore 后，\"Restore\"即可把它发回\nDispatch action：输入带 \"type\"（例如 \"LOGOUT\"）的 JSON 对象并点击\"Dispatch\"；React Native 需要 connectReduxStore(store)，Flutter 和 Android 需要 onReduxDispatch\n它们引起的变更会在应用的 state 库上报后出现在\"Timeline\"中';

  @override
  String get guideStateControlsTip =>
      'Subscriptions 读取最后上报的 state：Redux 为整个 store，而 Zustand、MobX、Riverpod 或 ViewModel 只是最后变更的 store 或 provider。如果 Restore 或 Dispatch 没有效果，说明应用还没设置处理函数；处理函数抛出的错误会显示在 Console 中。';

  @override
  String get guideNetworkConditionsTitle => '慢速或离线网络';

  @override
  String get guideNetworkConditionsSummary =>
      '延迟应用的 HTTP 请求或让请求失败，无需改动设备设置——DevConnect 自身的连接不受影响。';

  @override
  String get guideNetworkConditionsSteps =>
      '在 Network 中，打开工具栏里的仪表图标菜单\"网络条件\"\n选择\"慢速 (+500 ms)\"或\"慢速 3G (~2 秒)\"，延迟每个请求\n选择\"离线\"，让请求立即失败，就像网络断了一样\n用完后选择\"正常\"——在此之前图标会一直高亮\n在 Android 上，只有通过 DevConnect.okHttpInterceptor() 的 OkHttp 流量会变慢';

  @override
  String get guideNetworkConditionsTip =>
      '它对所有已连接的应用生效，也对之后连接的应用生效，直到你选择\"正常\"。';

  @override
  String get guideReplayTitle => '重放请求';

  @override
  String get guideReplaySummary =>
      '让应用再次发送一个已捕获的请求——方法、URL、请求头和正文都相同——无需在应用界面里一步步点击。';

  @override
  String get guideReplaySteps =>
      '在 Network 中，右键点击某个请求并选择\"重放请求\"\n或者打开该请求，点击面板顶部的重复图标\n重放的请求会作为新的一行出现在列表中';

  @override
  String get guideReplayTip =>
      'Android 会通过应用自己的客户端和拦截器重新执行最近的 OkHttp 调用；Flutter 和 React Native 则原样重发已捕获的请求头。';

  @override
  String get guideHarExportTitle => '导出为 HAR';

  @override
  String get guideHarExportSummary =>
      '把 Network 列出的请求保存为标准的 HAR 1.2 文件——包含标头、正文、状态和耗时——以便用其他工具打开。';

  @override
  String get guideHarExportSteps =>
      '用设备、方法、状态和 URL 筛选器缩小\"HTTP\"列表的范围\n点击工具栏中的下载图标\"将列出的请求导出为 HAR\"\n选择 .har 文件的保存位置\n用 Chrome DevTools 或 Charles 打开它，或分享给你的团队';

  @override
  String get guideHarExportTip =>
      '只会保存 HTTP 列表中显示的内容，所以筛选条件决定文件内容；\"Protocols\"中的条目不包含在内。';

  @override
  String get guideDatabaseQueryTitle => '查询应用的数据库';

  @override
  String get guideDatabaseQuerySummary =>
      '直接在 DevConnect 中浏览应用内 SQLite 数据库的表，并对其执行 SQL。';

  @override
  String get guideDatabaseQuerySteps =>
      '在应用中用 DevConnect.registerDatabase 注册数据库（代码片段见下方）\n打开 Database，点击某个表，预览它的前 50 行\n编辑 SQL 并点击\"运行\"——结果最多显示 1,000 行\n应用修改了表之后，点击\"重新加载表\"';

  @override
  String get guideDatabaseQueryTip =>
      '查询会在你最近点击的那个表所属的数据库上运行；如果没点击过，则在第一个注册的数据库上运行。';

  @override
  String get guideBigJsonTitle => '大型正文';

  @override
  String get guideBigJsonSummary =>
      '大型正文打开时不会卡住 DevConnect：它们在后台解析，Tree 和 JSON 只构建屏幕上可见的部分。';

  @override
  String get guideBigJsonSteps =>
      '点击长 Tree 列表下方的\"再显示 … 项\"，加载接下来的 200 项\n对 Tree 中的长字符串使用\"复制值\"——Tree 只显示其前 2,000 个字符\n切换到 JSON，即可滚动和搜索整个文档\n在 JSON 中使用\"Copy JSON\"或\"Save as file\"——两者都会包含完整的正文\n超过 20,000 个字符的 JSON 行只显示开头；复制或保存即可获取全部内容';

  @override
  String get guideBigJsonTip =>
      '当正文是对象列表时，Tree 提供\"表格\"：它显示 500 行，但\"下载表格 (CSV)\"会保存所有匹配的行。';

  @override
  String get guideCustomCommandsTitle => '自定义命令';

  @override
  String get guideCustomCommandsSummary =>
      '从 DevConnect 运行应用内的代码——清除缓存、退出登录、生成测试数据——并查看它的返回结果。';

  @override
  String get guideCustomCommandsSteps =>
      '在应用中用 DevConnect.registerCommand 注册 handler（代码片段见下方）\n打开\"自定义命令\"，点击应用列出的某个命令，或输入它的名称\n如果命令需要参数，以 JSON 对象的形式添加\n点击\"运行\"，或在\"命令\"字段中按 ↵，然后在下方查看结果';

  @override
  String get guideCustomCommandsTip =>
      'Flutter 和 React Native 的 handler 可以是异步的；抛出的错误会作为结果显示，超过 10 秒没有回应则超时。';

  @override
  String get restart => '重启';

  @override
  String get serverAddressHint => '应用会连接到这个地址。';

  @override
  String get serverStoppedHint => '启动服务器后应用才能连接。';

  @override
  String get tabBenchmark => '基准测试';

  @override
  String get tabDisplay => '显示';

  @override
  String get tabAsync => '异步操作';

  @override
  String get tabLayout => '布局检查';

  @override
  String get tabCommands => '自定义命令';

  @override
  String get tabMockServer => '模拟服务器';

  @override
  String get tabsAlwaysShown => '所有事件和设置始终显示。';

  @override
  String get quickStartDesc => '安装 SDK，在应用中启动，然后连接。';

  @override
  String get quickStartNext => '下一步 — 在应用中启动';

  @override
  String get quickStartEmulator => '模拟器自动连接';

  @override
  String get quickStartWifi => 'Wi‑Fi 真机';

  @override
  String get quickStartUsb => 'USB 连接 Android';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class SZhTw extends SZh {
  SZhTw() : super('zh_TW');

  @override
  String get appTitle => 'DevConnect 管理工具';

  @override
  String get ok => '確定';

  @override
  String get cancel => '取消';

  @override
  String get close => '關閉';

  @override
  String get clear => '清除';

  @override
  String get copy => '複製';

  @override
  String get copied => '已複製';

  @override
  String get start => '啟動';

  @override
  String get stop => '停止';

  @override
  String get on => '開啟';

  @override
  String get off => '關閉';

  @override
  String get autoScroll => '自動捲動';

  @override
  String get newestFirst => '最新優先';

  @override
  String get oldestFirst => '最舊優先';

  @override
  String get clearAll => '全部清除';

  @override
  String get maintenance => '維護';

  @override
  String get clearAllCache => '清除所有快取';

  @override
  String get clearAllCacheDesc =>
      '斷開所有設備並清除所有記憶體數據（日誌、網路擷取、狀態、效能等）。您的設定（主題、語言、連接埠）將被保留。';

  @override
  String get clearAllCacheConfirm =>
      '清除所有快取？\n\n這將斷開所有已連接的設備並清除記憶體中的所有日誌、網路擷取、狀態變更、效能指標和基準測試結果。\n\n您的設定（主題、語言、連接埠）將被保留。';

  @override
  String get cacheCleared => '已清除所有快取。設定已保留。';

  @override
  String clearAllCacheFailed(Object error) {
    return '清除快取失敗：$error';
  }

  @override
  String get deviceHistory => '已快取的裝置';

  @override
  String get deviceHistoryDesc => '所有曾連線到此桌面端的裝置。條目跨重啟持久保存,您可以查看之前有哪些裝置連線過。';

  @override
  String get noDeviceHistory => '尚無裝置連線';

  @override
  String get deviceHistoryEmptyHint => '透過 SDK 連線裝置後,裝置將顯示在此處。條目跨重啟持久保存。';

  @override
  String get restarting => '正在重新啟動…';

  @override
  String get online => '線上';

  @override
  String get offline => '離線';

  @override
  String get markOnline => '標記為線上';

  @override
  String get markOffline => '標記為離線';

  @override
  String get deviceOnline => '線上';

  @override
  String get deviceOffline => '離線';

  @override
  String lastSeen(Object time) {
    return '最後上線 $time';
  }

  @override
  String firstSeen(Object time) {
    return '首次連線 $time';
  }

  @override
  String get forgetDevice => '忘記';

  @override
  String get forgetAllOffline => '忘記所有離線';

  @override
  String get forgetAllDevices => '全部忘記';

  @override
  String get forgetDeviceConfirm => '忘記此裝置?\n\n將從歷史記錄中刪除。下次連線時會作為新條目重新出現。';

  @override
  String get forgetAllOfflineConfirm => '忘記所有離線裝置?\n\n將刪除所有未連線的條目。在線裝置會保留。';

  @override
  String get forgetAllDevicesConfirm =>
      '忘記所有已快取的裝置?\n\n將清除整個歷史記錄,包括在線裝置。它們會在重新連線時再次出現。';

  @override
  String get deviceForgotten => '裝置已忘記';

  @override
  String devicesForgotten(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已忘記 $count 台裝置',
      one: '已忘記 1 台裝置',
      zero: '未忘記任何裝置',
    );
    return '$_temp0';
  }

  @override
  String connectionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '連線 $count 次',
      one: '連線 1 次',
      zero: '從未連線',
    );
    return '$_temp0';
  }

  @override
  String get restartServer => '重新啟動伺服器';

  @override
  String portOccupied(Object port) {
    return '連接埠 $port 已被佔用';
  }

  @override
  String get serverRestarted => '伺服器已重新啟動';

  @override
  String get restartFailed => '重新啟動失敗';

  @override
  String portStillInUse(Object port) {
    return '連接埠 $port 仍被其他程式佔用';
  }

  @override
  String couldNotRestart(Object port) {
    return '無法在連接埠 $port 重新啟動';
  }

  @override
  String listeningOnPort(Object port) {
    return '正在監聽連接埠 $port';
  }

  @override
  String waitingForReconnect(Object port) {
    return '連接埠 $port · 等待裝置重新連線';
  }

  @override
  String reconnectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台裝置已重新連線',
      one: '1 台裝置已重新連線',
      zero: '0 已重新連線',
    );
    return '$_temp0';
  }

  @override
  String get reloadApp => '重新載入應用程式';

  @override
  String get reloadAppHotReload => '熱重載';

  @override
  String get reloadAppHotRestart => '熱重啟';

  @override
  String get reloadAppMetro => '重載 Metro';

  @override
  String get reloadAppNoDevices => '無裝置連線';

  @override
  String get reloadSent => '已傳送重新載入';

  @override
  String sentReloadTo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已向 $count 台裝置發送重新載入',
      one: '已向 1 台裝置發送重新載入',
      zero: '未指定任何裝置',
    );
    return '$_temp0';
  }

  @override
  String get screenshotSaved => '截圖已儲存';

  @override
  String get screenshotFailed => '截圖失敗';

  @override
  String get reveal => '開啟';

  @override
  String get captureFull => '完整';

  @override
  String get captureTab => '分頁';

  @override
  String get captureFullTooltip => '將完整詳細資訊截圖為圖片';

  @override
  String get captureTabTooltip => '僅截圖當前分頁';

  @override
  String get captureAsImage => '截圖為圖片';

  @override
  String get captureDetailAsImage => '將詳細資訊截圖為圖片';

  @override
  String get noData => '無資料';

  @override
  String get noItems => '無項目';

  @override
  String get searchHint => '搜尋...';

  @override
  String get filterHint => '篩選...';

  @override
  String get value => '值';

  @override
  String get key => '鍵';

  @override
  String get metadata => '中繼資料';

  @override
  String get duration => '持續時間';

  @override
  String get error => '錯誤';

  @override
  String get json => 'JSON';

  @override
  String get tree => 'Tree';

  @override
  String get code => 'Code';

  @override
  String get raw => '原始';

  @override
  String get format => '格式';

  @override
  String get pretty => '美化';

  @override
  String get collapse => '收合';

  @override
  String get showMore => '顯示更多';

  @override
  String get noHeaders => '無標頭';

  @override
  String get inProgress => '處理中';

  @override
  String get inProgressDots => '處理中...';

  @override
  String hideShowTooltip(Object action, Object label) {
    return '$action $label';
  }

  @override
  String get hide => '隱藏';

  @override
  String get show => '顯示';

  @override
  String get steps => '步驟';

  @override
  String get portInUse => '連接埠已被佔用。請關閉使用此連接埠的其他應用程式，或在設定中選擇其他連接埠。';

  @override
  String portInUseShort(Object port) {
    return '連接埠 $port 已被佔用。請關閉使用此連接埠的其他應用程式，或在上方輸入其他連接埠並按下啟動。';
  }

  @override
  String failedToStartServer(Object msg) {
    return '無法啟動伺服器：$msg';
  }

  @override
  String failedToStartServerOnPort(Object msg, Object port) {
    return '無法在連接埠 $port 上啟動伺服器：$msg';
  }

  @override
  String get settings => '設定';

  @override
  String get server => '伺服器';

  @override
  String get serverRunning => '伺服器運行中';

  @override
  String get serverStopped => '伺服器已停止';

  @override
  String get port => '連接埠';

  @override
  String deviceCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個裝置',
      one: '1 個裝置',
      zero: '0 個裝置',
    );
    return '$_temp0';
  }

  @override
  String get network => '網路';

  @override
  String get hostname => '主機名稱';

  @override
  String get noNetworkInterfaces => '未找到網路介面';

  @override
  String copiedIp(Object ip) {
    return '已複製 $ip';
  }

  @override
  String connectedDevices(Object count) {
    return '已連線裝置 ($count)';
  }

  @override
  String get noDevicesConnected => '無裝置連線';

  @override
  String get appearance => '外觀';

  @override
  String get theme => '主題';

  @override
  String get dark => '深色';

  @override
  String get light => '淺色';

  @override
  String get bottom => '底部';

  @override
  String get top => '頂部';

  @override
  String get language => '語言';

  @override
  String get tabVisibility => '分頁可見性';

  @override
  String get tabVisibilityDesc => '切換分頁的可見性。停用的分頁會顯示鎖定圖示，其資料將從所有事件中排除。';

  @override
  String get detailView => '詳細檢視';

  @override
  String get detailViewDesc => '記住請求/回應內容的顯示方式並控制分頁切換動畫。';

  @override
  String get dataRetention => '資料保留';

  @override
  String get dataRetentionDesc =>
      '套用於每個功能清單的硬上限。當清單超過上限時,最舊的條目將依 FIFO 順序刪除。等待中的非同步操作將被保留。';

  @override
  String get maxItems => '最大項目數';

  @override
  String get dataRetentionHelper => '無限制保留所有項目。較低的值可釋放記憶體,但會遺失歷史記錄。';

  @override
  String get allEventsDisplay => '所有事件顯示';

  @override
  String get allEventsDisplayDesc => '彙總的所有事件清單的僅檢視篩選器。底層記錄不會被刪除 — 切換回無限制即可還原。';

  @override
  String get allEventsDisplayHelper => '較低的值僅保留最近的 N 筆記錄,代價是較舊的歷史記錄。';

  @override
  String get bodyView => '內容檢視';

  @override
  String get tabAnimation => '分頁動畫';

  @override
  String get tabAnimationDuration => '持續時間';

  @override
  String get codeModeDesc => '程式碼模式根據已連線的 SDK 匯出為 TypeScript / Dart / Kotlin。';

  @override
  String get treeModeDesc => '樹狀模式以可展開/摺疊的節點階層顯示資料,適合瀏覽深度巢狀的值。';

  @override
  String get jsonModeDesc => 'JSON 模式將資料呈現為單一、帶語法醒目提示、易於複製的 JSON 文件。';

  @override
  String get captureDataJson => '擷取資料 (目前模式的金鑰 + 值)';

  @override
  String get captureDataText => '擷取資料 (金鑰 + 值作為文字)';

  @override
  String get copyKey => '複製金鑰';

  @override
  String get usbConnection => 'USB 連線';

  @override
  String get android => 'Android';

  @override
  String get ios => 'iOS';

  @override
  String get runAdbReverse => '執行 ADB Reverse';

  @override
  String adbNotFound(Object home) {
    return '找不到 adb。\nHOME=$home';
  }

  @override
  String adbReverseOk(Object path) {
    return 'adb reverse OK ($path)';
  }

  @override
  String adbError(Object error) {
    return 'adb 錯誤：$error';
  }

  @override
  String adbException(Object error) {
    return 'adb 例外：$error';
  }

  @override
  String get devices => '裝置';

  @override
  String get adbDevices => 'ADB 裝置';

  @override
  String get wifiAutoConnect =>
      'iPhone 透過 Wi‑Fi 連線：請讓它與這台 Mac 位於同一個網路。只插 USB 傳輸線無法連線。';

  @override
  String get quickStart => '快速入門';

  @override
  String get installSdk => '安裝 SDK';

  @override
  String get initialize => '初始化';

  @override
  String get connect => '連線';

  @override
  String get supportDevConnect => '支援 DevConnect';

  @override
  String get supportDevConnectDesc =>
      'DevConnect 管理工具是免費且開源的。如果它對您的工作流程有幫助，請考慮支援開發。';

  @override
  String get kofi => 'Ko-fi';

  @override
  String get paypal => 'PayPal';

  @override
  String get ethernet => '乙太網路';

  @override
  String get wifi => 'WiFi';

  @override
  String get vpn => 'VPN';

  @override
  String get bridge => '橋接';

  @override
  String get loopback => '迴路';

  @override
  String get console => '主控台';

  @override
  String get state => '狀態';

  @override
  String get storage => '儲存';

  @override
  String get database => '資料庫';

  @override
  String get performance => '效能';

  @override
  String get memoryLeaks => '記憶體洩漏';

  @override
  String get history => '歷史記錄';

  @override
  String get noNetworkRequests => '無網路請求';

  @override
  String get apiCallsAppearHere => 'API 呼叫將即時顯示在這裡';

  @override
  String clearStaleButton(Object count) {
    return '過期 ($count)';
  }

  @override
  String clearStaleTooltip(Object count) {
    return '清除 $count 個超過 10 分鐘未回應的掛起請求';
  }

  @override
  String clearStaleSnackbar(Object count) {
    return '已清除 $count 個過期請求 (掛起 > 10 分鐘)';
  }

  @override
  String memorySafetyOverflow(Object count) {
    return '記憶體安全: 已從 open-trips 快取中丟棄 $count 個過期網路條目';
  }

  @override
  String get sdkTipsPill => 'Tips lib';

  @override
  String get sdkTipsHeader => '庫相容性';

  @override
  String get sdkTipsSubtitle => '為確保所有資料完整顯示,請確保使用的是最新版本的庫。';

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
    return 'v$version · 最新';
  }

  @override
  String sdkTipsPillUpdate(Object version) {
    return 'v$version · 更新';
  }

  @override
  String get sdkTipsInstalled => '目前';

  @override
  String get sdkTipsLatestLabel => '最新';

  @override
  String get sdkTipsUpdate => '更新';

  @override
  String get sdkTipsChecking => '檢查中';

  @override
  String get sdkTipsOffline => '無法檢查';

  @override
  String get sdkTipsRetry => '重試';

  @override
  String get sdkTipsCheckProject => '在專案中執行此指令，查看目前版本：';

  @override
  String get sdkTipsInstallLatest => '安裝最新版本：';

  @override
  String get appUpdateTitle => 'DevConnect 版本';

  @override
  String get appUpdateAvailable => '有新版本可用。';

  @override
  String get appUpdateUpToDate => '已是最新版本。';

  @override
  String get appUpdateViewRelease => '查看發布說明';

  @override
  String devicesConnected(Object count) {
    return '已連線 $count 台';
  }

  @override
  String get devicesAll => '全部';

  @override
  String devicesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台裝置',
    );
    return '$_temp0';
  }

  @override
  String get commandsTitle => '自訂指令';

  @override
  String get commandsNoDevice => '連線裝置後即可執行其指令。';

  @override
  String get commandsEmptyHint =>
      '應用尚未註冊指令。可在應用中用 DevConnect.registerCommand(name, handler) 新增，或輸入指令名稱直接執行。';

  @override
  String get commandsName => '指令';

  @override
  String get commandsArgs => '參數 — JSON 物件（選填）';

  @override
  String get commandsArgsInvalid => '參數必須是 JSON 物件。';

  @override
  String get commandsRun => '執行';

  @override
  String commandsTarget(Object device) {
    return '在 $device 上執行';
  }

  @override
  String get commandsHistoryEmpty => '執行的指令結果會顯示在這裡。';

  @override
  String get commandsNoResponse => '無回應。應用是否註冊了此指令？';

  @override
  String get dbTables => '資料表';

  @override
  String get dbRefresh => '重新載入資料表';

  @override
  String get dbNoDevice => '連線裝置後即可瀏覽其資料庫。';

  @override
  String get dbSelectDevice => '在底部列選擇裝置以瀏覽其資料庫。';

  @override
  String get dbNoDatabases =>
      '應用尚未註冊資料庫。可用 DevConnect.registerDatabase(name, query) 新增，然後重新載入資料表。';

  @override
  String get dbRun => '執行';

  @override
  String get dbRunHint => '選擇資料表或撰寫 SQL';

  @override
  String get dbRunHintSubtitle => '選擇資料表即可預覽前 50 列。';

  @override
  String dbRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 列',
    );
    return '$_temp0';
  }

  @override
  String dbTruncated(Object count) {
    return '僅前 $count 列';
  }

  @override
  String get dbFilterTables => '篩選資料表';

  @override
  String get dbData => '資料';

  @override
  String get dbStructure => '結構';

  @override
  String dbColumnCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 個欄位',
    );
    return '$_temp0';
  }

  @override
  String get dbNoResponse =>
      '無回應。應用是否用 DevConnect.registerDatabase 註冊了資料庫？需要最新的 SDK。';

  @override
  String get stateToolsTab => '控制';

  @override
  String get stateNoDevice => '在底部列選擇裝置，以監看、快照並操控其狀態。';

  @override
  String get stateNoState => '此裝置尚未回報任何狀態。';

  @override
  String get stateSubscriptions => '訂閱';

  @override
  String get stateSubscriptionsHint =>
      '固定一個路徑以即時查看它的值，例如 auth.user.name 或 cart.items[0].price。所有平台都可用，無需在應用程式中寫程式碼；讀取的是最新一次變更的 state：Redux 為整個 store，Zustand、MobX、Riverpod 或 ViewModel 則是最後變更的 store 或 provider。';

  @override
  String get statePinPath => '釘選路徑';

  @override
  String get statePathMissing => '（狀態中不存在）';

  @override
  String get stateRemove => '移除';

  @override
  String get stateSnapshots => '快照';

  @override
  String get stateSnapshotsHint =>
      '儲存最新的 state，之後再傳回應用程式以重現問題或略過冗長的表單。儲存在所有平台都可用；Restore 需要應用程式透過 onStateRestore 套用該 state（React Native、Flutter 和 Android）。';

  @override
  String get stateTakeSnapshot => '拍攝快照';

  @override
  String stateKeys(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個鍵',
    );
    return '$_temp0';
  }

  @override
  String get stateRestore => '還原';

  @override
  String get stateRestoreHere => '將應用狀態還原到此時';

  @override
  String get stateSaveSnapshot => '儲存為快照';

  @override
  String get stateSnapshotSaved => '快照已儲存';

  @override
  String get stateRestoreSent => '已送出狀態還原';

  @override
  String get stateDispatch => '派發 action';

  @override
  String get stateDispatchHint =>
      '向應用程式傳送一個 action（帶 \"type\" 的 JSON 物件，例如 \"LOGOUT\"）。React Native 會在透過 connectReduxStore(store) 接入的 Redux store 中執行；Flutter 和 Android 會把它交給 onReduxDispatch。';

  @override
  String get stateDispatchButton => '派發';

  @override
  String get stateDispatchSent => 'action 已派發';

  @override
  String stateSetupIn(String platform) {
    return '在 $platform 應用程式中設定';
  }

  @override
  String get stateActionInvalid => 'action 必須是 JSON 物件。';

  @override
  String get stateRecentActions => '最近';

  @override
  String get jsonTreeView => '樹';

  @override
  String get jsonTableView => '表格';

  @override
  String get jsonSearchHint => '搜尋鍵與值';

  @override
  String get jsonExportCsv => '下載表格 (CSV)';

  @override
  String get jsonTableNoMatch => '沒有符合的列';

  @override
  String get jsonPrevMatch => '上一個符合';

  @override
  String get jsonNextMatch => '下一個符合';

  @override
  String get jsonExpandAll => '全部展開';

  @override
  String get jsonCollapseAll => '全部摺疊';

  @override
  String get jsonCopyKey => '複製鍵';

  @override
  String get jsonCopyValue => '複製值';

  @override
  String get jsonCopyPath => '複製路徑';

  @override
  String get jsonKeyCopied => '已複製鍵';

  @override
  String get jsonValueCopied => '已複製值';

  @override
  String get jsonPathCopied => '已複製路徑';

  @override
  String jsonShowMore(int count, int remaining) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return '再顯示 $countString 項（剩餘 $remainingString 項）';
  }

  @override
  String jsonLongValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '共 $countString 個字元，複製可取得全部';
  }

  @override
  String jsonPrettyCut(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '顯示前 $shownString 行，共 $totalString 行。複製或儲存可取得全部內容。';
  }

  @override
  String jsonTableTruncated(Object count) {
    return '僅顯示前 $count 列。';
  }

  @override
  String get networkErrors => '錯誤';

  @override
  String get networkSearchBodies => '同時搜尋請求與回應內文';

  @override
  String get networkExportHar => '將列出的請求匯出為 HAR';

  @override
  String get networkNothingToExport => '沒有可匯出的請求';

  @override
  String get fileSaved => '檔案已儲存';

  @override
  String get consoleGroupRepeats => '合併重複日誌';

  @override
  String get consoleOccurrences => '重複記錄';

  @override
  String get consoleNoMatchTitle => '沒有符合的日誌';

  @override
  String get consoleNoMatchSubtitle => '移除篩選條件即可重新顯示。';

  @override
  String get consoleShowAllLevels => '顯示所有級別';

  @override
  String get consoleClearSearch => '清除搜尋';

  @override
  String get consoleResetFilters => '重設篩選';

  @override
  String get consoleExport => '匯出日誌';

  @override
  String get consoleExportText => '文字 (.txt)';

  @override
  String get consoleExportJson => 'JSON (.json)';

  @override
  String get consoleNothingToExport => '沒有可匯出的日誌';

  @override
  String get errorSymbolicate => '符號化';

  @override
  String get errorSymbolicated => '已對應到原始碼';

  @override
  String get errorSymbolicateFailed =>
      '無法解析此堆疊：無法連線 Metro，且此建置未上傳 source map（SDK 中的 uploadSourceMap）。';

  @override
  String get storageTabHistory => '歷史';

  @override
  String get storageTabKeyValue => '鍵值';

  @override
  String get storageKvNoDevice => '在底部列選擇裝置以檢視並編輯其儲存。';

  @override
  String get storageKvEmpty =>
      '尚無可編輯的儲存。請用 SDK 包裝儲存（DevConnectAsyncStorage.wrap、DevConnectMMKV.wrap、DevConnectSharedPreferences.wrap…）— 需要最新的 SDK。';

  @override
  String get storageKvRefresh => '重新載入';

  @override
  String get storageKvAdd => '新增鍵';

  @override
  String get storageKvEdit => '編輯值';

  @override
  String get storageKvDelete => '刪除鍵';

  @override
  String get storageKvClear => '全部清除';

  @override
  String storageKvClearConfirm(Object storage) {
    return '刪除 $storage 中的所有鍵？此操作無法復原。';
  }

  @override
  String get storageKvKey => '鍵';

  @override
  String get storageKvValue => '值';

  @override
  String get storageKvSave => '儲存';

  @override
  String get storageKvFilter => '篩選鍵';

  @override
  String get storageNoMatchTitle => '沒有符合的操作';

  @override
  String get storageNoMatchSubtitle => '移除篩選條件即可重新顯示。';

  @override
  String get storageShowAllOps => '顯示所有操作';

  @override
  String get storageShowAllTypes => '顯示所有儲存類型';

  @override
  String get storageCopyValue => '複製值';

  @override
  String get storageKvNoMatch => '沒有符合的鍵';

  @override
  String storageFilterHide(String name) {
    return '隱藏 $name';
  }

  @override
  String storageFilterShow(String name) {
    return '顯示 $name';
  }

  @override
  String get deepLinkTitle => '開啟深層連結';

  @override
  String get deepLinkHint => '應用會像點擊了其連結一樣開啟它。';

  @override
  String get deepLinkOpen => '開啟';

  @override
  String get deepLinkSent => '已送出深層連結';

  @override
  String get devMenu => '開啟開發選單';

  @override
  String get networkReplay => '重送請求';

  @override
  String get networkReplaySent => '已重新送出請求 — 將顯示為新的一列';

  @override
  String get networkConditions => '網路條件';

  @override
  String get networkPresetNormal => '正常';

  @override
  String get networkPresetSlow => '慢速 (+500 ms)';

  @override
  String get networkPresetSlow3g => '慢速 3G (~2 秒)';

  @override
  String get networkPresetOffline => '離線';

  @override
  String get networkTabHttpHint =>
      '應用程式透過 fetch、XHR、axios、Dio、OkHttp… 發出的 HTTP 請求';

  @override
  String get networkTabProtocolsHint =>
      '一般 HTTP 以外的流量：GraphQL 操作、WebSocket 訊息與 gRPC 呼叫';

  @override
  String get networkTabMockAuditHint => '由 Mock Server 規則代替真實網路回應的請求';

  @override
  String get protocolGraphqlHint => '透過 SDK 的 GraphQL link / 攔截器送出的查詢與變更';

  @override
  String get protocolWebsocketHint => 'WebSocket 連線及每個收發的訊框';

  @override
  String get protocolGrpcHint => 'gRPC 呼叫（Android SDK 攔截器）';

  @override
  String get layoutTitle => '版面配置';

  @override
  String get layoutCapture => '擷取';

  @override
  String get layoutHint => '擷取應用程式目前的畫面以檢視其元素樹。將滑鼠停在截圖上可醒目提示元素，點擊可檢視其屬性。';

  @override
  String get layoutNoDevice => '連接應用程式或選擇裝置以檢查其版面配置。';

  @override
  String get layoutNoScreenshot =>
      '此應用程式未提供截圖，僅顯示元素外框。React Native：使用 DevConnect.registerScreenshot 新增。';

  @override
  String get layoutPickElement => '停留或點擊截圖上的元素，或在樹中選擇一個。';

  @override
  String get layoutTree => '元素樹';

  @override
  String get layoutProperties => '屬性';

  @override
  String get layoutTreeError => '無法讀取元素樹';

  @override
  String get layoutSearchHint => '依名稱或值尋找';

  @override
  String get layoutAppOnly => '僅顯示應用程式元素';

  @override
  String get layoutFit => '符合視窗';

  @override
  String get layoutActualSize => '實際大小';

  @override
  String get layoutZoomIn => '放大';

  @override
  String get layoutZoomOut => '縮小';

  @override
  String get layoutZoomLevel => '縮放比例';

  @override
  String get layoutZoomToSelection => '縮放至所選元素';

  @override
  String get layoutClose => '關閉截圖';

  @override
  String get layoutCopyName => '複製名稱';

  @override
  String get layoutCopyJson => '複製為 JSON';

  @override
  String get layoutExport => '匯出';

  @override
  String get layoutSavePng => '儲存截圖 (PNG)';

  @override
  String get layoutSaveJson => '儲存快照 (JSON)';

  @override
  String get layoutNoAnswer =>
      '應用程式沒有回應。版面配置需要支援版面配置的 DevConnect SDK，並以除錯版本執行。';

  @override
  String get layoutTruncated => '樹過大：僅擷取了前一部分。';

  @override
  String get layoutState => '狀態';

  @override
  String get layoutMeasureHint => '⌥ + 懸停：測量距離';

  @override
  String get networkTitle => '網路';

  @override
  String get filterUrls => '篩選 URL...';

  @override
  String get copyUrl => '複製 URL';

  @override
  String get urlCopied => '已複製 URL';

  @override
  String get copyPath => '複製路徑';

  @override
  String get pathCopied => '已複製路徑';

  @override
  String get copyCurl => '複製 cURL';

  @override
  String get curlCopied => '已複製 cURL';

  @override
  String get copyRequest => '複製請求';

  @override
  String get requestCopied => '已複製請求';

  @override
  String get copyResponse => '複製回應';

  @override
  String get responseCopied => '已複製回應';

  @override
  String get requestBody => '請求內容';

  @override
  String get responseBody => '回應內容';

  @override
  String get requestHeaders => '請求標頭';

  @override
  String get responseHeaders => '回應標頭';

  @override
  String get headers => '標頭';

  @override
  String get request => '請求';

  @override
  String get response => '回應';

  @override
  String get timing => '計時';

  @override
  String get startTime => '開始時間';

  @override
  String get endTime => '結束時間';

  @override
  String noLabel(Object label) {
    return '無$label';
  }

  @override
  String get noStorageData => '無儲存資料';

  @override
  String get storageEntriesAppearHere =>
      'SharedPreferences、AsyncStorage 和 Hive 項目將顯示在這裡';

  @override
  String get storageTitle => '儲存';

  @override
  String get filterKeys => '篩選鍵...';

  @override
  String get read => '讀取';

  @override
  String get write => '寫入';

  @override
  String get delete => '刪除';

  @override
  String get noEventsYet => '尚無事件';

  @override
  String get startAppToSeeEvents => '使用 DevConnect SDK 啟動應用程式以查看事件';

  @override
  String get eventsAppearHere => '事件將即時顯示在這裡';

  @override
  String get allEventsTitle => '所有事件';

  @override
  String get stopped => '已停止';

  @override
  String get searchEvents => '搜尋事件...';

  @override
  String get logDetail => '日誌詳細資訊';

  @override
  String get networkDetail => '網路詳細資訊';

  @override
  String get stateDetail => '狀態詳細資訊';

  @override
  String get storageDetail => '儲存詳細資訊';

  @override
  String get displayDetail => '顯示詳細資訊';

  @override
  String get asyncOperation => '非同步操作';

  @override
  String get errorDetail => '錯誤詳細資訊';

  @override
  String get tag => '標籤';

  @override
  String get message => '訊息';

  @override
  String get stackTrace => '堆疊追蹤';

  @override
  String get noLogsYet => '尚無日誌';

  @override
  String get connectDeviceToSeeLogs => '連線裝置並開始記錄以在此處查看項目';

  @override
  String get consoleTitle => '主控台';

  @override
  String get searchLogs => '搜尋日誌...';

  @override
  String get clearConsole => '清除主控台';

  @override
  String get copyMessage => '複製訊息';

  @override
  String get logCopied => '已複製日誌';

  @override
  String get closePanel => '關閉面板';

  @override
  String hideShowLogs(Object action, Object label) {
    return '$action $label 日誌';
  }

  @override
  String get errors => '錯誤';

  @override
  String get searchErrors => '搜尋錯誤...';

  @override
  String get clearErrors => '清除錯誤';

  @override
  String get totalErrors => '錯誤總數';

  @override
  String get fatalCrash => '致命/當機';

  @override
  String get noErrorsCaptured => '未擷取到錯誤';

  @override
  String get errorsAppearHere => '來自 React Native 和 Flutter 的錯誤將顯示在這裡';

  @override
  String get stackTraceCopied => '已複製堆疊追蹤';

  @override
  String get noStackTrace => '無堆疊追蹤';

  @override
  String get platform => '平台';

  @override
  String get severity => '嚴重程度';

  @override
  String get source => '來源';

  @override
  String get deviceId => '裝置 ID';

  @override
  String get deviceInfo => '裝置資訊';

  @override
  String get details => '詳細資訊';

  @override
  String hideShowErrors(Object action, Object label) {
    return '$action $label 錯誤';
  }

  @override
  String get noStateChanges => '無狀態變更';

  @override
  String get stateChangesAppearHere => 'Redux、BLoC、Riverpod 和 MobX 狀態變更將顯示在這裡';

  @override
  String get stateInspectorTitle => '狀態檢查器';

  @override
  String changesCount(Object count) {
    return '$count 個變更';
  }

  @override
  String changeCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個變更',
      one: '1 個變更',
      zero: '0 個變更',
    );
    return '$_temp0';
  }

  @override
  String get filterActions => '篩選操作...';

  @override
  String get newestAtTop => '最新在頂部';

  @override
  String get newestAtBottom => '最新在底部';

  @override
  String get noChanges => '無變更';

  @override
  String get diff => '差異';

  @override
  String get before => '之前';

  @override
  String get after => '之後';

  @override
  String get noChangesDetected => '未偵測到變更';

  @override
  String get noBenchmarks => '無基準測試';

  @override
  String get useBenchmarkSdk => '在 SDK 中使用 benchmarkStart/Step/Stop 來衡量效能';

  @override
  String get benchmarksTitle => '基準測試';

  @override
  String get searchBenchmarks => '搜尋基準測試...';

  @override
  String get total => '總計';

  @override
  String get avg => '平均';

  @override
  String get min => '最小';

  @override
  String get max => '最大';

  @override
  String get p50 => 'P50';

  @override
  String get end => '結束';

  @override
  String stepsCount(Object count) {
    return '步驟 ($count)';
  }

  @override
  String get noIntermediateSteps => '未記錄中間步驟';

  @override
  String get noPerformanceData => '無效能資料';

  @override
  String get connectAppToProfile => '連接應用程式與 DevConnect SDK 以開始分析';

  @override
  String get stopRecording => '停止錄製';

  @override
  String get startRecording => '開始錄製';

  @override
  String get performanceProfiler => '效能分析器';

  @override
  String slowFrames(Object count) {
    return '慢幀數：$count';
  }

  @override
  String get systemStatus => '系統狀態';

  @override
  String get startup => '啟動';

  @override
  String get battery => '電池';

  @override
  String get emulator => '模擬器';

  @override
  String get drainRate => '耗電速率';

  @override
  String get thermal => '溫度';

  @override
  String get diskRead => '磁碟讀取';

  @override
  String get diskWrite => '磁碟寫入';

  @override
  String get anr => 'ANR';

  @override
  String get charging => '充電中';

  @override
  String get normal => '正常';

  @override
  String get fair => '一般';

  @override
  String get serious => '嚴重';

  @override
  String get critical => '危急';

  @override
  String get reqs => '請求';

  @override
  String get live => '即時';

  @override
  String get reqPerSec => '請求/秒';

  @override
  String get err => '錯誤';

  @override
  String get waitingForRequests => '等待請求...';

  @override
  String get waitingForData => '等待資料...';

  @override
  String get noMemoryLeaksDetected => '未偵測到記憶體洩漏';

  @override
  String get connectAppToMonitorLeaks => '連接應用程式與 DevConnect SDK 以監控記憶體洩漏';

  @override
  String get memoryLeakDetection => '記憶體洩漏偵測';

  @override
  String get warning => '警告';

  @override
  String get info => '資訊';

  @override
  String get detail => '詳細資訊';

  @override
  String get retainedSize => '保留大小';

  @override
  String get timestamp => '時間戳記';

  @override
  String get undisposedController => '未釋放的 Controller';

  @override
  String get undisposedStream => '未釋放的 Stream';

  @override
  String get undisposedTimer => '未釋放的 Timer';

  @override
  String get undisposedAnimation => '未釋放的 Animation';

  @override
  String get widgetLeak => 'Widget 洩漏';

  @override
  String get growingCollection => '增長中的集合';

  @override
  String get custom => '自訂';

  @override
  String get smoothScrolling => '平滑捲動';

  @override
  String get smoothScrollingDesc => '為滑鼠滾輪事件添加平滑動畫。如果遇到卡頓或性能下降，請關閉此選項。';

  @override
  String get smoothScrollingDuration => '滾動持續時間';

  @override
  String get smoothScrollingDurationDesc => '滾動動畫的持續時間（毫秒）。';

  @override
  String binaryBody(String label) {
    return '$label 內文為二進位';
  }

  @override
  String binaryBodySize(String kb, int bytes) {
    return '$kb ($bytes 位元組)';
  }

  @override
  String get binaryBodyHint => '透過 X-Amz-Target 標頭識別操作。';

  @override
  String get openWithDefaultApp => '用預設應用程式開啟';

  @override
  String get tipsAndShortcuts => '提示與快捷鍵';

  @override
  String get tipsAndShortcutsDesc => '最常用工作流程的快速指南。點擊任意卡片查看詳情。';

  @override
  String get tipAllEventsTitle => '所有事件流';

  @override
  String get tipAllEventsBody =>
      '一條即時時間軸，彙整應用程式的日誌、網路請求、state 變更、儲存操作與錯誤，另含 display 與非同步操作事件。';

  @override
  String get tipAllEventsSteps =>
      '在\"搜尋事件...\"中輸入，比對訊息、URL 路徑、action、儲存鍵或標籤\n切換\"LOG\"、\"API\"、\"STATE\"與\"STORE\"篩選按鈕；\"ERRORS\"只保留錯誤與失敗的請求\n點擊某一列查看詳情；\"完整\"或\"Tab\"可將詳情儲存為圖片\n在底部列選擇一台裝置或\"全部\"，決定顯示哪台裝置的事件\n用\"最舊優先\"/\"最新優先\"切換順序，用\"自動捲動\"跟隨新事件';

  @override
  String get tipAllEventsTip =>
      '此處的\"全部清除\"會清空所有頁面的清單——Console、Network、State、Storage、Errors 等——而不只是這個事件流。';

  @override
  String get tipNetworkTitle => '檢查網路流量';

  @override
  String get tipNetworkBody =>
      '應用程式發出的 HTTP 請求，含標頭、內文、狀態與耗時，另有 GraphQL、WebSocket、gRPC 流量，以及被模擬規則回應的請求。gRPC 僅來自 Android SDK。';

  @override
  String get tipNetworkSteps =>
      '點擊某個請求，查看其\"Headers\"、\"Request\"、\"Response\"與\"Timing\"分頁\n依方法、\"2xx\"/\"3xx\"/\"錯誤\"篩選，或在\"篩選 URL...\"中輸入部分 URL\n開啟\"同時搜尋請求與回應內文\"，即可在 payload 內部一併搜尋\n點擊面板中的\"複製 cURL\"取得 curl 指令；在某一列按右鍵可選擇\"重送請求\"\n開啟\"Protocols\"查看 GraphQL、WebSocket 與 gRPC，或開啟\"Mock Audit\"查看被模擬的請求';

  @override
  String get tipNetworkTip =>
      'generate_204、captive.apple.com 等連線檢查請求預設隱藏，直到搜尋內容比對到它們才會顯示。';

  @override
  String get tipConsoleTitle => 'Console 日誌';

  @override
  String get tipConsoleBody =>
      '應用程式的日誌行會即時顯示，並附帶層級、標籤與時間——包括 React Native 的 console 呼叫、Flutter 的 print 與 debugPrint，以及 Android 的 println。';

  @override
  String get tipConsoleSteps =>
      '切換\"DEBUG\"、\"INFO\"、\"WARN\"與\"ERROR\"，顯示或隱藏對應層級\n在\"搜尋日誌...\"中輸入，比對訊息文字或標籤\n點擊某一列，查看其標籤、訊息、中繼資料與堆疊追蹤（如有）\n保持\"合併重複日誌\"開啟，可把連續相同的日誌行摺疊成一列並計數\n用\"匯出日誌\"把篩選後的清單儲存為\"文字 (.txt)\"或\"JSON (.json)\"';

  @override
  String get tipConsoleTip =>
      '一般的 console.log、print 與 println 日誌都以 DEBUG 層級送達——關閉\"DEBUG\"即可只保留資訊、警告與錯誤。';

  @override
  String get tipStateTitle => 'State 檢查器';

  @override
  String get tipStateBody =>
      '應用程式回報的每一次 state 變更，附帶對應的 action 以及變更前後的 state——React Native 上的 Redux、Zustand、MobX 等，Flutter 上的 BLoC、Riverpod 與 Provider，Android 上的 ViewModel。';

  @override
  String get tipStateSteps =>
      '開啟\"Timeline\"分頁——它會列出所有 state 函式庫的變更；用標題列的標籤可逐一顯示或隱藏\n在\"篩選操作...\"中輸入，比對 action 或 store 名稱\n點擊某次變更，再在\"差異\"、\"之前\"與\"之後\"之間切換\n使用\"將應用狀態還原到此時\"（需要 DevConnect.onStateRestore）或\"儲存為快照\"\n開啟\"控制\"，可固定 state 路徑、建立快照並派發 Redux action';

  @override
  String get tipStateTip =>
      '\"差異\"僅在 SDK 傳送了差異資料時才有內容——Redux、Zustand 與 MobX 會傳送；Flutter 與 Android 不會，此時請比較\"之前\"與\"之後\"。';

  @override
  String get tipStorageTitle => '應用程式儲存';

  @override
  String get tipStorageBody =>
      '顯示你用 SDK 包裝的儲存（AsyncStorage、MMKV、SharedPreferences、Hive 等）上的每一次讀取、寫入與刪除，以及受支援儲存的目前鍵——可直接在此編輯。';

  @override
  String get tipStorageSteps =>
      '在\"歷史記錄\"中選擇\"讀取\"、\"寫入\"或\"刪除\"，並切換\"AS\"、\"SP\"等儲存篩選按鈕\n在\"篩選鍵...\"中輸入一個鍵，查看對它的所有操作；值也會被比對\n點擊某一列，查看該操作的值、大小、儲存與時間\n開啟\"Key-Value\"查看某個儲存的目前鍵，再使用\"新增鍵\"、\"編輯值\"或\"刪除鍵\"\n點擊\"重新載入\"，從應用程式取得最新內容';

  @override
  String get tipStorageTip =>
      '在\"歷史記錄\"中，\"全部清除\"只清空這份日誌；在\"Key-Value\"中，\"全部清除\"會刪除應用程式儲存中的所有鍵。';

  @override
  String get tipDatabaseTitle => 'SQLite 資料庫';

  @override
  String get tipDatabaseBody =>
      '瀏覽並查詢應用程式透過 DevConnect.registerDatabase 註冊的 SQLite 資料庫：資料表（含資料列數）、SQL 輸入框與結果表格。';

  @override
  String get tipDatabaseSteps =>
      '在應用程式中用 DevConnect.registerDatabase 註冊資料庫\n點擊某個資料表，預覽它的前 50 列\n編輯 SQL，點擊\"執行\"來執行你自己的查詢\n再次點擊\"執行\"重新查詢——結果不會自動重新整理\n點擊\"重新載入資料表\"，重新整理資料表清單與資料列數';

  @override
  String get tipDatabaseTip => '要排序，請在查詢中加入 ORDER BY——點擊欄位標題不會排序。';

  @override
  String get tipPerformanceTitle => '效能分析器';

  @override
  String get tipPerformanceBody =>
      '即時圖表，呈現應用程式的 FPS、CPU、記憶體與網路活動，以及 SDK 回報的幀耗時、執行緒、電池、溫度狀態、磁碟 I/O、啟動時間與 ANR。';

  @override
  String get tipPerformanceSteps =>
      '在底部列選擇一台裝置——選擇\"全部\"時，圖表會混合所有應用程式的取樣資料\n查看工具列中即時的\"FPS\"、\"MEM\"、\"CPU\"與\"SLOW\"指標\n將滑鼠停在圖表上，查看精確數值以及它是多久之前收到的\n在\"系統狀態\"中查看啟動時間、電池消耗、溫度狀態、磁碟 I/O 與 ANR\n用\"截圖為圖片\"把圖表儲存為 PNG，用\"清除\"重新開始';

  @override
  String get tipPerformanceTip =>
      '將滑鼠停在 FPS 列的紅色徽章上，可查看慢幀的平均耗時與最差耗時，以及最近 5 個慢幀。';

  @override
  String get tipLeaksTitle => '記憶體洩漏偵測';

  @override
  String get tipLeaksBody =>
      '來自應用程式的洩漏警告：三個 SDK 都會自動偵測到的記憶體持續增長、React Native 上超過 50 個作用中的 timer，以及你用 DevConnect.reportMemoryLeak 回報的任何內容。';

  @override
  String get tipLeaksSteps =>
      '查看工具列中紅色、黃色與藍色的計數：嚴重、警告與資訊\n點擊某一列，查看其\"詳細資訊\"、\"保留大小\"、\"堆疊追蹤\"與\"中繼資料\"（如有回報）\n在記憶體增長的列中查看\"中繼資料\"，了解每次取樣以及總增長量（單位 MB）\n用 DevConnect.reportMemoryLeak 回報你自己發現的洩漏，例如尚未 dispose 的 controller 或 stream\n點擊\"清除\"，重複可疑的操作流程，留意是否出現新警告';

  @override
  String get tipLeaksTip =>
      '記憶體預設每 10 秒取樣一次；持續增長超過 20 MB 才會警告，超過 40 MB 則升級為嚴重。';

  @override
  String get tipBenchmarkTitle => '基準測試';

  @override
  String get tipBenchmarkBody =>
      '對你用 SDK 的 benchmark 呼叫包住的程式碼計時，另有每個 SDK 自行記錄的 App Startup 與 App Background 執行。';

  @override
  String get tipBenchmarkSteps =>
      '用 DevConnect.benchmarkStart 與 benchmarkStop 包住程式碼——React Native 則以 benchmark 開始\n用 benchmarkStep 標記各個階段（Flutter、React Native）；Android 的執行沒有步驟\n點擊某次執行，查看其\"啟動\"、\"結束\"、\"持續時間\"以及各步驟的瀑布圖\n在\"搜尋基準測試...\"中輸入，篩選清單與統計列\n點擊\"截圖為圖片\"，把該次執行的面板儲存為 PNG';

  @override
  String get tipBenchmarkTip =>
      '統計列統計的是清單中的所有執行——搜尋某一個標題，即可只看該基準測試的\"最小\"、\"平均\"與\"P50\"。';

  @override
  String get tipErrorsTitle => '錯誤';

  @override
  String get tipErrorsBody =>
      '列出應用程式回報的錯誤：React Native 的 JavaScript 錯誤與 console.error 呼叫、Flutter 的框架錯誤與 Dart 錯誤，以及 Android 的例外。';

  @override
  String get tipErrorsSteps =>
      'Flutter：用 DevConnect.initAndRunApp 啟動應用程式——僅呼叫 init 不會安裝錯誤擷取掛鉤\n點擊\"JS\"、\"Native\"、\"Android\"與\"iOS\"按鈕，顯示或隱藏對應平台\n在\"搜尋錯誤...\"中輸入，比對訊息、來源或堆疊追蹤\n點擊某個錯誤，開啟其\"Message\"、\"Stack Trace\"與\"Details\"分頁\n對於 React Native 的堆疊，點擊\"符號化\"，透過 Metro 把堆疊框架對應到你的原始碼';

  @override
  String get tipErrorsTip =>
      'Flutter 錯誤帶有其所在裝置的 Android 或 iOS 標籤——沒有單獨的 Flutter 按鈕。';

  @override
  String get tipMockTitle => 'Mock Server';

  @override
  String get tipMockBody =>
      '儲存模擬的 API 回應——方法、URL 正規表示式、狀態、標頭、內文以及可選的延遲——並安裝到所選裝置上，讓符合的請求根本不會到達網路。';

  @override
  String get tipMockSteps =>
      'Android：先把 DevConnect.mockServerInterceptor() 加到你的 OkHttpClient\n選擇一台裝置，點擊\"Add rule\"，填寫各欄位，再點擊\"Save changes\"\n點擊\"Push all\"——此後的編輯、開關切換與刪除會自動同步到裝置\n撥動規則的開關可暫停它，或開啟規則並按住\"Hold to delete\"刪除它（Undo 可復原）\n點擊\"Clear device\"，移除裝置上的所有規則並停止同步';

  @override
  String get tipMockTip =>
      '規則只儲存在 DevConnect 的記憶體中——結束後就會遺失，但已同步的裝置重新連線時會把規則拿回來。';

  @override
  String get tipHistoryTitle => '工作階段歷史';

  @override
  String get tipHistoryBody =>
      '裝置中斷連線並持續 15 秒未重新連線後，它的日誌、網路呼叫、state 變更與儲存操作會以唯讀工作階段的形式保留在這裡，直到它重新連線或 DevConnect 結束。';

  @override
  String get tipHistorySteps =>
      '點擊某個工作階段，開啟其\"All\"、\"Logs\"、\"Network\"、\"State\"與\"Storage\"分頁\n查看每張卡片上的中斷連線時間與事件數量\n點擊卡片上的 × 即可移除該工作階段\n點擊\"Clear All\"清空清單';

  @override
  String get tipHistoryTip =>
      '同一台裝置——或同一 IP 上的任何應用程式——一重新連線，工作階段就會消失，所以請在重新啟動應用程式前先查看。';

  @override
  String get tipDisplayTitle => 'Display';

  @override
  String get tipDisplayBody =>
      '顯示應用程式透過 DevConnect.display() 傳送的內容——名稱、可選的預覽文字、JSON 值與中繼資料。三個 SDK 都支援。';

  @override
  String get tipDisplaySteps =>
      '呼叫 DevConnect.display，傳入名稱，以及可選的值、預覽與中繼資料\n瀏覽各列，最新的在最前：每列顯示名稱、預覽與時間\n點擊某一列，查看其\"Preview\"、JSON 格式的\"Value\"與\"Metadata\"\n點擊\"Clear all\"清空清單';

  @override
  String get tipDisplayTip => '每次呼叫都會新增一列，而不是取代上一列——重複使用同一個名稱即可形成時間軸。';

  @override
  String get tipAsyncTitle => '非同步作業';

  @override
  String get tipAsyncBody =>
      '列出應用程式透過 DevConnect.reportAsyncOperation() 回報的非同步步驟——saga effect、任務、背景作業——並附帶狀態、耗時以及結果或錯誤。不會自動追蹤任何內容。';

  @override
  String get tipAsyncSteps =>
      '呼叫 reportAsyncOperation，傳入類型、描述以及狀態 start、resolve 或 reject\n在 React Native 上，用 trackAsync 包住 promise，即可從開始到結束自動回報\n看徽章顏色：橘色表示已開始，綠色表示已 resolve，紅色表示已 reject\n點擊某一列，查看其詳情、\"Result\"與\"Metadata\"\n點擊\"Clear all\"清空清單';

  @override
  String get tipAsyncTip =>
      '給相關的呼叫設定相同的 sagaName——選取其中任何一個，整組呼叫都會列在\"Saga timeline\"下。';

  @override
  String get tipLayoutTitle => 'Layout 檢查器';

  @override
  String get tipLayoutBody =>
      '擷取應用程式目前的畫面及其元素樹——Flutter widget、React Native 元件或 Android view——並顯示每個元素的位置、大小、padding、margin 與 props。';

  @override
  String get tipLayoutSteps =>
      '選擇裝置並點擊\"擷取\"，取得它的畫面與元素樹\n將滑鼠停在截圖上可醒目提示元素；點擊即可選取\n也可以在\"元素樹\"中選擇，或用\"依名稱或值尋找\"搜尋\n開啟\"僅顯示應用程式元素\"，隱藏函式庫中的 widget（Flutter、React Native）\n查看\"屬性\"——box model、位置、大小與 props——或點擊\"複製為 JSON\"';

  @override
  String get tipLayoutTip =>
      'React Native 只有在你呼叫 DevConnect.registerScreenshot() 之後才會傳送截圖——否則只能看到元素外框。';

  @override
  String get settingsGroupConnection => '連線';

  @override
  String get settingsGroupConnectionDesc => '伺服器、網路位址與 USB。';

  @override
  String get settingsGroupDevices => '裝置';

  @override
  String get settingsGroupDevicesDesc => '目前連線的應用與先前連線過的裝置。';

  @override
  String get settingsGroupAppearance => '外觀';

  @override
  String get settingsGroupAppearanceDesc => '主題、語言與顯示的分頁。';

  @override
  String get settingsGroupData => '顯示與資料';

  @override
  String get settingsGroupDataDesc => '詳情的顯示方式與保留的歷史量。';

  @override
  String get settingsGroupGuides => '指南';

  @override
  String get settingsGroupGuidesDesc => '快速開始、快捷鍵與使用技巧。';

  @override
  String get settingsGroupSupport => '支持';

  @override
  String get settingsGroupSupportDesc => '支持 DevConnect 持續發展。';

  @override
  String get tipsTabFeatures => '功能';

  @override
  String get tipsTabShortcuts => '快捷鍵';

  @override
  String get tipsTabConnect => '連接裝置';

  @override
  String get tipsTabSdk => '整合 SDK';

  @override
  String get tipsTabAdvanced => '進階';

  @override
  String get tipsSteps => '步驟';

  @override
  String get tipsKeys => '按鍵';

  @override
  String get tipsProTip => '小技巧';

  @override
  String get tipsPrevious => '上一個';

  @override
  String get tipsNext => '下一個';

  @override
  String get tipsDone => '完成';

  @override
  String get tipsOpenPage => '開啟頁面';

  @override
  String get tipsCopyCode => '複製';

  @override
  String get tipsCodeCopied => '已複製程式碼';

  @override
  String get tipsClose => '關閉';

  @override
  String get pageGuide => '如何使用此頁面';

  @override
  String get guideReloadTitle => '重新載入應用程式';

  @override
  String get guideReloadSummary =>
      '在 DevConnect 的任何頁面都能重新載入正在除錯的應用程式，即使正在輸入也行：Flutter 會重建 widget，React Native 會從 Metro 重新載入，Android 會重新建立目前的 activity。';

  @override
  String get guideReloadSteps =>
      '[⌘ R] 重新載入所選的應用程式；未選取應用程式時，重新載入所有已連線的應用程式\n[⇧ ⌘ R] 熱重啟：執行 Flutter 應用程式的 onHotRestartRequest，否則與 ⌘ R 一樣重新載入\n也可以點擊底部列中的重新載入按鈕——它們的工具提示會顯示快捷鍵';

  @override
  String get guideReloadTip =>
      'Flutter 的 ⌘ R 會重建 widget 樹並保留 state，但不會載入程式碼變更——這要用 IDE 的熱重載。';

  @override
  String get guideJsonSearchTitle => '在內文中搜尋';

  @override
  String get guideJsonSearchSummary =>
      'Tree、JSON 與程式碼檢視（TypeScript、Dart 或 Kotlin）各有自己的搜尋：不分大小寫，醒目提示所有相符項目，並捲動到目前的相符項目。';

  @override
  String get guideJsonSearchSteps =>
      '[⌘ F] 跳到該檢視的搜尋框——請先點擊內文內部\n[↵] 跳到下一個相符項目\n[⇧ ↵] 跳到上一個相符項目\n[Esc] 清除搜尋';

  @override
  String get guideJsonSearchTip =>
      'Tree 搜尋會展開節點並載入後續分頁，最多顯示 500 個相符項目；JSON 最多可統計 100,000 個。';

  @override
  String get guideLayoutZoomTitle => '縮放版面截圖';

  @override
  String get guideLayoutZoomSummary =>
      '在 Layout 頁面用鍵盤縮放截圖並調整顯示範圍——截圖一顯示，這些按鍵就立即生效。';

  @override
  String get guideLayoutZoomSteps =>
      '[⌘ +] 放大，每按一次 1.25×\n[⌘ −] 縮小\n[⌘ 0] 實際大小：100% 即應用程式本身的畫面尺寸\n[⌘ 1] 讓整個畫面符合面板\n[⌘ 2] 縮放到所選元素';

  @override
  String get guideLayoutZoomTip =>
      '點擊縮放百分比可選擇 50、100、200 或 400%；兩指捏合可縮放，拖曳可平移。';

  @override
  String get guideLayoutMeasureTitle => '測量間距';

  @override
  String get guideLayoutMeasureSummary =>
      '按住 Option，查看所選元素與滑鼠指標下方元素之間的距離，就像設計工具那樣。';

  @override
  String get guideLayoutMeasureSteps =>
      '選擇一個元素：在截圖上點擊它，或在元素樹中選擇它\n[⌥] 按住 Option，指向另一個元素\n讀取分開的元素之間的間隙；若其中一個元素包含另一個，則讀取邊距\n放開 Option，重新查看懸停元素的 box model';

  @override
  String get guideLayoutMeasureTip => '重疊的元素不會顯示距離——測量需要一個元素在另一個元素內部，或兩者之間有間隙。';

  @override
  String get guideLayoutTreeTitle => '瀏覽元素樹';

  @override
  String get guideLayoutTreeSummary =>
      '點擊某一列，或點擊截圖上的某個元素，讓元素樹取得焦點，然後用方向鍵在已擷取的元素樹中移動。';

  @override
  String get guideLayoutTreeSteps =>
      '[↑ ↓] 移到上一列或下一列\n[→] 展開該列；再按一次進入它的第一個子元素\n[←] 收合該列；再按一次退到它的父元素\n[Esc] 取消選取';

  @override
  String get guideLayoutTreeTip =>
      '在\"依名稱或值尋找\"中輸入，可搜尋名稱、props 與 state；用 ↵ 與 ⇧ ↵ 逐一跳轉相符項目。';

  @override
  String get guideAndroidEmulatorTitle => 'Android 模擬器';

  @override
  String get guideAndroidEmulatorSummary =>
      'Android 模擬器中的應用程式透過 10.0.2.2（Genymotion：10.0.3.2）連到這台 Mac，所以不需要任何設定。';

  @override
  String get guideAndroidEmulatorSteps =>
      '確認設定 › \"連線\" › \"伺服器\"顯示\"伺服器運行中\"\n原生 Android：把 enabled = BuildConfig.DEBUG 傳給 installForApp——預設是關閉的\n在模擬器中執行除錯版本；不需要 adb reverse\n在視窗底部的裝置列中找到該應用程式';

  @override
  String get guideAndroidEmulatorTip =>
      'DevConnect 每次啟動都使用連接埠 9090；在\"伺服器\"中修改的連接埠在結束前一直有效，且 SDK 的連接埠必須與之一致。';

  @override
  String get guideAndroidUsbTitle => '透過 USB 連接 Android 手機';

  @override
  String get guideAndroidUsbSummary =>
      'adb reverse 透過傳輸線把手機的 localhost 指向這台 Mac，所以應用程式不需要 Wi‑Fi 就能連線。';

  @override
  String get guideAndroidUsbSteps =>
      '開啟 USB 偵錯，插上手機，並在提示時允許這台 Mac\n在設定 › \"連線\" › \"USB 連線\"中點擊\"執行 ADB Reverse\"，或執行下方的指令\n啟動應用程式——已在執行的原生 Android 應用程式需要重新啟動\n連不上？在同一位置點擊\"裝置\"，檢查 adb 是否能辨識到手機';

  @override
  String get guideAndroidUsbTip =>
      '重新插拔、重新啟動 adb 或重新開機後需要再執行一次；插著多台裝置時，請在終端機中用 adb -s 加上手機的序號執行。';

  @override
  String get guideIosSimulatorTitle => 'iOS 模擬器';

  @override
  String get guideIosSimulatorSummary =>
      '模擬器與 Mac 共用網路，所以除錯版本不需要任何設定，就能透過 localhost 連到 DevConnect。';

  @override
  String get guideIosSimulatorSteps =>
      '確認設定 › \"連線\" › \"伺服器\"顯示\"伺服器運行中\"\n在模擬器中執行應用程式的除錯版本\n在視窗底部的裝置列中找到它';

  @override
  String get guideIosSimulatorTip =>
      '啟動順序無所謂：React Native 與 Flutter 應用程式會不斷重試，所以在 DevConnect 啟動幾秒後就會連上。';

  @override
  String get guideIphoneTitle => 'iPhone';

  @override
  String get guideIphoneSummary =>
      '與 Mac 位於同一個 Wi‑Fi 時，除錯版本通常能自動找到 DevConnect；如果找不到，就把 Mac 的位址設為 host。';

  @override
  String get guideIphoneSteps =>
      '讓 iPhone 和 Mac 連上同一個 Wi‑Fi——訪客網路通常會阻擋這一點\n執行除錯版本，iOS 詢問時允許存取區域網路\n等待幾秒：React Native 透過 Metro 找到 Mac，Flutter 透過廣播找到\n沒有出現？從設定 › \"連線\" › \"網路\"中複製 Mac 的位址\n在 SDK 的 init 中把它設為 host（程式碼見下方），然後重新啟動應用程式';

  @override
  String get guideIphoneTip => '只插 USB 傳輸線無法讓 iPhone 上的應用程式連線——手機必須透過網路連到 Mac。';

  @override
  String get guideTroubleshootTitle => '應用程式連不上';

  @override
  String get guideTroubleshootSummary => '大多數連線問題都出在幾個原因上——請依以下順序檢查。';

  @override
  String get guideTroubleshootSteps =>
      '設定 › \"連線\" › \"伺服器\"顯示\"伺服器運行中\"，且沒有連接埠錯誤\n應用程式是除錯版本；原生 Android 還需要 enabled = BuildConfig.DEBUG\nSDK 的連接埠與伺服器的連接埠一致——兩者預設都是 9090\n手機與 Mac 在同一個 Wi‑Fi 下，或 Android 的連接埠已透過 adb reverse 轉送\n使用 Wi‑Fi 時，macOS 允許 DevConnect 接受傳入連線（系統設定 › 網路 › 防火牆）';

  @override
  String get guideTroubleshootTip =>
      '還是不行？從設定 › \"連線\" › \"網路\"中選一個位址作為 host，並傳入 auto: false（Flutter：auto_: false），這樣重新連線時仍會使用它。';

  @override
  String get guideSdkReactNativeSummary =>
      '安裝該套件並在啟動時呼叫一次 init——此後 fetch 與 XHR（因此 axios 也在內）、console 日誌、錯誤與效能都會被擷取。';

  @override
  String get guideSdkReactNativeSteps =>
      '用 yarn 或 npm 加入 devconnect-manage-kit（指令見下方）\n在啟動時、第一個請求之前呼叫一次 DevConnect.init\n要擷取 state，請加入 devConnectReduxMiddleware（Redux）、devConnectMiddleware（Zustand）或 setupMobxSpy（MobX）\n執行除錯版本——在發行版本中 init 不會執行任何動作，除非傳入 enabled: true';

  @override
  String get guideSdkReactNativeTip =>
      'init 每次應用程式啟動只會執行一次，所以修改 host 或連接埠後要完整重新載入——Fast Refresh 會保留舊設定。';

  @override
  String get guideSdkFlutterSummary =>
      '透過 initAndRunApp 啟動應用程式：基於 dart:io 的 HTTP（http、Dio、Chopper……）、print 與 debugPrint、錯誤與效能都會被擷取，不需要額外的程式碼。';

  @override
  String get guideSdkFlutterSteps =>
      '執行 flutter pub add devconnect_manage_kit\n在 main() 中用 DevConnect.initAndRunApp 啟動應用程式，並傳入非同步的 runApp 回呼\n使用 Riverpod 或 BLoC 時，在你的 observer 中呼叫 DevConnect.reportStateChange 或 reportBlocChange\n執行除錯版本——profile 與 release 版本保持關閉';

  @override
  String get guideSdkFlutterTip =>
      '把 Firebase 與其他啟動程式碼放進 runApp 回呼裡——在 initAndRunApp 之前呼叫 ensureInitialized() 會導致 zone 不一致。';

  @override
  String get guideSdkAndroidSummary =>
      '加入 Maven Central 相依套件，並在 Application.onCreate 中呼叫 installForApp：println 輸出、當機、ANR、效能與 ViewModel state 都會被擷取；HTTP 則需要 OkHttp 攔截器。';

  @override
  String get guideSdkAndroidSteps =>
      '把 io.github.buivietphi:devconnect-android:1.1.0 加入 app/build.gradle.kts\n在 Application.onCreate 中呼叫 DevConnect.installForApp，並傳入 enabled = BuildConfig.DEBUG——預設是關閉的\n把 DevConnect.okHttpInterceptor() 加到每個 OkHttpClient，Retrofit 使用的也不例外\n用 DCLog 取代 android.util.Log 來記錄日誌；使用 Timber 時，plant 一個呼叫 DevConnectTimberHelper.log 的 Tree\n確保應用程式的 manifest 宣告了 INTERNET 權限';

  @override
  String get guideSdkAndroidTip =>
      'SDK 只在啟動時尋找一次 DevConnect——請先啟動 DevConnect（以及 adb reverse），或重新啟動應用程式。';

  @override
  String get guideMockApiTitle => '模擬 API';

  @override
  String get guideMockApiSummary =>
      '用你自己的狀態、標頭與內文回應符合的請求，還可以設定延遲，不需要改動伺服器或應用程式。';

  @override
  String get guideMockApiSteps =>
      '在底部列選擇一台裝置，開啟\"Mock Server\"，點擊\"Add rule\"\n設定\"Method\"、\"Status\"、\"URL pattern\"（在 URL 任意位置比對的正規表示式）與內文\n點擊\"Save changes\"，再點擊\"Push all\"——會傳送完整的規則清單，之後的儲存會自動同步到裝置\n在 Network › \"Mock Audit\"中查看被規則回應的請求\n用規則的開關暫停它，或用\"Clear device\"移除所有規則';

  @override
  String get guideMockApiTip =>
      'Android 需要在 OkHttp 上加入 DevConnect.mockServerInterceptor()；React Native 只模擬 fetch 呼叫，不模擬 axios 或 XMLHttpRequest。';

  @override
  String get guideStateControlsTitle => '從桌面控制 state';

  @override
  String get guideStateControlsSummary =>
      'State Inspector 的 Controls 分頁可以監看 state 路徑、儲存可傳回的快照，並向應用程式傳送 action。';

  @override
  String get guideStateControlsSteps =>
      '在底部列選擇一台裝置，開啟 State Inspector 並切換到\"Controls\"分頁\nSubscriptions：固定 auth.user.name 這樣的路徑；所有平台都可用，無需在應用程式中寫程式碼\nSnapshots：\"Take snapshot\"儲存最新的 state；應用程式處理 onStateRestore 後，\"Restore\"即可把它傳回\nDispatch action：輸入帶 \"type\"（例如 \"LOGOUT\"）的 JSON 物件並點擊\"Dispatch\"；React Native 需要 connectReduxStore(store)，Flutter 和 Android 需要 onReduxDispatch\n它們引起的變更會在應用程式的 state 函式庫回報後出現在\"Timeline\"中';

  @override
  String get guideStateControlsTip =>
      'Subscriptions 讀取最後回報的 state：Redux 為整個 store，而 Zustand、MobX、Riverpod 或 ViewModel 只是最後變更的 store 或 provider。如果 Restore 或 Dispatch 沒有效果，表示應用程式尚未設定處理函式；處理函式擲出的錯誤會顯示在 Console 中。';

  @override
  String get guideNetworkConditionsTitle => '慢速或離線網路';

  @override
  String get guideNetworkConditionsSummary =>
      '延遲應用程式的 HTTP 請求或讓請求失敗，不需要改動裝置設定——DevConnect 自身的連線不受影響。';

  @override
  String get guideNetworkConditionsSteps =>
      '在 Network 中，開啟工具列裡的儀表圖示選單\"網路條件\"\n選擇\"慢速 (+500 ms)\"或\"慢速 3G (~2 秒)\"，延遲每個請求\n選擇\"離線\"，讓請求立即失敗，就像網路斷了一樣\n用完後選擇\"正常\"——在此之前圖示會一直醒目提示\n在 Android 上，只有透過 DevConnect.okHttpInterceptor() 的 OkHttp 流量會變慢';

  @override
  String get guideNetworkConditionsTip =>
      '它對所有已連線的應用程式生效，也對之後連線的應用程式生效，直到你選擇\"正常\"。';

  @override
  String get guideReplayTitle => '重送請求';

  @override
  String get guideReplaySummary =>
      '讓應用程式再次送出一個已擷取的請求——方法、URL、請求標頭與內文都相同——不必在應用程式畫面裡一步步點擊。';

  @override
  String get guideReplaySteps =>
      '在 Network 中，對某個請求按右鍵並選擇\"重送請求\"\n或者開啟該請求，點擊面板頂部的重複圖示\n重送的請求會作為新的一列出現在清單中';

  @override
  String get guideReplayTip =>
      'Android 會透過應用程式自己的用戶端與攔截器重新執行最近的 OkHttp 呼叫；Flutter 與 React Native 則原樣重送已擷取的請求標頭。';

  @override
  String get guideHarExportTitle => '匯出為 HAR';

  @override
  String get guideHarExportSummary =>
      '把 Network 列出的請求儲存為標準的 HAR 1.2 檔案——包含標頭、內文、狀態與耗時——以便用其他工具開啟。';

  @override
  String get guideHarExportSteps =>
      '用裝置、方法、狀態與 URL 篩選器縮小\"HTTP\"清單的範圍\n點擊工具列中的下載圖示\"將列出的請求匯出為 HAR\"\n選擇 .har 檔案的儲存位置\n用 Chrome DevTools 或 Charles 開啟它，或分享給你的團隊';

  @override
  String get guideHarExportTip =>
      '只會儲存 HTTP 清單中顯示的內容，所以篩選條件決定檔案內容；\"Protocols\"中的項目不包含在內。';

  @override
  String get guideDatabaseQueryTitle => '查詢應用程式的資料庫';

  @override
  String get guideDatabaseQuerySummary =>
      '直接在 DevConnect 中瀏覽應用程式內 SQLite 資料庫的資料表，並對其執行 SQL。';

  @override
  String get guideDatabaseQuerySteps =>
      '在應用程式中用 DevConnect.registerDatabase 註冊資料庫（程式碼片段見下方）\n開啟 Database，點擊某個資料表，預覽它的前 50 列\n編輯 SQL 並點擊\"執行\"——結果最多顯示 1,000 列\n應用程式修改了資料表之後，點擊\"重新載入資料表\"';

  @override
  String get guideDatabaseQueryTip =>
      '查詢會在你最近點擊的那個資料表所屬的資料庫上執行；如果沒點擊過，則在第一個註冊的資料庫上執行。';

  @override
  String get guideBigJsonTitle => '大型內文';

  @override
  String get guideBigJsonSummary =>
      '大型內文開啟時不會卡住 DevConnect：它們在背景解析，Tree 與 JSON 只建構畫面上可見的部分。';

  @override
  String get guideBigJsonSteps =>
      '點擊長 Tree 清單下方的\"再顯示 … 項\"，載入接下來的 200 項\n對 Tree 中的長字串使用\"複製值\"——Tree 只顯示其前 2,000 個字元\n切換到 JSON，即可捲動並搜尋整份文件\n在 JSON 中使用\"Copy JSON\"或\"Save as file\"——兩者都會包含完整的內文\n超過 20,000 個字元的 JSON 行只顯示開頭；複製或儲存即可取得全部內容';

  @override
  String get guideBigJsonTip =>
      '當內文是物件清單時，Tree 提供\"表格\"：它顯示 500 列，但\"下載表格 (CSV)\"會儲存所有符合的列。';

  @override
  String get guideCustomCommandsTitle => '自訂指令';

  @override
  String get guideCustomCommandsSummary =>
      '從 DevConnect 執行應用程式內的程式碼——清除快取、登出、產生測試資料——並查看它的回傳結果。';

  @override
  String get guideCustomCommandsSteps =>
      '在應用程式中用 DevConnect.registerCommand 註冊 handler（程式碼片段見下方）\n開啟\"自訂指令\"，點擊應用程式列出的某個指令，或輸入它的名稱\n如果指令需要參數，以 JSON 物件的形式加入\n點擊\"執行\"，或在\"指令\"欄位中按 ↵，然後在下方查看結果';

  @override
  String get guideCustomCommandsTip =>
      'Flutter 與 React Native 的 handler 可以是非同步的；擲出的錯誤會作為結果顯示，超過 10 秒沒有回應則逾時。';

  @override
  String get restart => '重新啟動';

  @override
  String get serverAddressHint => '應用會連線到這個位址。';

  @override
  String get serverStoppedHint => '啟動伺服器後應用才能連線。';

  @override
  String get tabBenchmark => '基準測試';

  @override
  String get tabDisplay => '顯示';

  @override
  String get tabAsync => '非同步作業';

  @override
  String get tabLayout => '版面檢查';

  @override
  String get tabCommands => '自訂指令';

  @override
  String get tabMockServer => '模擬伺服器';

  @override
  String get tabsAlwaysShown => '所有事件與設定一律顯示。';

  @override
  String get quickStartDesc => '安裝 SDK，在應用中啟動，然後連線。';

  @override
  String get quickStartNext => '下一步 — 在應用中啟動';

  @override
  String get quickStartEmulator => '模擬器自動連線';

  @override
  String get quickStartWifi => 'Wi‑Fi 實機';

  @override
  String get quickStartUsb => 'USB 連接 Android';
}
