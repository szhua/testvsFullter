import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/import_record.dart';

class StorageService {
  static const String _recordsFileName = 'import_records.json';
  File? _recordsFile;

  Future<File> _getRecordsFile() async {
    if (_recordsFile != null) return _recordsFile!;

    final directory = await getApplicationDocumentsDirectory();
    _recordsFile = File(p.join(directory.path, _recordsFileName));
    return _recordsFile!;
  }

  Future<void> saveImportRecord(ImportRecord record) async {
    final records = await getImportRecords();
    records.insert(0, record);

    final recordsJson = records.map((r) => r.toMap()).toList();
    final encoded = jsonEncode(recordsJson);

    final file = await _getRecordsFile();
    await file.writeAsString(encoded);

    debugPrint('===== 保存导入记录 =====');
    debugPrint('记录ID: ${record.id}');
    debugPrint('文件名: ${record.fileName}');
    debugPrint('行数: ${record.rowCount}');
    debugPrint('总记录数: ${records.length}');
    debugPrint('保存路径: ${file.path}');
    debugPrint('======================');
  }

  Future<List<ImportRecord>> getImportRecords() async {
    try {
      final file = await _getRecordsFile();

      if (!await file.exists()) {
        debugPrint('记录文件不存在，返回空列表');
        return [];
      }

      final recordsJson = await file.readAsString();

      if (recordsJson.isEmpty) {
        debugPrint('记录文件为空');
        return [];
      }

      final List<dynamic> decoded = jsonDecode(recordsJson);
      debugPrint('读取到 ${decoded.length} 条记录');

      final records = decoded
          .where((r) => r != null)
          .map((r) {
            try {
              return ImportRecord.fromMap(r as Map<String, dynamic>);
            } catch (e) {
              debugPrint('解析单条记录错误: $e');
              return null;
            }
          })
          .whereType<ImportRecord>()
          .toList();

      debugPrint('成功解析 ${records.length} 条记录');
      return records;
    } catch (e, stackTrace) {
      debugPrint('读取记录错误: $e');
      debugPrint('堆栈: $stackTrace');
      return [];
    }
  }

  Future<void> deleteRecord(String id) async {
    final records = await getImportRecords();
    records.removeWhere((r) => r.id == id);

    final recordsJson = records.map((r) => r.toMap()).toList();
    final file = await _getRecordsFile();
    await file.writeAsString(jsonEncode(recordsJson));
  }

  Future<void> updateRecord(ImportRecord updatedRecord) async {
    final records = await getImportRecords();

    final index = records.indexWhere((r) => r.id == updatedRecord.id);
    if (index != -1) {
      records[index] = updatedRecord;
      final recordsJson = records.map((r) => r.toMap()).toList();
      final file = await _getRecordsFile();
      await file.writeAsString(jsonEncode(recordsJson));
    }
  }

  Future<void> clearRecords() async {
    final file = await _getRecordsFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 获取存储文件路径
  Future<String> getStoragePath() async {
    final file = await _getRecordsFile();
    return file.path;
  }
}