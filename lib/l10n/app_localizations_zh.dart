// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Excel导入工具';

  @override
  String get history => '历史记录';

  @override
  String get version => 'v1.0.0';

  @override
  String get stable => '稳定版';

  @override
  String get heroTitle => 'Excel数据导入器';

  @override
  String get heroDescription => '导入Excel文件并转换为JSON格式。支持 .xlsx 和 .csv 文件。';

  @override
  String get supportedFormats => 'xlsx, csv';

  @override
  String get jsonOutput => 'JSON输出';

  @override
  String get export => '导出';

  @override
  String get importFile => '导入文件';

  @override
  String get dragDropHint => '将Excel文件拖放到此处';

  @override
  String get orClickToBrowse => '或点击选择文件';

  @override
  String get chooseFile => '选择文件';

  @override
  String get importSuccessful => '导入成功';

  @override
  String get copy => '复制';

  @override
  String get rows => '行';

  @override
  String get sheets => '个工作表';

  @override
  String get jsonOutputLabel => 'JSON输出';

  @override
  String get json => 'json';

  @override
  String get noValidDataFound => '未找到有效数据';

  @override
  String fileContainsNoData(String fileName, int rowCount) {
    return '文件 $fileName 包含 $rowCount 行但没有有效数据。';
  }

  @override
  String get processing => '处理中...';

  @override
  String successfullyImported(String fileName) {
    return '成功导入 $fileName';
  }

  @override
  String get importFailed => '导入失败';

  @override
  String get unsupportedFormat => '不支持该文件格式，请另存为标准xlsx格式。';

  @override
  String get unsupportedExcelFormat => '不支持的Excel格式，请转换后重试。';

  @override
  String get jsonCopied => 'JSON已复制到剪贴板';

  @override
  String exportedTo(String path) {
    return '已导出到: $path';
  }

  @override
  String get importHistory => '导入历史';

  @override
  String get clear => '清空';

  @override
  String get noImportHistory => '暂无导入记录';

  @override
  String get importedFilesWillAppear => '导入的Excel文件将在此显示';

  @override
  String get record => '条记录';

  @override
  String get records => '条记录';

  @override
  String total(int count) {
    return '总计: $count 行';
  }

  @override
  String get deleteRecord => '删除记录？';

  @override
  String deleteRecordConfirm(String fileName) {
    return '从历史记录中删除 \"$fileName\"？';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get recordDeleted => '记录已删除';

  @override
  String get noRecordsToExport => '没有记录可导出';

  @override
  String get clearAllRecords => '清空所有记录？';

  @override
  String get clearAllConfirm => '此操作不可撤销，所有导入记录将被永久删除。';

  @override
  String get clearAll => '清空全部';

  @override
  String get allRecordsCleared => '所有记录已清空';

  @override
  String get sheetNames => '工作表名称';

  @override
  String get totalRows => '总行数';

  @override
  String get sheetsCount => '工作表数';

  @override
  String importedOn(String date, String time) {
    return '导入于 $date $time';
  }

  @override
  String get jsonPreview => 'JSON预览';

  @override
  String get selectSheet => '选择工作表：';

  @override
  String get language => '语言';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String get settings => '设置';
}
