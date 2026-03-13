import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/import_record.dart';
import '../services/excel_service.dart';
import '../main.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final ExcelService _excelService = ExcelService();
  List<ImportRecord> _records = [];
  bool _isLoading = true;
  final Map<String, bool> _uploadingIds = {}; // 记录正在上传的ID

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await _excelService.getImportRecords();
      setState(() => _records = records);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshRecords() async {
    final l10n = AppLocalizations.of(context)!;
    await _loadRecords();
    if (mounted) {
      _showToast(l10n.refreshed, isError: false);
    }
  }

  Future<void> _exportRecords() async {
    final l10n = AppLocalizations.of(context)!;
    if (_records.isEmpty) {
      _showToast(l10n.noRecordsToExport, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final path = await _excelService.exportRecordsToExcel(_records);
      if (path != null && mounted) {
        _showToast('${l10n.exportedTo}: $path', isError: false);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearRecords() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFFD0D7DE)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFF9A6700)),
            const SizedBox(width: 8),
            Text(l10n.clearAllRecords),
          ],
        ),
        content: Text(
          l10n.clearAllConfirm,
          style: const TextStyle(fontSize: 14, color: Color(0xFF57606A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFCF222E),
            ),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _excelService.clearRecords();
      await _loadRecords();
      if (mounted) {
        _showToast(l10n.allRecordsCleared, isError: false);
      }
    }
  }

  Future<void> _deleteRecord(String id) async {
    final l10n = AppLocalizations.of(context)!;
    await _excelService.deleteRecord(id);
    await _loadRecords();
    if (mounted) {
      _showToast(l10n.recordDeleted, isError: false);
    }
  }

  /// 显示数据详情弹窗
  Future<void> _showDataDetail(ImportRecord record) async {
    final l10n = AppLocalizations.of(context)!;

    // 解析JSON数据
    Map<String, dynamic>? sheetsData;
    if (record.jsonPreview != null && record.jsonPreview!.isNotEmpty) {
      try {
        sheetsData = jsonDecode(record.jsonPreview!) as Map<String, dynamic>;
      } catch (e) {
        _showToast(l10n.noValidDataFound, isError: true);
        return;
      }
    }

    if (sheetsData == null || sheetsData.isEmpty) {
      _showToast(l10n.noValidDataFound, isError: true);
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => _DataDetailDialog(
        record: record,
        sheetsData: sheetsData!,
        l10n: l10n,
        onEditAndUpload: (updatedData, newHeaders) async {
          Navigator.pop(context);
          setState(() {
            _uploadingIds[record.id] = true;
          });

          try {
            // 创建更新后的记录
            final updatedRecord = record.copyWith(
              jsonPreview: const JsonEncoder.withIndent('  ').convert(updatedData),
              headers: newHeaders,
            );

            final result = await _excelService.reuploadRecord(updatedRecord, updatedData: updatedData);
            await _loadRecords();

            if (mounted) {
              if (result.uploadStatus == UploadStatus.success) {
                _showToast(l10n.uploadSuccess, isError: false);
              } else {
                _showToast('${l10n.uploadFailed}: ${result.uploadError}', isError: true);
              }
            }
          } finally {
            setState(() {
              _uploadingIds.remove(record.id);
            });
          }
        },
      ),
    );
  }

  /// 直接重新上传
  Future<void> _reupload(ImportRecord record) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _uploadingIds[record.id] = true;
    });

    try {
      final updatedRecord = await _excelService.reuploadRecord(record);
      await _loadRecords();

      if (mounted) {
        if (updatedRecord.uploadStatus == UploadStatus.success) {
          _showToast(l10n.uploadSuccess, isError: false);
        } else {
          _showToast('${l10n.uploadFailed}: ${updatedRecord.uploadError}', isError: true);
        }
      }
    } finally {
      setState(() {
        _uploadingIds.remove(record.id);
      });
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
              child: const Icon(Icons.history, size: 20, color: Color(0xFF24292F)),
            ),
            const SizedBox(width: 10),
            Text(l10n.importHistory),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _refreshRecords,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.refresh),
          ),
          if (_records.isNotEmpty) ...[
            TextButton.icon(
              onPressed: _exportRecords,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: Text(l10n.export),
            ),
            TextButton.icon(
              onPressed: _clearRecords,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(l10n.clear),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFCF222E),
              ),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1F883D),
              ),
            )
          : _records.isEmpty
              ? _buildEmptyState(l10n)
              : _buildRecordsList(l10n),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0D7DE)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 32,
                color: Color(0xFF8B949E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noImportHistory,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF24292F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.importedFilesWillAppear,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF57606A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(AppLocalizations l10n) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final dateFormat = isZh ? DateFormat('yyyy年MM月dd日') : DateFormat('MMM d, yyyy');
    final timeFormat = isZh ? DateFormat('HH:mm') : DateFormat('h:mm a');

    return Column(
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFD0D7DE)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, size: 16, color: Color(0xFF57606A)),
              const SizedBox(width: 8),
              Text(
                l10n.recordsCount(_records.length),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF24292F),
                ),
              ),
              const Spacer(),
              Text(
                l10n.totalRowsCount(_records.fold<int>(0, (sum, r) => sum + r.rowCount)),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF57606A),
                ),
              ),
            ],
          ),
        ),

        // Records list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final record = _records[index];
              return _buildRecordCard(record, l10n, dateFormat, timeFormat, isZh);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(
    ImportRecord record,
    AppLocalizations l10n,
    DateFormat dateFormat,
    DateFormat timeFormat,
    bool isZh,
  ) {
    final isUploading = _uploadingIds[record.id] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D7DE)),
      ),
      child: Dismissible(
        key: Key(record.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBE9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Color(0xFFCF222E),
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Color(0xFFD0D7DE)),
              ),
              title: Text(
                l10n.deleteRecord,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              content: Text(
                l10n.deleteRecordConfirm,
                style: const TextStyle(fontSize: 14, color: Color(0xFF57606A)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFCF222E),
                  ),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => _deleteRecord(record.id),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: GitHubFileIcon(fileName: record.fileName),
            title: Text(
              record.fileName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF24292F),
              ),
            ),
            subtitle: Row(
              children: [
                // 上传状态徽章
                _buildUploadStatusBadge(record, l10n),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D7DE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${record.rowCount} ${l10n.rows}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF57606A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(record.uploadTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF57606A),
                  ),
                ),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.grid_view_outlined, l10n.sheetsCount, '${record.sheetCount}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.table_rows_outlined, l10n.totalRows, '${record.rowCount}'),
                    if (record.sheetNames.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.folder_outlined,
                        l10n.sheetNames,
                        record.sheetNames.take(3).join(', ') +
                            (record.sheetNames.length > 3 ? '...' : ''),
                      ),
                    ],
                    // 显示修改后的headers
                    if (record.headers.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.view_column_outlined, size: 14, color: Color(0xFF57606A)),
                          const SizedBox(width: 8),
                          Text(
                            l10n.headersLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF57606A),
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              record.headers.take(5).join(', ') + (record.headers.length > 5 ? '...' : ''),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF24292F),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF8B949E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.uploadedOn(dateFormat.format(record.uploadTime), timeFormat.format(record.uploadTime)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ),
                    // 显示服务器返回的数据
                    if (record.serverResponse != null && record.serverResponse!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.serverResponse,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF57606A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 80),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            record.serverResponse!.length > 200
                                ? '${record.serverResponse!.substring(0, 200)}...'
                                : record.serverResponse!,
                            style: const TextStyle(
                              fontFamily: 'ui-monospace, SFMono-Regular, monospace',
                              fontSize: 11,
                              color: Color(0xFFC9D1D9),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                    // 操作按钮
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isUploading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1F883D),
                            ),
                          )
                        else ...[
                          TextButton.icon(
                            onPressed: () => _showDataDetail(record),
                            icon: const Icon(Icons.visibility_outlined, size: 16),
                            label: Text(l10n.viewData),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _reupload(record),
                            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                            label: Text(l10n.reupload),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF57606A)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF57606A),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF24292F),
          ),
        ),
      ],
    );
  }
}

