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
  String get dataRetention => 'データ保持';

  @override
  String get dataRetentionDesc =>
      '各機能リストに適用されるハードキャップ。リストが上限を超えると、最も古いエントリがFIFOで削除されます。保留中の非同期操作は保持されます。';

  @override
  String get maxItems => '最大件数';

  @override
  String get dataRetentionHelper =>
      '無制限はすべてのエントリを保持します。値を小さくするとメモリを解放しますが履歴を失います。';

  @override
  String get allEventsDisplay => '全イベント表示';

  @override
  String get allEventsDisplayDesc =>
      '集約された全イベントリストの表示専用フィルター。元のログは削除されません — 無制限に戻すとすべて復元されます。';

  @override
  String get allEventsDisplayHelper => '値を小さくすると最新のN件のみ表示され、過去の履歴は失われます。';

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
  String get wifiAutoConnect =>
      'iPhone は Wi‑Fi 経由で接続します。この Mac と同じネットワークに接続してください。USB ケーブルだけでは接続できません。';

  @override
  String get quickStart => 'クイックスタート';

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
  String clearStaleButton(Object count) {
    return '古い ($count)';
  }

  @override
  String clearStaleTooltip(Object count) {
    return '10分以上応答のない保留中のリクエスト$count件を削除';
  }

  @override
  String clearStaleSnackbar(Object count) {
    return '古いリクエスト$count件を削除しました (保留中 > 10分)';
  }

  @override
  String memorySafetyOverflow(Object count) {
    return 'メモリ保護: open-trips キャッシュから古いネットワーク エントリ $count 件を削除しました';
  }

  @override
  String get sdkTipsPill => 'Tips lib';

  @override
  String get sdkTipsHeader => 'ライブラリの互換性';

  @override
  String get sdkTipsSubtitle =>
      'すべてのデータが完全に表示されるよう、ライブラリが最新バージョンであることを確認してください。';

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
  String get sdkTipsInstalled => '使用中';

  @override
  String get sdkTipsLatestLabel => '最新';

  @override
  String get sdkTipsUpdate => '更新';

  @override
  String get sdkTipsChecking => '確認中';

  @override
  String get sdkTipsOffline => '確認できません';

  @override
  String get sdkTipsRetry => '再試行';

  @override
  String get sdkTipsCheckProject => 'プロジェクトで実行して、使用中のバージョンを確認:';

  @override
  String get sdkTipsInstallLatest => '最新バージョンをインストール:';

  @override
  String get appUpdateTitle => 'DevConnect のバージョン';

  @override
  String get appUpdateAvailable => '新しいバージョンがあります。';

  @override
  String get appUpdateUpToDate => '最新バージョンを使用しています。';

  @override
  String get appUpdateViewRelease => 'リリースを見る';

  @override
  String devicesConnected(Object count) {
    return '$count 台接続中';
  }

  @override
  String get devicesAll => 'すべて';

  @override
  String devicesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台',
    );
    return '$_temp0';
  }

  @override
  String get commandsTitle => 'カスタムコマンド';

  @override
  String get commandsNoDevice => 'デバイスを接続するとコマンドを実行できます。';

  @override
  String get commandsEmptyHint =>
      'まだコマンドが登録されていません。アプリで DevConnect.registerCommand(name, handler) を使って追加するか、コマンド名を入力して実行してください。';

  @override
  String get commandsName => 'コマンド';

  @override
  String get commandsArgs => '引数 — JSON オブジェクト（任意）';

  @override
  String get commandsArgsInvalid => '引数は JSON オブジェクトにしてください。';

  @override
  String get commandsRun => '実行';

  @override
  String commandsTarget(Object device) {
    return '$device で実行';
  }

  @override
  String get commandsHistoryEmpty => '実行したコマンドの結果がここに表示されます。';

  @override
  String get commandsNoResponse => '応答がありません。アプリにこのコマンドは登録されていますか？';

  @override
  String get dbTables => 'テーブル';

  @override
  String get dbRefresh => 'テーブルを再読み込み';

  @override
  String get dbNoDevice => 'デバイスを接続するとデータベースを閲覧できます。';

  @override
  String get dbSelectDevice => '下部バーでデバイスを選ぶとデータベースを閲覧できます。';

  @override
  String get dbNoDatabases =>
      'データベースが登録されていません。アプリで DevConnect.registerDatabase(name, query) を使って追加し、テーブルを再読み込みしてください。';

  @override
  String get dbRun => '実行';

  @override
  String get dbRunHint => 'テーブルを選ぶか SQL を書いてください';

  @override
  String get dbRunHintSubtitle => 'テーブルを選ぶと先頭 50 行をプレビューします。';

  @override
  String dbRows(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行',
    );
    return '$_temp0';
  }

  @override
  String dbTruncated(Object count) {
    return '先頭 $count 行のみ';
  }

  @override
  String get dbNoResponse =>
      '応答がありません。アプリは DevConnect.registerDatabase でデータベースを登録していますか？最新の SDK が必要です。';

  @override
  String get stateToolsTab => 'コントロール';

  @override
  String get stateNoDevice => '下部バーでデバイスを選ぶと、状態の監視・スナップショット・操作ができます。';

  @override
  String get stateNoState => 'このデバイスはまだ状態を送信していません。';

  @override
  String get stateSubscriptions => 'サブスクリプション';

  @override
  String get stateSubscriptionsHint =>
      '状態のパスをピン留めすると値をライブで確認できます（例: auth.user、cart.items[0].price）。';

  @override
  String get statePinPath => 'パスをピン留め';

  @override
  String get statePathMissing => '（状態にありません）';

  @override
  String get stateRemove => '削除';

  @override
  String get stateSnapshots => 'スナップショット';

  @override
  String get stateSnapshotsHint =>
      '現在の状態を保存し、後で送り返してバグの再現や長いフォームの省略に使えます。アプリは onStateRestore で適用します。';

  @override
  String get stateTakeSnapshot => 'スナップショットを撮る';

  @override
  String stateKeys(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count キー',
    );
    return '$_temp0';
  }

  @override
  String get stateRestore => '復元';

  @override
  String get stateRestoreHere => 'アプリの状態をこの時点に復元';

  @override
  String get stateSaveSnapshot => 'スナップショットとして保存';

  @override
  String get stateSnapshotSaved => 'スナップショットを保存しました';

  @override
  String get stateRestoreSent => '状態の復元を送信しました';

  @override
  String get stateDispatch => 'アクションをディスパッチ';

  @override
  String get stateDispatchHint =>
      'Redux アクションをアプリに送ります。ストアの接続が必要です: React Native は connectReduxStore(store)、Flutter と Android は onReduxDispatch。';

  @override
  String get stateDispatchButton => 'ディスパッチ';

  @override
  String get stateDispatchSent => 'アクションを送信しました';

  @override
  String get stateActionInvalid => 'アクションは JSON オブジェクトにしてください。';

  @override
  String get stateRecentActions => '最近';

  @override
  String get jsonTreeView => 'ツリー';

  @override
  String get jsonTableView => 'テーブル';

  @override
  String get jsonSearchHint => 'キーと値を検索';

  @override
  String get jsonExportCsv => '表をCSVでダウンロード';

  @override
  String get jsonTableNoMatch => '一致する行がありません';

  @override
  String get jsonPrevMatch => '前の一致';

  @override
  String get jsonNextMatch => '次の一致';

  @override
  String get jsonExpandAll => 'すべて展開';

  @override
  String get jsonCollapseAll => 'すべて折りたたむ';

  @override
  String get jsonCopyKey => 'キーをコピー';

  @override
  String get jsonCopyValue => '値をコピー';

  @override
  String get jsonCopyPath => 'パスをコピー';

  @override
  String get jsonKeyCopied => 'キーをコピーしました';

  @override
  String get jsonValueCopied => '値をコピーしました';

  @override
  String get jsonPathCopied => 'パスをコピーしました';

  @override
  String jsonShowMore(int count, int remaining) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return 'さらに $countString 件表示（残り $remainingString 件）';
  }

  @override
  String jsonLongValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 文字、全文はコピーで取得';
  }

  @override
  String jsonPrettyCut(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalString 行のうち先頭 $shownString 行を表示中。全文はコピーまたは保存で取得できます。';
  }

  @override
  String jsonTableTruncated(Object count) {
    return '先頭 $count 行のみ表示しています。';
  }

  @override
  String get networkErrors => 'エラー';

  @override
  String get networkSearchBodies => 'リクエスト/レスポンスのボディも検索';

  @override
  String get networkExportHar => '表示中のリクエストを HAR で書き出す';

  @override
  String get networkNothingToExport => '書き出すリクエストがありません';

  @override
  String get fileSaved => 'ファイルを保存しました';

  @override
  String get consoleGroupRepeats => '繰り返しログをまとめる';

  @override
  String get consoleOccurrences => '発生履歴';

  @override
  String get consoleNoMatchTitle => '一致するログがありません';

  @override
  String get consoleNoMatchSubtitle => 'フィルターを外すと再び表示されます。';

  @override
  String get consoleShowAllLevels => 'すべてのレベルを表示';

  @override
  String get consoleClearSearch => '検索をクリア';

  @override
  String get consoleResetFilters => 'フィルターをリセット';

  @override
  String get consoleExport => 'ログを書き出す';

  @override
  String get consoleExportText => 'テキスト (.txt)';

  @override
  String get consoleExportJson => 'JSON (.json)';

  @override
  String get consoleNothingToExport => '書き出すログがありません';

  @override
  String get errorSymbolicate => 'シンボル化';

  @override
  String get errorSymbolicated => 'ソースに対応付け済み';

  @override
  String get errorSymbolicateFailed =>
      'このスタックを解決できません: Metro に接続できず、このビルドのソースマップもアップロードされていません（SDK の uploadSourceMap）。';

  @override
  String get storageTabHistory => '履歴';

  @override
  String get storageTabKeyValue => 'キー・値';

  @override
  String get storageKvNoDevice => '下部バーでデバイスを選ぶとストレージを表示・編集できます。';

  @override
  String get storageKvEmpty =>
      '編集できるストレージがまだありません。SDK でストアをラップしてください（DevConnectAsyncStorage.wrap、DevConnectMMKV.wrap、DevConnectSharedPreferences.wrap など）— 最新の SDK が必要です。';

  @override
  String get storageKvRefresh => '再読み込み';

  @override
  String get storageKvAdd => 'キーを追加';

  @override
  String get storageKvEdit => '値を編集';

  @override
  String get storageKvDelete => 'キーを削除';

  @override
  String get storageKvClear => 'すべて消去';

  @override
  String storageKvClearConfirm(Object storage) {
    return '$storage のキーをすべて削除しますか？元に戻せません。';
  }

  @override
  String get storageKvKey => 'キー';

  @override
  String get storageKvValue => '値';

  @override
  String get storageKvSave => '保存';

  @override
  String get storageKvFilter => 'キーを絞り込む';

  @override
  String get deepLinkTitle => 'ディープリンクを開く';

  @override
  String get deepLinkHint => 'アプリ内のリンクをタップしたときと同じように開きます。';

  @override
  String get deepLinkOpen => '開く';

  @override
  String get deepLinkSent => 'ディープリンクを送信しました';

  @override
  String get devMenu => '開発メニューを開く';

  @override
  String get networkReplay => 'リクエストを再送';

  @override
  String get networkReplaySent => 'リクエストを再送しました — 新しい行として表示されます';

  @override
  String get networkConditions => 'ネットワーク条件';

  @override
  String get networkPresetNormal => '通常';

  @override
  String get networkPresetSlow => '低速 (+500 ms)';

  @override
  String get networkPresetSlow3g => '低速 3G (~2 秒)';

  @override
  String get networkPresetOffline => 'オフライン';

  @override
  String get networkTabHttpHint =>
      'アプリが fetch・XHR・axios・Dio・OkHttp などで送ったHTTPリクエスト';

  @override
  String get networkTabProtocolsHint =>
      '通常のHTTP以外の通信：GraphQL操作、WebSocketメッセージ、gRPC呼び出し';

  @override
  String get networkTabMockAuditHint => '実際のネットワークの代わりにモックサーバーのルールで応答したリクエスト';

  @override
  String get protocolGraphqlHint => 'SDKのGraphQLリンク/インターセプター経由のクエリとミューテーション';

  @override
  String get protocolWebsocketHint => 'WebSocket接続と送受信した各フレーム';

  @override
  String get protocolGrpcHint => 'gRPC呼び出し（Android SDKのインターセプター）';

  @override
  String get layoutTitle => 'レイアウト';

  @override
  String get layoutCapture => 'キャプチャ';

  @override
  String get layoutHint =>
      'アプリの現在の画面をキャプチャして要素ツリーを表示します。スクリーンショット上にカーソルを合わせると要素がハイライトされ、クリックするとプロパティが表示されます。';

  @override
  String get layoutNoDevice => 'レイアウトを調べるには、アプリを接続するかデバイスを選択してください。';

  @override
  String get layoutNoScreenshot =>
      'このアプリからスクリーンショットがないため、要素の枠線のみ表示しています。React Native: DevConnect.registerScreenshot で追加できます。';

  @override
  String get layoutPickElement =>
      'スクリーンショット上の要素にカーソルを合わせるかクリックするか、ツリーから選択してください。';

  @override
  String get layoutTree => '要素ツリー';

  @override
  String get layoutProperties => 'プロパティ';

  @override
  String get layoutTreeError => '要素ツリーを読み取れませんでした';

  @override
  String get layoutSearchHint => '名前や値で検索';

  @override
  String get layoutAppOnly => 'アプリの要素のみ';

  @override
  String get layoutFit => '全体表示';

  @override
  String get layoutActualSize => '実寸';

  @override
  String get layoutZoomIn => '拡大';

  @override
  String get layoutZoomOut => '縮小';

  @override
  String get layoutZoomLevel => 'ズーム倍率';

  @override
  String get layoutZoomToSelection => '選択した要素にズーム';

  @override
  String get layoutClose => 'キャプチャを閉じる';

  @override
  String get layoutCopyName => '名前をコピー';

  @override
  String get layoutCopyJson => 'JSONでコピー';

  @override
  String get layoutExport => 'エクスポート';

  @override
  String get layoutSavePng => 'スクリーンショットを保存 (PNG)';

  @override
  String get layoutSaveJson => 'スナップショットを保存 (JSON)';

  @override
  String get layoutNoAnswer =>
      'アプリが応答しませんでした。レイアウトにはレイアウト対応の DevConnect SDK とデバッグビルドが必要です。';

  @override
  String get layoutTruncated => 'ツリーが大きいため、最初の部分のみ取得しました。';

  @override
  String get layoutState => 'ステート';

  @override
  String get layoutMeasureHint => '⌥ + ホバー: 距離を測る';

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
    return '$kb ($bytes バイト)';
  }

  @override
  String get binaryBodyHint => 'アクションは X-Amz-Target ヘッダーで識別してください。';

  @override
  String get openWithDefaultApp => '既定のアプリで開く';

  @override
  String get tipsAndShortcuts => 'ヒント＆ショートカット';

  @override
  String get tipsAndShortcutsDesc => '最も便利なワークフローのクイックガイド。カードをクリックして詳細を表示。';

  @override
  String get tipAllEventsTitle => 'すべてのイベントフィード';

  @override
  String get tipAllEventsBody =>
      'アプリのログ、ネットワークリクエスト、state の変更、ストレージ操作、エラーを 1 つのライブタイムラインにまとめて表示します。display と async 処理のイベントも含まれます。';

  @override
  String get tipAllEventsSteps =>
      '\"イベントを検索...\"に入力して、メッセージ、URL パス、アクション、ストレージのキー、タグで絞り込み\n\"LOG\"、\"API\"、\"STATE\"、\"STORE\"のチップで種類を切り替え。\"ERRORS\"はエラーと失敗したリクエストのみ表示\n行をクリックして詳細を表示。\"全体\"または\"Tab\"で詳細を画像として保存\n下部のバーでデバイス、または\"すべて\"を選び、表示するイベントの対象を決める\n\"古い順\"/\"新しい順\"で並び順を切り替え、\"自動スクロール\"で新しいイベントに追従';

  @override
  String get tipAllEventsTip =>
      'ここでの\"すべてクリア\"は、このフィードだけでなく、Console、Network、State、Storage、Errors など、すべてのページの一覧を空にします。';

  @override
  String get tipNetworkTitle => 'ネットワーク通信を検査';

  @override
  String get tipNetworkBody =>
      'アプリが送信する HTTP リクエストを、ヘッダー、本文、ステータス、所要時間とともに表示します。GraphQL、WebSocket、gRPC の通信や、モックルールが応答したリクエストも含まれます。gRPC は Android SDK からのみ届きます。';

  @override
  String get tipNetworkSteps =>
      'リクエストをクリックして、\"Headers\"、\"Request\"、\"Response\"、\"Timing\"のタブを表示\nメソッドや\"2xx\"/\"3xx\"/\"エラー\"で絞り込むか、\"URLをフィルター...\"に URL の一部を入力\n\"リクエスト/レスポンスのボディも検索\"をオンにすると、ペイロードの中も検索\nパネルの\"cURLをコピー\"で curl コマンドを取得。行を右クリックして\"リクエストを再送\"も選べる\n\"Protocols\"で GraphQL、WebSocket、gRPC を、\"Mock Audit\"でモックされたリクエストを表示';

  @override
  String get tipNetworkTip =>
      'generate_204 や captive.apple.com などの接続確認リクエストは、検索が一致するまで非表示のままです。';

  @override
  String get tipConsoleTitle => 'Console のログ';

  @override
  String get tipConsoleBody =>
      'アプリのログ行を、レベル、タグ、時刻とともに届いた順に表示します。React Native の console 呼び出し、Flutter の print と debugPrint、Android の println が対象です。';

  @override
  String get tipConsoleSteps =>
      '\"DEBUG\"、\"INFO\"、\"WARN\"、\"ERROR\"を切り替えて、レベルごとに表示/非表示\n\"ログを検索...\"に入力して、メッセージ本文やタグで絞り込み\n行をクリックして、タグ、メッセージ、メタデータ、スタックトレース（ある場合）を表示\n\"繰り返しログをまとめる\"をオンにすると、同じ内容が連続する行を件数付きの 1 行にまとめる\n\"ログを書き出す\"で、絞り込んだ一覧を\"テキスト (.txt)\"または\"JSON (.json)\"として保存';

  @override
  String get tipConsoleTip =>
      '通常の console.log、print、println の行は DEBUG として届きます。\"DEBUG\"をオフにすると、info、警告、エラーだけが残ります。';

  @override
  String get tipStateTitle => 'State インスペクター';

  @override
  String get tipStateBody =>
      'アプリが報告するすべての state 変更を、アクションと変更前後の state とともに表示します。React Native は Redux、Zustand、MobX など、Flutter は BLoC、Riverpod、Provider、Android は ViewModel が対象です。';

  @override
  String get tipStateSteps =>
      '\"Redux\"タブを開く（Redux だけでなく、すべての state ライブラリの変更が表示される）\n\"アクションをフィルター...\"に入力して、アクション名や store 名で絞り込み\n変更をクリックして、\"差分\"、\"変更前\"、\"変更後\"を切り替え\n\"アプリの状態をこの時点に復元\"（DevConnect.onStateRestore が必要）または\"スナップショットとして保存\"を使う\n\"コントロール\"を開いて、state パスの固定、スナップショットの取得、Redux アクションの dispatch を行う';

  @override
  String get tipStateTip =>
      '\"差分\"は SDK が差分を送ったときだけ表示されます。Redux、Zustand、MobX は送りますが、Flutter と Android は送らないため、\"変更前\"と\"変更後\"を見比べてください。';

  @override
  String get tipStorageTitle => 'アプリのストレージ';

  @override
  String get tipStorageBody =>
      'SDK でラップしたストア（AsyncStorage、MMKV、SharedPreferences、Hive など）への読み取り、書き込み、削除をすべて表示します。対応ストアの現在のキーも表示され、ここで編集できます。';

  @override
  String get tipStorageSteps =>
      '\"履歴\"で\"読み取り\"、\"書き込み\"、\"削除\"を選び、\"AS\"や\"SP\"などのストアのチップを切り替え\n\"キーをフィルター...\"にキーを入力すると、そのキーに対するすべての操作を表示（値も検索対象）\n行をクリックして、その操作の値、サイズ、ストア、時刻を表示\n\"Key-Value\"を開いてストアの現在のキーを表示し、\"キーを追加\"、\"値を編集\"、\"キーを削除\"を使う\n\"再読み込み\"を押して、アプリから最新の内容を取得';

  @override
  String get tipStorageTip =>
      '\"履歴\"の\"すべてクリア\"はこのログを空にするだけですが、\"Key-Value\"の\"すべてクリア\"はアプリのストアからすべてのキーを削除します。';

  @override
  String get tipDatabaseTitle => 'SQLite データベース';

  @override
  String get tipDatabaseBody =>
      'アプリが DevConnect.registerDatabase で登録した SQLite データベースを閲覧・照会できます。行数付きのテーブル一覧、SQL 入力欄、結果グリッドがあります。';

  @override
  String get tipDatabaseSteps =>
      'アプリで DevConnect.registerDatabase を使ってデータベースを登録\nテーブルをクリックして、先頭 50 行をプレビュー\nSQL を編集して\"実行\"を押すと、独自のクエリを実行\nもう一度\"実行\"を押すと再照会（結果は自動では更新されない）\n\"テーブルを再読み込み\"を押して、テーブル一覧と行数を更新';

  @override
  String get tipDatabaseTip =>
      '並べ替えるにはクエリに ORDER BY を追加してください。列ヘッダーをクリックしても並べ替えはできません。';

  @override
  String get tipPerformanceTitle => 'パフォーマンスプロファイラー';

  @override
  String get tipPerformanceBody =>
      'アプリの FPS、CPU、メモリ、ネットワーク通信のライブチャートを表示します。SDK が報告する場合は、フレーム時間、スレッド、バッテリー、熱状態、ディスク I/O、起動時間、ANR も表示されます。';

  @override
  String get tipPerformanceSteps =>
      '下部のバーでデバイスを 1 つ選ぶ。\"すべて\"を選ぶと、チャートにはすべてのアプリのサンプルが混ざる\nツールバーにある\"FPS\"、\"MEM\"、\"CPU\"、\"SLOW\"のライブ値を確認\nチャートにカーソルを合わせると、正確な値と、受信からの経過時間を確認できる\n\"システム状態\"で、起動時間、バッテリー消費、熱状態、ディスク I/O、ANR を確認\n\"画像としてキャプチャ\"でチャートを PNG として保存し、\"クリア\"でやり直し';

  @override
  String get tipPerformanceTip =>
      'FPS 行の赤いバッジにカーソルを合わせると、低速フレームの平均時間と最悪時間、直近 5 件の低速フレームを確認できます。';

  @override
  String get tipLeaksTitle => 'メモリリーク検出';

  @override
  String get tipLeaksBody =>
      'アプリからのリーク警告を表示します。3 つの SDK すべてが自動検出するメモリの継続的な増加、React Native で 50 個を超えるアクティブなタイマー、DevConnect.reportMemoryLeak で送信した内容が対象です。';

  @override
  String get tipLeaksSteps =>
      'ツールバーの赤、黄、青の件数を確認：重大、警告、情報\n行をクリックして、\"詳細\"、\"保持サイズ\"、\"スタックトレース\"、\"メタデータ\"（報告されている場合）を表示\nメモリ増加の行の\"メタデータ\"で、各サンプルと増加量の合計（MB）を確認\nDevConnect.reportMemoryLeak で、解放されていない controller や stream など、自分で見つけたリークを報告\n\"クリア\"を押して、疑わしい操作を繰り返し、新しい警告が出ないか確認';

  @override
  String get tipLeaksTip =>
      '既定ではメモリを 10 秒ごとにサンプリングします。警告は継続的に 20 MB を超えて増加した場合に出て、40 MB を超えると重大になります。';

  @override
  String get tipBenchmarkTitle => 'ベンチマーク';

  @override
  String get tipBenchmarkBody =>
      'SDK の benchmark 呼び出しで囲んだコードの所要時間を計測します。各 SDK が自動で記録する App Startup と App Background の実行も表示されます。';

  @override
  String get tipBenchmarkSteps =>
      'DevConnect.benchmarkStart と benchmarkStop でコードを囲む（React Native は benchmark で開始）\nbenchmarkStep でフェーズに印を付ける（Flutter、React Native）。Android の実行にはステップがない\n実行をクリックして、\"開始\"、\"終了\"、\"期間\"と、ステップのウォーターフォールを表示\n\"ベンチマークを検索...\"に入力して、一覧と統計バーを絞り込み\n\"画像としてキャプチャ\"を押して、実行のパネルを PNG として保存';

  @override
  String get tipBenchmarkTip =>
      '統計バーは一覧にあるすべての実行が対象です。1 つのタイトルで検索すると、そのベンチマークだけの\"最小\"、\"平均\"、\"P50\"が表示されます。';

  @override
  String get tipErrorsTitle => 'エラー';

  @override
  String get tipErrorsBody =>
      'アプリが報告するエラーを一覧表示します。React Native の JavaScript エラーと console.error 呼び出し、Flutter のフレームワークエラーと Dart エラー、Android の例外が対象です。';

  @override
  String get tipErrorsSteps =>
      'Flutter：DevConnect.initAndRunApp でアプリを起動（通常の init ではエラーフックは入らない）\n\"JS\"、\"Native\"、\"Android\"、\"iOS\"のチップをクリックして、プラットフォームの表示/非表示を切り替え\n\"エラーを検索...\"に入力して、メッセージ、ソース、スタックトレースで絞り込み\nエラーをクリックして、\"Message\"、\"Stack Trace\"、\"Details\"のタブを開く\nReact Native のスタックでは\"シンボル化\"を押すと、Metro 経由でフレームをソースに対応付け';

  @override
  String get tipErrorsTip =>
      'Flutter のエラーには、実行されたデバイスの Android または iOS のタグが付きます。Flutter 専用のチップはありません。';

  @override
  String get tipMockTitle => 'Mock Server';

  @override
  String get tipMockBody =>
      '偽の API レスポンス（メソッド、URL の正規表現、ステータス、ヘッダー、ボディ、任意の遅延）を保持し、選択したデバイスにインストールします。一致するリクエストはネットワークに出ません。';

  @override
  String get tipMockSteps =>
      'Android：まず OkHttpClient に DevConnect.mockServerInterceptor() を追加\nデバイスを 1 つ選び、\"Add rule\"を押して項目を入力し、\"Save changes\"を押す\n\"Push all\"を押す。以降の編集、スイッチの切り替え、削除は自動でデバイスに反映される\nルールのスイッチを切り替えて一時停止、またはゴミ箱アイコンで削除\n\"Clear device\"を押すと、デバイスからすべてのルールを削除して同期を停止';

  @override
  String get tipMockTip =>
      'ルールは DevConnect のメモリ上にだけあり、終了すると失われます。ただし、同期済みのデバイスは再接続時にルールを取り戻します。';

  @override
  String get tipHistoryTitle => 'セッション履歴';

  @override
  String get tipHistoryBody =>
      'デバイスが切断されて 15 秒戻らないと、そのログ、ネットワーク呼び出し、state 変更、ストレージ操作が、読み取り専用のセッションとしてここに残ります。再接続するか DevConnect を終了するまで保持されます。';

  @override
  String get tipHistorySteps =>
      'セッションをクリックして、\"All\"、\"Logs\"、\"Network\"、\"State\"、\"Storage\"のタブを開く\n各タイルの切断時刻とイベント数を確認\nタイルの × を押すと、そのセッションを削除\n\"Clear All\"を押して一覧を空にする';

  @override
  String get tipHistoryTip =>
      '同じデバイス（または同じ IP のどのアプリ）が再接続すると、セッションはすぐに消えます。アプリを起動し直す前に確認してください。';

  @override
  String get tipDisplayTitle => 'Display';

  @override
  String get tipDisplayBody =>
      'アプリが DevConnect.display() で送信した内容（名前、任意のプレビューテキスト、JSON の値、メタデータ）を表示します。3 つの SDK すべてで使えます。';

  @override
  String get tipDisplaySteps =>
      '名前と、任意の value、preview、metadata を指定して DevConnect.display を呼ぶ\n新しい順に並ぶ行を確認：各行に名前、プレビュー、時刻が表示される\n行をクリックして、\"Preview\"、JSON 形式の\"Value\"、\"Metadata\"を表示\n\"Clear all\"を押して一覧を空にする';

  @override
  String get tipDisplayTip =>
      '呼び出すたびに前の行を置き換えず、新しい行が追加されます。同じ名前を使い回すと、タイムラインを作れます。';

  @override
  String get tipAsyncTitle => '非同期処理';

  @override
  String get tipAsyncBody =>
      'アプリが DevConnect.reportAsyncOperation() で報告した非同期処理（saga の effect、タスク、バックグラウンドジョブなど）を、ステータス、所要時間、結果またはエラーとともに一覧表示します。自動で追跡されるものはありません。';

  @override
  String get tipAsyncSteps =>
      '種類、説明、ステータス（start、resolve、reject）を指定して reportAsyncOperation を呼ぶ\nReact Native では、promise を trackAsync で包むと、開始から完了までを報告できる\nバッジの色を確認：オレンジは開始、緑は resolve、赤は reject\n行をクリックして、詳細、\"Result\"、\"Metadata\"を表示\n\"Clear all\"を押して一覧を空にする';

  @override
  String get tipAsyncTip =>
      '関連する呼び出しには同じ sagaName を付けてください。そのうち 1 つを選ぶと、グループ全体が\"Saga timeline\"に表示されます。';

  @override
  String get tipLayoutTitle => 'Layout インスペクター';

  @override
  String get tipLayoutBody =>
      'アプリの現在の画面を要素ツリーとともにキャプチャし（Flutter の widget、React Native の component、Android の view）、各要素の位置、サイズ、padding、margin、props を表示します。';

  @override
  String get tipLayoutSteps =>
      'デバイスを選んで\"キャプチャ\"を押すと、画面と要素ツリーを取得\nスクリーンショットにカーソルを合わせると要素がハイライトされ、クリックで選択\nまたは\"要素ツリー\"で選ぶか、\"名前や値で検索\"で探す\n\"アプリの要素のみ\"をオンにすると、ライブラリの widget を非表示（Flutter、React Native）\n\"プロパティ\"でボックスモデル、位置、サイズ、props を確認、または\"JSONでコピー\"を押す';

  @override
  String get tipLayoutTip =>
      'React Native は DevConnect.registerScreenshot() を呼んだ後にだけスクリーンショットを送ります。呼ばないと、輪郭だけが表示されます。';

  @override
  String get settingsGroupConnection => '接続';

  @override
  String get settingsGroupConnectionDesc => 'サーバー、ネットワークアドレス、USB。';

  @override
  String get settingsGroupDevices => 'デバイス';

  @override
  String get settingsGroupDevicesDesc => '接続中のアプリと過去に接続したデバイス。';

  @override
  String get settingsGroupAppearance => '外観';

  @override
  String get settingsGroupAppearanceDesc => 'テーマ、言語、表示するタブ。';

  @override
  String get settingsGroupData => '表示とデータ';

  @override
  String get settingsGroupDataDesc => '詳細の表示方法と保持する履歴の量。';

  @override
  String get settingsGroupGuides => 'ガイド';

  @override
  String get settingsGroupGuidesDesc => 'クイックスタート、ショートカット、ヒント。';

  @override
  String get settingsGroupSupport => 'サポート';

  @override
  String get settingsGroupSupportDesc => 'DevConnect の開発を支援する。';

  @override
  String get tipsTabFeatures => '機能';

  @override
  String get tipsTabShortcuts => 'ショートカット';

  @override
  String get tipsTabConnect => 'デバイス接続';

  @override
  String get tipsTabSdk => 'SDK 導入';

  @override
  String get tipsTabAdvanced => '上級';

  @override
  String get tipsSteps => '手順';

  @override
  String get tipsKeys => 'キー';

  @override
  String get tipsProTip => 'ヒント';

  @override
  String get tipsPrevious => '前へ';

  @override
  String get tipsNext => '次へ';

  @override
  String get tipsDone => '完了';

  @override
  String get tipsOpenPage => 'ページを開く';

  @override
  String get tipsCopyCode => 'コピー';

  @override
  String get tipsCodeCopied => 'コードをコピーしました';

  @override
  String get tipsClose => '閉じる';

  @override
  String get pageGuide => 'このページの使い方';

  @override
  String get guideReloadTitle => 'アプリを再読み込み';

  @override
  String get guideReloadSummary =>
      'DevConnect のどのページからでも、入力中でも、調査中のアプリを再読み込みできます。Flutter は widget を再構築し、React Native は Metro から再読み込みし、Android は現在の activity を再作成します。';

  @override
  String get guideReloadSteps =>
      '[⌘ R] 選択中のアプリを再読み込み（未選択なら接続中のすべてのアプリ）\n[⇧ ⌘ R] ホットリスタート：Flutter アプリの onHotRestartRequest を実行し、それ以外は ⌘ R と同様に再読み込み\nまたは下部のバーの再読み込みボタンをクリック（ツールチップにショートカットが表示される）';

  @override
  String get guideReloadTip =>
      'Flutter での ⌘ R は widget ツリーを再構築して state を保持しますが、コードの変更は読み込みません。変更を反映するには IDE のホットリロードを使ってください。';

  @override
  String get guideJsonSearchTitle => '本文内を検索';

  @override
  String get guideJsonSearchSummary =>
      'Tree、JSON、コード表示（TypeScript、Dart、Kotlin）にはそれぞれ専用の検索があり、大文字と小文字を区別せず、一致箇所をすべて強調して、現在の一致位置までスクロールします。';

  @override
  String get guideJsonSearchSteps =>
      '[⌘ F] この表示の検索ボックスへ移動（先に本文の中をクリック）\n[↵] 次の一致へ移動\n[⇧ ↵] 前の一致へ移動\n[Esc] 検索をクリア';

  @override
  String get guideJsonSearchTip =>
      'Tree の検索はノードを展開し、後続のページも読み込んで最大 500 件まで表示します。JSON は最大 100,000 件までカウントします。';

  @override
  String get guideLayoutZoomTitle => 'レイアウトキャプチャを拡大';

  @override
  String get guideLayoutZoomSummary =>
      'Layout ページのキャプチャを、キーボードで拡大・縮小して見やすい位置に合わせられます。キャプチャが表示されていれば、すぐにキーが使えます。';

  @override
  String get guideLayoutZoomSteps =>
      '[⌘ +] 拡大（1 回押すごとに 1.25×）\n[⌘ −] 縮小\n[⌘ 0] 実寸：100% がアプリ自体の画面サイズ\n[⌘ 1] 画面全体をパネルに合わせる\n[⌘ 2] 選択中の要素にズーム';

  @override
  String get guideLayoutZoomTip =>
      'ズームの割合をクリックすると、50、100、200、400% を選べます。ピンチでズーム、ドラッグで移動できます。';

  @override
  String get guideLayoutMeasureTitle => '間隔を測る';

  @override
  String get guideLayoutMeasureSummary =>
      'Option を押し続けると、選択中の要素とポインターの下にある要素との距離が、デザインツールのように表示されます。';

  @override
  String get guideLayoutMeasureSteps =>
      '要素を選択：キャプチャ上でクリックするか、ツリーで選ぶ\n[⌥] Option を押したまま、別の要素にポインターを合わせる\n離れた要素どうしなら間隔、一方がもう一方を含むなら内側の余白（インセット）を確認\nOption を離すと、ホバー中の要素のボックスモデルが再び表示される';

  @override
  String get guideLayoutMeasureTip =>
      '重なっている要素には距離が表示されません。計測できるのは、一方がもう一方の内側にある場合か、間に隙間がある場合です。';

  @override
  String get guideLayoutTreeTitle => '要素ツリーを移動';

  @override
  String get guideLayoutTreeSummary =>
      'キャプチャした要素ツリーにフォーカスがあるときは、矢印キーで移動できます。行、またはキャプチャ上の要素をクリックしてください。';

  @override
  String get guideLayoutTreeSteps =>
      '[↑ ↓] 上または下の行へ移動\n[→] 行を開く。もう一度押すと最初の子に入る\n[←] 行を閉じる。もう一度押すと親に戻る\n[Esc] 選択を解除';

  @override
  String get guideLayoutTreeTip =>
      '\"名前や値で検索\"に入力すると、名前、props、state を検索できます。↵ と ⇧ ↵ で一致箇所を順に移動します。';

  @override
  String get guideAndroidEmulatorTitle => 'Android エミュレーター';

  @override
  String get guideAndroidEmulatorSummary =>
      'Android エミュレーター上のアプリは、10.0.2.2（Genymotion は 10.0.3.2）でこの Mac に接続できるため、設定は不要です。';

  @override
  String get guideAndroidEmulatorSteps =>
      '設定 › \"接続\" › \"サーバー\"に\"サーバー実行中\"と表示されていることを確認\nネイティブ Android：installForApp に enabled = BuildConfig.DEBUG を渡す（既定ではオフ）\nエミュレーターでデバッグビルドを実行（adb reverse は不要）\nウィンドウ下部のデバイスバーでアプリを探す';

  @override
  String get guideAndroidEmulatorTip =>
      'DevConnect は起動のたびにポート 9090 で始まります。\"サーバー\"で変更したポートは DevConnect を終了するまで有効で、SDK のポートも合わせる必要があります。';

  @override
  String get guideAndroidUsbTitle => 'USB 接続の Android 端末';

  @override
  String get guideAndroidUsbSummary =>
      'adb reverse は、端末の localhost をケーブル経由でこの Mac に向けるため、Wi‑Fi なしでアプリが接続できます。';

  @override
  String get guideAndroidUsbSteps =>
      'USB デバッグをオンにして端末を接続し、確認が出たらこの Mac を許可\n設定 › \"接続\" › \"USB接続\"の\"ADB Reverseを実行\"を押すか、下のコマンドを実行\nアプリを起動（すでに起動していたネイティブ Android アプリは再起動）\n接続できない場合は、そこで\"デバイス\"を押して、adb が端末を認識しているか確認';

  @override
  String get guideAndroidUsbTip =>
      'ケーブルを挿し直したとき、adb を再起動したとき、端末や Mac を再起動したときは、もう一度実行してください。複数のデバイスをつないでいる場合は、ターミナルで adb -s に端末のシリアル番号を付けて実行します。';

  @override
  String get guideIosSimulatorTitle => 'iOS シミュレーター';

  @override
  String get guideIosSimulatorSummary =>
      'シミュレーターは Mac とネットワークを共有するため、デバッグビルドは設定なしで localhost 経由で DevConnect に接続できます。';

  @override
  String get guideIosSimulatorSteps =>
      '設定 › \"接続\" › \"サーバー\"に\"サーバー実行中\"と表示されていることを確認\nシミュレーターでアプリのデバッグビルドを実行\nウィンドウ下部のデバイスバーでアプリを探す';

  @override
  String get guideIosSimulatorTip =>
      '起動順は関係ありません。React Native と Flutter のアプリは再試行を続けるため、DevConnect の起動から数秒後に接続されます。';

  @override
  String get guideIphoneTitle => 'iPhone';

  @override
  String get guideIphoneSummary =>
      'Mac と同じ Wi‑Fi にあれば、デバッグビルドは通常、自動で DevConnect を見つけます。見つからない場合は、Mac のアドレスを host に設定してください。';

  @override
  String get guideIphoneSteps =>
      'iPhone と Mac を同じ Wi‑Fi に接続（ゲストネットワークでは遮断されることが多い）\nデバッグビルドを実行し、iOS から確認されたらローカルネットワークへのアクセスを許可\n数秒待つ：React Native は Metro 経由で、Flutter はブロードキャストで Mac を見つける\n一覧に表示されない場合は、設定 › \"接続\" › \"ネットワーク\"から Mac のアドレスをコピー\nSDK の init の host にそのアドレスを設定し（コードは下記）、アプリを再起動';

  @override
  String get guideIphoneTip =>
      'USB ケーブルだけでは iPhone アプリを接続できません。iPhone はネットワーク経由で Mac に届く必要があります。';

  @override
  String get guideTroubleshootTitle => 'アプリが接続しないとき';

  @override
  String get guideTroubleshootSummary =>
      '接続の問題の多くは、いくつかの原因に絞られます。次の順に確認してください。';

  @override
  String get guideTroubleshootSteps =>
      '設定 › \"接続\" › \"サーバー\"に\"サーバー実行中\"と表示され、ポートのエラーがない\nアプリがデバッグビルドである（ネイティブ Android では enabled = BuildConfig.DEBUG も必要）\nSDK のポートがサーバーのポートと一致している（どちらも 9090 から始まる）\n端末が Mac と同じ Wi‑Fi にいるか、Android のポートが adb reverse で転送されている\nWi‑Fi 利用時は、macOS が DevConnect の受信接続を許可している（システム設定 › ネットワーク › ファイアウォール）';

  @override
  String get guideTroubleshootTip =>
      'それでも解決しない場合は、設定 › \"接続\" › \"ネットワーク\"にあるアドレスを host に設定し、auto: false（Flutter は auto_: false）を渡してください。再接続してもその設定が保たれます。';

  @override
  String get guideSdkReactNativeSummary =>
      'パッケージをインストールして起動時に init を一度呼ぶと、それ以降は fetch と XHR（axios も含む）、console ログ、エラー、パフォーマンスが記録されます。';

  @override
  String get guideSdkReactNativeSteps =>
      'yarn または npm で devconnect-manage-kit を追加（コマンドは下記）\n起動時、最初のリクエストより前に DevConnect.init を一度呼ぶ\nstate を扱うには、devConnectReduxMiddleware（Redux）、devConnectMiddleware（Zustand）、setupMobxSpy（MobX）を追加\nデバッグビルドを実行（リリースでは enabled: true を渡さない限り init は何もしない）';

  @override
  String get guideSdkReactNativeTip =>
      'init はアプリの起動ごとに一度だけ実行されます。host や port を変更したら、フルリロードしてください。Fast Refresh では古い設定が残ります。';

  @override
  String get guideSdkFlutterSummary =>
      'initAndRunApp 経由でアプリを起動すると、dart:io の HTTP（http、Dio、Chopper など）、print と debugPrint、エラー、パフォーマンスが、追加のコードなしで記録されます。';

  @override
  String get guideSdkFlutterSteps =>
      'flutter pub add devconnect_manage_kit を実行\nmain() で DevConnect.initAndRunApp を使ってアプリを起動し、async の runApp コールバックを渡す\nRiverpod や BLoC では、observer から DevConnect.reportStateChange または reportBlocChange を呼ぶ\nデバッグビルドを実行（profile と release のビルドではオフのまま）';

  @override
  String get guideSdkFlutterTip =>
      'Firebase などの起動時のコードは runApp コールバックの中に置いてください。initAndRunApp の前に ensureInitialized() を呼ぶと、zone mismatch が起きます。';

  @override
  String get guideSdkAndroidSummary =>
      'Maven Central の依存関係を追加し、Application.onCreate で installForApp を呼ぶと、println の出力、クラッシュ、ANR、パフォーマンス、ViewModel の state が記録されます。HTTP には OkHttp インターセプターが必要です。';

  @override
  String get guideSdkAndroidSteps =>
      'app/build.gradle.kts に io.github.buivietphi:devconnect-android:1.1.0 を追加\nApplication.onCreate で enabled = BuildConfig.DEBUG を指定して DevConnect.installForApp を呼ぶ（既定ではオフ）\nRetrofit のものも含め、すべての OkHttpClient に DevConnect.okHttpInterceptor() を追加\nandroid.util.Log の代わりに DCLog でログを出力。Timber では DevConnectTimberHelper.log を呼ぶ Tree を plant する\nアプリのマニフェストに INTERNET 権限があることを確認';

  @override
  String get guideSdkAndroidTip =>
      'SDK が DevConnect を探すのは起動時の一度だけです。先に DevConnect を起動する（必要なら adb reverse も実行）か、アプリを再起動してください。';

  @override
  String get guideMockApiTitle => 'API をモックする';

  @override
  String get guideMockApiSummary =>
      '一致するリクエストに、独自のステータス、ヘッダー、ボディで応答します。遅延も付けられ、サーバーもアプリも変更する必要はありません。';

  @override
  String get guideMockApiSteps =>
      '下部のバーでデバイスを選び、\"Mock Server\"を開いて\"Add rule\"を押す\n\"Method\"、\"Status\"、\"URL pattern\"（URL のどこかに一致する正規表現）、ボディを設定\n\"Save & push\"または\"Push all\"を押す（どちらもルール一覧全体を送信）\nNetwork › \"Mock Audit\"で、ルールが応答したリクエストを確認\nルールのスイッチで一時停止、または\"Clear device\"ですべてのルールを削除';

  @override
  String get guideMockApiTip =>
      'Android では OkHttp に DevConnect.mockServerInterceptor() が必要です。React Native でモックされるのは fetch 呼び出しだけで、axios や XMLHttpRequest は対象外です。';

  @override
  String get guideNetworkConditionsTitle => '低速・オフラインのネットワーク';

  @override
  String get guideNetworkConditionsSummary =>
      'デバイスの設定を変えずに、アプリの HTTP リクエストを遅延させたり失敗させたりできます。DevConnect 自身の接続は影響を受けません。';

  @override
  String get guideNetworkConditionsSteps =>
      'Network で、ツールバーのゲージアイコンのメニュー\"ネットワーク条件\"を開く\n\"低速 (+500 ms)\"または\"低速 3G (~2 秒)\"を選ぶと、すべてのリクエストが遅延\n\"オフライン\"を選ぶと、回線が切れたときのように、リクエストがすぐ失敗\n終わったら\"通常\"を選ぶ（それまでアイコンは強調表示のまま）\nAndroid では、DevConnect.okHttpInterceptor() を通る OkHttp の通信だけが遅くなる';

  @override
  String get guideNetworkConditionsTip =>
      '接続中のすべてのアプリと、後から接続するアプリにも、\"通常\"を選ぶまで適用されます。';

  @override
  String get guideReplayTitle => 'リクエストを再送';

  @override
  String get guideReplaySummary =>
      '記録したリクエストを、同じメソッド、URL、ヘッダー、ボディで、アプリに再送させます。画面を操作し直す必要はありません。';

  @override
  String get guideReplaySteps =>
      'Network でリクエストを右クリックし、\"リクエストを再送\"を選ぶ\nまたはリクエストを開き、ヘッダーの繰り返しアイコンをクリック\n再送されたリクエストは一覧に新しい行として表示される';

  @override
  String get guideReplayTip =>
      'Android は最近の OkHttp 呼び出しを、アプリ自身のクライアントとインターセプターを通して再実行します。Flutter と React Native は、記録したヘッダーをそのまま再送します。';

  @override
  String get guideHarExportTitle => 'HAR に書き出す';

  @override
  String get guideHarExportSummary =>
      'Network に一覧表示されているリクエストを、標準の HAR 1.2 ファイルとして保存できます。ヘッダー、ボディ、ステータス、タイミングも含まれ、他のツールで開けます。';

  @override
  String get guideHarExportSteps =>
      'デバイス、メソッド、ステータス、URL のフィルターで\"HTTP\"の一覧を絞り込む\nツールバーのダウンロードアイコン\"表示中のリクエストを HAR で書き出す\"をクリック\n.har ファイルの保存先を選ぶ\nChrome DevTools や Charles で開く、またはチームと共有';

  @override
  String get guideHarExportTip =>
      '保存されるのは HTTP の一覧に表示されているものだけなので、フィルターがファイルの内容を決めます。\"Protocols\"のエントリは含まれません。';

  @override
  String get guideDatabaseQueryTitle => 'アプリのデータベースを照会';

  @override
  String get guideDatabaseQuerySummary =>
      'アプリ内の SQLite データベースのテーブルを閲覧し、DevConnect からそのまま SQL を実行できます。';

  @override
  String get guideDatabaseQuerySteps =>
      'アプリで DevConnect.registerDatabase を使ってデータベースを登録（スニペットは下記）\nDatabase を開き、テーブルをクリックして先頭 50 行をプレビュー\nSQL を編集して\"実行\"を押す（結果は 1,000 行まで）\nアプリがテーブルを変更したら\"テーブルを再読み込み\"をクリック';

  @override
  String get guideDatabaseQueryTip =>
      'クエリは、最後にクリックしたテーブルのデータベースに対して実行されます。まだクリックしていなければ、最初に登録されたデータベースが対象です。';

  @override
  String get guideBigJsonTitle => '大きな本文';

  @override
  String get guideBigJsonSummary =>
      '大きな本文でも DevConnect が固まることなく開けます。バックグラウンドで解析され、Tree と JSON は画面に表示されている部分だけを構築します。';

  @override
  String get guideBigJsonSteps =>
      '長い Tree リストの下にある\"さらに … 件表示\"をクリックすると、次の 200 件を読み込む\nTree の長い文字列では\"値をコピー\"を使う（Tree には先頭 2,000 文字しか表示されない）\nJSON に切り替えると、文書全体をスクロール・検索できる\nそこで\"Copy JSON\"または\"Save as file\"を使う（どちらも本文全体が対象）\n20,000 文字を超える JSON の行は先頭だけ表示される。全体はコピーまたは保存で取得';

  @override
  String get guideBigJsonTip =>
      '本文がオブジェクトのリストの場合、Tree に\"テーブル\"が表示されます。表示は 500 行までですが、\"表をCSVでダウンロード\"は一致するすべての行を保存します。';

  @override
  String get guideCustomCommandsTitle => 'カスタムコマンド';

  @override
  String get guideCustomCommandsSummary =>
      'DevConnect からアプリ内のコードを実行できます。キャッシュの削除、ログアウト、テストデータの作成などを行い、戻り値を確認します。';

  @override
  String get guideCustomCommandsSteps =>
      'アプリで DevConnect.registerCommand を使ってハンドラーを登録（スニペットは下記）\n\"カスタムコマンド\"を開き、アプリが一覧に出したコマンドをクリックするか、名前を入力\nコマンドが必要とする場合は、引数を JSON オブジェクトで追加\n\"実行\"を押すか、\"コマンド\"欄で ↵ を押して、下に表示される結果を確認';

  @override
  String get guideCustomCommandsTip =>
      'Flutter と React Native のハンドラーは async にできます。スローされたエラーは結果として表示され、応答がない場合は 10 秒でタイムアウトします。';

  @override
  String get restart => '再起動';

  @override
  String get serverAddressHint => 'アプリはこのアドレスに接続します。';

  @override
  String get serverStoppedHint => 'アプリが接続できるようにサーバーを起動してください。';

  @override
  String get tabBenchmark => 'ベンチマーク';

  @override
  String get tabDisplay => '表示';

  @override
  String get tabAsync => '非同期処理';

  @override
  String get tabLayout => 'レイアウト検査';

  @override
  String get tabCommands => 'カスタムコマンド';

  @override
  String get tabMockServer => 'モックサーバー';

  @override
  String get tabsAlwaysShown => 'すべてのイベントと設定は常に表示されます。';

  @override
  String get quickStartDesc => 'SDK を入れてアプリで起動し、接続します。';

  @override
  String get quickStartNext => '次に — アプリで起動';

  @override
  String get quickStartEmulator => 'エミュレーターは自動接続';

  @override
  String get quickStartWifi => 'Wi‑Fi の実機';

  @override
  String get quickStartUsb => 'USB の Android';
}
