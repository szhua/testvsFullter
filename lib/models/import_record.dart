import 'dart:convert';

/// 上传状态枚举
enum UploadStatus {
  pending,    // 待上传
  uploading,  // 上传中
  success,    // 上传成功
  failed,     // 上传失败
}

class ImportRecord {
  final String id;
  final String fileName;
  final int rowCount;
  final int sheetCount;
  final DateTime importTime;
  final String? jsonPreview;
  final List<String> sheetNames;
  final UploadStatus uploadStatus;
  final String? uploadError;
  final DateTime? uploadTime;

  ImportRecord({
    required this.id,
    required this.fileName,
    required this.rowCount,
    required this.sheetCount,
    required this.importTime,
    this.jsonPreview,
    required this.sheetNames,
    this.uploadStatus = UploadStatus.pending,
    this.uploadError,
    this.uploadTime,
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
      'uploadStatus': uploadStatus.name,
      'uploadError': uploadError,
      'uploadTime': uploadTime?.toIso8601String(),
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
      uploadStatus: map['uploadStatus'] != null
          ? UploadStatus.values.firstWhere(
              (e) => e.name == map['uploadStatus'],
              orElse: () => UploadStatus.pending,
            )
          : UploadStatus.pending,
      uploadError: map['uploadError']?.toString(),
      uploadTime: map['uploadTime'] != null
          ? DateTime.tryParse(map['uploadTime'].toString())
          : null,
    );
  }

  /// 创建带有更新上传状态的副本
  ImportRecord copyWith({
    UploadStatus? uploadStatus,
    String? uploadError,
    DateTime? uploadTime,
  }) {
    return ImportRecord(
      id: id,
      fileName: fileName,
      rowCount: rowCount,
      sheetCount: sheetCount,
      importTime: importTime,
      jsonPreview: jsonPreview,
      sheetNames: sheetNames,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadError: uploadError ?? this.uploadError,
      uploadTime: uploadTime ?? this.uploadTime,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ImportRecord.fromJson(String source) =>
      ImportRecord.fromMap(jsonDecode(source));
}