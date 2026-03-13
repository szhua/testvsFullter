import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/import_record.dart';
import '../services/excel_service.dart';
import 'records_screen.dart';
import '../main.dart';
import '../providers/locale_provider.dart';

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
  List<String> _editableHeaders = []; // 可编辑的headers
  bool _isUploading = false; // 上传状态

  Future<void> _pickAndImportExcel() async {
    setState(() => _isLoading = true);
    try {
      final record = await _excelService.importExcel();

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

        // 获取第一个sheet的headers用于编辑
        List<String> headers = [];
        if (parsedData != null && parsedData.isNotEmpty) {
          final firstSheet = parsedData.values.first;
          if (firstSheet is Map && firstSheet['headers'] is List) {
            headers = List<String>.from(firstSheet['headers']);
          }
        }

        setState(() {
          _lastRecord = record;
          _parsedData = parsedData ?? {};
          _selectedSheet = _parsedData?.keys.firstOrNull;
          _editableHeaders = headers;
        });

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showToast('${l10n.successfullyImported} ${record.fileName}', isError: false);
        }
      }
    } catch (e) {
      final errorStr = e.toString();
      String userMessage;

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        userMessage = l10n.importFailed;

        if (errorStr.contains('numFmtId') || errorStr.contains('custom number format')) {
          userMessage = l10n.unsupportedFormat;
        } else if (errorStr.contains('Invalid') || errorStr.contains('format') || errorStr.contains('OLE2')) {
          userMessage = l10n.unsupportedExcelFormat;
        }

        _showToast(userMessage, isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? const Color(0xFFCF222E) : const Color(0xFF1F883D),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.cancel_outlined : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyJsonToClipboard() {
    if (_parsedData == null) return;

    final jsonString = const JsonEncoder.withIndent('  ').convert(_parsedData);
    Clipboard.setData(ClipboardData(text: jsonString));

    final l10n = AppLocalizations.of(context)!;
    _showToast(l10n.jsonCopied, isError: false);
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
        final l10n = AppLocalizations.of(context)!;
        _showToast('${l10n.exportedTo}: $path', isError: false);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 显示编辑Header的对话框
  Future<void> _showEditHeadersDialog() async {
    if (_editableHeaders.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final controllers = _editableHeaders
        .map((h) => TextEditingController(text: h))
        .toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFFD0D7DE)),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit_outlined, color: Color(0xFF1F883D)),
            const SizedBox(width: 8),
            Text(l10n.editHeaders),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controllers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF57606A),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controllers[index],
                        decoration: InputDecoration(
                          hintText: '${l10n.column} ${index + 1}',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // 更新headers
      final newHeaders = controllers.map((c) => c.text.trim()).toList();

      // 更新parsedData中的headers
      if (_parsedData != null && _selectedSheet != null) {
        final sheetData = _parsedData![_selectedSheet];
        if (sheetData is Map<String, dynamic>) {
          final oldHeaders = sheetData['headers'] as List;
          final data = sheetData['data'] as List;

          // 创建映射
          final headerMap = <String, String>{};
          for (var i = 0; i < oldHeaders.length && i < newHeaders.length; i++) {
            headerMap[oldHeaders[i].toString()] = newHeaders[i];
          }

          // 更新data中的key
          final newData = data.map((row) {
            final newRow = <String, dynamic>{};
            (row as Map<String, dynamic>).forEach((key, value) {
              final newKey = headerMap[key] ?? key;
              newRow[newKey] = value;
            });
            return newRow;
          }).toList();

          // 更新状态
          setState(() {
            _editableHeaders = newHeaders;
            _parsedData![_selectedSheet!] = {
              'headers': newHeaders,
              'data': newData,
              'rowCount': sheetData['rowCount'],
            };
          });
        }
      }

      // 清理controllers
      for (var c in controllers) {
        c.dispose();
      }

      _showToast(l10n.headersUpdated, isError: false);
    }
  }

  /// 上传数据到服务器
  Future<void> _uploadToServer() async {
    if (_lastRecord == null || _parsedData == null) return;

    setState(() => _isUploading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      // 先更新记录的jsonPreview
      final updatedJsonPreview = jsonEncode(_parsedData);
      final updatedRecord = ImportRecord(
        id: _lastRecord!.id,
        fileName: _lastRecord!.fileName,
        rowCount: _lastRecord!.rowCount,
        sheetCount: _lastRecord!.sheetCount,
        importTime: _lastRecord!.importTime,
        jsonPreview: updatedJsonPreview,
        sheetNames: _lastRecord!.sheetNames,
        uploadStatus: UploadStatus.uploading,
      );

      // 上传到服务器
      final result = await _excelService.uploadRecordToServer(updatedRecord);

      setState(() {
        _lastRecord = result;
      });

      if (result.uploadStatus == UploadStatus.success) {
        if (mounted) _showToast(l10n.uploadSuccess, isError: false);
      } else {
        if (mounted) _showToast('${l10n.uploadFailed}: ${result.uploadError}', isError: true);
      }
    } catch (e) {
      if (mounted) _showToast('${l10n.uploadFailed}: $e', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFFD0D7DE)),
        ),
        title: Row(
          children: [
            const Icon(Icons.language, color: Color(0xFF1F883D)),
            const SizedBox(width: 8),
            Text(l10n.language),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context,
              locale: const Locale('en'),
              label: l10n.english,
              isSelected: localeProvider.isEnglish,
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              context,
              locale: const Locale('zh'),
              label: l10n.chinese,
              isSelected: localeProvider.isChinese,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required Locale locale,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        context.read<LocaleProvider>().setLocale(locale);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F883D).withValues(alpha: 0.1) : null,
          border: Border.all(
            color: isSelected ? const Color(0xFF1F883D) : const Color(0xFFD0D7DE),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF1F883D) : const Color(0xFF57606A),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF24292F) : const Color(0xFF57606A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.table_chart, size: 20, color: Color(0xFF24292F)),
            ),
            const SizedBox(width: 10),
            Text(l10n.appTitle),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _showLanguageDialog,
            icon: const Icon(Icons.language, size: 18),
            label: Text(l10n.language),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordsScreen()),
              );
            },
            icon: const Icon(Icons.history, size: 18),
            label: Text(l10n.history),
          ),
        ],
      ),
      body: _isLoading
          ? _GitHubLoading(processingText: l10n.processing)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  _buildHeroSection(l10n),
                  const SizedBox(height: 24),

                  // Import Card
                  _buildImportCard(l10n),
                  const SizedBox(height: 24),

                  // Results
                  if (_parsedData != null && _parsedData!.isNotEmpty)
                    _buildResultCard(l10n)
                  else if (_lastRecord != null)
                    _buildEmptyResultCard(l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF24292F), Color(0xFF32383F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF32383F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F883D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.version,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF57606A)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.stable,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.heroTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.heroDescription,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8B949E), height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatChip(Icons.insert_drive_file_outlined, l10n.supportedFormats),
              const SizedBox(width: 12),
              _buildStatChip(Icons.code_outlined, l10n.jsonOutput),
              const SizedBox(width: 12),
              _buildStatChip(Icons.cloud_upload_outlined, l10n.export),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8B949E)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard(AppLocalizations l10n) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFD0D7DE))),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F883D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.file_upload_outlined, size: 16, color: Color(0xFF1F883D)),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.importFile,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF24292F),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Drop zone
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD0D7DE), style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F883D).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_outlined, size: 24, color: Color(0xFF1F883D)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.dragDropHint,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF24292F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.orClickToBrowse,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF57606A)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _pickAndImportExcel,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: Text(l10n.chooseFile),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '.xlsx',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF57606A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '.csv',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF57606A)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(AppLocalizations l10n) {
    final sheets = _parsedData?.keys.toList() ?? [];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFD0D7DE))),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F883D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF1F883D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.importSuccessful,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF24292F),
                    ),
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _editableHeaders.isNotEmpty ? _showEditHeadersDialog : null,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(l10n.editHeaders),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _copyJsonToClipboard,
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: Text(l10n.copy),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _exportCurrentData,
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: Text(l10n.export),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // File info
          if (_lastRecord != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8FA),
                border: Border(bottom: BorderSide(color: Color(0xFFD0D7DE))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GitHubFileIcon(fileName: _lastRecord!.fileName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lastRecord!.fileName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF24292F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_lastRecord!.rowCount} ${l10n.rows} • ${_lastRecord!.sheetCount} ${l10n.sheets}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF57606A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Upload status and button
                  Row(
                    children: [
                      // Upload status badge
                      _buildUploadStatusBadge(_lastRecord!, l10n),
                      const Spacer(),
                      // Upload button
                      if (_isUploading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1F883D),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _lastRecord!.uploadStatus == UploadStatus.uploading
                              ? null
                              : _uploadToServer,
                          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: Text(l10n.uploadToServer),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _lastRecord!.uploadStatus == UploadStatus.success
                                ? const Color(0xFF1F883D)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Sheet tabs
          if (sheets.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFD0D7DE))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sheets.map((sheet) {
                    final isSelected = sheet == _selectedSheet;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSheet = sheet),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF6F8FA) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFD0D7DE) : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sheet,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? const Color(0xFF24292F) : const Color(0xFF57606A),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // JSON Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code_outlined, size: 16, color: Color(0xFF57606A)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.jsonOutputLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF57606A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D7DE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.json,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF57606A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildJsonPreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8C5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.warning_amber_outlined, color: Color(0xFF9A6700)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noValidDataFound,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF24292F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.fileContainsNoData(
                      _lastRecord!.fileName,
                      _lastRecord!.rowCount,
                    ),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF57606A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadStatusBadge(ImportRecord record, AppLocalizations l10n) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (record.uploadStatus) {
      case UploadStatus.pending:
        bgColor = const Color(0xFFF6F8FA);
        textColor = const Color(0xFF57606A);
        label = l10n.pending;
        icon = Icons.schedule;
        break;
      case UploadStatus.uploading:
        bgColor = const Color(0xFFFFF8C5);
        textColor = const Color(0xFF9A6700);
        label = l10n.uploading;
        icon = Icons.sync;
        break;
      case UploadStatus.success:
        bgColor = const Color(0xFFDAFBE1);
        textColor = const Color(0xFF1F883D);
        label = l10n.uploaded;
        icon = Icons.check_circle_outline;
        break;
      case UploadStatus.failed:
        bgColor = const Color(0xFFFFEBE9);
        textColor = const Color(0xFFCF222E);
        label = l10n.uploadFailed;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonPreview() {
    if (_selectedSheet == null || _parsedData == null) {
      return const SizedBox();
    }

    final sheetData = _parsedData![_selectedSheet];
    if (sheetData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'No data available',
          style: TextStyle(color: Color(0xFF57606A)),
        ),
      );
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(sheetData);

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '$_selectedSheet.json',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                jsonString,
                style: const TextStyle(
                  fontFamily: 'ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace',
                  color: Color(0xFFC9D1D9),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GitHubLoading extends StatelessWidget {
  final String processingText;

  const _GitHubLoading({required this.processingText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0D7DE)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F883D)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              processingText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF24292F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}