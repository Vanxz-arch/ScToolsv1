import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

class YouTubeService {
  // Ganti dengan API Key YouTube Data v3 Anda
  static const String _apiKey = 'YOUR_YOUTUBE_API_KEY_HERE';
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  static Future<List<YouTubeVideo>> searchVideos(String query,
      {int maxResults = 15}) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': maxResults.toString(),
        'key': _apiKey,
        'relevanceLanguage': 'id',
        'order': 'relevance',
      });

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List? ?? [];
        return items.map((item) => YouTubeVideo.fromJson(item)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('API Key tidak valid atau kuota habis');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
