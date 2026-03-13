import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/import_record.dart';

class StorageService {
  static const String _recordsKey = 'import_records';

  Future<void> saveImportRecord(ImportRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getImportRecords();
    records.insert(0, record);

    final recordsJson = records.map((r) => r.toMap()).toList();
    final encoded = jsonEncode(recordsJson);
    await prefs.setString(_recordsKey, encoded);

    debugPrint('===== 保存导入记录 =====');
    debugPrint('记录ID: ${record.id}');
    debugPrint('文件名: ${record.fileName}');
    debugPrint('行数: ${record.rowCount}');
    debugPrint('总记录数: ${records.length}');
    debugPrint('保存的数据长度: ${encoded.length} 字符');
    debugPrint('======================');
  }

  Future<List<ImportRecord>> getImportRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString(_recordsKey);

    debugPrint('===== 读取导入记录 =====');
    debugPrint('存储Key: $_recordsKey');
    debugPrint('原始数据是否为空: ${recordsJson == null || recordsJson.isEmpty}');
    if (recordsJson != null) {
      debugPrint('原始数据长度: ${recordsJson.length} 字符');
    }

    if (recordsJson == null || recordsJson.isEmpty) {
      debugPrint('返回空列表');
      debugPrint('======================');
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(recordsJson);
      debugPrint('解码后的记录数: ${decoded.length}');

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

      debugPrint('成功解析的记录数: ${records.length}');
      for (var i = 0; i < records.length && i < 3; i++) {
        debugPrint('记录[$i]: ${records[i].fileName}, ${records[i].rowCount}行');
      }
      debugPrint('======================');
      return records;
    } catch (e, stackTrace) {
      debugPrint('解析JSON错误: $e');
      debugPrint('堆栈: $stackTrace');
      debugPrint('======================');
      return [];
    }
  }

  Future<void> deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getImportRecords();
    records.removeWhere((r) => r.id == id);

    final recordsJson = records.map((r) => r.toMap()).toList();
    await prefs.setString(_recordsKey, jsonEncode(recordsJson));
  }

  Future<void> updateRecord(ImportRecord updatedRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getImportRecords();

    final index = records.indexWhere((r) => r.id == updatedRecord.id);
    if (index != -1) {
      records[index] = updatedRecord;
      final recordsJson = records.map((r) => r.toMap()).toList();
      await prefs.setString(_recordsKey, jsonEncode(recordsJson));
    }
  }

  Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
  }
}