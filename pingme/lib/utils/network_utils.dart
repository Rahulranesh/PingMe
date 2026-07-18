import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkUtils {
  static Future<String?> getLocalIP() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiIP();
    } catch (e) {
      return _getLocalIpAddress();
    }
  }

  static Future<String?> _getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null;
  }

  static Future<bool> isSameNetwork(String ip1, String ip2) async {
    try {
      final parts1 = ip1.split('.');
      final parts2 = ip2.split('.');

      if (parts1.length != 4 || parts2.length != 4) return false;

      // Check first 3 octets match
      return parts1[0] == parts2[0] &&
             parts1[1] == parts2[1] &&
             parts1[2] == parts2[2];
    } catch (e) {
      return false;
    }
  }

  static String getNetworkPrefix(String ip) {
    final parts = ip.split('.');
    if (parts.length >= 3) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return ip;
  }
}
