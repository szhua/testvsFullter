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
                Text(
                  dateFormat.format(record.importTime),
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
                          l10n.importedOn(dateFormat.format(record.importTime), timeFormat.format(record.importTime)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ),
                    if (record.jsonPreview != null && record.jsonPreview!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.jsonPreview,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF57606A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            record.jsonPreview!.length > 300
                                ? '${record.jsonPreview!.substring(0, 300)}...'
                                : record.jsonPreview!,
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