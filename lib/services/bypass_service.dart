import 'dart:convert';
import 'package:http/http.dart' as http;

class BypassResult {
  final bool success;
  final String? resultUrl;
  final String? error;

  BypassResult({required this.success, this.resultUrl, this.error});
}

class BypassService {
  // Endpoints disembunyikan dari user
  static const String _ep1 = 'safebypass.vercel.app';
  static const String _ep2 = 'malz-official.com';

  static Future<BypassResult> bypass(String inputUrl) async {
    // Coba endpoint pertama
    final result1 = await _tryPrimary(inputUrl);
    if (result1.success) return result1;

    // Fallback ke endpoint kedua
    return await _tryFallback(inputUrl);
  }

  static Future<BypassResult> _tryPrimary(String url) async {
    try {
      final uri = Uri.https(_ep1, '/api/bypass', {'url': url});
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final dest = body['destination'] ??
            body['result'] ??
            body['url'] ??
            body['link'];
        if (dest != null && dest.toString().startsWith('http')) {
          return BypassResult(success: true, resultUrl: dest.toString());
        }
      }
    } catch (_) {}
    return BypassResult(success: false, error: 'Primary failed');
  }

  static Future<BypassResult> _tryFallback(String url) async {
    try {
      // Encode URL untuk query param
      final encoded = Uri.encodeComponent(url);
      final uri = Uri.https(_ep2, '/slf/', {'url': encoded});
      final response = await http
          .get(uri, headers: {
            'Accept': 'application/json, text/plain',
            'User-Agent': 'Mozilla/5.0',
          })
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Coba parse JSON
        try {
          final body = jsonDecode(response.body);
          final dest = body['destination'] ??
              body['result'] ??
              body['url'] ??
              body['link'] ??
              body['data'];
          if (dest != null && dest.toString().startsWith('http')) {
            return BypassResult(success: true, resultUrl: dest.toString());
          }
        } catch (_) {}

        // Coba extract URL dari plain text / HTML
        final text = response.body;
        final urlRegex = RegExp(
          r'https?://[^\s"\'<>]+',
          caseSensitive: false,
        );
        final matches = urlRegex.allMatches(text);
        for (final match in matches) {
          final found = match.group(0)!;
          // Skip URL dari domain bypass itu sendiri
          if (!found.contains(_ep1) &&
              !found.contains(_ep2) &&
              !found.contains('sfl.gl') &&
              !found.contains('safelinkid')) {
            return BypassResult(success: true, resultUrl: found);
          }
        }
      }
    } catch (e) {
      return BypassResult(success: false, error: 'Bypass gagal: $e');
    }
    return BypassResult(success: false, error: 'Tidak dapat mem-bypass link ini');
  }
}
