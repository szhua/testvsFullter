import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import 'package:archive/archive.dart';
import '../models/import_record.dart';
import 'storage_service.dart';

class ExcelService {
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>?> pickAndReadExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          if (file.name.toLowerCase().endsWith('.csv')) {
            return parseCsvBytes(file.bytes!, file.name);
          }
          return parseExcelBytes(file.bytes!, file.name);
        }
      }
      return null;
    } catch (e) {
      debugPrint('选择文件错误: $e');
      return null;
    }
  }

  Map<String, dynamic> parseCsvBytes(Uint8List bytes, String fileName, {int headerRow = 0}) {
    final String csvString = utf8.decode(bytes);
    return parseCsvString(csvString, fileName, headerRow: headerRow);
  }

  Map<String, dynamic> parseCsvString(String csvString, String fileName, {int headerRow = 0}) {
    // 检测分隔符：优先检测制表符，其次逗号
    final lines = csvString.split('\n');
    final firstLine = lines.isNotEmpty ? lines[0] : '';
    final tabCount = '\t'.allMatches(firstLine).length;
    final commaCount = ','.allMatches(firstLine).length;
    final fieldDelimiter = tabCount >= commaCount ? '\t' : ',';

    debugPrint('CSV分隔符检测: ${fieldDelimiter == '\t' ? 'Tab' : '逗号'}');

    final List<List<dynamic>> csvData = const CsvToListConverter()
        .convert(csvString, fieldDelimiter: fieldDelimiter);

    final Map<String, dynamic> result = {
      'fileName': fileName,
      'sheets': <String, dynamic>{},
      'totalRows': 0,
      'sheetNames': <String>['Sheet1'],
    };

    if (csvData.isEmpty) {
      return result;
    }

    final List<String> headers = [];
    final List<Map<String, dynamic>> sheetData = [];

    // 获取表头 - 使用指定的行（默认第一行，索引0）
    if (headerRow < csvData.length) {
      final headerRowData = csvData[headerRow];
      for (var col = 0; col < headerRowData.length; col++) {
        headers.add(headerRowData[col]?.toString().trim() ?? 'Column$col');
      }
    }
    debugPrint('CSV表头(第${headerRow + 1}行): $headers');

    // 解析数据行 - 跳过表头行之前的行和表头行本身
    for (var rowIdx = headerRow + 1; rowIdx < csvData.length; rowIdx++) {
      final row = csvData[rowIdx];
      // 跳过空行
      if (row.every((cell) => cell?.toString().trim().isEmpty ?? true)) {
        continue;
      }

      final Map<String, dynamic> rowData = {};
      for (var col = 0; col < headers.length; col++) {
        final value = col < row.length ? row[col] : null;
        rowData[headers[col]] = value?.toString().trim() ?? '';
      }
      sheetData.add(rowData);
    }

    result['sheets']['Sheet1'] = {
      'headers': headers,
      'data': sheetData,
      'rowCount': sheetData.length,
    };
    result['totalRows'] = sheetData.length;

    debugPrint('CSV文件解析完成: $fileName, 表头数: ${headers.length}, 数据行数: ${sheetData.length}');
    return result;
  }

  /// 使用XML直接解析xlsx文件（绑过numFmtId验证问题）
  Map<String, dynamic> parseExcelBytes(Uint8List bytes, String fileName, {int headerRow = 0}) {
    try {
      return _parseXlsxXml(bytes, fileName, headerRow: headerRow);
    } catch (e, stackTrace) {
      debugPrint('Excel解析错误: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> _parseXlsxXml(Uint8List bytes, String fileName, {int headerRow = 0}) {
    final Map<String, dynamic> result = {
      'fileName': fileName,
      'sheets': <String, dynamic>{},
      'totalRows': 0,
      'sheetNames': <String>[],
    };

    // 解压xlsx文件（xlsx本质是zip文件）
    final archive = ZipDecoder().decodeBytes(bytes.toList());

    // 读取共享字符串
    final Map<int, String> sharedStrings = {};
    ArchiveFile? sharedStringsFile;
    for (final file in archive) {
      if (file.name == 'xl/sharedStrings.xml') {
        sharedStringsFile = file;
        break;
      }
    }

    if (sharedStringsFile != null) {
      final content = utf8.decode(sharedStringsFile.content as List<int>);
      final doc = XmlDocument.parse(content);
      final siElements = doc.findAllElements('si');
      int index = 0;
      for (final si in siElements) {
        final tElements = si.findElements('t');
        if (tElements.isNotEmpty) {
          sharedStrings[index] = tElements.first.innerText;
        } else {
          // 处理富文本
          final rElements = si.findElements('r');
          String text = '';
          for (final r in rElements) {
            final tInR = r.findElements('t');
            if (tInR.isNotEmpty) {
              text += tInR.first.innerText;
            }
          }
          sharedStrings[index] = text;
        }
        index++;
      }
      debugPrint('读取到 ${sharedStrings.length} 个共享字符串');
    }

    // 读取工作表
    int totalRows = 0;
    for (final file in archive) {
      if (file.name.startsWith('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
        final sheetName = 'Sheet${file.name.replaceAll(RegExp(r'[^0-9]'), '')}';

        final content = utf8.decode(file.content as List<int>);
        final doc = XmlDocument.parse(content);

        final sheetDataElement = doc.findAllElements('sheetData').firstOrNull;
        if (sheetDataElement == null) continue;

        final rows = sheetDataElement.findElements('row');
        if (rows.isEmpty) continue;

        result['sheetNames'].add(sheetName);

        // 收集所有行数据
        final List<List<String>> allRows = [];
        int maxCols = 0;

        for (final row in rows) {
          final cells = row.findElements('c');
          final Map<int, String> rowData = {};

          for (final cell in cells) {
            final ref = cell.getAttribute('r') ?? '';
            final colIndex = _colRefToIndex(ref);
            final type = cell.getAttribute('t');

            String value = '';
            final vElement = cell.findElements('v').firstOrNull;

            if (vElement != null) {
              if (type == 's') {
                // 共享字符串
                final si = int.tryParse(vElement.innerText);
                if (si != null && sharedStrings.containsKey(si)) {
                  value = sharedStrings[si]!;
                }
              } else if (type == 'inlineStr') {
                // 内联字符串
                final tElement = cell.findAllElements('t').firstOrNull;
                if (tElement != null) {
                  value = tElement.innerText;
                }
              } else {
                // 数值或其他
                value = vElement.innerText;
              }
            }

            rowData[colIndex] = value;
            if (colIndex + 1 > maxCols) {
              maxCols = colIndex + 1;
            }
          }

          // 转换为列表
          final rowList = List<String>.filled(maxCols, '');
          rowData.forEach((idx, val) {
            if (idx < maxCols) rowList[idx] = val;
          });
          allRows.add(rowList);
        }

        // 确定表头行
        if (allRows.isEmpty) continue;

        final List<String> headers = [];
        // 更新 maxCols 到当前行数
        for (var r in allRows) {
          if (r.length > maxCols) maxCols = r.length;
        }

        if (headerRow < allRows.length) {
          // 确保headers长度正确
          final headerRowData = allRows[headerRow];
          for (var col = 0; col < headerRowData.length; col++) {
            final h = headerRowData[col].trim();
            headers.add(h.isEmpty ? 'Column$col' : h);
          }
        }

        // 解析数据行
        final List<Map<String, dynamic>> sheetData = [];
        for (var rowIdx = headerRow + 1; rowIdx < allRows.length; rowIdx++) {
          final row = allRows[rowIdx];
          // 跳过空行
          if (row.every((cell) => cell.trim().isEmpty)) continue;

          final Map<String, dynamic> rowData = {};
          for (var col = 0; col < headers.length; col++) {
            rowData[headers[col]] = col < row.length ? row[col].trim() : '';
          }
          sheetData.add(rowData);
        }

        result['sheets'][sheetName] = {
          'headers': headers,
          'data': sheetData,
          'rowCount': sheetData.length,
        };

        debugPrint('工作表 $sheetName 解析完成，表头数: ${headers.length}, 数据行数: ${sheetData.length}');
        totalRows += sheetData.length;
      }
    }

    result['totalRows'] = totalRows;
    debugPrint('xlsx XML解析完成: $fileName, 总行数: $totalRows');
    return result;
  }

  /// 将列引用（如 A1, B2）转换为列索引
  int _colRefToIndex(String ref) {
    final match = RegExp(r'^([A-Z]+)').firstMatch(ref.toUpperCase());
    if (match == null) return 0;

    final colStr = match.group(1)!;
    int index = 0;
    for (var i = 0; i < colStr.length; i++) {
      index = index * 26 + (colStr.codeUnitAt(i) - 64);
    }
    return index - 1; // A = 0
  }

  Future<ImportRecord?> importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          Map<String, dynamic> data;

          // 根据文件扩展名选择解析方式
          if (file.name.toLowerCase().endsWith('.csv')) {
            data = parseCsvBytes(file.bytes!, file.name);
          } else {
            data = parseExcelBytes(file.bytes!, file.name);
          }

          final record = ImportRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            fileName: file.name,
            rowCount: data['totalRows'] as int,
            sheetCount: (data['sheetNames'] as List).length,
            importTime: DateTime.now(),
            jsonPreview: const JsonEncoder.withIndent('  ').convert(data['sheets']),
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
      final workbook = Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = '导入记录';

      // 添加表头
      final headers = ['序号', '文件名', '工作表数', '行数', '导入时间', '工作表名称'];
      for (var col = 0; col < headers.length; col++) {
        sheet.getRangeByIndex(1, col + 1).setText(headers[col]);
      }

      // 添加数据行
      for (var i = 0; i < records.length; i++) {
        final record = records[i];
        final row = i + 2;

        sheet.getRangeByIndex(row, 1).setNumber((i + 1).toDouble());
        sheet.getRangeByIndex(row, 2).setText(record.fileName);
        sheet.getRangeByIndex(row, 3).setNumber(record.sheetCount.toDouble());
        sheet.getRangeByIndex(row, 4).setNumber(record.rowCount.toDouble());
        sheet.getRangeByIndex(row, 5).setText(
          '${record.importTime.year}-${record.importTime.month.toString().padLeft(2, '0')}-${record.importTime.day.toString().padLeft(2, '0')} ${record.importTime.hour.toString().padLeft(2, '0')}:${record.importTime.minute.toString().padLeft(2, '0')}:${record.importTime.second.toString().padLeft(2, '0')}',
        );
        sheet.getRangeByIndex(row, 6).setText(record.sheetNames.join(', '));
      }

      // 保存文件
      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toString()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final filePath = p.join(directory.path, 'import_records_$timestamp.xlsx');

      final bytes = workbook.saveSync();
      workbook.dispose();

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('导出记录错误: $e');
      return null;
    }
  }

  Future<String?> exportJsonToExcel(
    Map<String, dynamic> jsonData, {
    String? customFileName,
  }) async {
    try {
      final workbook = Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = '数据';

      // 获取第一个sheet的数据
      final firstSheetKey = jsonData.keys.first;
      final sheetData = jsonData[firstSheetKey] as Map<String, dynamic>;
      final headers = List<String>.from(sheetData['headers'] as List);
      final data = List<Map<String, dynamic>>.from(sheetData['data'] as List);

      // 写入表头
      for (var col = 0; col < headers.length; col++) {
        sheet.getRangeByIndex(1, col + 1).setText(headers[col]);
      }

      // 写入数据
      for (var rowIdx = 0; rowIdx < data.length; rowIdx++) {
        final row = data[rowIdx];
        final excelRow = rowIdx + 2;

        for (var colIdx = 0; colIdx < headers.length; colIdx++) {
          final value = row[headers[colIdx]];
          sheet.getRangeByIndex(excelRow, colIdx + 1).setText(value?.toString() ?? '');
        }
      }

      // 保存文件
      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toString()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = customFileName ?? 'exported_data_$timestamp.xlsx';
      final filePath = p.join(
        directory.path,
        fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx',
      );

      final bytes = workbook.saveSync();
      workbook.dispose();

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('导出JSON到Excel错误: $e');
      return null;
    }
  }
}