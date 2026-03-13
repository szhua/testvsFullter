import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/import_record.dart';

class StorageService {
  static const String _recordsKey = 'import_records';
  static const String _recordsFileName = 'import_records.json';
  File? _recordsFile;

  Future<List<ImportRecord>> getImportRecords() async {
    try {
      final recordsJson = await _readRecordsData();

      if (recordsJson.isEmpty) {
        debugPrint('记录为空');
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

  Future<String> _readRecordsData() async {
    if (kIsWeb) {
      // Web 平台使用 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_recordsKey) ?? '';
    } else {
      // 桌面平台使用文件
      final file = await _getRecordsFile();
      if (!await file.exists()) {
        return '';
      }
      return await file.readAsString();
    }
  }

  Future<void> _writeRecordsData(String data) async {
    if (kIsWeb) {
      // Web 平台使用 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recordsKey, data);
    } else {
      // 桌面平台使用文件
      final file = await _getRecordsFile();
      await file.writeAsString(data);
    }
  }

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

    await _writeRecordsData(encoded);

    debugPrint('===== 保存导入记录 =====');
    debugPrint('记录ID: ${record.id}');
    debugPrint('文件名: ${record.fileName}');
    debugPrint('行数: ${record.rowCount}');
    debugPrint('总记录数: ${records.length}');
    debugPrint('======================');
  }

  Future<void> deleteRecord(String id) async {
    final records = await getImportRecords();
    records.removeWhere((r) => r.id == id);

    final recordsJson = records.map((r) => r.toMap()).toList();
    await _writeRecordsData(jsonEncode(recordsJson));
  }

  Future<void> updateRecord(ImportRecord updatedRecord) async {
    final records = await getImportRecords();

    final index = records.indexWhere((r) => r.id == updatedRecord.id);
    if (index != -1) {
      records[index] = updatedRecord;
      final recordsJson = records.map((r) => r.toMap()).toList();
      await _writeRecordsData(jsonEncode(recordsJson));
    }
  }

  Future<void> clearRecords() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recordsKey);
    } else {
      final file = await _getRecordsFile();
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// 获取存储路径（仅桌面平台有效）
  Future<String?> getStoragePath() async {
    if (kIsWeb) {
      return null;
    }
    final file = await _getRecordsFile();
    return file.path;
  }
}