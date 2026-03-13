import 'dart:convert';

/// 上传状态枚举
enum UploadStatus {
  pending,    // 待上传
  uploading,  // 上传中
  success,    // 上传成功
  failed,     // 上传失败
}

/// 单次上传记录
class UploadHistory {
  final String id;
  final DateTime uploadTime;
  final UploadStatus status;
  final String? serverResponse;
  final String? errorMessage;
  final String? uploadedData;  // 上传的数据JSON
  final List<String> headers;  // 当时的表头

  UploadHistory({
    required this.id,
    required this.uploadTime,
    required this.status,
    this.serverResponse,
    this.errorMessage,
    this.uploadedData,
    this.headers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uploadTime': uploadTime.toIso8601String(),
      'status': status.name,
      'serverResponse': serverResponse,
      'errorMessage': errorMessage,
      'uploadedData': uploadedData,
      'headers': headers,
    };
  }

  factory UploadHistory.fromMap(Map<String, dynamic> map) {
    return UploadHistory(
      id: map['id']?.toString() ?? '',
      uploadTime: map['uploadTime'] != null
          ? DateTime.tryParse(map['uploadTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] != null
          ? UploadStatus.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => UploadStatus.pending,
            )
          : UploadStatus.pending,
      serverResponse: map['serverResponse']?.toString(),
      errorMessage: map['errorMessage']?.toString(),
      uploadedData: map['uploadedData']?.toString(),
      headers: map['headers'] != null
          ? List<String>.from(map['headers'] as List)
          : [],
    );
  }
}

class ImportRecord {
  final String id;
  final String fileName;
  final int rowCount;
  final int sheetCount;
  final DateTime createdAt;  // 创建时间（解析时间）
  final String? jsonPreview;
  final List<String> sheetNames;
  final List<UploadHistory> uploadHistory;  // 上传历史记录列表

  ImportRecord({
    required this.id,
    required this.fileName,
    required this.rowCount,
    required this.sheetCount,
    required this.createdAt,
    this.jsonPreview,
    required this.sheetNames,
    this.uploadHistory = const [],
  });

  /// 获取最新的上传状态
  UploadStatus get uploadStatus {
    if (uploadHistory.isEmpty) return UploadStatus.pending;
    return uploadHistory.last.status;
  }

  /// 获取上传次数
  int get uploadCount => uploadHistory.length;

  /// 获取成功上传次数
  int get successUploadCount => uploadHistory.where((h) => h.status == UploadStatus.success).length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'rowCount': rowCount,
      'sheetCount': sheetCount,
      'createdAt': createdAt.toIso8601String(),
      'jsonPreview': jsonPreview,
      'sheetNames': sheetNames,
      'uploadHistory': uploadHistory.map((h) => h.toMap()).toList(),
    };
  }

  factory ImportRecord.fromMap(Map<String, dynamic> map) {
    return ImportRecord(
      id: map['id']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? '',
      rowCount: map['rowCount'] as int? ?? 0,
      sheetCount: map['sheetCount'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : map['uploadTime'] != null  // 兼容旧数据
              ? DateTime.tryParse(map['uploadTime'].toString()) ?? DateTime.now()
              : DateTime.now(),
      jsonPreview: map['jsonPreview']?.toString(),
      sheetNames: map['sheetNames'] != null
          ? List<String>.from(map['sheetNames'] as List)
          : [],
      uploadHistory: map['uploadHistory'] != null
          ? (map['uploadHistory'] as List)
              .map((h) => UploadHistory.fromMap(h as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  /// 创建带有新上传记录的副本
  ImportRecord addUploadHistory(UploadHistory history) {
    return ImportRecord(
      id: id,
      fileName: fileName,
      rowCount: rowCount,
      sheetCount: sheetCount,
      createdAt: createdAt,
      jsonPreview: jsonPreview,
      sheetNames: sheetNames,
      uploadHistory: [...uploadHistory, history],
    );
  }

  /// 创建带有更新jsonPreview的副本
  ImportRecord copyWith({
    String? jsonPreview,
    List<String>? headers,
  }) {
    return ImportRecord(
      id: id,
      fileName: fileName,
      rowCount: rowCount,
      sheetCount: sheetCount,
      createdAt: createdAt,
      jsonPreview: jsonPreview ?? this.jsonPreview,
      sheetNames: sheetNames,
      uploadHistory: uploadHistory,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ImportRecord.fromJson(String source) =>
      ImportRecord.fromMap(jsonDecode(source));
}