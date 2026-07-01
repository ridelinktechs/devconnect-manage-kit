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
      other: '$count 台设备已重新加载',
      one: '1 台设备已重新加载',
      zero: '0 台设备已重新加载',
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
  String get tree => '树形';

  @override
  String get code => '代码';

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
  String get bodyView => '内容视图';

  @override
  String get tabAnimation => '标签页动画';

  @override
  String get tabAnimationDuration => '持续时间';

  @override
  String get codeModeDesc => '代码模式根据已连接的 SDK 导出为 TypeScript / Dart / Kotlin。';

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
  String get wifiAutoConnect => '同一网络下 WiFi 自动连接。USB：安装 iproxy。';

  @override
  String get quickStart => '快速入门';

  @override
  String get quickStartDesc => '三步连接您的应用。点击任意平台标签查看对应 SDK 的代码片段。';

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
      other: '$count 台设备已重新加载',
      one: '1 台设备已重新加载',
      zero: '0 台设备已重新加载',
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
  String get tree => '树形';

  @override
  String get code => '代码';

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
  String get bodyView => '内容视图';

  @override
  String get tabAnimation => '标签页动画';

  @override
  String get tabAnimationDuration => '持续时间';

  @override
  String get codeModeDesc => '代码模式根据已连接的 SDK 导出为 TypeScript / Dart / Kotlin。';

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
  String get wifiAutoConnect => '同一网络下 WiFi 自动连接。USB：安装 iproxy。';

  @override
  String get quickStart => '快速入门';

  @override
  String get quickStartDesc => '三步连接您的应用。点击任意平台标签查看对应 SDK 的代码片段。';

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
      other: '$count 台裝置已重新載入',
      one: '1 台裝置已重新載入',
      zero: '0 台裝置已重新載入',
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
  String get tree => '樹狀';

  @override
  String get code => '程式碼';

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
  String get bodyView => '內容檢視';

  @override
  String get tabAnimation => '分頁動畫';

  @override
  String get tabAnimationDuration => '持續時間';

  @override
  String get codeModeDesc => '程式碼模式根據已連線的 SDK 匯出為 TypeScript / Dart / Kotlin。';

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
  String get wifiAutoConnect => '同一網路下 WiFi 自動連線。USB：安裝 iproxy。';

  @override
  String get quickStart => '快速入門';

  @override
  String get quickStartDesc => '三步連線您的應用。點擊任意平台標籤查看對應 SDK 的程式碼片段。';

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
}
