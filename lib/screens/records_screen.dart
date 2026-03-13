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
  final Map<String, bool> _uploadingIds = {};

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
            final result = await _excelService.reuploadRecord(record, updatedData: updatedData);
            await _loadRecords();

            if (mounted) {
              if (result.uploadStatus == UploadStatus.success) {
                _showToast(l10n.uploadSuccess, isError: false);
              } else {
                _showToast(l10n.uploadFailed, isError: true);
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

  /// 显示上传历史
  Future<void> _showUploadHistory(ImportRecord record) async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) => _UploadHistoryDialog(
        record: record,
        l10n: l10n,
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
          _showToast(l10n.uploadFailed, isError: true);
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
                // 上传次数
                if (record.uploadCount > 0)
                  GestureDetector(
                    onTap: () => _showUploadHistory(record),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: record.successUploadCount > 0
                            ? const Color(0xFFDAFBE1)
                            : const Color(0xFFFFEBE9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${record.successUploadCount}/${record.uploadCount} ${l10n.uploads}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: record.successUploadCount > 0
                              ? const Color(0xFF1F883D)
                              : const Color(0xFFCF222E),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.notUploaded,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF57606A),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(record.createdAt),
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
                          l10n.createdOn(dateFormat.format(record.createdAt), timeFormat.format(record.createdAt)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ),
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
                          if (record.uploadCount > 0)
                            TextButton.icon(
                              onPressed: () => _showUploadHistory(record),
                              icon: const Icon(Icons.history, size: 16),
                              label: Text(l10n.uploadHistory),
                            ),
                          TextButton.icon(
                            onPressed: () => _showDataDetail(record),
                            icon: const Icon(Icons.visibility_outlined, size: 16),
                            label: Text(l10n.viewData),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _reupload(record),
                            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                            label: Text(l10n.upload),
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

/// 上传历史对话框
class _UploadHistoryDialog extends StatelessWidget {
  final ImportRecord record;
  final AppLocalizations l10n;

  const _UploadHistoryDialog({
    required this.record,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final dateFormat = isZh ? DateFormat('yyyy年MM月dd日') : DateFormat('MMM d, yyyy');
    final timeFormat = isZh ? DateFormat('HH:mm:ss') : DateFormat('h:mm:ss a');

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFFD0D7DE)),
      ),
      child: Container(
        width: 600,
        height: 500,
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
                  child: const Icon(Icons.history, size: 16, color: Color(0xFF1F883D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.uploadHistoryTitle,
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
            Text(
              record.fileName,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF57606A),
              ),
            ),
            const SizedBox(height: 16),

            // 上传历史列表
            Expanded(
              child: record.uploadHistory.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noUploadHistory,
                        style: const TextStyle(color: Color(0xFF57606A)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: record.uploadHistory.length,
                      itemBuilder: (context, index) {
                        final history = record.uploadHistory[index];
                        final isLast = index == record.uploadHistory.length - 1;
                        return _buildHistoryItem(history, dateFormat, timeFormat, isLast);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    UploadHistory history,
    DateFormat dateFormat,
    DateFormat timeFormat,
    bool isLast,
  ) {
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusText;

    switch (history.status) {
      case UploadStatus.success:
        statusColor = const Color(0xFF1F883D);
        statusBgColor = const Color(0xFFDAFBE1);
        statusIcon = Icons.check_circle_outline;
        statusText = l10n.uploadSuccess;
        break;
      case UploadStatus.failed:
        statusColor = const Color(0xFFCF222E);
        statusBgColor = const Color(0xFFFFEBE9);
        statusIcon = Icons.error_outline;
        statusText = l10n.uploadFailed;
        break;
      case UploadStatus.uploading:
        statusColor = const Color(0xFF9A6700);
        statusBgColor = const Color(0xFFFFF8C5);
        statusIcon = Icons.sync;
        statusText = l10n.uploading;
        break;
      case UploadStatus.pending:
        statusColor = const Color(0xFF57606A);
        statusBgColor = const Color(0xFFF6F8FA);
        statusIcon = Icons.schedule;
        statusText = l10n.pending;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD0D7DE)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${dateFormat.format(history.uploadTime)} ${timeFormat.format(history.uploadTime)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF57606A),
                ),
              ),
              if (isLast) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F883D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.latest,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F883D),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (history.headers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.headersLabel}: ${history.headers.take(5).join(', ')}${history.headers.length > 5 ? '...' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF57606A),
              ),
            ),
          ],
          if (history.errorMessage != null && history.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.error}: ${history.errorMessage}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFCF222E),
              ),
            ),
          ],
        ],
      ),
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

      final headerMap = <String, String>{};
      for (var i = 0; i < _editableHeaders.length && i < newHeaders.length; i++) {
        headerMap[_editableHeaders[i]] = newHeaders[i];
      }

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