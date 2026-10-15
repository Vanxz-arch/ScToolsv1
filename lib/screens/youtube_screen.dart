import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/youtube_service.dart';
import '../models/youtube_video.dart';
import '../widgets/app_theme.dart';

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchController = TextEditingController();
  List<YouTubeVideo> _videos = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  final List<String> _suggestions = [
    'script mobile legends',
    'script ML drone view',
    'config ML rank',
    'script moonton ML',
    'tutorial script ML',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search([String? overrideQuery]) async {
    final q = (overrideQuery ?? _searchController.text).trim();
    if (q.isEmpty) return;

    if (overrideQuery != null) {
      _searchController.text = overrideQuery;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final results = await YouTubeService.searchVideos(q);
      if (mounted) {
        setState(() {
          _videos = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openVideo(YouTubeVideo video) async {
    final uri = Uri.parse(video.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: GradientAppBar(title: '🎬 Cari Script'),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSuggestions(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: NeonTextField(
              controller: _searchController,
              hint: 'Cari script ML di YouTube...',
              prefixIcon: Icons.search_rounded,
              onSubmitted: _search,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _search,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.purple.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => _search(_suggestions[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.purple.withOpacity(0.25), width: 1),
              ),
              child: Text(
                _suggestions[i],
                style: const TextStyle(
                  color: AppTheme.purple,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.purple),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.red.shade400, size: 52),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Coba Lagi',
                onPressed: _search,
                icon: Icons.refresh_rounded,
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_videos.isEmpty) {
      return const Center(
        child: Text('Tidak ada hasil ditemukan',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _videos.length,
      itemBuilder: (_, i) => _buildVideoCard(_videos[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.purple.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
              child: const Icon(Icons.play_circle_rounded,
                  size: 64, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cari Script ML di YouTube',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ketik kata kunci untuk mencari\nvideo script Mobile Legends',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(YouTubeVideo video) {
    return GestureDetector(
      onTap: () => _openVideo(video),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: AppTheme.neonCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  video.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 180,
                            color: AppTheme.cardBg,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(AppTheme.purple),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 180,
                            color: AppTheme.cardBg,
                            child: const Icon(Icons.video_library_rounded,
                                color: AppTheme.purple, size: 40),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: AppTheme.cardBg,
                          child: const Icon(Icons.video_library_rounded,
                              color: AppTheme.purple, size: 40),
                        ),
                  // Play overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_circle_filled_rounded,
                            color: Colors.white, size: 52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: AppTheme.purple, size: 13),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          video.channelName,
                          style: const TextStyle(
                            color: AppTheme.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              size: 12),
                          const SizedBox(width: 3),
                          Text(
                            video.publishedAt,
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
