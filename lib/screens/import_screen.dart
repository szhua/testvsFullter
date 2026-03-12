import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/import_record.dart';
import '../services/excel_service.dart';
import 'records_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final ExcelService _excelService = ExcelService();
  Map<String, dynamic>? _parsedData;
  String? _selectedSheet;
  bool _isLoading = false;
  ImportRecord? _lastRecord;

  Future<void> _pickAndImportExcel() async {
    setState(() => _isLoading = true);
    try {
      final record = await _excelService.importExcel();
      debugPrint('导入记录: ${record?.fileName}, 行数: ${record?.rowCount}, Sheet数: ${record?.sheetCount}');
      debugPrint('JSON预览长度: ${record?.jsonPreview?.length ?? 0}');

      if (record != null) {
        Map<String, dynamic>? parsedData;
        try {
          final jsonStr = record.jsonPreview ?? '{}';
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map<String, dynamic>) {
            parsedData = decoded;
          }
        } catch (e) {
          debugPrint('JSON解析错误: $e');
        }

        setState(() {
          _lastRecord = record;
          _parsedData = parsedData ?? {};
          _selectedSheet = _parsedData?.keys.firstOrNull;
        });
        debugPrint('解析后的数据: $_parsedData');
        debugPrint('选中的sheet: $_selectedSheet');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功导入: ${record.fileName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('导入错误: $e');
      final errorStr = e.toString();

      // 解析错误类型并给出友好提示
      String userMessage = '导入失败: $e';
      if (errorStr.contains('numFmtId') || errorStr.contains('custom number format')) {
        userMessage = 'Excel文件包含自定义数字格式，不被支持。\n解决方法：请用Excel打开文件，另存为"Excel工作簿(*.xlsx)"格式后重试。';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyJsonToClipboard() {
    if (_parsedData == null) return;

    final jsonString = const JsonEncoder.withIndent('  ').convert(_parsedData);
    Clipboard.setData(ClipboardData(text: jsonString));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON已复制到剪贴板')),
    );
  }

  Future<void> _exportCurrentData() async {
    if (_parsedData == null) return;

    setState(() => _isLoading = true);
    try {
      final path = await _excelService.exportJsonToExcel(
        _parsedData!,
        customFileName: 'exported_${_lastRecord?.fileName ?? 'data'}.xlsx',
      );
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到: $path')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel导入工具'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '查看记录',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '导入Excel文件',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '支持 .xlsx 和 .xls 格式',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickAndImportExcel,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('选择Excel文件'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_parsedData != null && _parsedData!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildResultCard(),
                  ] else if (_lastRecord != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '导入结果',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('文件: ${_lastRecord!.fileName}'),
                                  Text('总行数: ${_lastRecord!.rowCount}'),
                                  Text('工作表数: ${_lastRecord!.sheetCount}'),
                                  const SizedBox(height: 8),
                                  const Text('⚠️ Excel文件没有有效数据或工作表为空',
                                      style: TextStyle(color: Colors.orange)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildResultCard() {
    final sheets = _parsedData?.keys.toList() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '导入结果',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _copyJsonToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('复制JSON'),
                    ),
                    TextButton.icon(
                      onPressed: _exportCurrentData,
                      icon: const Icon(Icons.download),
                      label: const Text('导出Excel'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_lastRecord != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('文件: ${_lastRecord!.fileName}'),
                    Text('总行数: ${_lastRecord!.rowCount}'),
                    Text('工作表数: ${_lastRecord!.sheetCount}'),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (sheets.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Excel文件为空或没有有效数据', style: TextStyle(color: Colors.grey)),
              )
            else ...[
              if (sheets.length > 1)
                DropdownButton<String>(
                  value: _selectedSheet,
                  isExpanded: true,
                  items: sheets.map((sheet) {
                    return DropdownMenuItem(
                      value: sheet,
                      child: Text(sheet),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSheet = value);
                  },
                ),
              const SizedBox(height: 16),
              const Text(
                'JSON预览:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildJsonPreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJsonPreview() {
    if (_selectedSheet == null || _parsedData == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('请选择一个工作表'),
      );
    }

    final sheetData = _parsedData![_selectedSheet];
    if (sheetData == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('工作表数据为空'),
      );
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(sheetData);

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          jsonString,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.lightGreenAccent,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}