import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/import_record.dart';

class StorageService {
  static const String _recordsKey = 'import_records';

  Future<void> saveImportRecord(ImportRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getImportRecords();
    records.insert(0, record);

    final recordsJson =
        records.map((r) => r.toJson()).toList();
    await prefs.setString(_recordsKey, jsonEncode(recordsJson));
  }

  Future<List<ImportRecord>> getImportRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getString(_recordsKey);

    if (recordsJson == null || recordsJson.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(recordsJson);
      return decoded
          .where((r) => r != null)
          .map((r) {
            try {
              return ImportRecord.fromMap(r as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .whereType<ImportRecord>()
          .toList();
    } catch (e) {
      // Error loading records
      return [];
    }
  }

  Future<void> deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getImportRecords();
    records.removeWhere((r) => r.id == id);

    final recordsJson =
        records.map((r) => r.toJson()).toList();
    await prefs.setString(_recordsKey, jsonEncode(recordsJson));
  }

  Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
  }
}