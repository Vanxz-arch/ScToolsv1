import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/script_model.dart';

class ExtractResult {
  final bool success;
  final String? error;
  final List<String> extractedFolders;
  final int totalBytes;

  ExtractResult({
    required this.success,
    this.error,
    required this.extractedFolders,
    required this.totalBytes,
  });
}

class ScriptService {
  static const String _mlTargetPath =
      '/storage/emulated/0/Android/data/com.mobile.legends/files/dragon2017/assets/';

  static const String _scriptsKey = 'installed_scripts';

  // Folder-folder yang dikenali dalam ML asset
  static const List<String> _knownFolders = [
    'Art',
    'Audio',
    'UI',
    'Scenes',
    'TextAsset',
    'UnityData',
    'Shader',
    'Resources',
    'Prefab',
    'Sprites',
    'Fonts',
    'Materials',
    'Animations',
    'Video',
    'Config',
    'Localization',
  ];

  static Future<List<String>> detectFoldersInZip(String zipPath) async {
    try {
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final Set<String> folders = {};

      for (final file in archive) {
        final parts = file.name.split('/');
        if (parts.isNotEmpty) {
          final topLevel = parts[0];
          if (topLevel.isNotEmpty) {
            folders.add(topLevel);
          }
        }
      }

      return folders.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  static Future<ExtractResult> extractScript({
    required String zipPath,
    required String scriptName,
    required List<String> selectedFolders,
  }) async {
    try {
      final targetDir = Directory(_mlTargetPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      int totalBytes = 0;
      final Set<String> extractedFolders = {};

      for (final file in archive) {
        final name = file.name;
        
        // Cek apakah file ini termasuk folder yang dipilih
        final parts = name.split('/');
        if (parts.isEmpty) continue;
        
        final topFolder = parts[0];
        
        // Skip jika bukan folder yang dipilih
        if (selectedFolders.isNotEmpty && !selectedFolders.contains(topFolder)) {
          continue;
        }

        final targetPath = '$_mlTargetPath$name';

        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(targetPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(data);
          totalBytes += data.length;
          extractedFolders.add(topFolder);
        } else {
          await Directory(targetPath).create(recursive: true);
          extractedFolders.add(topFolder);
        }
      }

      // Simpan ke daftar script
      await _saveScript(ScriptModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: scriptName,
        sizeBytes: totalBytes,
        installedAt: DateTime.now(),
        folders: extractedFolders.toList()..sort(),
      ));

      return ExtractResult(
        success: true,
        extractedFolders: extractedFolders.toList()..sort(),
        totalBytes: totalBytes,
      );
    } catch (e) {
      return ExtractResult(
        success: false,
        error: 'Gagal ekstrak: $e',
        extractedFolders: [],
        totalBytes: 0,
      );
    }
  }

  static Future<void> _saveScript(ScriptModel script) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getInstalledScripts();
    current.insert(0, script);
    await prefs.setString(_scriptsKey, ScriptModel.listToJsonString(current));
  }

  static Future<List<ScriptModel>> getInstalledScripts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scriptsKey) ?? '[]';
    return ScriptModel.listFromJsonString(raw);
  }

  static Future<void> deleteScript(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getInstalledScripts();
    current.removeWhere((s) => s.id == id);
    await prefs.setString(_scriptsKey, ScriptModel.listToJsonString(current));
  }

  static Future<String?> copyZipToTemp(String sourcePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = sourcePath.split('/').last;
      final dest = '${tempDir.path}/$fileName';
      await File(sourcePath).copy(dest);
      return dest;
    } catch (e) {
      return null;
    }
  }

  static bool checkMlPathExists() {
    return Directory(_mlTargetPath).existsSync();
  }
}
