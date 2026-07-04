// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class SJa extends S {
  SJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'DevConnect 管理ツール';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get clear => 'クリア';

  @override
  String get copy => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String get start => '開始';

  @override
  String get stop => '停止';

  @override
  String get on => 'オン';

  @override
  String get off => 'オフ';

  @override
  String get autoScroll => '自動スクロール';

  @override
  String get newestFirst => '新しい順';

  @override
  String get oldestFirst => '古い順';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String get maintenance => 'メンテナンス';

  @override
  String get clearAllCache => 'すべてキャッシュをクリア';

  @override
  String get clearAllCacheDesc =>
      'すべてのデバイスを切断し、すべてのメモリ内データ（ログ、ネットワークキャプチャ、状態、パフォーマンスなど）を消去します。設定（テーマ、言語、ポート）は保持されます。';

  @override
  String get clearAllCacheConfirm =>
      'すべてキャッシュをクリアしますか？\n\n接続されているすべてのデバイスを切断し、メモリ内のすべてのログ、ネットワークキャプチャ、状態変更、パフォーマンス指標、ベンチマークを消去します。\n\n設定（テーマ、言語、ポート）は保持されます。';

  @override
  String get cacheCleared => 'すべてキャッシュをクリアしました。設定は保持されます。';

  @override
  String clearAllCacheFailed(Object error) {
    return 'キャッシュのクリアに失敗しました：$error';
  }

  @override
  String get deviceHistory => 'キャッシュされたデバイス';

  @override
  String get deviceHistoryDesc =>
      'このデスクトップに接続したすべてのデバイス。エントリは再起動後も保持され、以前に何が接続されていたかを確認できます。';

  @override
  String get noDeviceHistory => 'まだデバイスが接続されていません';

  @override
  String get deviceHistoryEmptyHint =>
      'SDK 経由でデバイスを接続すると、ここに表示されます。エントリは再起動後も保持されます。';

  @override
  String get restarting => '再起動中…';

  @override
  String get online => 'オンライン';

  @override
  String get offline => 'オフライン';

  @override
  String get markOnline => 'オンラインとしてマーク';

  @override
  String get markOffline => 'オフラインとしてマーク';

  @override
  String get deviceOnline => 'オンライン';

  @override
  String get deviceOffline => 'オフライン';

  @override
  String lastSeen(Object time) {
    return '最終確認 $time';
  }

  @override
  String firstSeen(Object time) {
    return '初回確認 $time';
  }

  @override
  String get forgetDevice => '削除';

  @override
  String get forgetAllOffline => 'オフラインをすべて削除';

  @override
  String get forgetAllDevices => 'すべて削除';

  @override
  String get forgetDeviceConfirm =>
      'このデバイスを削除しますか？\n\n履歴から削除されます。次回接続時に新しいエントリとして表示されます。';

  @override
  String get forgetAllOfflineConfirm =>
      'オフラインのデバイスをすべて削除しますか？\n\n未接続のエントリがすべて削除されます。オンラインのデバイスは保持されます。';

  @override
  String get forgetAllDevicesConfirm =>
      'キャッシュされたすべてのデバイスを削除しますか？\n\nオンラインのデバイスを含む履歴全体が削除されます。再接続時に再表示されます。';

  @override
  String get deviceForgotten => 'デバイスを削除しました';

  @override
  String devicesForgotten(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台のデバイスを削除',
      one: '1 台のデバイスを削除',
      zero: '0 件削除',
    );
    return '$_temp0';
  }

  @override
  String connectionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回接続',
      one: '1 回接続',
      zero: '未接続',
    );
    return '$_temp0';
  }

  @override
  String get restartServer => 'サーバーを再起動';

  @override
  String portOccupied(Object port) {
    return 'ポート $port は使用中です';
  }

  @override
  String get serverRestarted => 'サーバーを再起動しました';

  @override
  String get restartFailed => '再起動に失敗しました';

  @override
  String portStillInUse(Object port) {
    return 'ポート $port は他のプロセスに使用されています';
  }

  @override
  String couldNotRestart(Object port) {
    return 'ポート $port で再起動できません';
  }

  @override
  String listeningOnPort(Object port) {
    return 'ポート $port でリッスン中';
  }

  @override
  String waitingForReconnect(Object port) {
    return 'ポート $port · デバイスの再接続を待機中';
  }

  @override
  String reconnectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台のデバイスが再接続',
      one: '1 台のデバイスが再接続',
      zero: '0 件再接続',
    );
    return '$_temp0';
  }

  @override
  String get reloadApp => 'アプリをリロード';

  @override
  String get reloadAppHotReload => 'ホットリロード';

  @override
  String get reloadAppHotRestart => 'ホットリスタート';

  @override
  String get reloadAppMetro => 'Metro をリロード';

  @override
  String get reloadAppNoDevices => 'デバイス未接続';

  @override
  String get reloadSent => 'リロードを送信しました';

  @override
  String sentReloadTo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台のデバイスにリロードを送信',
      one: '1 台のデバイスにリロードを送信',
      zero: '対象デバイスなし',
    );
    return '$_temp0';
  }

  @override
  String get screenshotSaved => 'スクリーンショットを保存しました';

  @override
  String get screenshotFailed => 'スクリーンショット失敗';

  @override
  String get reveal => '開く';

  @override
  String get captureFull => '全体';

  @override
  String get captureTab => 'タブ';

  @override
  String get captureFullTooltip => '詳細全体を画像としてキャプチャ';

  @override
  String get captureTabTooltip => '現在のタブのみキャプチャ';

  @override
  String get captureAsImage => '画像としてキャプチャ';

  @override
  String get captureDetailAsImage => '詳細を画像としてキャプチャ';

  @override
  String get noData => 'データなし';

  @override
  String get noItems => '項目なし';

  @override
  String get searchHint => '検索...';

  @override
  String get filterHint => 'フィルター...';

  @override
  String get value => '値';

  @override
  String get key => 'キー';

  @override
  String get metadata => 'メタデータ';

  @override
  String get duration => '期間';

  @override
  String get error => 'エラー';

  @override
  String get json => 'JSON';

  @override
  String get tree => 'Tree';

  @override
  String get code => 'Code';

  @override
  String get raw => 'Raw';

  @override
  String get format => 'フォーマット';

  @override
  String get pretty => '整形';

  @override
  String get collapse => '折りたたむ';

  @override
  String get showMore => 'もっと見る';

  @override
  String get noHeaders => 'ヘッダーなし';

  @override
  String get inProgress => '処理中';

  @override
  String get inProgressDots => '処理中...';

  @override
  String hideShowTooltip(Object action, Object label) {
    return '$action $label';
  }

  @override
  String get hide => '非表示';

  @override
  String get show => '表示';

  @override
  String get steps => 'ステップ';

  @override
  String get portInUse => 'ポートが使用中です。このポートを使用している他のアプリを閉じるか、設定で別のポートを選択してください。';

  @override
  String portInUseShort(Object port) {
    return 'ポート $port が使用中です。このポートを使用している他のアプリを閉じるか、上記に別のポートを入力して開始を押してください。';
  }

  @override
  String failedToStartServer(Object msg) {
    return 'サーバーを起動できません：$msg';
  }

  @override
  String failedToStartServerOnPort(Object msg, Object port) {
    return 'ポート $port でサーバーを起動できません：$msg';
  }

  @override
  String get settings => '設定';

  @override
  String get server => 'サーバー';

  @override
  String get serverRunning => 'サーバー実行中';

  @override
  String get serverStopped => 'サーバー停止';

  @override
  String get port => 'ポート';

  @override
  String deviceCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台のデバイス',
      one: '1 台のデバイス',
      zero: '0 台のデバイス',
    );
    return '$_temp0';
  }

  @override
  String get network => 'ネットワーク';

  @override
  String get hostname => 'ホスト名';

  @override
  String get noNetworkInterfaces => 'ネットワークインターフェースが見つかりません';

  @override
  String copiedIp(Object ip) {
    return '$ip をコピーしました';
  }

  @override
  String connectedDevices(Object count) {
    return '接続済みデバイス ($count)';
  }

  @override
  String get noDevicesConnected => 'デバイス未接続';

  @override
  String get appearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get dark => 'ダーク';

  @override
  String get light => 'ライト';

  @override
  String get bottom => '下';

  @override
  String get top => '上';

  @override
  String get language => '言語';

  @override
  String get tabVisibility => 'タブの表示';

  @override
  String get tabVisibilityDesc =>
      'タブの表示/非表示を切り替えます。無効なタブはロックアイコンが表示され、すべてのイベントからデータが除外されます。';

  @override
  String get detailView => '詳細ビュー';

  @override
  String get detailViewDesc => 'リクエスト/レスポンスの表示方法を記憶し、タブ切り替えアニメーションを制御します。';

  @override
  String get bodyView => 'ボディ表示';

  @override
  String get tabAnimation => 'タブアニメーション';

  @override
  String get tabAnimationDuration => '期間';

  @override
  String get codeModeDesc =>
      'コードモードは接続されたSDKに基づいてTypeScript / Dart / Kotlinとしてエクスポートします。';

  @override
  String get treeModeDesc =>
      'ツリーモードはデータを展開/折りたたみ可能なノード階層で表示します。深くネストされた値の閲覧に適しています。';

  @override
  String get jsonModeDesc =>
      'JSONモードはデータを構文強調表示付きの単一のコピーしやすいJSONドキュメントとして表示します。';

  @override
  String get captureDataJson => 'データをキャプチャ (現在のモードのキー + 値)';

  @override
  String get captureDataText => 'データをキャプチャ (キー + 値をテキストとして)';

  @override
  String get copyKey => 'キーをコピー';

  @override
  String get usbConnection => 'USB接続';

  @override
  String get android => 'Android';

  @override
  String get ios => 'iOS';

  @override
  String get runAdbReverse => 'ADB Reverseを実行';

  @override
  String adbNotFound(Object home) {
    return 'adbが見つかりません。\nHOME=$home';
  }

  @override
  String adbReverseOk(Object path) {
    return 'adb reverse OK ($path)';
  }

  @override
  String adbError(Object error) {
    return 'adbエラー：$error';
  }

  @override
  String adbException(Object error) {
    return 'adb例外：$error';
  }

  @override
  String get devices => 'デバイス';

  @override
  String get adbDevices => 'ADBデバイス';

  @override
  String get wifiAutoConnect => '同一ネットワークでWiFi自動接続。USB：iproxyをインストール。';

  @override
  String get quickStart => 'クイックスタート';

  @override
  String get quickStartDesc =>
      'アプリを接続する 3 ステップ。プラットフォームのタブをクリックして、各 SDK のコードを表示します。';

  @override
  String get installSdk => 'SDKをインストール';

  @override
  String get initialize => '初期化';

  @override
  String get connect => '接続';

  @override
  String get supportDevConnect => 'DevConnectを支援';

  @override
  String get supportDevConnectDesc =>
      'DevConnect管理ツールは無料でオープンソースです。ワークフローに役立つ場合は、開発の支援をご検討ください。';

  @override
  String get kofi => 'Ko-fi';

  @override
  String get paypal => 'PayPal';

  @override
  String get ethernet => 'イーサネット';

  @override
  String get wifi => 'WiFi';

  @override
  String get vpn => 'VPN';

  @override
  String get bridge => 'ブリッジ';

  @override
  String get loopback => 'ループバック';

  @override
  String get console => 'コンソール';

  @override
  String get state => '状態';

  @override
  String get storage => 'ストレージ';

  @override
  String get database => 'データベース';

  @override
  String get performance => 'パフォーマンス';

  @override
  String get memoryLeaks => 'メモリリーク';

  @override
  String get history => '履歴';

  @override
  String get noNetworkRequests => 'ネットワークリクエストなし';

  @override
  String get apiCallsAppearHere => 'APIコールがリアルタイムでここに表示されます';

  @override
  String get networkTitle => 'ネットワーク';

  @override
  String get filterUrls => 'URLをフィルター...';

  @override
  String get copyUrl => 'URLをコピー';

  @override
  String get urlCopied => 'URLをコピーしました';

  @override
  String get copyPath => 'パスをコピー';

  @override
  String get pathCopied => 'パスをコピーしました';

  @override
  String get copyCurl => 'cURLをコピー';

  @override
  String get curlCopied => 'cURLをコピーしました';

  @override
  String get copyRequest => 'リクエストをコピー';

  @override
  String get requestCopied => 'リクエストをコピーしました';

  @override
  String get copyResponse => 'レスポンスをコピー';

  @override
  String get responseCopied => 'レスポンスをコピーしました';

  @override
  String get requestBody => 'リクエストボディ';

  @override
  String get responseBody => 'レスポンスボディ';

  @override
  String get requestHeaders => 'リクエストヘッダー';

  @override
  String get responseHeaders => 'レスポンスヘッダー';

  @override
  String get headers => 'ヘッダー';

  @override
  String get request => 'リクエスト';

  @override
  String get response => 'レスポンス';

  @override
  String get timing => 'タイミング';

  @override
  String get startTime => '開始時間';

  @override
  String get endTime => '終了時間';

  @override
  String noLabel(Object label) {
    return '$labelなし';
  }

  @override
  String get noStorageData => 'ストレージデータなし';

  @override
  String get storageEntriesAppearHere =>
      'SharedPreferences、AsyncStorage、Hiveのエントリがここに表示されます';

  @override
  String get storageTitle => 'ストレージ';

  @override
  String get filterKeys => 'キーをフィルター...';

  @override
  String get read => '読み取り';

  @override
  String get write => '書き込み';

  @override
  String get delete => '削除';

  @override
  String get noEventsYet => 'イベントなし';

  @override
  String get startAppToSeeEvents => 'DevConnect SDKでアプリを起動してイベントを表示';

  @override
  String get eventsAppearHere => 'イベントがリアルタイムでここに表示されます';

  @override
  String get allEventsTitle => 'すべてのイベント';

  @override
  String get stopped => '停止済み';

  @override
  String get searchEvents => 'イベントを検索...';

  @override
  String get logDetail => 'ログ詳細';

  @override
  String get networkDetail => 'ネットワーク詳細';

  @override
  String get stateDetail => '状態詳細';

  @override
  String get storageDetail => 'ストレージ詳細';

  @override
  String get displayDetail => '表示詳細';

  @override
  String get asyncOperation => '非同期操作';

  @override
  String get errorDetail => 'エラー詳細';

  @override
  String get tag => 'タグ';

  @override
  String get message => 'メッセージ';

  @override
  String get stackTrace => 'スタックトレース';

  @override
  String get noLogsYet => 'ログなし';

  @override
  String get connectDeviceToSeeLogs => 'デバイスを接続してログを開始するとここに表示されます';

  @override
  String get consoleTitle => 'コンソール';

  @override
  String get searchLogs => 'ログを検索...';

  @override
  String get clearConsole => 'コンソールをクリア';

  @override
  String get copyMessage => 'メッセージをコピー';

  @override
  String get logCopied => 'ログをコピーしました';

  @override
  String get closePanel => 'パネルを閉じる';

  @override
  String hideShowLogs(Object action, Object label) {
    return '$labelログを$action';
  }

  @override
  String get errors => 'エラー';

  @override
  String get searchErrors => 'エラーを検索...';

  @override
  String get clearErrors => 'エラーをクリア';

  @override
  String get totalErrors => 'エラー合計';

  @override
  String get fatalCrash => '致命的/クラッシュ';

  @override
  String get noErrorsCaptured => 'エラー未キャプチャ';

  @override
  String get errorsAppearHere => 'React NativeとFlutterのエラーがここに表示されます';

  @override
  String get stackTraceCopied => 'スタックトレースをコピーしました';

  @override
  String get noStackTrace => 'スタックトレースなし';

  @override
  String get platform => 'プラットフォーム';

  @override
  String get severity => '深刻度';

  @override
  String get source => 'ソース';

  @override
  String get deviceId => 'デバイスID';

  @override
  String get deviceInfo => 'デバイス情報';

  @override
  String get details => '詳細';

  @override
  String hideShowErrors(Object action, Object label) {
    return '$labelエラーを$action';
  }

  @override
  String get noStateChanges => '状態変更なし';

  @override
  String get stateChangesAppearHere =>
      'Redux、BLoC、Riverpod、MobXの状態変更がここに表示されます';

  @override
  String get stateInspectorTitle => '状態インスペクター';

  @override
  String changesCount(Object count) {
    return '$count件の変更';
  }

  @override
  String changeCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の変更',
      one: '1件の変更',
      zero: '0件の変更',
    );
    return '$_temp0';
  }

  @override
  String get filterActions => 'アクションをフィルター...';

  @override
  String get newestAtTop => '最新が上';

  @override
  String get newestAtBottom => '最新が下';

  @override
  String get noChanges => '変更なし';

  @override
  String get diff => '差分';

  @override
  String get before => '変更前';

  @override
  String get after => '変更後';

  @override
  String get noChangesDetected => '変更を検出しませんでした';

  @override
  String get noBenchmarks => 'ベンチマークなし';

  @override
  String get useBenchmarkSdk => 'SDKでbenchmarkStart/Step/Stopを使用してパフォーマンスを測定';

  @override
  String get benchmarksTitle => 'ベンチマーク';

  @override
  String get searchBenchmarks => 'ベンチマークを検索...';

  @override
  String get total => '合計';

  @override
  String get avg => '平均';

  @override
  String get min => '最小';

  @override
  String get max => '最大';

  @override
  String get p50 => 'P50';

  @override
  String get end => '終了';

  @override
  String stepsCount(Object count) {
    return 'ステップ ($count)';
  }

  @override
  String get noIntermediateSteps => '中間ステップの記録なし';

  @override
  String get noPerformanceData => 'パフォーマンスデータなし';

  @override
  String get connectAppToProfile => 'DevConnect SDKでアプリを接続してプロファイリングを開始';

  @override
  String get stopRecording => '記録停止';

  @override
  String get startRecording => '記録開始';

  @override
  String get performanceProfiler => 'パフォーマンスプロファイラー';

  @override
  String slowFrames(Object count) {
    return 'スローフレーム：$count';
  }

  @override
  String get systemStatus => 'システム状態';

  @override
  String get startup => '起動';

  @override
  String get battery => 'バッテリー';

  @override
  String get emulator => 'エミュレーター';

  @override
  String get drainRate => '消費率';

  @override
  String get thermal => '温度';

  @override
  String get diskRead => 'ディスク読み取り';

  @override
  String get diskWrite => 'ディスク書き込み';

  @override
  String get anr => 'ANR';

  @override
  String get charging => '充電中';

  @override
  String get normal => '正常';

  @override
  String get fair => '普通';

  @override
  String get serious => '重大';

  @override
  String get critical => '緊急';

  @override
  String get reqs => 'リクエスト';

  @override
  String get live => 'ライブ';

  @override
  String get reqPerSec => 'req/秒';

  @override
  String get err => 'エラー';

  @override
  String get waitingForRequests => 'リクエスト待ち...';

  @override
  String get waitingForData => 'データ待ち...';

  @override
  String get noMemoryLeaksDetected => 'メモリリーク未検出';

  @override
  String get connectAppToMonitorLeaks => 'DevConnect SDKでアプリを接続してメモリリークを監視';

  @override
  String get memoryLeakDetection => 'メモリリーク検出';

  @override
  String get warning => '警告';

  @override
  String get info => '情報';

  @override
  String get detail => '詳細';

  @override
  String get retainedSize => '保持サイズ';

  @override
  String get timestamp => 'タイムスタンプ';

  @override
  String get undisposedController => '未解放のController';

  @override
  String get undisposedStream => '未解放のStream';

  @override
  String get undisposedTimer => '未解放のTimer';

  @override
  String get undisposedAnimation => '未解放のAnimation';

  @override
  String get widgetLeak => 'Widgetリーク';

  @override
  String get growingCollection => '増加中のコレクション';

  @override
  String get custom => 'カスタム';

  @override
  String get smoothScrolling => 'スムーズスクロール';

  @override
  String get smoothScrollingDesc =>
      'マウスホイールのスクロールイベントに滑らかなアニメーションを追加します。ラグやパフォーマンス低下を感じる場合は、この設定をオフにしてください。';

  @override
  String get smoothScrollingDuration => 'スクロール時間';

  @override
  String get smoothScrollingDurationDesc => 'スクロールアニメーションの時間（ミリ秒）。';

  @override
  String binaryBody(String label) {
    return '$labelのボディはバイナリです';
  }

  @override
  String binaryBodySize(String kb, int bytes) {
    return '$kb KB ($bytes バイト)';
  }

  @override
  String get binaryBodyHint => 'アクションは X-Amz-Target ヘッダーで識別してください。';
}
