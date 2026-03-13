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
  final DateTime uploadTime;  // 上传时间（改为上传成功的时间）
  final String? jsonPreview;
  final List<String> sheetNames;
  final UploadStatus uploadStatus;
  final String? uploadError;
  final List<String> headers;  // 修改后的表头
  final String? serverResponse;  // 服务器返回的数据

  ImportRecord({
    required this.id,
    required this.fileName,
    required this.rowCount,
    required this.sheetCount,
    required this.uploadTime,
    this.jsonPreview,
    required this.sheetNames,
    this.uploadStatus = UploadStatus.pending,
    this.uploadError,
    this.headers = const [],
    this.serverResponse,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'rowCount': rowCount,
      'sheetCount': sheetCount,
      'uploadTime': uploadTime.toIso8601String(),
      'jsonPreview': jsonPreview,
      'sheetNames': sheetNames,
      'uploadStatus': uploadStatus.name,
      'uploadError': uploadError,
      'headers': headers,
      'serverResponse': serverResponse,
    };
  }

  factory ImportRecord.fromMap(Map<String, dynamic> map) {
    return ImportRecord(
      id: map['id']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? '',
      rowCount: map['rowCount'] as int? ?? 0,
      sheetCount: map['sheetCount'] as int? ?? 0,
      uploadTime: map['uploadTime'] != null
          ? DateTime.tryParse(map['uploadTime'].toString()) ?? DateTime.now()
          : map['importTime'] != null  // 兼容旧数据
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
      headers: map['headers'] != null
          ? List<String>.from(map['headers'] as List)
          : [],
      serverResponse: map['serverResponse']?.toString(),
    );
  }

  /// 创建带有更新上传状态的副本
  ImportRecord copyWith({
    UploadStatus? uploadStatus,
    String? uploadError,
    DateTime? uploadTime,
    List<String>? headers,
    String? serverResponse,
    String? jsonPreview,
  }) {
    return ImportRecord(
      id: id,
      fileName: fileName,
      rowCount: rowCount,
      sheetCount: sheetCount,
      uploadTime: uploadTime ?? this.uploadTime,
      jsonPreview: jsonPreview ?? this.jsonPreview,
      sheetNames: sheetNames,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadError: uploadError ?? this.uploadError,
      headers: headers ?? this.headers,
      serverResponse: serverResponse ?? this.serverResponse,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ImportRecord.fromJson(String source) =>
      ImportRecord.fromMap(jsonDecode(source));
}