import 'dart:convert';

class ScriptModel {
  final String id;
  final String name;
  final int sizeBytes;
  final DateTime installedAt;
  final List<String> folders;

  ScriptModel({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.installedAt,
    required this.folders,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    final d = installedAt;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} $h:$m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sizeBytes': sizeBytes,
        'installedAt': installedAt.toIso8601String(),
        'folders': folders,
      };

  factory ScriptModel.fromJson(Map<String, dynamic> json) => ScriptModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        sizeBytes: json['sizeBytes'] ?? 0,
        installedAt: DateTime.tryParse(json['installedAt'] ?? '') ?? DateTime.now(),
        folders: List<String>.from(json['folders'] ?? []),
      );

  static String listToJsonString(List<ScriptModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<ScriptModel> listFromJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => ScriptModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
