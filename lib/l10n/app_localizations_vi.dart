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
      'WiFi tự động kết nối nếu cùng mạng. USB: cài đặt iproxy.';

  @override
  String get quickStart => 'Bắt đầu nhanh';

  @override
  String get quickStartDesc =>
      'Ba bước để kết nối app của bạn. Nhấn vào tab nền tảng để xem đoạn code tương ứng.';

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
  String get sdkTipsPill => 'Mẹo';

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
    return '$kb KB ($bytes byte)';
  }

  @override
  String get binaryBodyHint => 'Xác định action thông qua header X-Amz-Target.';
}
