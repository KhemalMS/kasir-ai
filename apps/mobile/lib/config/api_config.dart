import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart' if (dart.library.html) '../utils/mdns_stub.dart';

class ApiConfig {
  static String _baseUrl = '';
  static const int connectTimeout = 10;
  static const int receiveTimeout = 30;

  static String get baseUrl => _baseUrl;
  static set baseUrl(String url) => _baseUrl = url;

  static Future<void> loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base_url');
    if (saved != null && saved.isNotEmpty) {
      if (saved.contains(':3001/api')) {
        _baseUrl = saved;
      } else {
        await prefs.remove('api_base_url');
      }
    }
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  /// Auto-detect server IP at runtime.
  /// Web: uses browser's origin hostname (always correct, zero config).
  /// Android: tries mDNS first, then parallel network scan.
  static Future<void> autoDetect() async {
    // ── Web: hostname is always the server's IP ────────────────────────
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty) {
        _baseUrl = 'http://$host:3001/api';
        debugPrint('🌐 Web auto-detect: $_baseUrl');
        return;
      }
    }

    // ── Android/Non-Web: try mDNS first ───────────────────────────────
    if (!kIsWeb) {
      final mdns = await _discoverViaMdns();
      if (mdns != null) {
        _baseUrl = mdns;
        debugPrint('📡 mDNS auto-detect: $_baseUrl');
        return;
      }

      // ── Fallback: parallel network scan ───────────────────────────
      final scan = await _scanNetwork();
      if (scan != null) {
        _baseUrl = scan;
        debugPrint('🔍 Network scan auto-detect: $_baseUrl');
      }
      // If all fail, _baseUrl stays empty — user can input manually
    }
  }

  static Future<String?> _discoverViaMdns() async {
    if (kIsWeb) return null;
    try {
      final MDnsClient client = MDnsClient();
      await client.start();
      await for (final PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer('_kasir-ai._tcp.local'),
          )
          .timeout(const Duration(seconds: 3), onTimeout: (_) {})) {
        await for (final SrvResourceRecord srv in client
            .lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )
            .timeout(const Duration(seconds: 2), onTimeout: (_) {})) {
          await for (final IPAddressResourceRecord ip in client
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              )
              .timeout(const Duration(seconds: 2), onTimeout: (_) {})) {
            client.stop();
            return 'http://${ip.address.address}:${srv.port}/api';
          }
        }
      }
      client.stop();
    } catch (e) {
      debugPrint('mDNS error: $e');
    }
    return null;
  }

  static Future<String?> _scanNetwork() async {
    if (kIsWeb) return null;
    try {
      // Derive subnet from current _baseUrl or try common subnets
      List<String> subnets = [];
      if (_baseUrl.isNotEmpty) {
        final match = RegExp(r'(\d+\.\d+\.\d+)\.\d+').firstMatch(_baseUrl);
        if (match != null) subnets.add(match.group(1)!);
      }
      // Common LAN subnets as fallback
      subnets.addAll(['192.168.1', '192.168.0', '10.0.0', '172.16.0']);
      subnets = subnets.toSet().toList(); // deduplicate

      for (final subnet in subnets) {
        final futures = List.generate(254, (i) => i + 1).map((host) async {
          final url = 'http://$subnet.$host:3001/api/health';
          try {
            final resp = await http.get(Uri.parse(url)).timeout(
              const Duration(milliseconds: 800),
            );
            if (resp.statusCode == 200) return 'http://$subnet.$host:3001/api';
          } catch (_) {}
          return null;
        });
        final results = await Future.wait(futures);
        final found = results.whereType<String>().firstOrNull;
        if (found != null) return found;
      }
    } catch (e) {
      debugPrint('Network scan error: $e');
    }
    return null;
  }
}
