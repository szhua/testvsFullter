import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/locale_provider.dart';
import 'screens/import_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'Excel Importer',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif',
            scaffoldBackgroundColor: const Color(0xFFF6F8FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF24292F),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                side: BorderSide(color: Color(0xFFD0D7DE)),
              ),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1F883D),
              brightness: Brightness.light,
              primary: const Color(0xFF1F883D),
              surface: Colors.white,
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFFD0D7DE),
              thickness: 1,
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F883D), width: 2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F883D),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0969DA),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          home: const ImportScreen(),
        );
      },
    );
  }
}

/// 简单的国际化实现（无需代码生成）
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  // 所有翻译字符串
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Excel Importer',
      'history': 'History',
      'version': 'v1.0.0',
      'stable': 'Stable',
      'heroTitle': 'Excel Data Importer',
      'heroDescription': 'Import Excel files and convert them to JSON format. Supports .xlsx and .csv files.',
      'supportedFormats': 'xlsx, csv',
      'jsonOutput': 'JSON output',
      'export': 'Export',
      'importFile': 'Import File',
      'dragDropHint': 'Drag and drop your Excel file here',
      'orClickToBrowse': 'or click to browse',
      'chooseFile': 'Choose file',
      'importSuccessful': 'Import Successful',
      'copy': 'Copy',
      'rows': 'rows',
      'sheets': 'sheets',
      'jsonOutputLabel': 'JSON Output',
      'json': 'json',
      'noValidDataFound': 'No valid data found',
      'processing': 'Processing...',
      'successfullyImported': 'Successfully imported',
      'importFailed': 'Import failed',
      'unsupportedFormat': 'File format not supported. Please save as standard xlsx format.',
      'unsupportedExcelFormat': 'Unsupported Excel format. Please convert and try again.',
      'jsonCopied': 'JSON copied to clipboard',
      'exportedTo': 'Exported to',
      'importHistory': 'Import History',
      'clear': 'Clear',
      'noImportHistory': 'No import history',
      'importedFilesWillAppear': 'Imported Excel files will appear here',
      'record': 'record',
      'records': 'records',
      'total': 'Total',
      'deleteRecord': 'Delete record?',
      'deleteRecordConfirm': 'Delete from history?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'recordDeleted': 'Record deleted',
      'noRecordsToExport': 'No records to export',
      'clearAllRecords': 'Clear all records?',
      'clearAllConfirm': 'This action cannot be undone. All import records will be permanently deleted.',
      'clearAll': 'Clear all',
      'allRecordsCleared': 'All records cleared',
      'sheetNames': 'Sheet names',
      'totalRows': 'Total rows',
      'sheetsCount': 'Sheets',
      'importedOn': 'Imported on',
      'jsonPreview': 'JSON Preview',
      'selectSheet': 'SELECT SHEET:',
      'language': 'Language',
      'english': 'English',
      'chinese': '中文',
      'settings': 'Settings',
      'editHeaders': 'Edit Headers',
      'column': 'Column',
      'save': 'Save',
      'headersUpdated': 'Headers updated',
      'uploadToServer': 'Upload to Server',
      'uploadSuccess': 'Upload successful',
      'uploadFailed': 'Upload failed',
      'uploading': 'Uploading...',
      'uploadStatus': 'Upload Status',
      'pending': 'Pending',
      'uploaded': 'Uploaded',
      'headersLabel': 'Headers',
      'serverResponse': 'Server Response',
      'reupload': 'Re-upload',
      'refresh': 'Refresh',
      'refreshed': 'Refreshed',
      'viewData': 'View Data',
      'editRow': 'Edit Row',
    },
    'zh': {
      'appTitle': 'Excel导入工具',
      'history': '历史记录',
      'version': 'v1.0.0',
      'stable': '稳定版',
      'heroTitle': 'Excel数据导入器',
      'heroDescription': '导入Excel文件并转换为JSON格式。支持 .xlsx 和 .csv 文件。',
      'supportedFormats': 'xlsx, csv',
      'jsonOutput': 'JSON输出',
      'export': '导出',
      'importFile': '导入文件',
      'dragDropHint': '将Excel文件拖放到此处',
      'orClickToBrowse': '或点击选择文件',
      'chooseFile': '选择文件',
      'importSuccessful': '导入成功',
      'copy': '复制',
      'rows': '行',
      'sheets': '个工作表',
      'jsonOutputLabel': 'JSON输出',
      'json': 'json',
      'noValidDataFound': '未找到有效数据',
      'processing': '处理中...',
      'successfullyImported': '成功导入',
      'importFailed': '导入失败',
      'unsupportedFormat': '不支持该文件格式，请另存为标准xlsx格式。',
      'unsupportedExcelFormat': '不支持的Excel格式，请转换后重试。',
      'jsonCopied': 'JSON已复制到剪贴板',
      'exportedTo': '已导出到',
      'importHistory': '导入历史',
      'clear': '清空',
      'noImportHistory': '暂无导入记录',
      'importedFilesWillAppear': '导入的Excel文件将在此显示',
      'record': '条记录',
      'records': '条记录',
      'total': '总计',
      'deleteRecord': '删除记录？',
      'deleteRecordConfirm': '从历史记录中删除？',
      'cancel': '取消',
      'delete': '删除',
      'recordDeleted': '记录已删除',
      'noRecordsToExport': '没有记录可导出',
      'clearAllRecords': '清空所有记录？',
      'clearAllConfirm': '此操作不可撤销，所有导入记录将被永久删除。',
      'clearAll': '清空全部',
      'allRecordsCleared': '所有记录已清空',
      'sheetNames': '工作表名称',
      'totalRows': '总行数',
      'sheetsCount': '工作表数',
      'importedOn': '导入于',
      'jsonPreview': 'JSON预览',
      'selectSheet': '选择工作表：',
      'language': '语言',
      'english': 'English',
      'chinese': '中文',
      'settings': '设置',
      'editHeaders': '编辑表头',
      'column': '列',
      'save': '保存',
      'headersUpdated': '表头已更新',
      'uploadToServer': '上传到服务器',
      'uploadSuccess': '上传成功',
      'uploadFailed': '上传失败',
      'uploading': '上传中...',
      'uploadStatus': '上传状态',
      'pending': '待上传',
      'uploaded': '已上传',
      'headersLabel': '表头',
      'serverResponse': '服务器响应',
      'reupload': '重新上传',
      'refresh': '刷新',
      'refreshed': '已刷新',
      'viewData': '查看数据',
      'editRow': '编辑行',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]?['appTitle'] ?? 'Excel Importer';
  String get history => _localizedValues[locale.languageCode]?['history'] ?? 'History';
  String get version => _localizedValues[locale.languageCode]?['version'] ?? 'v1.0.0';
  String get stable => _localizedValues[locale.languageCode]?['stable'] ?? 'Stable';
  String get heroTitle => _localizedValues[locale.languageCode]?['heroTitle'] ?? 'Excel Data Importer';
  String get heroDescription => _localizedValues[locale.languageCode]?['heroDescription'] ?? '';
  String get supportedFormats => _localizedValues[locale.languageCode]?['supportedFormats'] ?? 'xlsx, csv';
  String get jsonOutput => _localizedValues[locale.languageCode]?['jsonOutput'] ?? 'JSON output';
  String get export => _localizedValues[locale.languageCode]?['export'] ?? 'Export';
  String get importFile => _localizedValues[locale.languageCode]?['importFile'] ?? 'Import File';
  String get dragDropHint => _localizedValues[locale.languageCode]?['dragDropHint'] ?? '';
  String get orClickToBrowse => _localizedValues[locale.languageCode]?['orClickToBrowse'] ?? '';
  String get chooseFile => _localizedValues[locale.languageCode]?['chooseFile'] ?? 'Choose file';
  String get importSuccessful => _localizedValues[locale.languageCode]?['importSuccessful'] ?? '';
  String get copy => _localizedValues[locale.languageCode]?['copy'] ?? 'Copy';
  String get rows => _localizedValues[locale.languageCode]?['rows'] ?? 'rows';
  String get sheets => _localizedValues[locale.languageCode]?['sheets'] ?? 'sheets';
  String get jsonOutputLabel => _localizedValues[locale.languageCode]?['jsonOutputLabel'] ?? '';
  String get json => _localizedValues[locale.languageCode]?['json'] ?? 'json';
  String get noValidDataFound => _localizedValues[locale.languageCode]?['noValidDataFound'] ?? '';
  String get processing => _localizedValues[locale.languageCode]?['processing'] ?? 'Processing...';
  String get successfullyImported => _localizedValues[locale.languageCode]?['successfullyImported'] ?? '';
  String get importFailed => _localizedValues[locale.languageCode]?['importFailed'] ?? '';
  String get unsupportedFormat => _localizedValues[locale.languageCode]?['unsupportedFormat'] ?? '';
  String get unsupportedExcelFormat => _localizedValues[locale.languageCode]?['unsupportedExcelFormat'] ?? '';
  String get jsonCopied => _localizedValues[locale.languageCode]?['jsonCopied'] ?? '';
  String get exportedTo => _localizedValues[locale.languageCode]?['exportedTo'] ?? '';
  String get importHistory => _localizedValues[locale.languageCode]?['importHistory'] ?? '';
  String get clear => _localizedValues[locale.languageCode]?['clear'] ?? 'Clear';
  String get noImportHistory => _localizedValues[locale.languageCode]?['noImportHistory'] ?? '';
  String get importedFilesWillAppear => _localizedValues[locale.languageCode]?['importedFilesWillAppear'] ?? '';
  String get record => _localizedValues[locale.languageCode]?['record'] ?? 'record';
  String get records => _localizedValues[locale.languageCode]?['records'] ?? 'records';
  String get total => _localizedValues[locale.languageCode]?['total'] ?? 'Total';
  String get deleteRecord => _localizedValues[locale.languageCode]?['deleteRecord'] ?? '';
  String get deleteRecordConfirm => _localizedValues[locale.languageCode]?['deleteRecordConfirm'] ?? '';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Delete';
  String get recordDeleted => _localizedValues[locale.languageCode]?['recordDeleted'] ?? '';
  String get noRecordsToExport => _localizedValues[locale.languageCode]?['noRecordsToExport'] ?? '';
  String get clearAllRecords => _localizedValues[locale.languageCode]?['clearAllRecords'] ?? '';
  String get clearAllConfirm => _localizedValues[locale.languageCode]?['clearAllConfirm'] ?? '';
  String get clearAll => _localizedValues[locale.languageCode]?['clearAll'] ?? 'Clear all';
  String get allRecordsCleared => _localizedValues[locale.languageCode]?['allRecordsCleared'] ?? '';
  String get sheetNames => _localizedValues[locale.languageCode]?['sheetNames'] ?? '';
  String get totalRows => _localizedValues[locale.languageCode]?['totalRows'] ?? '';
  String get sheetsCount => _localizedValues[locale.languageCode]?['sheetsCount'] ?? '';
  String get jsonPreview => _localizedValues[locale.languageCode]?['jsonPreview'] ?? '';
  String get selectSheet => _localizedValues[locale.languageCode]?['selectSheet'] ?? '';
  String get language => _localizedValues[locale.languageCode]?['language'] ?? 'Language';
  String get english => _localizedValues[locale.languageCode]?['english'] ?? 'English';
  String get chinese => _localizedValues[locale.languageCode]?['chinese'] ?? '中文';
  String get settings => _localizedValues[locale.languageCode]?['settings'] ?? 'Settings';
  String get editHeaders => _localizedValues[locale.languageCode]?['editHeaders'] ?? 'Edit Headers';
  String get column => _localizedValues[locale.languageCode]?['column'] ?? 'Column';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get headersUpdated => _localizedValues[locale.languageCode]?['headersUpdated'] ?? 'Headers updated';
  String get uploadToServer => _localizedValues[locale.languageCode]?['uploadToServer'] ?? 'Upload to Server';
  String get uploadSuccess => _localizedValues[locale.languageCode]?['uploadSuccess'] ?? 'Upload successful';
  String get uploadFailed => _localizedValues[locale.languageCode]?['uploadFailed'] ?? 'Upload failed';
  String get uploading => _localizedValues[locale.languageCode]?['uploading'] ?? 'Uploading...';
  String get uploadStatus => _localizedValues[locale.languageCode]?['uploadStatus'] ?? 'Upload Status';
  String get pending => _localizedValues[locale.languageCode]?['pending'] ?? 'Pending';
  String get uploaded => _localizedValues[locale.languageCode]?['uploaded'] ?? 'Uploaded';
  String get headersLabel => _localizedValues[locale.languageCode]?['headersLabel'] ?? 'Headers';
  String get serverResponse => _localizedValues[locale.languageCode]?['serverResponse'] ?? 'Server Response';
  String get reupload => _localizedValues[locale.languageCode]?['reupload'] ?? 'Re-upload';
  String get refresh => _localizedValues[locale.languageCode]?['refresh'] ?? 'Refresh';
  String get refreshed => _localizedValues[locale.languageCode]?['refreshed'] ?? 'Refreshed';
  String get viewData => _localizedValues[locale.languageCode]?['viewData'] ?? 'View Data';
  String get editRow => _localizedValues[locale.languageCode]?['editRow'] ?? 'Edit Row';

  // 带参数的方法
  String importedOn(String date, String time) {
    final isZh = locale.languageCode == 'zh';
    if (isZh) {
      return '导入于 $date $time';
    }
    return 'Imported on $date at $time';
  }

  String uploadedOn(String date, String time) {
    final isZh = locale.languageCode == 'zh';
    if (isZh) {
      return '上传于 $date $time';
    }
    return 'Uploaded on $date at $time';
  }

  String fileContainsNoData(String fileName, int rowCount) {
    final isZh = locale.languageCode == 'zh';
    if (isZh) {
      return '文件 $fileName 包含 $rowCount 行但没有有效数据。';
    }
    return 'File $fileName contains $rowCount rows but no valid data.';
  }

  String recordsCount(int count) {
    final isZh = locale.languageCode == 'zh';
    return '$count ${isZh ? '条记录' : (count == 1 ? 'record' : 'records')}';
  }

  String totalRowsCount(int count) {
    final isZh = locale.languageCode == 'zh';
    return isZh ? '总计: $count 行' : 'Total: $count rows';
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// GitHub 风格的状态徽章
class GitHubBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const GitHubBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

/// GitHub 风格的统计数字
class GitHubCounter extends StatelessWidget {
  final int count;
  final String label;
  final IconData? icon;

  const GitHubCounter({
    super.key,
    required this.count,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: const Color(0xFF57606A)),
          const SizedBox(width: 4),
        ],
        Text(
          _formatCount(count),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF24292F),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF57606A),
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

/// GitHub 风格的提交样式信息行
class GitHubInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const GitHubInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF57606A)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF57606A),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF24292F),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF57606A)),
            ],
          ],
        ),
      ),
    );
  }
}

