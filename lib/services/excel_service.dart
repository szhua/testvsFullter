import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/import_record.dart';
import 'storage_service.dart';

class ExcelService {
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>?> pickAndReadExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          return parseExcelBytes(file.bytes!, file.name);
        }
      }
      return null;
    } catch (e) {
      // Error picking Excel file
      return null;
    }
  }

  Map<String, dynamic> parseExcelBytes(Uint8List bytes, String fileName) {
    final excel = Excel.decodeBytes(bytes);
    return _parseExcelData(excel, fileName);
  }

  Map<String, dynamic> _parseExcelData(Excel excel, String fileName) {
    final Map<String, dynamic> result = {
      'fileName': fileName,
      'sheets': <String, dynamic>{},
      'totalRows': 0,
      'sheetNames': <String>[],
    };

    int totalRows = 0;

    debugPrint('Excel文件: $fileName');
    debugPrint('工作表数量: ${excel.tables.length}');
    debugPrint('工作表名称: ${excel.tables.keys.toList()}');

    for (final tableName in excel.tables.keys) {
      final sheet = excel.tables[tableName];
      if (sheet == null) {
        debugPrint('工作表 $tableName 为空，跳过');
        continue;
      }

      debugPrint('处理工作表: $tableName, 行数: ${sheet.rows.length}');

      result['sheetNames'].add(tableName);
      final List<Map<String, dynamic>> sheetData = [];
      final List<String> headers = [];

      // 获取表头 - 从第一行获取列数
      if (sheet.rows.isNotEmpty) {
        final firstRow = sheet.rows[0];
        for (var col = 0; col < firstRow.length; col++) {
          final cell = firstRow[col];
          final headerValue = cell?.value;
          if (headerValue == null) {
            headers.add('Column$col');
          } else {
            headers.add(headerValue.toString());
          }
        }
        debugPrint('表头: $headers');
      }

      // 解析数据行
      for (var rowIdx = 1; rowIdx < sheet.rows.length; rowIdx++) {
        final row = sheet.rows[rowIdx];
        final Map<String, dynamic> rowData = {};

        for (var col = 0; col < headers.length; col++) {
          final cell = col < row.length ? row[col] : null;
          final value = cell?.value;
          // 处理各种可能的null情况
          if (value == null) {
            rowData[headers[col]] = '';
          } else {
            rowData[headers[col]] = value.toString();
          }
        }

        sheetData.add(rowData);
      }

      result['sheets'][tableName] = {
        'headers': headers,
        'data': sheetData,
        'rowCount': sheetData.length,
      };

      debugPrint('工作表 $tableName 解析完成，数据行数: ${sheetData.length}');

      totalRows += sheetData.length;
    }

    result['totalRows'] = totalRows;
    debugPrint('总行数: $totalRows');
    return result;
  }

  Future<ImportRecord?> importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final data = parseExcelBytes(file.bytes!, file.name);

          final record = ImportRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            fileName: file.name,
            rowCount: data['totalRows'] as int,
            sheetCount: (data['sheetNames'] as List).length,
            importTime: DateTime.now(),
            jsonPreview: const JsonEncoder.withIndent('  ')
                .convert(data['sheets']),
            sheetNames: List<String>.from(data['sheetNames']),
          );

          await _storageService.saveImportRecord(record);
          return record;
        } else {
          throw Exception('无法读取文件内容 - bytes 为空');
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('导入Excel错误: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  Future<List<ImportRecord>> getImportRecords() async {
    return await _storageService.getImportRecords();
  }

  Future<void> clearRecords() async {
    await _storageService.clearRecords();
  }

  Future<void> deleteRecord(String id) async {
    await _storageService.deleteRecord(id);
  }

  Future<String?> exportRecordsToExcel(List<ImportRecord> records) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['导入记录'];

      // 添加表头
      final headers = ['序号', '文件名', '工作表数', '行数', '导入时间', '工作表名称'];
      for (var col = 0; col < headers.length; col++) {
        sheet
            .cell(CellIndex.indexByString('${String.fromCharCode(65 + col)}1'))
            .value = TextCellValue(headers[col]);
      }

      // 添加数据行
      for (var i = 0; i < records.length; i++) {
        final record = records[i];
        final row = i + 2;

        sheet.cell(CellIndex.indexByString('A$row')).value =
            IntCellValue(i + 1);
        sheet.cell(CellIndex.indexByString('B$row')).value =
            TextCellValue(record.fileName);
        sheet.cell(CellIndex.indexByString('C$row')).value =
            IntCellValue(record.sheetCount);
        sheet.cell(CellIndex.indexByString('D$row')).value =
            IntCellValue(record.rowCount);
        sheet.cell(CellIndex.indexByString('E$row')).value =
            TextCellValue(
                '${record.importTime.year}-${record.importTime.month.toString().padLeft(2, '0')}-${record.importTime.day.toString().padLeft(2, '0')} ${record.importTime.hour.toString().padLeft(2, '0')}:${record.importTime.minute.toString().padLeft(2, '0')}:${record.importTime.second.toString().padLeft(2, '0')}');
        sheet.cell(CellIndex.indexByString('F$row')).value =
            TextCellValue(record.sheetNames.join(', '));
      }

      // 保存文件
      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final timestamp =
          DateTime.now().toString().replaceAll(':', '-').split('.').first;
      final filePath =
          p.join(directory.path, 'import_records_$timestamp.xlsx');

      final bytes = excel.encode();
      if (bytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      }
      return null;
    } catch (e) {
      // Error exporting records
      return null;
    }
  }

  Future<String?> exportJsonToExcel(Map<String, dynamic> jsonData,
      {String? customFileName}) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['数据'];

      // 获取第一个sheet的数据
      final firstSheetKey = jsonData.keys.first;
      final sheetData = jsonData[firstSheetKey] as Map<String, dynamic>;
      final headers = List<String>.from(sheetData['headers'] as List);
      final data = List<Map<String, dynamic>>.from(sheetData['data'] as List);

      // 写入表头
      for (var col = 0; col < headers.length; col++) {
        sheet
            .cell(CellIndex.indexByString('${String.fromCharCode(65 + col)}1'))
            .value = TextCellValue(headers[col]);
      }

      // 写入数据
      for (var rowIdx = 0; rowIdx < data.length; rowIdx++) {
        final row = data[rowIdx];
        final excelRow = rowIdx + 2;

        for (var colIdx = 0; colIdx < headers.length; colIdx++) {
          final cellRef =
              '${String.fromCharCode(65 + colIdx)}$excelRow';
          final value = row[headers[colIdx]];
          sheet.cell(CellIndex.indexByString(cellRef)).value =
              TextCellValue(value?.toString() ?? '');
        }
      }

      // 保存文件
      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final timestamp =
          DateTime.now().toString().replaceAll(':', '-').split('.').first;
      final fileName = customFileName ?? 'exported_data_$timestamp.xlsx';
      final filePath =
          p.join(directory.path, fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx');

      final bytes = excel.encode();
      if (bytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      }
      return null;
    } catch (e) {
      // Error exporting JSON to Excel
      return null;
    }
  }
}