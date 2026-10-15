import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bypass_service.dart';
import '../widgets/app_theme.dart';

class BypassScreen extends StatefulWidget {
  const BypassScreen({super.key});

  @override
  State<BypassScreen> createState() => _BypassScreenState();
}

class _BypassScreenState extends State<BypassScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _resultUrl;
  String? _errorMsg;
  List<Map<String, String>> _history = [];

  static const _historyKey = 'bypass_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    setState(() {
      _history = raw.map((e) {
        final parts = e.split('|||');
        return {
          'input': parts.isNotEmpty ? parts[0] : '',
          'result': parts.length > 1 ? parts[1] : '',
          'time': parts.length > 2 ? parts[2] : '',
        };
      }).toList();
    });
  }

  Future<void> _saveHistory(String input, String result) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final timeStr =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final entry = '$input|||$result|||$timeStr';
    final current = prefs.getStringList(_historyKey) ?? [];
    current.insert(0, entry);
    if (current.length > 30) current.removeLast();
    await prefs.setStringList(_historyKey, current);
    await _loadHistory();
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() => _history = []);
  }

  Future<void> _doBypass() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      _showSnack('Masukkan link terlebih dahulu', isError: true);
      return;
    }
    if (!url.startsWith('http')) {
      _showSnack('Format link tidak valid', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _resultUrl = null;
      _errorMsg = null;
    });

    final result = await BypassService.bypass(url);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.resultUrl != null) {
          _resultUrl = result.resultUrl;
          _errorMsg = null;
          _saveHistory(url, result.resultUrl!);
        } else {
          _errorMsg = result.error ?? 'Bypass gagal';
          _resultUrl = null;
        }
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Link disalin!');
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade400 : AppTheme.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: GradientAppBar(
        title: '⚡ SFL Bypass',
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              onPressed: _showHistorySheet,
              color: AppTheme.purple,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInputCard(),
            const SizedBox(height: 20),
            if (_resultUrl != null) _buildResultCard(),
            if (_errorMsg != null) _buildErrorCard(),
            const SizedBox(height: 24),
            if (_history.isNotEmpty) _buildRecentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AFF), Color(0xFF00D4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.purple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SFL Link Bypass',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bypass link sfl.gl/safelinku dengan mudah',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.neonCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan Link SFL',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          NeonTextField(
            controller: _controller,
            hint: 'https://sfl.gl/xxxxx',
            prefixIcon: Icons.link_rounded,
            keyboardType: TextInputType.url,
            onSubmitted: _doBypass,
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Bypass Sekarang',
            onPressed: _doBypass,
            icon: Icons.flash_on_rounded,
            isLoading: _isLoading,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Bypass Berhasil!',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              _resultUrl!,
              style: const TextStyle(
                color: AppTheme.purple,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _copyToClipboard(_resultUrl!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.purple.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded,
                            color: AppTheme.purple, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Salin Link',
                          style: TextStyle(
                            color: AppTheme.purple,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openLink(_resultUrl!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.purple, AppTheme.cyan],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Buka Link',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.error_rounded, color: Colors.red.shade500, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMsg!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Terbaru',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: _showHistorySheet,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(color: AppTheme.purple, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(_history.take(3).map((h) => _buildHistoryItem(h))),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, String> item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.text = item['input'] ?? '';
          _resultUrl = item['result'];
          _errorMsg = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history_rounded,
                  color: AppTheme.purple, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['input'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['time'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: AppTheme.purple, size: 18),
              onPressed: () => _copyToClipboard(item['result'] ?? ''),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Text(
                    'Riwayat Bypass',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      _clearHistory();
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 18),
                    label: const Text('Hapus',
                        style: TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _history.isEmpty
                  ? const Center(
                      child: Text('Belum ada riwayat',
                          style: TextStyle(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _history.length,
                      itemBuilder: (_, i) {
                        final h = _history[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.link_rounded,
                                      color: AppTheme.purple, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      h['input'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                h['result'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    h['time'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () =>
                                        _copyToClipboard(h['result'] ?? ''),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.purple.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.copy_rounded,
                                              color: AppTheme.purple,
                                              size: 13),
                                          SizedBox(width: 4),
                                          Text(
                                            'Salin',
                                            style: TextStyle(
                                              color: AppTheme.purple,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
