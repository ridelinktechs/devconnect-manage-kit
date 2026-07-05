/// Plain data carrier for one IPv4 interface returned by
/// `NetworkInterface.list()`. Used by [NetworkSection] to render an IP
/// row with the resolved interface type label.
class NetworkInfo {
  final String ip;
  final String interfaceName;
  final String type;

  const NetworkInfo({
    required this.ip,
    required this.interfaceName,
    required this.type,
  });
}