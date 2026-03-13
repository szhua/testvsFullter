// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Excel Importer';

  @override
  String get history => 'History';

  @override
  String get version => 'v1.0.0';

  @override
  String get stable => 'Stable';

  @override
  String get heroTitle => 'Excel Data Importer';

  @override
  String get heroDescription =>
      'Import Excel files and convert them to JSON format. Supports .xlsx and .csv files.';

  @override
  String get supportedFormats => 'xlsx, csv';

  @override
  String get jsonOutput => 'JSON output';

  @override
  String get export => 'Export';

  @override
  String get importFile => 'Import File';

  @override
  String get dragDropHint => 'Drag and drop your Excel file here';

  @override
  String get orClickToBrowse => 'or click to browse';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get importSuccessful => 'Import Successful';

  @override
  String get copy => 'Copy';

  @override
  String get rows => 'rows';

  @override
  String get sheets => 'sheets';

  @override
  String get jsonOutputLabel => 'JSON Output';

  @override
  String get json => 'json';

  @override
  String get noValidDataFound => 'No valid data found';

  @override
  String fileContainsNoData(String fileName, int rowCount) {
    return 'File $fileName contains $rowCount rows but no valid data.';
  }

  @override
  String get processing => 'Processing...';

  @override
  String successfullyImported(String fileName) {
    return 'Successfully imported $fileName';
  }

  @override
  String get importFailed => 'Import failed';

  @override
  String get unsupportedFormat =>
      'File format not supported. Please save as standard xlsx format.';

  @override
  String get unsupportedExcelFormat =>
      'Unsupported Excel format. Please convert and try again.';

  @override
  String get jsonCopied => 'JSON copied to clipboard';

  @override
  String exportedTo(String path) {
    return 'Exported to: $path';
  }

  @override
  String get importHistory => 'Import History';

  @override
  String get clear => 'Clear';

  @override
  String get noImportHistory => 'No import history';

  @override
  String get importedFilesWillAppear => 'Imported Excel files will appear here';

  @override
  String get record => 'record';

  @override
  String get records => 'records';

  @override
  String total(int count) {
    return 'Total: $count rows';
  }

  @override
  String get deleteRecord => 'Delete record?';

  @override
  String deleteRecordConfirm(String fileName) {
    return 'Delete \"$fileName\" from history?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get noRecordsToExport => 'No records to export';

  @override
  String get clearAllRecords => 'Clear all records?';

  @override
  String get clearAllConfirm =>
      'This action cannot be undone. All import records will be permanently deleted.';

  @override
  String get clearAll => 'Clear all';

  @override
  String get allRecordsCleared => 'All records cleared';

  @override
  String get sheetNames => 'Sheet names';

  @override
  String get totalRows => 'Total rows';

  @override
  String get sheetsCount => 'Sheets';

  @override
  String importedOn(String date, String time) {
    return 'Imported on $date at $time';
  }

  @override
  String get jsonPreview => 'JSON Preview';

  @override
  String get selectSheet => 'SELECT SHEET:';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String get settings => 'Settings';
}
