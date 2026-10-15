import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/script_model.dart';
import '../services/script_service.dart';
import '../widgets/app_theme.dart';

class ScriptManagerScreen extends StatefulWidget {
  const ScriptManagerScreen({super.key});

  @override
  State<ScriptManagerScreen> createState() => _ScriptManagerScreenState();
}

class _ScriptManagerScreenState extends State<ScriptManagerScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<ScriptModel> _scripts = [];
  bool _isLoading = false;
  bool _isExtracting = false;
  String _extractStatus = '';

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    setState(() => _isLoading = true);
    final scripts = await ScriptService.getInstalledScripts();
    if (mounted) setState(() {
      _scripts = scripts;
      _isLoading = false;
    });
  }

  Future<bool> _requestPermissions() async {
    // Android 11+
    if (await Permission.manageExternalStorage.isGranted) return true;

    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    if (statuses[Permission.manageExternalStorage]?.isGranted == true) {
      return true;
    }

    if (statuses[Permission.storage]?.isGranted == true) {
      return true;
    }

    return false;
  }

  Future<void> _pickAndInstallScript() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission && mounted) {
      _showPermissionDialog();
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Pilih File Script (.zip)',
    );

    if (result == null || result.files.single.path == null) return;

    final zipPath = result.files.single.path!;
    final fileName = result.files.single.name;
    final scriptName = fileName.replaceAll('.zip', '');

    // Deteksi folder dalam zip
    setState(() {
      _isExtracting = true;
      _extractStatus = 'Memindai isi zip...';
    });

    final folders = await ScriptService.detectFoldersInZip(zipPath);

    if (mounted) {
      setState(() {
        _isExtracting = false;
        _extractStatus = '';
      });
      
      if (folders.isEmpty) {
        _showSnack('Zip kosong atau format tidak valid', isError: true);
        return;
      }

      // Tampilkan dialog konfirmasi folder
      _showFolderSelectionDialog(zipPath, scriptName, folders);
    }
  }

  void _showFolderSelectionDialog(
      String zipPath, String scriptName, List<String> folders) {
    final selected = Set<String>.from(folders); // default semua dipilih

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Folder Terdeteksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Script: $scriptName\nPilih folder yang akan diinstall:',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: folders.length,
                    itemBuilder: (_, i) {
                      final folder = folders[i];
                      final isSelected = selected.contains(folder);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              selected.remove(folder);
                            } else {
                              selected.add(folder);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.purple.withOpacity(0.1)
                                : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.purple.withOpacity(0.5)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_rounded,
                                color: isSelected
                                    ? AppTheme.purple
                                    : AppTheme.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                folder,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? AppTheme.purple
                                    : Colors.grey.shade300,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppTheme.purple.withOpacity(0.3)),
                            ),
                            child: const Center(
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  color: AppTheme.purple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GradientButton(
                          label: 'Install Script',
                          onPressed: selected.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  _doExtract(zipPath, scriptName,
                                      selected.toList());
                                },
                          icon: Icons.download_rounded,
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _doExtract(
      String zipPath, String scriptName, List<String> selectedFolders) async {
    setState(() {
      _isExtracting = true;
      _extractStatus = 'Mengekstrak script ke ML...';
    });

    final result = await ScriptService.extractScript(
      zipPath: zipPath,
      scriptName: scriptName,
      selectedFolders: selectedFolders,
    );

    if (mounted) {
      setState(() {
        _isExtracting = false;
        _extractStatus = '';
      });

      if (result.success) {
        _showSnack(
            '✅ Script berhasil diinstall! (${result.extractedFolders.length} folder)');
        await _loadScripts();
      } else {
        _showSnack(result.error ?? 'Ekstrak gagal', isError: true);
      }
    }
  }

  Future<void> _deleteScript(ScriptModel script) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Script?',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 17)),
        content: Text(
          'Script "${script.name}" akan dihapus dari daftar.\n(File yang sudah terinstall tidak akan dihapus)',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ScriptService.deleteScript(script.id);
      _showSnack('Script dihapus dari daftar');
      await _loadScripts();
    }
  }

  void _showScriptDetail(ScriptModel script) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_zip_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        script.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Script Mobile Legends',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Info rows
            _detailRow(Icons.storage_rounded, 'Ukuran', script.formattedSize),
            _detailRow(Icons.calendar_today_rounded, 'Dipasang',
                script.formattedDate),
            const SizedBox(height: 16),
            const Text(
              'Folder Terinstall:',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: script.folders.map((f) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        f,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Hapus dari Daftar',
              onPressed: () {
                Navigator.pop(ctx);
                _deleteScript(script);
              },
              icon: Icons.delete_rounded,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.purple, size: 18),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Izin Diperlukan'),
        content: const Text(
            'Aplikasi memerlukan izin akses storage untuk menginstall script ke folder Mobile Legends.\n\nBuka Settings > Permissions > Files untuk mengizinkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Buka Settings',
                style: TextStyle(
                    color: AppTheme.purple, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade400 : AppTheme.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: GradientAppBar(
        title: '📦 Script Manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadScripts,
            color: AppTheme.purple,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          if (_isExtracting) _buildExtractingIndicator(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isExtracting ? null : _pickAndInstallScript,
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.purple.withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.upload_file_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Install Script',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AFF), Color(0xFF00D4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.purple.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_special_rounded,
              color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ML Script Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_scripts.length} script terpasang',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _scripts.length.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.purple),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _extractStatus,
            style: const TextStyle(
              color: AppTheme.purple,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

    if (_scripts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: _scripts.length,
      itemBuilder: (_, i) => _buildScriptCard(_scripts[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
            child: const Icon(Icons.folder_zip_rounded,
                size: 72, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Script',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Install Script" untuk memasang\nscript ML dari file .zip',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.purple.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  'Path Target:',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '/Android/data/com.mobile.legends/\nfiles/dragon2017/assets/',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptCard(ScriptModel script) {
    return GestureDetector(
      onTap: () => _showScriptDetail(script),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.neonCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.folder_zip_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      script.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.storage_rounded,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            size: 13),
                        const SizedBox(width: 4),
                        Text(
                          script.formattedSize,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.folder_rounded,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${script.folders.length} folder',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      script.formattedDate,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (script.folders.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: script.folders.take(4).map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              f,
                              style: const TextStyle(
                                color: AppTheme.purple,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList()
                          ..addAll(
                            script.folders.length > 4
                                ? [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.cyan.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '+${script.folders.length - 4}',
                                        style: const TextStyle(
                                          color: AppTheme.cyan,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ]
                                : [],
                          ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.info_outline_rounded,
                        color: AppTheme.purple.withOpacity(0.7), size: 20),
                    onPressed: () => _showScriptDetail(script),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.withOpacity(0.7), size: 20),
                    onPressed: () => _deleteScript(script),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
