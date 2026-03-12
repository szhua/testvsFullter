import 'dart:convert';

class ImportRecord {
  final String id;
  final String fileName;
  final int rowCount;
  final int sheetCount;
  final DateTime importTime;
  final String? jsonPreview;
  final List<String> sheetNames;

  ImportRecord({
    required this.id,
    required this.fileName,
    required this.rowCount,
    required this.sheetCount,
    required this.importTime,
    this.jsonPreview,
    required this.sheetNames,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'rowCount': rowCount,
      'sheetCount': sheetCount,
      'importTime': importTime.toIso8601String(),
      'jsonPreview': jsonPreview,
      'sheetNames': sheetNames,
    };
  }

  factory ImportRecord.fromMap(Map<String, dynamic> map) {
    return ImportRecord(
      id: map['id']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? '',
      rowCount: map['rowCount'] as int? ?? 0,
      sheetCount: map['sheetCount'] as int? ?? 0,
      importTime: map['importTime'] != null
          ? DateTime.tryParse(map['importTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      jsonPreview: map['jsonPreview']?.toString(),
      sheetNames: map['sheetNames'] != null
          ? List<String>.from(map['sheetNames'] as List)
          : [],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ImportRecord.fromJson(String source) =>
      ImportRecord.fromMap(jsonDecode(source));
}