/// 数据详情弹窗
class _DataDetailDialog extends StatefulWidget {
  final ImportRecord record;
  final Map<String, dynamic> sheetsData;
  final AppLocalizations l10n;
  final Function(Map<String, dynamic> updatedData, List<String> newHeaders) onEditAndUpload;

  const _DataDetailDialog({
    required this.record,
    required this.sheetsData,
    required this.l10n,
    required this.onEditAndUpload,
  });

  @override
  State<_DataDetailDialog> createState() => _DataDetailDialogState();
}

class _DataDetailDialogState extends State<_DataDetailDialog> {
  String? _selectedSheet;
  late Map<String, dynamic> _editableData;
  List<String> _editableHeaders = [];
  List<Map<String, dynamic>> _editableRows = [];

  @override
  void initState() {
    super.initState();
    _editableData = Map<String, dynamic>.from(widget.sheetsData);
    _selectedSheet = _editableData.keys.firstOrNull;
    _loadSheetData();
  }

  void _loadSheetData() {
    if (_selectedSheet == null) return;

    final sheetData = _editableData[_selectedSheet] as Map<String, dynamic>?;
    if (sheetData != null) {
      _editableHeaders = List<String>.from(sheetData['headers'] as List? ?? []);
      _editableRows = List<Map<String, dynamic>>.from(
        (sheetData['data'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
    }
  }

  Future<void> _showEditHeadersDialog() async {
    if (_editableHeaders.isEmpty) return;

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
            Text(widget.l10n.editHeaders),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 400,
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
                          hintText: '${widget.l10n.column} ${index + 1}',
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
            child: Text(widget.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.l10n.save),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final newHeaders = controllers.map((c) => c.text.trim()).toList();

      // 创建映射
      final headerMap = <String, String>{};
      for (var i = 0; i < _editableHeaders.length && i < newHeaders.length; i++) {
        headerMap[_editableHeaders[i]] = newHeaders[i];
      }

      // 更新data中的key
      final newData = _editableRows.map((row) {
        final newRow = <String, dynamic>{};
        row.forEach((key, value) {
          final newKey = headerMap[key] ?? key;
          newRow[newKey] = value;
        });
        return newRow;
      }).toList();

      setState(() {
        _editableHeaders = newHeaders;
        _editableRows = newData;
        _editableData[_selectedSheet!] = {
          'headers': newHeaders,
          'data': newData,
          'rowCount': newData.length,
        };
      });

      // 清理controllers
      for (var c in controllers) {
        c.dispose();
      }
    }
  }

  Future<void> _showEditRowDialog(int rowIndex) async {
    if (rowIndex < 0 || rowIndex >= _editableRows.length) return;

    final rowData = _editableRows[rowIndex];
    final controllers = <String, TextEditingController>{};

    rowData.forEach((key, value) {
      controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });

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
            Text('${widget.l10n.editRow} ${rowIndex + 1}'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controllers.length,
            itemBuilder: (context, index) {
              final key = controllers.keys.elementAt(index);
              final controller = controllers[key]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF57606A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
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
            child: Text(widget.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.l10n.save),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        final newRow = <String, dynamic>{};
        controllers.forEach((key, controller) {
          newRow[key] = controller.text;
        });
        _editableRows[rowIndex] = newRow;
        _editableData[_selectedSheet!] = {
          'headers': _editableHeaders,
          'data': _editableRows,
          'rowCount': _editableRows.length,
        };
      });

      // 清理controllers
      for (var c in controllers.values) {
        c.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFFD0D7DE)),
      ),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F883D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.table_chart, size: 16, color: Color(0xFF1F883D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.record.fileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF24292F),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sheet tabs
            if (_editableData.length > 1)
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _editableData.keys.map((sheet) {
                      final isSelected = sheet == _selectedSheet;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSheet = sheet;
                            _loadSheetData();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1F883D) : const Color(0xFFF6F8FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sheet,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? Colors.white : const Color(0xFF57606A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Data table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD0D7DE)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF6F8FA)),
                      columns: _editableHeaders.map((header) {
                        return DataColumn(
                          label: Text(
                            header,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF24292F),
                            ),
                          ),
                        );
                      }).toList(),
                      rows: _editableRows.asMap().entries.map((entry) {
                        final rowIndex = entry.key;
                        final row = entry.value;
                        return DataRow(
                          cells: _editableHeaders.map((header) {
                            final value = row[header]?.toString() ?? '';
                            return DataCell(
                              Text(
                                value.length > 50 ? '${value.substring(0, 50)}...' : value,
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () => _showEditRowDialog(rowIndex),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _showEditHeadersDialog,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(widget.l10n.editHeaders),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onEditAndUpload(_editableData, _editableHeaders);
                  },
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(widget.l10n.uploadToServer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}