/// GitHub 风格的文件图标
class GitHubFileIcon extends StatelessWidget {
  final String fileName;
  final double size;

  const GitHubFileIcon({
    super.key,
    required this.fileName,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final ext = fileName.split('.').last.toLowerCase();
    Color bgColor;
    IconData iconData;

    switch (ext) {
      case 'xlsx':
      case 'xls':
        bgColor = const Color(0xFF217346);
        iconData = Icons.table_chart;
        break;
      case 'csv':
        bgColor = const Color(0xFF1F883D);
        iconData = Icons.table_rows;
        break;
      case 'json':
        bgColor = const Color(0xFFCB3837);
        iconData = Icons.data_object;
        break;
      default:
        bgColor = const Color(0xFF57606A);
        iconData = Icons.insert_drive_file;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(iconData, size: size * 0.6, color: Colors.white),
    );
  }
}

/// GitHub 风格的按钮组
class GitHubButtonGroup extends StatelessWidget {
  final List<Widget> children;

  const GitHubButtonGroup({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D7DE)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: const Color(0xFFD0D7DE),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// GitHub 风格的表格头部
class GitHubTableHeader extends StatelessWidget {
  final List<String> columns;

  const GitHubTableHeader({
    super.key,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FA),
        border: Border(
          bottom: BorderSide(color: Color(0xFFD0D7DE)),
        ),
      ),
      child: Row(
        children: columns.map((col) {
          return Expanded(
            child: Text(
              col,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF57606A),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// GitHub 风格的活动时间线
class GitHubTimelineItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? time;

  const GitHubTimelineItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF24292F),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF57606A),
                ),
              ),
            ],
          ),
        ),
        if (time != null)
          Text(
            time!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF57606A),
            ),
          ),
      ],
    );
  }
}