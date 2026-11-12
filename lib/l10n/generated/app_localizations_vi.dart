// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SVi extends S {
  SVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'DevConnect Công Cụ Quản Lý';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Hủy';

  @override
  String get close => 'Đóng';

  @override
  String get clear => 'Xóa';

  @override
  String get copy => 'Sao chép';

  @override
  String get copied => 'Đã sao chép';

  @override
  String get start => 'Bắt đầu';

  @override
  String get stop => 'Dừng';

  @override
  String get on => 'Bật';

  @override
  String get off => 'Tắt';

  @override
  String get autoScroll => 'Tự động cuộn';

  @override
  String get newestFirst => 'Mới nhất trước';

  @override
  String get oldestFirst => 'Cũ nhất trước';

  @override
  String get clearAll => 'Xóa tất cả';

  @override
  String get maintenance => 'Bảo trì';

  @override
  String get clearAllCache => 'Xóa Toàn Bộ Cache';

  @override
  String get clearAllCacheDesc =>
      'Ngắt kết nối tất cả thiết bị và xóa mọi dữ liệu trong bộ nhớ (logs, network captures, state, performance, v.v.). Cài đặt của bạn (theme, ngôn ngữ, port) được giữ nguyên.';

  @override
  String get clearAllCacheConfirm =>
      'Xóa toàn bộ cache?\n\nThao tác này sẽ ngắt kết nối mọi thiết bị đang kết nối và xóa toàn bộ log, network capture, state change, performance metric và benchmark trong bộ nhớ.\n\nCài đặt của bạn (theme, ngôn ngữ, port) sẽ được giữ lại.';

  @override
  String get cacheCleared => 'Đã xóa toàn bộ cache. Cài đặt được giữ nguyên.';

  @override
  String clearAllCacheFailed(Object error) {
    return 'Lỗi khi xóa cache: $error';
  }

  @override
  String get deviceHistory => 'Thiết bị đã cache';

  @override
  String get deviceHistoryDesc =>
      'Mọi thiết bị đã từng kết nối tới desktop. Lưu xuyên suốt các lần restart để bạn thấy được thiết bị nào đã kết nối trước đây.';

  @override
  String get noDeviceHistory => 'Chưa có thiết bị nào kết nối';

  @override
  String get deviceHistoryEmptyHint =>
      'Kết nối thiết bị qua SDK và thiết bị sẽ xuất hiện ở đây. Lưu xuyên suốt các lần restart.';

  @override
  String get restarting => 'Đang khởi động lại…';

  @override
  String get online => 'trực tuyến';

  @override
  String get offline => 'ngoại tuyến';

  @override
  String get markOnline => 'Đánh dấu trực tuyến';

  @override
  String get markOffline => 'Đánh dấu ngoại tuyến';

  @override
  String get deviceOnline => 'Đang online';

  @override
  String get deviceOffline => 'Offline';

  @override
  String lastSeen(Object time) {
    return 'Lần cuối thấy $time';
  }

  @override
  String firstSeen(Object time) {
    return 'Lần đầu $time';
  }

  @override
  String get forgetDevice => 'Quên';

  @override
  String get forgetAllOffline => 'Quên tất cả offline';

  @override
  String get forgetAllDevices => 'Quên tất cả';

  @override
  String get forgetDeviceConfirm =>
      'Quên thiết bị này?\n\nSẽ bị xóa khỏi lịch sử. Lần kết nối tiếp theo nó sẽ xuất hiện lại như một entry mới.';

  @override
  String get forgetAllOfflineConfirm =>
      'Quên tất cả thiết bị đang offline?\n\nXóa mọi entry không đang kết nối. Các thiết bị online được giữ lại.';

  @override
  String get forgetAllDevicesConfirm =>
      'Quên tất cả thiết bị đã cache?\n\nXóa toàn bộ lịch sử, kể cả thiết bị đang online. Chúng sẽ xuất hiện lại khi (re)connect.';

  @override
  String get deviceForgotten => 'Đã quên thiết bị';

  @override
  String devicesForgotten(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã quên $count thiết bị',
      one: 'Đã quên 1 thiết bị',
      zero: 'Không quên thiết bị nào',
    );
    return '$_temp0';
  }

  @override
  String connectionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lần kết nối',
      one: '1 lần kết nối',
      zero: 'chưa từng kết nối',
    );
    return '$_temp0';
  }

  @override
  String get restartServer => 'Khởi động lại server';

  @override
  String portOccupied(Object port) {
    return 'Cổng $port đang bị chiếm';
  }

  @override
  String get serverRestarted => 'Đã khởi động lại server';

  @override
  String get restartFailed => 'Khởi động lại thất bại';

  @override
  String portStillInUse(Object port) {
    return 'Cổng $port vẫn đang bị tiến trình khác chiếm';
  }

  @override
  String couldNotRestart(Object port) {
    return 'Không thể khởi động lại trên cổng $port';
  }

  @override
  String listeningOnPort(Object port) {
    return 'Đang lắng nghe trên cổng $port';
  }

  @override
  String waitingForReconnect(Object port) {
    return 'Cổng $port · đang chờ thiết bị kết nối lại';
  }

  @override
  String reconnectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thiết bị kết nối lại',
      one: '1 thiết bị kết nối lại',
      zero: '0 kết nối lại',
    );
    return '$_temp0';
  }

  @override
  String get reloadApp => 'Tải lại ứng dụng';

  @override
  String get reloadAppHotReload => 'Tải lại nhanh';

  @override
  String get reloadAppHotRestart => 'Khởi động lại nhanh';

  @override
  String get reloadAppMetro => 'Tải lại Metro';

  @override
  String get reloadAppNoDevices => 'Chưa có thiết bị kết nối';

  @override
  String get reloadSent => 'Đã gửi lệnh tải lại';

  @override
  String sentReloadTo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã gửi lệnh tới $count thiết bị',
      one: 'Đã gửi lệnh tới 1 thiết bị',
      zero: 'Không có thiết bị nào',
    );
    return '$_temp0';
  }

  @override
  String get screenshotSaved => 'Đã lưu ảnh chụp';

  @override
  String get screenshotFailed => 'Chụp ảnh thất bại';

  @override
  String get reveal => 'Mở';

  @override
  String get captureFull => 'Toàn bộ';

  @override
  String get captureTab => 'Tab';

  @override
  String get captureFullTooltip => 'Chụp toàn bộ chi tiết dưới dạng ảnh';

  @override
  String get captureTabTooltip => 'Chỉ chụp tab hiện tại';

  @override
  String get captureAsImage => 'Chụp dưới dạng ảnh';

  @override
  String get captureDetailAsImage => 'Chụp chi tiết dưới dạng ảnh';

  @override
  String get noData => 'Không có dữ liệu';

  @override
  String get noItems => 'Không có mục nào';

  @override
  String get searchHint => 'Tìm kiếm...';

  @override
  String get filterHint => 'Lọc...';

  @override
  String get value => 'Giá trị';

  @override
  String get key => 'Khóa';

  @override
  String get metadata => 'Siêu dữ liệu';

  @override
  String get duration => 'Thời lượng';

  @override
  String get error => 'Lỗi';

  @override
  String get json => 'JSON';

  @override
  String get tree => 'Tree';

  @override
  String get code => 'Code';

  @override
  String get raw => 'Thô';

  @override
  String get format => 'Định dạng';

  @override
  String get pretty => 'Đẹp';

  @override
  String get collapse => 'Thu gọn';

  @override
  String get showMore => 'Xem thêm';

  @override
  String get noHeaders => 'Không có tiêu đề';

  @override
  String get inProgress => 'đang xử lý';

  @override
  String get inProgressDots => 'Đang xử lý...';

  @override
  String hideShowTooltip(Object action, Object label) {
    return '$action $label';
  }

  @override
  String get hide => 'Ẩn';

  @override
  String get show => 'Hiện';

  @override
  String get steps => 'bước';

  @override
  String get portInUse =>
      'Cổng đang được sử dụng. Đóng ứng dụng khác đang dùng cổng này, hoặc chọn cổng khác trong Cài đặt.';

  @override
  String portInUseShort(Object port) {
    return 'Cổng $port đang được sử dụng. Đóng ứng dụng khác đang dùng cổng này, hoặc nhập cổng khác ở trên và nhấn Bắt đầu.';
  }

  @override
  String failedToStartServer(Object msg) {
    return 'Không thể khởi động máy chủ: $msg';
  }

  @override
  String failedToStartServerOnPort(Object msg, Object port) {
    return 'Không thể khởi động máy chủ trên cổng $port: $msg';
  }

  @override
  String get settings => 'Cài đặt';

  @override
  String get server => 'Máy chủ';

  @override
  String get serverRunning => 'Máy chủ đang chạy';

  @override
  String get serverStopped => 'Máy chủ đã dừng';

  @override
  String get port => 'Cổng';

  @override
  String deviceCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thiết bị',
      one: '1 thiết bị',
      zero: '0 thiết bị',
    );
    return '$_temp0';
  }

  @override
  String get network => 'Mạng';

  @override
  String get hostname => 'Tên máy chủ';

  @override
  String get noNetworkInterfaces => 'Không tìm thấy giao diện mạng';

  @override
  String copiedIp(Object ip) {
    return 'Đã sao chép $ip';
  }

  @override
  String connectedDevices(Object count) {
    return 'Thiết bị đã kết nối ($count)';
  }

  @override
  String get noDevicesConnected => 'Không có thiết bị nào kết nối';

  @override
  String get appearance => 'Giao diện';

  @override
  String get theme => 'Chủ đề';

  @override
  String get dark => 'Tối';

  @override
  String get light => 'Sáng';

  @override
  String get bottom => 'Dưới';

  @override
  String get top => 'Trên';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get tabVisibility => 'Hiển thị tab';

  @override
  String get tabVisibilityDesc =>
      'Bật/tắt tab hiển thị. Tab bị tắt sẽ hiển thị biểu tượng khóa và dữ liệu bị loại trừ khỏi Tất cả sự kiện.';

  @override
  String get detailView => 'Chi tiết';

  @override
  String get detailViewDesc =>
      'Ghi nhớ cách hiển thị nội dung yêu cầu/phản hồi và điều khiển hoạt ảnh chuyển tab.';

  @override
  String get dataRetention => 'Giữ dữ liệu';

  @override
  String get dataRetentionDesc =>
      'Giới hạn cứng áp dụng cho từng danh sách theo tính năng. Khi danh sách vượt giới hạn, các mục cũ nhất sẽ bị xóa theo FIFO. Tác vụ bất đồng bộ đang chờ được giữ lại.';

  @override
  String get maxItems => 'Số mục tối đa';

  @override
  String get dataRetentionHelper =>
      'Không giới hạn giữ mọi mục. Giá trị thấp hơn giải phóng bộ nhớ nhưng mất lịch sử.';

  @override
  String get allEventsDisplay => 'Hiển thị Tất cả sự kiện';

  @override
  String get allEventsDisplayDesc =>
      'Bộ lọc chỉ hiển thị cho danh sách Tất cả sự kiện tổng hợp. Log gốc không bị xóa — chuyển về Không giới hạn để khôi phục.';

  @override
  String get allEventsDisplayHelper =>
      'Giá trị thấp hơn chỉ giữ N mục mới nhất, đánh đổi bằng lịch sử cũ hơn.';

  @override
  String get bodyView => 'Hiển thị nội dung';

  @override
  String get tabAnimation => 'Hoạt ảnh tab';

  @override
  String get tabAnimationDuration => 'Thời lượng';

  @override
  String get codeModeDesc =>
      'Chế độ mã xuất dưới dạng TypeScript / Dart / Kotlin dựa trên SDK đã kết nối.';

  @override
  String get treeModeDesc =>
      'Chế độ cây hiển thị dữ liệu dưới dạng cây nút có thể mở rộng/thu gọn. Phù hợp để duyệt các giá trị lồng nhau sâu.';

  @override
  String get jsonModeDesc =>
      'Chế độ JSON hiển thị dữ liệu dưới dạng tài liệu JSON tô màu cú pháp, dễ sao chép.';

  @override
  String get captureDataJson =>
      'Chụp ảnh dữ liệu (key + value theo chế độ hiện tại)';

  @override
  String get captureDataText => 'Chụp ảnh dữ liệu (key + value dạng text)';

  @override
  String get copyKey => 'Sao chép key';

  @override
  String get usbConnection => 'Kết nối USB';

  @override
  String get android => 'Android';

  @override
  String get ios => 'iOS';

  @override
  String get runAdbReverse => 'Chạy ADB Reverse';

  @override
  String adbNotFound(Object home) {
    return 'Không tìm thấy adb.\nHOME=$home';
  }

  @override
  String adbReverseOk(Object path) {
    return 'adb reverse OK ($path)';
  }

  @override
  String adbError(Object error) {
    return 'Lỗi adb: $error';
  }

  @override
  String adbException(Object error) {
    return 'Ngoại lệ adb: $error';
  }

  @override
  String get devices => 'Thiết bị';

  @override
  String get adbDevices => 'Thiết bị ADB';

  @override
  String get wifiAutoConnect =>
      'iPhone kết nối qua Wi‑Fi: cho iPhone vào cùng mạng với Mac này. Chỉ cắm cáp USB thì không kết nối được.';

  @override
  String get quickStart => 'Bắt đầu nhanh';

  @override
  String get installSdk => 'Cài đặt SDK';

  @override
  String get initialize => 'Khởi tạo';

  @override
  String get connect => 'Kết nối';

  @override
  String get supportDevConnect => 'Hỗ trợ DevConnect';

  @override
  String get supportDevConnectDesc =>
      'DevConnect Công Cụ Quản Lý miễn phí và mã nguồn mở. Nếu nó giúp ích cho quy trình làm việc của bạn, hãy cân nhắc hỗ trợ phát triển.';

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
  String get bridge => 'Cầu nối';

  @override
  String get loopback => 'Vòng lặp';

  @override
  String get console => 'Bảng điều khiển';

  @override
  String get state => 'Trạng thái';

  @override
  String get storage => 'Lưu trữ';

  @override
  String get database => 'Cơ sở dữ liệu';

  @override
  String get performance => 'Hiệu suất';

  @override
  String get memoryLeaks => 'Rò rỉ bộ nhớ';

  @override
  String get history => 'Lịch sử';

  @override
  String get noNetworkRequests => 'Không có yêu cầu mạng';

  @override
  String get apiCallsAppearHere =>
      'Các lệnh gọi API sẽ xuất hiện ở đây theo thời gian thực';

  @override
  String clearStaleButton(Object count) {
    return 'Cũ ($count)';
  }

  @override
  String clearStaleTooltip(Object count) {
    return 'Xóa $count yêu cầu đang chờ không có phản hồi trên 10 phút';
  }

  @override
  String clearStaleSnackbar(Object count) {
    return 'Đã xóa $count yêu cầu cũ (chờ > 10 phút)';
  }

  @override
  String memorySafetyOverflow(Object count) {
    return 'An toàn bộ nhớ: đã loại $count mục mạng cũ khỏi bộ nhớ đệm open-trips';
  }

  @override
  String get sdkTipsPill => 'Tips lib';

  @override
  String get sdkTipsHeader => 'Tương thích thư viện';

  @override
  String get sdkTipsSubtitle =>
      'Để đảm bảo mọi data được hiển thị đầy đủ, hãy đảm bảo thư viện đã là version mới nhất.';

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
    return 'v$version · Mới nhất';
  }

  @override
  String sdkTipsPillUpdate(Object version) {
    return 'v$version · Cập nhật';
  }

  @override
  String get sdkTipsInstalled => 'Đang dùng';

  @override
  String get sdkTipsLatestLabel => 'Mới nhất';

  @override
  String get sdkTipsUpdate => 'Cập nhật';

  @override
  String get sdkTipsChecking => 'Đang kiểm tra';

  @override
  String get sdkTipsOffline => 'Không kiểm tra được';

  @override
  String get sdkTipsRetry => 'Thử lại';

  @override
  String get sdkTipsCheckProject =>
      'Chạy lệnh này trong project để xem version đang cài:';

  @override
  String get sdkTipsInstallLatest => 'Cài version mới nhất:';

  @override
  String get appUpdateTitle => 'Phiên bản DevConnect';

  @override
  String get appUpdateAvailable => 'Đã có phiên bản mới.';

  @override
  String get appUpdateUpToDate => 'Bạn đang dùng phiên bản mới nhất.';

  @override
  String get appUpdateViewRelease => 'Xem bản phát hành';

  @override
  String devicesConnected(Object count) {
    return '$count đã kết nối';
  }

  @override
  String get devicesAll => 'Tất cả';

  @override
  String devicesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thiết bị',
    );
    return '$_temp0';
  }

  @override
  String get commandsTitle => 'Lệnh tùy biến';

  @override
  String get commandsNoDevice => 'Kết nối một thiết bị để chạy lệnh của nó.';

  @override
  String get commandsEmptyHint =>
      'App chưa đăng ký lệnh nào. Thêm bằng DevConnect.registerCommand(name, handler), hoặc gõ tên lệnh để chạy.';

  @override
  String get commandsName => 'Lệnh';

  @override
  String get commandsArgs => 'Tham số — object JSON, không bắt buộc';

  @override
  String get commandsArgsInvalid => 'Tham số phải là một object JSON.';

  @override
  String get commandsRun => 'Chạy';

  @override
  String commandsTarget(Object device) {
    return 'Chạy trên $device';
  }

  @override
  String get commandsHistoryEmpty => 'Kết quả các lệnh bạn chạy sẽ hiện ở đây.';

  @override
  String get commandsNoResponse =>
      'Không có phản hồi. App đã đăng ký lệnh này chưa?';

  @override
  String get dbTables => 'Bảng';

  @override
  String get dbRefresh => 'Tải lại danh sách bảng';

  @override
  String get dbNoDevice => 'Kết nối một thiết bị để xem database của nó.';

  @override
  String get dbSelectDevice =>
      'Chọn một thiết bị ở thanh dưới để xem database của nó.';

  @override
  String get dbNoDatabases =>
      'App chưa đăng ký database nào. Thêm bằng DevConnect.registerDatabase(name, query) rồi tải lại danh sách bảng.';

  @override
  String get dbRun => 'Chạy';

  @override
  String get dbRunHint => 'Chọn một bảng hoặc viết câu SQL';

  @override
  String get dbRunHintSubtitle => 'Chọn một bảng để xem trước 50 dòng đầu.';

  @override
  String dbRows(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dòng',
    );
    return '$_temp0';
  }

  @override
  String dbTruncated(Object count) {
    return 'chỉ $count dòng đầu';
  }

  @override
  String get dbNoResponse =>
      'Không có phản hồi. App đã đăng ký database bằng DevConnect.registerDatabase chưa? Tính năng này cần SDK mới nhất.';

  @override
  String get stateToolsTab => 'Điều khiển';

  @override
  String get stateNoDevice =>
      'Chọn một thiết bị ở thanh dưới để theo dõi, chụp và điều khiển state của nó.';

  @override
  String get stateNoState => 'Thiết bị này chưa gửi state nào.';

  @override
  String get stateSubscriptions => 'Theo dõi';

  @override
  String get stateSubscriptionsHint =>
      'Ghim một đường dẫn state để xem giá trị trực tiếp, ví dụ auth.user hoặc cart.items[0].price.';

  @override
  String get statePinPath => 'Ghim đường dẫn';

  @override
  String get statePathMissing => '(không có trong state)';

  @override
  String get stateRemove => 'Xóa';

  @override
  String get stateSnapshots => 'Snapshot';

  @override
  String get stateSnapshotsHint =>
      'Lưu state hiện tại rồi gửi ngược lại sau để tái hiện bug hoặc bỏ qua form dài. App áp dụng trong onStateRestore.';

  @override
  String get stateTakeSnapshot => 'Chụp state';

  @override
  String stateKeys(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count khóa',
    );
    return '$_temp0';
  }

  @override
  String get stateRestore => 'Khôi phục';

  @override
  String get stateRestoreHere => 'Khôi phục state của app về thời điểm này';

  @override
  String get stateSaveSnapshot => 'Lưu thành snapshot';

  @override
  String get stateSnapshotSaved => 'Đã lưu snapshot';

  @override
  String get stateRestoreSent => 'Đã gửi lệnh khôi phục state';

  @override
  String get stateDispatch => 'Dispatch action';

  @override
  String get stateDispatchHint =>
      'Gửi một Redux action vào app. Cần nối store: connectReduxStore(store) với React Native, onReduxDispatch với Flutter và Android.';

  @override
  String get stateDispatchButton => 'Dispatch';

  @override
  String get stateDispatchSent => 'Đã gửi action';

  @override
  String get stateActionInvalid => 'Action phải là một object JSON.';

  @override
  String get stateRecentActions => 'Gần đây';

  @override
  String get jsonTreeView => 'Cây';

  @override
  String get jsonTableView => 'Bảng';

  @override
  String get jsonSearchHint => 'Tìm key và giá trị';

  @override
  String get jsonExportCsv => 'Tải bảng xuống (CSV)';

  @override
  String get jsonTableNoMatch => 'Không có dòng nào khớp';

  @override
  String get jsonPrevMatch => 'Kết quả trước';

  @override
  String get jsonNextMatch => 'Kết quả sau';

  @override
  String get jsonExpandAll => 'Mở rộng tất cả';

  @override
  String get jsonCollapseAll => 'Thu gọn tất cả';

  @override
  String get jsonCopyKey => 'Copy key';

  @override
  String get jsonCopyValue => 'Copy giá trị';

  @override
  String get jsonCopyPath => 'Copy đường dẫn';

  @override
  String get jsonKeyCopied => 'Đã copy key';

  @override
  String get jsonValueCopied => 'Đã copy giá trị';

  @override
  String get jsonPathCopied => 'Đã copy đường dẫn';

  @override
  String jsonShowMore(int count, int remaining) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return 'Hiện thêm $countString (còn $remainingString)';
  }

  @override
  String jsonLongValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ký tự, copy để lấy đủ';
  }

  @override
  String jsonPrettyCut(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Đang hiện $shownString/$totalString dòng đầu. Copy hoặc lưu file để lấy đầy đủ.';
  }

  @override
  String jsonTableTruncated(Object count) {
    return 'Chỉ hiện $count dòng đầu.';
  }

  @override
  String get networkErrors => 'Lỗi';

  @override
  String get networkSearchBodies => 'Tìm cả trong body request & response';

  @override
  String get networkExportHar => 'Xuất các request đang hiển thị ra file HAR';

  @override
  String get networkNothingToExport => 'Không có request nào để xuất';

  @override
  String get fileSaved => 'Đã lưu file';

  @override
  String get consoleGroupRepeats => 'Gộp log lặp lại';

  @override
  String get consoleOccurrences => 'Các lần lặp';

  @override
  String get consoleNoMatchTitle => 'Không có log nào khớp';

  @override
  String get consoleNoMatchSubtitle => 'Bỏ bớt bộ lọc để xem lại log.';

  @override
  String get consoleShowAllLevels => 'Hiện tất cả level';

  @override
  String get consoleClearSearch => 'Xóa tìm kiếm';

  @override
  String get consoleResetFilters => 'Đặt lại bộ lọc';

  @override
  String get consoleExport => 'Xuất log';

  @override
  String get consoleExportText => 'Văn bản (.txt)';

  @override
  String get consoleExportJson => 'JSON (.json)';

  @override
  String get consoleNothingToExport => 'Không có log nào để xuất';

  @override
  String get errorSymbolicate => 'Giải mã';

  @override
  String get errorSymbolicated => 'Đã giải mã về mã nguồn';

  @override
  String get errorSymbolicateFailed =>
      'Không giải mã được stack này: không kết nối được Metro và bản build này chưa upload source map (uploadSourceMap trong SDK).';

  @override
  String get storageTabHistory => 'Lịch sử';

  @override
  String get storageTabKeyValue => 'Key-Value';

  @override
  String get storageKvNoDevice =>
      'Chọn một thiết bị ở thanh dưới để xem và sửa storage của nó.';

  @override
  String get storageKvEmpty =>
      'Chưa có storage nào sửa được. Bọc store bằng SDK (DevConnectAsyncStorage.wrap, DevConnectMMKV.wrap, DevConnectSharedPreferences.wrap…) — cần SDK mới nhất.';

  @override
  String get storageKvRefresh => 'Tải lại';

  @override
  String get storageKvAdd => 'Thêm key';

  @override
  String get storageKvEdit => 'Sửa giá trị';

  @override
  String get storageKvDelete => 'Xóa key';

  @override
  String get storageKvClear => 'Xóa tất cả';

  @override
  String storageKvClearConfirm(Object storage) {
    return 'Xóa mọi key trong $storage? Không thể hoàn tác.';
  }

  @override
  String get storageKvKey => 'Key';

  @override
  String get storageKvValue => 'Giá trị';

  @override
  String get storageKvSave => 'Lưu';

  @override
  String get storageKvFilter => 'Lọc key';

  @override
  String get deepLinkTitle => 'Mở deep link';

  @override
  String get deepLinkHint =>
      'App sẽ mở như khi người dùng bấm vào một link của nó.';

  @override
  String get deepLinkOpen => 'Mở';

  @override
  String get deepLinkSent => 'Đã gửi deep link';

  @override
  String get devMenu => 'Mở Dev Menu';

  @override
  String get networkReplay => 'Gửi lại request';

  @override
  String get networkReplaySent =>
      'Đã gửi lại request — kết quả hiện thành một dòng mới';

  @override
  String get networkConditions => 'Điều kiện mạng';

  @override
  String get networkPresetNormal => 'Bình thường';

  @override
  String get networkPresetSlow => 'Chậm (+500 ms)';

  @override
  String get networkPresetSlow3g => '3G chậm (~2 s)';

  @override
  String get networkPresetOffline => 'Mất mạng';

  @override
  String get networkTabHttpHint =>
      'Request HTTP app gọi qua fetch, XHR, axios, Dio, OkHttp…';

  @override
  String get networkTabProtocolsHint =>
      'Lưu lượng ngoài HTTP thường: GraphQL, tin nhắn WebSocket và lời gọi gRPC';

  @override
  String get networkTabMockAuditHint =>
      'Các request được rule của Mock Server trả lời thay cho mạng thật';

  @override
  String get protocolGraphqlHint =>
      'Query và mutation gửi qua GraphQL link / interceptor của SDK';

  @override
  String get protocolWebsocketHint =>
      'Kết nối WebSocket và từng frame gửi / nhận';

  @override
  String get protocolGrpcHint => 'Lời gọi gRPC (interceptor của SDK Android)';

  @override
  String get layoutTitle => 'Bố cục';

  @override
  String get layoutCapture => 'Chụp';

  @override
  String get layoutHint =>
      'Chụp màn hình hiện tại của app để xem cây phần tử. Di chuột trên ảnh để highlight phần tử, click để xem thuộc tính.';

  @override
  String get layoutNoDevice =>
      'Kết nối một app hoặc chọn thiết bị để xem bố cục.';

  @override
  String get layoutNoScreenshot =>
      'App không gửi ảnh chụp, chỉ hiển thị khung viền phần tử. React Native: thêm bằng DevConnect.registerScreenshot.';

  @override
  String get layoutPickElement =>
      'Di chuột hoặc click vào phần tử trên ảnh chụp, hoặc chọn trong cây.';

  @override
  String get layoutTree => 'Cây phần tử';

  @override
  String get layoutProperties => 'Thuộc tính';

  @override
  String get layoutTreeError => 'Không đọc được cây phần tử';

  @override
  String get layoutSearchHint => 'Tìm theo tên hoặc giá trị';

  @override
  String get layoutAppOnly => 'Chỉ phần tử của app';

  @override
  String get layoutFit => 'Vừa khung';

  @override
  String get layoutActualSize => 'Kích thước thật';

  @override
  String get layoutZoomIn => 'Phóng to';

  @override
  String get layoutZoomOut => 'Thu nhỏ';

  @override
  String get layoutZoomLevel => 'Mức zoom';

  @override
  String get layoutZoomToSelection => 'Phóng to phần tử đang chọn';

  @override
  String get layoutClose => 'Đóng bản chụp';

  @override
  String get layoutCopyName => 'Copy tên';

  @override
  String get layoutCopyJson => 'Copy dạng JSON';

  @override
  String get layoutExport => 'Xuất';

  @override
  String get layoutSavePng => 'Lưu ảnh chụp (PNG)';

  @override
  String get layoutSaveJson => 'Lưu snapshot (JSON)';

  @override
  String get layoutNoAnswer =>
      'App không phản hồi. Tab Layout cần SDK DevConnect có hỗ trợ Layout và app chạy bản debug.';

  @override
  String get layoutTruncated => 'Cây quá lớn: chỉ lấy được phần đầu.';

  @override
  String get layoutState => 'State';

  @override
  String get layoutMeasureHint => '⌥ + rê chuột: đo khoảng cách';

  @override
  String get networkTitle => 'Mạng';

  @override
  String get filterUrls => 'Lọc URL...';

  @override
  String get copyUrl => 'Sao chép URL';

  @override
  String get urlCopied => 'Đã sao chép URL';

  @override
  String get copyPath => 'Sao chép đường dẫn';

  @override
  String get pathCopied => 'Đã sao chép đường dẫn';

  @override
  String get copyCurl => 'Sao chép cURL';

  @override
  String get curlCopied => 'Đã sao chép cURL';

  @override
  String get copyRequest => 'Sao chép yêu cầu';

  @override
  String get requestCopied => 'Đã sao chép yêu cầu';

  @override
  String get copyResponse => 'Sao chép phản hồi';

  @override
  String get responseCopied => 'Đã sao chép phản hồi';

  @override
  String get requestBody => 'Nội dung yêu cầu';

  @override
  String get responseBody => 'Nội dung phản hồi';

  @override
  String get requestHeaders => 'Tiêu đề yêu cầu';

  @override
  String get responseHeaders => 'Tiêu đề phản hồi';

  @override
  String get headers => 'Tiêu đề';

  @override
  String get request => 'Yêu cầu';

  @override
  String get response => 'Phản hồi';

  @override
  String get timing => 'Thời gian';

  @override
  String get startTime => 'Thời gian bắt đầu';

  @override
  String get endTime => 'Thời gian kết thúc';

  @override
  String noLabel(Object label) {
    return 'Không có $label';
  }

  @override
  String get noStorageData => 'Không có dữ liệu lưu trữ';

  @override
  String get storageEntriesAppearHere =>
      'Các mục SharedPreferences, AsyncStorage và Hive sẽ xuất hiện ở đây';

  @override
  String get storageTitle => 'Lưu trữ';

  @override
  String get filterKeys => 'Lọc khóa...';

  @override
  String get read => 'ĐỌC';

  @override
  String get write => 'GHI';

  @override
  String get delete => 'XÓA';

  @override
  String get noEventsYet => 'Chưa có sự kiện';

  @override
  String get startAppToSeeEvents =>
      'Khởi động ứng dụng với DevConnect SDK để xem sự kiện';

  @override
  String get eventsAppearHere =>
      'Các sự kiện sẽ xuất hiện ở đây theo thời gian thực';

  @override
  String get allEventsTitle => 'Tất cả sự kiện';

  @override
  String get stopped => 'Đã dừng';

  @override
  String get searchEvents => 'Tìm kiếm sự kiện...';

  @override
  String get logDetail => 'Chi tiết nhật ký';

  @override
  String get networkDetail => 'Chi tiết mạng';

  @override
  String get stateDetail => 'Chi tiết trạng thái';

  @override
  String get storageDetail => 'Chi tiết lưu trữ';

  @override
  String get displayDetail => 'Chi tiết hiển thị';

  @override
  String get asyncOperation => 'Thao tác bất đồng bộ';

  @override
  String get errorDetail => 'Chi tiết lỗi';

  @override
  String get tag => 'Thẻ';

  @override
  String get message => 'Tin nhắn';

  @override
  String get stackTrace => 'Dấu vết ngăn xếp';

  @override
  String get noLogsYet => 'Chưa có nhật ký';

  @override
  String get connectDeviceToSeeLogs =>
      'Kết nối thiết bị và bắt đầu ghi nhật ký để xem các mục ở đây';

  @override
  String get consoleTitle => 'Bảng điều khiển';

  @override
  String get searchLogs => 'Tìm kiếm nhật ký...';

  @override
  String get clearConsole => 'Xóa bảng điều khiển';

  @override
  String get copyMessage => 'Sao chép tin nhắn';

  @override
  String get logCopied => 'Đã sao chép nhật ký';

  @override
  String get closePanel => 'Đóng bảng';

  @override
  String hideShowLogs(Object action, Object label) {
    return '$action $label nhật ký';
  }

  @override
  String get errors => 'Lỗi';

  @override
  String get searchErrors => 'Tìm kiếm lỗi...';

  @override
  String get clearErrors => 'Xóa lỗi';

  @override
  String get totalErrors => 'Tổng lỗi';

  @override
  String get fatalCrash => 'Nghiêm trọng/Sự cố';

  @override
  String get noErrorsCaptured => 'Chưa có lỗi nào được ghi nhận';

  @override
  String get errorsAppearHere =>
      'Lỗi từ React Native và Flutter sẽ xuất hiện ở đây';

  @override
  String get stackTraceCopied => 'Đã sao chép dấu vết ngăn xếp';

  @override
  String get noStackTrace => 'Không có dấu vết ngăn xếp';

  @override
  String get platform => 'Nền tảng';

  @override
  String get severity => 'Mức độ';

  @override
  String get source => 'Nguồn';

  @override
  String get deviceId => 'ID thiết bị';

  @override
  String get deviceInfo => 'Thông tin thiết bị';

  @override
  String get details => 'Chi tiết';

  @override
  String hideShowErrors(Object action, Object label) {
    return '$action $label lỗi';
  }

  @override
  String get noStateChanges => 'Không có thay đổi trạng thái';

  @override
  String get stateChangesAppearHere =>
      'Các thay đổi trạng thái Redux, BLoC, Riverpod và MobX sẽ xuất hiện ở đây';

  @override
  String get stateInspectorTitle => 'Trình kiểm tra trạng thái';

  @override
  String changesCount(Object count) {
    return '$count thay đổi';
  }

  @override
  String changeCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thay đổi',
      one: '1 thay đổi',
      zero: '0 thay đổi',
    );
    return '$_temp0';
  }

  @override
  String get filterActions => 'Lọc hành động...';

  @override
  String get newestAtTop => 'Mới nhất ở trên';

  @override
  String get newestAtBottom => 'Mới nhất ở dưới';

  @override
  String get noChanges => 'Không có thay đổi';

  @override
  String get diff => 'Khác biệt';

  @override
  String get before => 'Trước';

  @override
  String get after => 'Sau';

  @override
  String get noChangesDetected => 'Không phát hiện thay đổi';

  @override
  String get noBenchmarks => 'Không có điểm chuẩn';

  @override
  String get useBenchmarkSdk =>
      'Sử dụng benchmarkStart/Step/Stop trong SDK để đo hiệu suất';

  @override
  String get benchmarksTitle => 'Điểm chuẩn';

  @override
  String get searchBenchmarks => 'Tìm kiếm điểm chuẩn...';

  @override
  String get total => 'Tổng';

  @override
  String get avg => 'TB';

  @override
  String get min => 'Nhỏ nhất';

  @override
  String get max => 'Lớn nhất';

  @override
  String get p50 => 'P50';

  @override
  String get end => 'Kết thúc';

  @override
  String stepsCount(Object count) {
    return 'Bước ($count)';
  }

  @override
  String get noIntermediateSteps =>
      'Không có bước trung gian nào được ghi nhận';

  @override
  String get noPerformanceData => 'Không có dữ liệu hiệu suất';

  @override
  String get connectAppToProfile =>
      'Kết nối ứng dụng với DevConnect SDK để bắt đầu phân tích';

  @override
  String get stopRecording => 'Dừng ghi';

  @override
  String get startRecording => 'Bắt đầu ghi';

  @override
  String get performanceProfiler => 'Trình phân tích hiệu suất';

  @override
  String slowFrames(Object count) {
    return 'Khung hình chậm: $count';
  }

  @override
  String get systemStatus => 'Trạng thái hệ thống';

  @override
  String get startup => 'Khởi động';

  @override
  String get battery => 'Pin';

  @override
  String get emulator => 'Trình giả lập';

  @override
  String get drainRate => 'Tốc độ hao pin';

  @override
  String get thermal => 'Nhiệt độ';

  @override
  String get diskRead => 'Đọc đĩa';

  @override
  String get diskWrite => 'Ghi đĩa';

  @override
  String get anr => 'ANR';

  @override
  String get charging => 'Đang sạc';

  @override
  String get normal => 'Bình thường';

  @override
  String get fair => 'Trung bình';

  @override
  String get serious => 'Nghiêm trọng';

  @override
  String get critical => 'Nguy cấp';

  @override
  String get reqs => 'yêu cầu';

  @override
  String get live => 'trực tiếp';

  @override
  String get reqPerSec => 'yêu cầu/giây';

  @override
  String get err => 'lỗi';

  @override
  String get waitingForRequests => 'Đang chờ yêu cầu...';

  @override
  String get waitingForData => 'Đang chờ dữ liệu...';

  @override
  String get noMemoryLeaksDetected => 'Không phát hiện rò rỉ bộ nhớ';

  @override
  String get connectAppToMonitorLeaks =>
      'Kết nối ứng dụng với DevConnect SDK để theo dõi rò rỉ bộ nhớ';

  @override
  String get memoryLeakDetection => 'Phát hiện rò rỉ bộ nhớ';

  @override
  String get warning => 'Cảnh báo';

  @override
  String get info => 'Thông tin';

  @override
  String get detail => 'Chi tiết';

  @override
  String get retainedSize => 'Kích thước giữ lại';

  @override
  String get timestamp => 'Dấu thời gian';

  @override
  String get undisposedController => 'Controller chưa giải phóng';

  @override
  String get undisposedStream => 'Stream chưa giải phóng';

  @override
  String get undisposedTimer => 'Timer chưa giải phóng';

  @override
  String get undisposedAnimation => 'Animation chưa giải phóng';

  @override
  String get widgetLeak => 'Rò rỉ Widget';

  @override
  String get growingCollection => 'Bộ sưu tập tăng trưởng';

  @override
  String get custom => 'Tùy chỉnh';

  @override
  String get smoothScrolling => 'Cuộn mượt';

  @override
  String get smoothScrollingDesc =>
      'Tạo hiệu ứng cuộn mượt mà hơn khi sử dụng con lăn chuột. Nếu bạn thấy lag hoặc ảnh hưởng đến hiệu năng, hãy tắt cài đặt này.';

  @override
  String get smoothScrollingDuration => 'Thời gian cuộn';

  @override
  String get smoothScrollingDurationDesc =>
      'Thời gian chạy hiệu ứng cuộn mượt mà tính bằng mili-giây.';

  @override
  String binaryBody(String label) {
    return 'Body $label là nhị phân';
  }

  @override
  String binaryBodySize(String kb, int bytes) {
    return '$kb ($bytes byte)';
  }

  @override
  String get binaryBodyHint => 'Xác định action thông qua header X-Amz-Target.';

  @override
  String get openWithDefaultApp => 'Mở bằng app mặc định';

  @override
  String get tipsAndShortcuts => 'Mẹo & Phím tắt';

  @override
  String get tipsAndShortcutsDesc =>
      'Hướng dẫn nhanh cho các quy trình hữu ích nhất. Nhấn vào thẻ bất kỳ để xem chi tiết.';

  @override
  String get tipAllEventsTitle => 'Tất cả sự kiện';

  @override
  String get tipAllEventsBody =>
      'Một dòng thời gian trực tiếp gồm log, request mạng, thay đổi state, thao tác storage và lỗi của app, cùng các sự kiện display và async.';

  @override
  String get tipAllEventsSteps =>
      'Gõ vào \"Tìm kiếm sự kiện...\" để tìm theo nội dung, đường dẫn URL, action, key storage hoặc tag\nBật/tắt các chip \"LOG\", \"API\", \"STATE\", \"STORE\"; \"ERRORS\" chỉ giữ lỗi và request thất bại\nNhấn một dòng để xem chi tiết; \"Toàn bộ\" hoặc \"Tab\" lưu chi tiết thành ảnh\nChọn một thiết bị, hoặc \"Tất cả\", ở thanh dưới cùng để chọn xem sự kiện của thiết bị nào\nDùng \"Cũ nhất trước\"/\"Mới nhất trước\" để đảo thứ tự và \"Tự động cuộn\" để theo sự kiện mới';

  @override
  String get tipAllEventsTip =>
      '\"Xóa tất cả\" ở đây xóa danh sách của mọi trang — Console, Network, State, Storage, Errors và các trang khác — chứ không chỉ dòng sự kiện này.';

  @override
  String get tipNetworkTitle => 'Xem lưu lượng mạng';

  @override
  String get tipNetworkBody =>
      'Các request HTTP app gửi đi, kèm header, body, status và thời lượng, cùng lưu lượng GraphQL, WebSocket, gRPC và các request được mock rule trả lời. gRPC chỉ có từ SDK Android.';

  @override
  String get tipNetworkSteps =>
      'Nhấn một request để xem các tab \"Headers\", \"Request\", \"Response\" và \"Timing\"\nLọc theo method, \"2xx\"/\"3xx\"/\"Lỗi\", hoặc gõ một phần URL vào \"Lọc URL...\"\nBật \"Tìm cả trong body request & response\" để tìm cả trong payload\nBấm \"Sao chép cURL\" trong panel để lấy lệnh curl; nhấn chuột phải một dòng để \"Gửi lại request\"\nMở \"Protocols\" để xem GraphQL, WebSocket, gRPC, hoặc \"Mock Audit\" để xem request bị mock';

  @override
  String get tipNetworkTip =>
      'Các request kiểm tra kết nối như generate_204 và captive.apple.com bị ẩn cho tới khi ô tìm kiếm khớp với chúng.';

  @override
  String get tipConsoleTitle => 'Log console';

  @override
  String get tipConsoleBody =>
      'Các dòng log của app hiện ngay khi tới, kèm level, tag và thời gian — lệnh console trên React Native, print và debugPrint trên Flutter, println trên Android.';

  @override
  String get tipConsoleSteps =>
      'Bật/tắt \"DEBUG\", \"INFO\", \"WARN\" và \"ERROR\" để hiện hoặc ẩn từng level\nGõ vào \"Tìm kiếm nhật ký...\" để tìm theo nội dung hoặc tag\nNhấn một dòng để xem tag, nội dung, metadata và stack trace nếu có\nGiữ \"Gộp log lặp lại\" bật để gộp các dòng giống nhau liên tiếp thành một dòng có đếm\nDùng \"Xuất log\" để lưu danh sách đã lọc thành \"Văn bản (.txt)\" hoặc \"JSON (.json)\"';

  @override
  String get tipConsoleTip =>
      'Các dòng console.log, print và println thường tới với level DEBUG — tắt \"DEBUG\" để chỉ giữ info, cảnh báo và lỗi.';

  @override
  String get tipStateTitle => 'Xem state';

  @override
  String get tipStateBody =>
      'Mọi thay đổi state app báo về, kèm action và state trước/sau — Redux, Zustand, MobX… trên React Native, BLoC, Riverpod, Provider trên Flutter, ViewModel trên Android.';

  @override
  String get tipStateSteps =>
      'Mở tab \"Redux\" — tab này chứa thay đổi từ mọi thư viện state, không chỉ Redux\nGõ vào \"Lọc hành động...\" để tìm theo tên action hoặc store\nNhấn một thay đổi rồi chuyển giữa \"Khác biệt\", \"Trước\" và \"Sau\"\nDùng \"Khôi phục state của app về thời điểm này\" (cần DevConnect.onStateRestore) hoặc \"Lưu thành snapshot\"\nMở \"Điều khiển\" để ghim đường dẫn state, chụp snapshot và dispatch action Redux';

  @override
  String get tipStateTip =>
      '\"Khác biệt\" chỉ có dữ liệu khi SDK gửi diff — Redux, Zustand và MobX có gửi; Flutter và Android thì không, nên hãy so \"Trước\" với \"Sau\".';

  @override
  String get tipStorageTitle => 'Storage của app';

  @override
  String get tipStorageBody =>
      'Mọi thao tác đọc, ghi, xóa trên các store bạn bọc bằng SDK — AsyncStorage, MMKV, SharedPreferences, Hive… — cùng các key hiện tại của store được hỗ trợ, sửa được ngay tại đây.';

  @override
  String get tipStorageSteps =>
      'Trong \"Lịch sử\", chọn \"ĐỌC\", \"GHI\" hoặc \"XÓA\", và bật/tắt chip store như \"AS\" hay \"SP\"\nGõ một key vào \"Lọc khóa...\" để xem mọi thao tác trên key đó; giá trị cũng được tìm\nNhấn một dòng để xem giá trị, kích thước, store và thời gian của thao tác đó\nMở \"Key-Value\" để xem các key hiện tại, rồi \"Thêm key\", \"Sửa giá trị\" hoặc \"Xóa key\"\nBấm \"Tải lại\" để lấy nội dung mới nhất từ app';

  @override
  String get tipStorageTip =>
      '\"Xóa tất cả\" trong \"Lịch sử\" chỉ xóa nhật ký này; \"Xóa tất cả\" trong \"Key-Value\" xóa mọi key trong store của app.';

  @override
  String get tipDatabaseTitle => 'Database SQLite';

  @override
  String get tipDatabaseBody =>
      'Xem và truy vấn các database SQLite mà app đăng ký bằng DevConnect.registerDatabase: danh sách bảng kèm số dòng, ô SQL và bảng kết quả.';

  @override
  String get tipDatabaseSteps =>
      'Đăng ký database trong app bằng DevConnect.registerDatabase\nNhấn một bảng để xem trước 50 dòng đầu\nSửa câu SQL rồi bấm \"Chạy\" để chạy truy vấn của bạn\nBấm \"Chạy\" lần nữa để truy vấn lại — kết quả không tự cập nhật\nBấm \"Tải lại danh sách bảng\" để làm mới danh sách bảng và số dòng';

  @override
  String get tipDatabaseTip =>
      'Muốn sắp xếp, hãy thêm ORDER BY vào câu truy vấn — bấm tiêu đề cột không sắp xếp được.';

  @override
  String get tipPerformanceTitle => 'Hiệu năng';

  @override
  String get tipPerformanceBody =>
      'Biểu đồ trực tiếp FPS, CPU, bộ nhớ và hoạt động mạng của app, cùng thời gian khung hình, thread, pin, nhiệt độ, I/O ổ đĩa, thời gian khởi động và ANR khi SDK có gửi.';

  @override
  String get tipPerformanceSteps =>
      'Chọn một thiết bị ở thanh dưới cùng — chọn \"Tất cả\" thì biểu đồ trộn mẫu của mọi app\nXem các pill \"FPS\", \"MEM\", \"CPU\" và \"SLOW\" trên thanh công cụ\nRê chuột lên biểu đồ để xem giá trị chính xác và thời điểm nhận\nXem \"Trạng thái hệ thống\" để biết thời gian khởi động, mức hao pin, nhiệt độ, I/O ổ đĩa và ANR\nDùng \"Chụp dưới dạng ảnh\" để lưu biểu đồ thành PNG, và \"Xóa\" để bắt đầu lại';

  @override
  String get tipPerformanceTip =>
      'Rê chuột lên huy hiệu đỏ ở hàng FPS để xem thời gian khung chậm trung bình, tệ nhất và 5 khung chậm gần nhất.';

  @override
  String get tipLeaksTitle => 'Phát hiện rò rỉ bộ nhớ';

  @override
  String get tipLeaksBody =>
      'Cảnh báo rò rỉ từ app: bộ nhớ tăng đều được cả ba SDK tự phát hiện, hơn 50 timer đang chạy trên React Native, và mọi thứ bạn gửi bằng DevConnect.reportMemoryLeak.';

  @override
  String get tipLeaksSteps =>
      'Xem số đếm đỏ, vàng, xanh trên thanh công cụ: nghiêm trọng, cảnh báo và thông tin\nNhấn một dòng để xem \"Chi tiết\", \"Kích thước giữ lại\", \"Dấu vết ngăn xếp\" và \"Siêu dữ liệu\" nếu có\nXem \"Siêu dữ liệu\" ở các dòng bộ nhớ tăng để biết từng mẫu đo và tổng số MB tăng thêm\nTự báo những gì bạn tìm được bằng DevConnect.reportMemoryLeak, như controller hay stream chưa dispose\nBấm \"Xóa\", lặp lại thao tác nghi ngờ và xem có cảnh báo mới không';

  @override
  String get tipLeaksTip =>
      'Mặc định bộ nhớ được đo mỗi 10 giây; phải tăng đều trên 20 MB mới cảnh báo, và trên 40 MB thì thành nghiêm trọng.';

  @override
  String get tipBenchmarkTitle => 'Benchmark';

  @override
  String get tipBenchmarkBody =>
      'Đo thời gian đoạn code bạn bọc bằng lệnh benchmark của SDK, cùng các lượt App Startup và App Background mà mọi SDK tự ghi.';

  @override
  String get tipBenchmarkSteps =>
      'Bọc code bằng DevConnect.benchmarkStart và benchmarkStop — React Native bắt đầu bằng benchmark\nĐánh dấu từng pha bằng benchmarkStep (Flutter, React Native); lượt chạy Android không có bước\nNhấn một lượt chạy để xem \"Bắt đầu\", \"Kết thúc\", \"Thời lượng\" và waterfall các bước\nGõ vào \"Tìm kiếm điểm chuẩn...\" để lọc danh sách và thanh thống kê\nBấm \"Chụp dưới dạng ảnh\" để lưu panel của lượt chạy thành PNG';

  @override
  String get tipBenchmarkTip =>
      'Thanh thống kê tính trên mọi lượt đang hiện — tìm đúng một tên để có \"Nhỏ nhất\", \"TB\" và \"P50\" của riêng benchmark đó.';

  @override
  String get tipErrorsTitle => 'Lỗi';

  @override
  String get tipErrorsBody =>
      'Liệt kê lỗi app báo về: lỗi JavaScript và console.error của React Native, lỗi framework và lỗi Dart của Flutter, và exception của Android.';

  @override
  String get tipErrorsSteps =>
      'Flutter: khởi động app bằng DevConnect.initAndRunApp — init thường không cài hook bắt lỗi\nNhấn các chip \"JS\", \"Native\", \"Android\" và \"iOS\" để hiện hoặc ẩn từng nền tảng\nGõ vào \"Tìm kiếm lỗi...\" để tìm trong nội dung, nguồn hoặc stack trace\nNhấn một lỗi để mở các tab \"Message\", \"Stack Trace\" và \"Details\"\nVới stack React Native, bấm \"Giải mã\" để map frame về mã nguồn qua Metro';

  @override
  String get tipErrorsTip =>
      'Lỗi Flutter mang nhãn Android hoặc iOS theo thiết bị đã chạy — không có chip Flutter riêng.';

  @override
  String get tipMockTitle => 'Mock Server';

  @override
  String get tipMockBody =>
      'Lưu các response giả — method, regex URL, status, header, body và độ trễ tùy chọn — rồi cài lên thiết bị đang chọn, để request khớp không bao giờ đi ra mạng.';

  @override
  String get tipMockSteps =>
      'Android: thêm DevConnect.mockServerInterceptor() vào OkHttpClient trước\nChọn một thiết bị, bấm \"Add rule\", điền các trường rồi bấm \"Save changes\"\nBấm \"Push all\" — sau đó mọi chỉnh sửa, bật/tắt và xóa tự đồng bộ xuống thiết bị\nGạt công tắc của rule để tạm tắt, hoặc mở rule rồi nhấn giữ \"Hold to delete\" để xóa (Undo khôi phục lại)\nBấm \"Clear device\" để gỡ mọi rule khỏi thiết bị và ngừng đồng bộ';

  @override
  String get tipMockTip =>
      'Rule chỉ nằm trong bộ nhớ của DevConnect — thoát app là mất, nhưng thiết bị đã đồng bộ sẽ nhận lại rule khi kết nối lại.';

  @override
  String get tipHistoryTitle => 'Lịch sử phiên';

  @override
  String get tipHistoryBody =>
      'Khi một thiết bị ngắt kết nối và vắng quá 15 giây, log, request mạng, thay đổi state và thao tác storage của nó được giữ ở đây thành phiên chỉ đọc, cho tới khi thiết bị kết nối lại hoặc DevConnect thoát.';

  @override
  String get tipHistorySteps =>
      'Nhấn một phiên để mở các tab \"All\", \"Logs\", \"Network\", \"State\" và \"Storage\"\nXem thời điểm ngắt kết nối và số sự kiện trên từng thẻ\nBấm × trên một thẻ để xóa phiên đó\nBấm \"Clear All\" để xóa cả danh sách';

  @override
  String get tipHistoryTip =>
      'Phiên biến mất ngay khi chính thiết bị đó — hoặc bất kỳ app nào cùng IP — kết nối lại, nên hãy xem trước khi mở lại app.';

  @override
  String get tipDisplayTitle => 'Display';

  @override
  String get tipDisplayBody =>
      'Hiện những gì app gửi bằng DevConnect.display() — một cái tên, đoạn xem trước tùy chọn, một giá trị JSON và metadata. Cả ba SDK đều có lệnh này.';

  @override
  String get tipDisplaySteps =>
      'Gọi DevConnect.display với một tên cùng value, preview, metadata tùy chọn\nXem các dòng, mới nhất ở trên: mỗi dòng có tên, đoạn xem trước và thời gian\nNhấn một dòng để xem \"Preview\", \"Value\" dạng JSON và \"Metadata\"\nBấm \"Clear all\" để xóa cả danh sách';

  @override
  String get tipDisplayTip =>
      'Mỗi lần gọi thêm một dòng mới chứ không thay dòng cũ — dùng lại cùng tên để có một dòng thời gian.';

  @override
  String get tipAsyncTitle => 'Tác vụ async';

  @override
  String get tipAsyncBody =>
      'Liệt kê các bước async app báo về bằng DevConnect.reportAsyncOperation() — effect của saga, task, job chạy nền — kèm trạng thái, thời lượng và kết quả hoặc lỗi. Không có gì được theo dõi tự động.';

  @override
  String get tipAsyncSteps =>
      'Gọi reportAsyncOperation với loại, mô tả và trạng thái start, resolve hoặc reject\nTrên React Native, bọc promise bằng trackAsync để báo từ lúc bắt đầu tới khi xong\nXem màu huy hiệu: cam là đang chạy, xanh lá là resolve, đỏ là reject\nNhấn một dòng để xem chi tiết, \"Result\" và \"Metadata\"\nBấm \"Clear all\" để xóa cả danh sách';

  @override
  String get tipAsyncTip =>
      'Đặt cùng sagaName cho các lệnh liên quan — chọn bất kỳ lệnh nào cũng hiện cả nhóm trong \"Saga timeline\".';

  @override
  String get tipLayoutTitle => 'Layout inspector';

  @override
  String get tipLayoutBody =>
      'Chụp màn hình hiện tại của app cùng cây phần tử — widget Flutter, component React Native hoặc view Android — và hiện vị trí, kích thước, padding, margin, props của từng phần tử.';

  @override
  String get tipLayoutSteps =>
      'Chọn thiết bị rồi bấm \"Chụp\" để lấy màn hình và cây phần tử\nRê chuột trên ảnh chụp để làm nổi một phần tử; nhấn để chọn\nHoặc chọn trong \"Cây phần tử\", hay tìm bằng \"Tìm theo tên hoặc giá trị\"\nBật \"Chỉ phần tử của app\" để ẩn widget của thư viện (Flutter, React Native)\nXem \"Thuộc tính\" — box model, vị trí, kích thước, props — hoặc bấm \"Copy dạng JSON\"';

  @override
  String get tipLayoutTip =>
      'React Native chỉ gửi ảnh chụp sau khi bạn gọi DevConnect.registerScreenshot() — nếu không thì chỉ thấy khung viền.';

  @override
  String get settingsGroupConnection => 'Kết nối';

  @override
  String get settingsGroupConnectionDesc =>
      'Máy chủ, địa chỉ mạng và kết nối USB.';

  @override
  String get settingsGroupDevices => 'Thiết bị';

  @override
  String get settingsGroupDevicesDesc =>
      'App đang kết nối và các thiết bị từng kết nối.';

  @override
  String get settingsGroupAppearance => 'Giao diện';

  @override
  String get settingsGroupAppearanceDesc =>
      'Chủ đề, ngôn ngữ và các tab được hiển thị.';

  @override
  String get settingsGroupData => 'Hiển thị & dữ liệu';

  @override
  String get settingsGroupDataDesc =>
      'Cách hiển thị chi tiết và lượng lịch sử được giữ lại.';

  @override
  String get settingsGroupGuides => 'Hướng dẫn';

  @override
  String get settingsGroupGuidesDesc =>
      'Bắt đầu nhanh, phím tắt và mẹo sử dụng.';

  @override
  String get settingsGroupSupport => 'Ủng hộ';

  @override
  String get settingsGroupSupportDesc => 'Góp phần giúp DevConnect phát triển.';

  @override
  String get tipsTabFeatures => 'Tính năng';

  @override
  String get tipsTabShortcuts => 'Phím tắt';

  @override
  String get tipsTabConnect => 'Kết nối thiết bị';

  @override
  String get tipsTabSdk => 'Cài SDK';

  @override
  String get tipsTabAdvanced => 'Nâng cao';

  @override
  String get tipsSteps => 'Các bước';

  @override
  String get tipsKeys => 'Phím';

  @override
  String get tipsProTip => 'Mẹo';

  @override
  String get tipsPrevious => 'Trước';

  @override
  String get tipsNext => 'Tiếp';

  @override
  String get tipsDone => 'Xong';

  @override
  String get tipsOpenPage => 'Mở trang';

  @override
  String get tipsCopyCode => 'Copy';

  @override
  String get tipsCodeCopied => 'Đã copy code';

  @override
  String get tipsClose => 'Đóng';

  @override
  String get pageGuide => 'Cách dùng trang này';

  @override
  String get guideReloadTitle => 'Tải lại app';

  @override
  String get guideReloadSummary =>
      'Tải lại app đang xem từ bất kỳ trang nào của DevConnect, kể cả khi đang gõ: Flutter dựng lại widget, React Native tải lại từ Metro, Android tạo lại activity hiện tại.';

  @override
  String get guideReloadSteps =>
      '[⌘ R] Tải lại app đang chọn, hoặc mọi app đang kết nối nếu chưa chọn app nào\n[⇧ ⌘ R] Hot restart: chạy onHotRestartRequest của app Flutter, nếu không thì tải lại như ⌘ R\nHoặc bấm nút tải lại ở thanh dưới cùng — tooltip của nút có ghi phím tắt';

  @override
  String get guideReloadTip =>
      '⌘ R với Flutter dựng lại cây widget và giữ state, nhưng không nạp code mới sửa — muốn vậy hãy dùng hot reload của IDE.';

  @override
  String get guideJsonSearchTitle => 'Tìm trong body';

  @override
  String get guideJsonSearchSummary =>
      'Tree, JSON và chế độ xem code (TypeScript, Dart hoặc Kotlin) đều có ô tìm kiếm riêng: không phân biệt hoa thường, tô sáng mọi kết quả và cuộn tới kết quả đang chọn.';

  @override
  String get guideJsonSearchSteps =>
      '[⌘ F] Nhảy tới ô tìm kiếm của chế độ xem — nhấn vào trong body trước\n[↵] Tới kết quả tiếp theo\n[⇧ ↵] Về kết quả trước\n[Esc] Xóa tìm kiếm';

  @override
  String get guideJsonSearchTip =>
      'Tìm trong Tree tự mở node và tải trang sau để hiện tới 500 kết quả; JSON đếm được tới 100.000.';

  @override
  String get guideLayoutZoomTitle => 'Zoom ảnh chụp layout';

  @override
  String get guideLayoutZoomSummary =>
      'Phóng to và căn khung ảnh chụp ở trang Layout bằng bàn phím — phím có tác dụng ngay khi ảnh chụp hiện ra.';

  @override
  String get guideLayoutZoomSteps =>
      '[⌘ +] Phóng to, 1,25 lần mỗi lần bấm\n[⌘ −] Thu nhỏ\n[⌘ 0] Kích thước thật: 100% bằng kích thước màn hình của app\n[⌘ 1] Vừa khít cả màn hình trong panel\n[⌘ 2] Zoom tới phần tử đang chọn';

  @override
  String get guideLayoutZoomTip =>
      'Nhấn vào số phần trăm để chọn 50, 100, 200 hoặc 400%; chụm hai ngón để zoom và kéo để di chuyển.';

  @override
  String get guideLayoutMeasureTitle => 'Đo khoảng cách';

  @override
  String get guideLayoutMeasureSummary =>
      'Giữ Option để xem khoảng cách giữa phần tử đang chọn và phần tử dưới con trỏ, giống các công cụ thiết kế.';

  @override
  String get guideLayoutMeasureSteps =>
      'Chọn một phần tử: nhấn trên ảnh chụp hoặc chọn trong cây\n[⌥] Giữ Option và trỏ vào một phần tử khác\nĐọc khoảng hở giữa hai phần tử tách rời, hoặc khoảng lề khi phần tử này nằm trong phần tử kia\nThả Option để xem lại box model của phần tử đang trỏ';

  @override
  String get guideLayoutMeasureTip =>
      'Hai phần tử chồng lên nhau sẽ không có số đo — cần một phần tử nằm trong phần tử kia, hoặc có khoảng hở giữa chúng.';

  @override
  String get guideLayoutTreeTitle => 'Duyệt cây phần tử';

  @override
  String get guideLayoutTreeSummary =>
      'Di chuyển trong cây phần tử đã chụp bằng phím mũi tên khi cây đang được focus — nhấn một dòng hoặc một phần tử trên ảnh chụp.';

  @override
  String get guideLayoutTreeSteps =>
      '[↑ ↓] Lên hoặc xuống một dòng\n[→] Mở dòng; bấm lần nữa để vào phần tử con đầu tiên\n[←] Đóng dòng; bấm lần nữa để ra phần tử cha\n[Esc] Bỏ chọn';

  @override
  String get guideLayoutTreeTip =>
      'Gõ vào \"Tìm theo tên hoặc giá trị\" để tìm theo tên, props và state; ↵ và ⇧ ↵ để đi qua các kết quả.';

  @override
  String get guideAndroidEmulatorTitle => 'Máy ảo Android';

  @override
  String get guideAndroidEmulatorSummary =>
      'App trong máy ảo Android gọi tới Mac này qua 10.0.2.2 (Genymotion: 10.0.3.2), nên không cần cài đặt gì.';

  @override
  String get guideAndroidEmulatorSteps =>
      'Kiểm tra Cài đặt › \"Kết nối\" › \"Máy chủ\" đang hiện \"Máy chủ đang chạy\"\nAndroid native: truyền enabled = BuildConfig.DEBUG vào installForApp — mặc định SDK tắt\nChạy bản debug trong máy ảo; không cần adb reverse\nTìm app ở thanh thiết bị dưới cùng cửa sổ';

  @override
  String get guideAndroidEmulatorTip =>
      'DevConnect luôn khởi động ở port 9090; port đổi trong \"Máy chủ\" chỉ giữ tới khi thoát app, và port của SDK phải khớp.';

  @override
  String get guideAndroidUsbTitle => 'Điện thoại Android qua USB';

  @override
  String get guideAndroidUsbSummary =>
      'adb reverse trỏ localhost của điện thoại về Mac này qua cáp, nên app kết nối được mà không cần Wi‑Fi.';

  @override
  String get guideAndroidUsbSteps =>
      'Bật USB debugging, cắm điện thoại và cho phép Mac này khi được hỏi\nBấm \"Chạy ADB Reverse\" ở Cài đặt › \"Kết nối\" › \"Kết nối USB\", hoặc chạy lệnh bên dưới\nMở app — app Android native đang chạy thì phải khởi động lại\nKhông kết nối được? Bấm \"Thiết bị\" ở đó để xem adb có thấy điện thoại không';

  @override
  String get guideAndroidUsbTip =>
      'Chạy lại sau khi cắm lại cáp, khởi động lại adb hay khởi động lại máy; cắm nhiều thiết bị thì chạy adb -s kèm serial của điện thoại trong Terminal.';

  @override
  String get guideIosSimulatorTitle => 'Máy ảo iOS';

  @override
  String get guideIosSimulatorSummary =>
      'Simulator dùng chung mạng với Mac, nên bản debug kết nối DevConnect qua localhost mà không cần cài đặt.';

  @override
  String get guideIosSimulatorSteps =>
      'Kiểm tra Cài đặt › \"Kết nối\" › \"Máy chủ\" đang hiện \"Máy chủ đang chạy\"\nChạy bản debug của app trong simulator\nTìm app ở thanh thiết bị dưới cùng cửa sổ';

  @override
  String get guideIosSimulatorTip =>
      'Mở cái nào trước cũng được: app React Native và Flutter tự thử lại, nên vài giây sau khi DevConnect chạy là kết nối.';

  @override
  String get guideIphoneTitle => 'iPhone';

  @override
  String get guideIphoneSummary =>
      'Khi cùng Wi‑Fi với Mac, bản debug thường tự tìm thấy DevConnect; nếu không, hãy đặt host là địa chỉ của Mac.';

  @override
  String get guideIphoneSteps =>
      'Cho iPhone và Mac vào cùng một Wi‑Fi — mạng khách thường chặn việc này\nChạy bản debug và cho phép truy cập mạng cục bộ khi iOS hỏi\nChờ vài giây: React Native tìm Mac qua Metro, Flutter qua tín hiệu quảng bá\nChưa thấy app? Copy địa chỉ của Mac ở Cài đặt › \"Kết nối\" › \"Mạng\"\nĐặt địa chỉ đó làm host trong lệnh init của SDK (code bên dưới), rồi khởi động lại app';

  @override
  String get guideIphoneTip =>
      'Chỉ cắm cáp USB thì không kết nối được app trên iPhone — điện thoại phải gọi tới Mac qua mạng.';

  @override
  String get guideTroubleshootTitle => 'App không kết nối';

  @override
  String get guideTroubleshootSummary =>
      'Phần lớn sự cố kết nối đến từ vài nguyên nhân — hãy kiểm tra theo thứ tự này.';

  @override
  String get guideTroubleshootSteps =>
      'Cài đặt › \"Kết nối\" › \"Máy chủ\" hiện \"Máy chủ đang chạy\" và không báo lỗi port\nApp là bản debug; Android native cần thêm enabled = BuildConfig.DEBUG\nPort của SDK khớp với máy chủ — cả hai đều bắt đầu ở 9090\nĐiện thoại dùng chung Wi‑Fi với Mac, hoặc Android đã chuyển port bằng adb reverse\nKhi dùng Wi‑Fi, macOS cho DevConnect nhận kết nối đến (System Settings › Network › Firewall)';

  @override
  String get guideTroubleshootTip =>
      'Vẫn không được? Đặt host là một địa chỉ trong Cài đặt › \"Kết nối\" › \"Mạng\" và truyền auto: false (Flutter: auto_: false) để khi kết nối lại vẫn giữ host đó.';

  @override
  String get guideSdkReactNativeSummary =>
      'Cài package và gọi init một lần khi app khởi động — từ đó fetch và XHR (nên cả axios), log console, lỗi và hiệu năng đều được ghi lại.';

  @override
  String get guideSdkReactNativeSteps =>
      'Thêm devconnect-manage-kit bằng yarn hoặc npm (lệnh bên dưới)\nGọi DevConnect.init một lần khi app khởi động, trước request đầu tiên\nVới state, thêm devConnectReduxMiddleware (Redux), devConnectMiddleware (Zustand) hoặc setupMobxSpy (MobX)\nChạy bản debug — với bản release, init không làm gì trừ khi bạn truyền enabled: true';

  @override
  String get guideSdkReactNativeTip =>
      'init chỉ chạy một lần mỗi lần app khởi động, nên sau khi đổi host hay port hãy reload toàn bộ — Fast Refresh vẫn giữ cấu hình cũ.';

  @override
  String get guideSdkFlutterSummary =>
      'Khởi động app qua initAndRunApp: HTTP qua dart:io (http, Dio, Chopper…), print và debugPrint, lỗi và hiệu năng được ghi lại mà không cần thêm code.';

  @override
  String get guideSdkFlutterSteps =>
      'Chạy flutter pub add devconnect_manage_kit\nKhởi động app bằng DevConnect.initAndRunApp trong main(), truyền callback runApp dạng async\nVới Riverpod hoặc BLoC, gọi DevConnect.reportStateChange hoặc reportBlocChange từ observer của bạn\nChạy bản debug — bản profile và release luôn tắt';

  @override
  String get guideSdkFlutterTip =>
      'Đặt Firebase và code khởi tạo khác trong callback runApp — gọi ensureInitialized() trước initAndRunApp sẽ gây lỗi lệch zone.';

  @override
  String get guideSdkAndroidSummary =>
      'Thêm dependency từ Maven Central và gọi installForApp trong Application.onCreate: output println, crash, ANR, hiệu năng và state ViewModel được ghi lại; HTTP cần thêm interceptor OkHttp.';

  @override
  String get guideSdkAndroidSteps =>
      'Thêm io.github.buivietphi:devconnect-android:1.1.0 vào app/build.gradle.kts\nGọi DevConnect.installForApp trong Application.onCreate với enabled = BuildConfig.DEBUG — mặc định SDK tắt\nThêm DevConnect.okHttpInterceptor() vào mọi OkHttpClient, kể cả của Retrofit\nGhi log bằng DCLog thay cho android.util.Log; với Timber, plant một Tree gọi DevConnectTimberHelper.log\nĐảm bảo manifest của app có quyền INTERNET';

  @override
  String get guideSdkAndroidTip =>
      'SDK chỉ tìm DevConnect một lần khi app khởi động — hãy mở DevConnect (và chạy adb reverse) trước, hoặc khởi động lại app.';

  @override
  String get guideMockApiTitle => 'Mock một API';

  @override
  String get guideMockApiSummary =>
      'Trả lời các request khớp bằng status, header và body của bạn, có thể kèm độ trễ, mà không cần sửa server hay app.';

  @override
  String get guideMockApiSteps =>
      'Chọn một thiết bị ở thanh dưới cùng, mở \"Mock Server\" rồi bấm \"Add rule\"\nĐặt \"Method\", \"Status\", \"URL pattern\" (regex, khớp ở bất kỳ đâu trong URL) và body\nBấm \"Save changes\" rồi \"Push all\" — toàn bộ danh sách rule được gửi, các lần lưu sau tự đồng bộ xuống thiết bị\nXem Network › \"Mock Audit\" để biết những request nào được rule trả lời\nGạt công tắc của rule để tạm tắt, hoặc bấm \"Clear device\" để gỡ mọi rule';

  @override
  String get guideMockApiTip =>
      'Android cần DevConnect.mockServerInterceptor() trên OkHttp; React Native chỉ mock được fetch, không mock axios hay XMLHttpRequest.';

  @override
  String get guideNetworkConditionsTitle => 'Mạng chậm hoặc mất mạng';

  @override
  String get guideNetworkConditionsSummary =>
      'Làm chậm hoặc làm lỗi các request HTTP của app mà không cần đụng tới cài đặt thiết bị — kết nối của chính DevConnect vẫn chạy bình thường.';

  @override
  String get guideNetworkConditionsSteps =>
      'Trong Network, mở menu đồng hồ \"Điều kiện mạng\" trên thanh công cụ\nChọn \"Chậm (+500 ms)\" hoặc \"3G chậm (~2 s)\" để làm trễ mọi request\nChọn \"Mất mạng\" để request lỗi ngay, như khi mất mạng thật\nChọn \"Bình thường\" khi xong — biểu tượng sẽ sáng cho tới lúc đó\nTrên Android chỉ lưu lượng OkHttp bị ảnh hưởng, qua DevConnect.okHttpInterceptor()';

  @override
  String get guideNetworkConditionsTip =>
      'Áp dụng cho mọi app đang kết nối, và cả app kết nối sau đó, cho tới khi bạn chọn \"Bình thường\".';

  @override
  String get guideReplayTitle => 'Gửi lại request';

  @override
  String get guideReplaySummary =>
      'Cho app gửi lại một request đã ghi — cùng method, URL, header và body — mà không phải bấm lại qua các màn hình.';

  @override
  String get guideReplaySteps =>
      'Trong Network, nhấn chuột phải vào một request và chọn \"Gửi lại request\"\nHoặc mở request và bấm biểu tượng lặp lại ở phần đầu panel\nRequest gửi lại hiện thành một dòng mới trong danh sách';

  @override
  String get guideReplayTip =>
      'Android chạy lại các lệnh gọi OkHttp gần đây qua chính client và interceptor của app; Flutter và React Native gửi lại header đã ghi y nguyên.';

  @override
  String get guideHarExportTitle => 'Xuất ra HAR';

  @override
  String get guideHarExportSummary =>
      'Lưu các request đang hiện trong Network thành file HAR 1.2 chuẩn — gồm header, body, status và thời gian — để mở bằng công cụ khác.';

  @override
  String get guideHarExportSteps =>
      'Thu hẹp danh sách \"HTTP\" bằng bộ lọc thiết bị, method, status và URL\nBấm biểu tượng tải xuống \"Xuất các request đang hiển thị ra file HAR\" trên thanh công cụ\nChọn nơi lưu file .har\nMở file bằng Chrome DevTools hoặc Charles, hoặc gửi cho đồng đội';

  @override
  String get guideHarExportTip =>
      'Chỉ những gì danh sách HTTP đang hiện mới được lưu, nên bộ lọc quyết định nội dung file; mục \"Protocols\" không được xuất.';

  @override
  String get guideDatabaseQueryTitle => 'Truy vấn database của app';

  @override
  String get guideDatabaseQuerySummary =>
      'Xem các bảng của database SQLite trong app và chạy SQL trên đó, ngay từ DevConnect.';

  @override
  String get guideDatabaseQuerySteps =>
      'Đăng ký database trong app bằng DevConnect.registerDatabase (code bên dưới)\nMở Database và nhấn một bảng để xem trước 50 dòng đầu\nSửa câu SQL rồi bấm \"Chạy\" — kết quả dừng ở 1.000 dòng\nBấm \"Tải lại danh sách bảng\" sau khi app thay đổi bảng';

  @override
  String get guideDatabaseQueryTip =>
      'Truy vấn chạy trên database của bảng bạn nhấn gần nhất, nếu chưa nhấn thì trên database đăng ký đầu tiên.';

  @override
  String get guideBigJsonTitle => 'Body lớn';

  @override
  String get guideBigJsonSummary =>
      'Body lớn mở ra mà không làm DevConnect đơ: dữ liệu được parse ở nền, Tree và JSON chỉ dựng phần đang hiện trên màn hình.';

  @override
  String get guideBigJsonSteps =>
      'Nhấn \"Hiện thêm …\" dưới một danh sách dài trong Tree để tải thêm 200 phần tử\nDùng \"Copy giá trị\" với chuỗi dài trong Tree — Tree chỉ hiện 2.000 ký tự đầu\nChuyển sang JSON để cuộn và tìm trên toàn bộ tài liệu\nDùng \"Copy JSON\" hoặc \"Save as file\" ở đó — cả hai đều lấy đủ body\nDòng JSON dài hơn 20.000 ký tự chỉ hiện phần đầu; copy hoặc lưu file để lấy đủ';

  @override
  String get guideBigJsonTip =>
      'Khi body là danh sách object, Tree có chế độ \"Bảng\": hiện 500 dòng, nhưng \"Tải bảng xuống (CSV)\" lưu mọi dòng khớp.';

  @override
  String get guideCustomCommandsTitle => 'Lệnh tuỳ chỉnh';

  @override
  String get guideCustomCommandsSummary =>
      'Chạy code trong app từ DevConnect — xóa cache, đăng xuất, tạo dữ liệu test — và xem kết quả trả về.';

  @override
  String get guideCustomCommandsSteps =>
      'Đăng ký handler trong app bằng DevConnect.registerCommand (code bên dưới)\nMở \"Lệnh tùy biến\" và nhấn một lệnh app đã liệt kê, hoặc gõ tên lệnh\nThêm tham số dạng object JSON nếu lệnh cần\nBấm \"Chạy\", hoặc ↵ trong ô \"Lệnh\", rồi xem kết quả bên dưới';

  @override
  String get guideCustomCommandsTip =>
      'Handler trên Flutter và React Native có thể async; lỗi ném ra hiện thành kết quả, và quá 10 giây không trả lời thì hết thời gian chờ.';

  @override
  String get restart => 'Khởi động lại';

  @override
  String get serverAddressHint => 'App kết nối tới địa chỉ này.';

  @override
  String get serverStoppedHint => 'Bật máy chủ để app có thể kết nối.';

  @override
  String get tabBenchmark => 'Đo thời gian';

  @override
  String get tabDisplay => 'Hiển thị';

  @override
  String get tabAsync => 'Tác vụ bất đồng bộ';

  @override
  String get tabLayout => 'Soi bố cục';

  @override
  String get tabCommands => 'Lệnh tuỳ chỉnh';

  @override
  String get tabMockServer => 'Mock server';

  @override
  String get tabsAlwaysShown => 'Tất cả sự kiện và Cài đặt luôn hiển thị.';

  @override
  String get quickStartDesc => 'Cài SDK, khởi động trong app rồi kết nối.';

  @override
  String get quickStartNext => 'Tiếp theo — khởi động trong app';

  @override
  String get quickStartEmulator => 'Máy ảo tự kết nối';

  @override
  String get quickStartWifi => 'Điện thoại qua Wi‑Fi';

  @override
  String get quickStartUsb => 'Android qua USB';
}
