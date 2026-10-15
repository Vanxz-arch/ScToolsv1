class YouTubeVideo {
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String publishedAt;
  final String description;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.publishedAt,
    required this.description,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    final thumbHigh = thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {};

    final rawDate = snippet['publishedAt'] ?? '';
    String formattedDate = '';
    if (rawDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate);
        formattedDate = _formatDate(dt);
      } catch (_) {
        formattedDate = rawDate.substring(0, 10);
      }
    }

    return YouTubeVideo(
      id: json['id']?['videoId'] ?? '',
      title: snippet['title'] ?? 'No Title',
      channelName: snippet['channelTitle'] ?? 'Unknown Channel',
      thumbnailUrl: thumbHigh['url'] ?? '',
      publishedAt: formattedDate,
      description: snippet['description'] ?? '',
    );
  }

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$id';

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '$years tahun yang lalu';
    } else if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months bulan yang lalu';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} hari yang lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}
