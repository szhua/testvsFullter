import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Excel Importer'**
  String get appTitle;

  /// History button text
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Version number
  ///
  /// In en, this message translates to:
  /// **'v1.0.0'**
  String get version;

  /// Stable release badge
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// Hero section title
  ///
  /// In en, this message translates to:
  /// **'Excel Data Importer'**
  String get heroTitle;

  /// Hero section description
  ///
  /// In en, this message translates to:
  /// **'Import Excel files and convert them to JSON format. Supports .xlsx and .csv files.'**
  String get heroDescription;

  /// Supported file formats
  ///
  /// In en, this message translates to:
  /// **'xlsx, csv'**
  String get supportedFormats;

  /// JSON output feature
  ///
  /// In en, this message translates to:
  /// **'JSON output'**
  String get jsonOutput;

  /// Export feature
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Import file card header
  ///
  /// In en, this message translates to:
  /// **'Import File'**
  String get importFile;

  /// Drag and drop hint text
  ///
  /// In en, this message translates to:
  /// **'Drag and drop your Excel file here'**
  String get dragDropHint;

  /// Alternative action hint
  ///
  /// In en, this message translates to:
  /// **'or click to browse'**
  String get orClickToBrowse;

  /// Choose file button text
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// Success message header
  ///
  /// In en, this message translates to:
  /// **'Import Successful'**
  String get importSuccessful;

  /// Copy button text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Rows count label
  ///
  /// In en, this message translates to:
  /// **'rows'**
  String get rows;

  /// Sheets count label
  ///
  /// In en, this message translates to:
  /// **'sheets'**
  String get sheets;

  /// JSON output section label
  ///
  /// In en, this message translates to:
  /// **'JSON Output'**
  String get jsonOutputLabel;

  /// JSON file extension label
  ///
  /// In en, this message translates to:
  /// **'json'**
  String get json;

  /// Empty result message
  ///
  /// In en, this message translates to:
  /// **'No valid data found'**
  String get noValidDataFound;

  /// File info with no data
  ///
  /// In en, this message translates to:
  /// **'File {fileName} contains {rowCount} rows but no valid data.'**
  String fileContainsNoData(String fileName, int rowCount);

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Success toast message
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {fileName}'**
  String successfullyImported(String fileName);

  /// Import failed message
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// Unsupported format error
  ///
  /// In en, this message translates to:
  /// **'File format not supported. Please save as standard xlsx format.'**
  String get unsupportedFormat;

  /// Unsupported Excel format error
  ///
  /// In en, this message translates to:
  /// **'Unsupported Excel format. Please convert and try again.'**
  String get unsupportedExcelFormat;

  /// Copy success message
  ///
  /// In en, this message translates to:
  /// **'JSON copied to clipboard'**
  String get jsonCopied;

  /// Export success message
  ///
  /// In en, this message translates to:
  /// **'Exported to: {path}'**
  String exportedTo(String path);

  /// History screen title
  ///
  /// In en, this message translates to:
  /// **'Import History'**
  String get importHistory;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Empty history message
  ///
  /// In en, this message translates to:
  /// **'No import history'**
  String get noImportHistory;

  /// Empty history hint
  ///
  /// In en, this message translates to:
  /// **'Imported Excel files will appear here'**
  String get importedFilesWillAppear;

  /// Singular record label
  ///
  /// In en, this message translates to:
  /// **'record'**
  String get record;

  /// Plural records label
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get records;

  /// Total rows count
  ///
  /// In en, this message translates to:
  /// **'Total: {count} rows'**
  String total(int count);

  /// Delete confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete record?'**
  String get deleteRecord;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Delete \"{fileName}\" from history?'**
  String deleteRecordConfirm(String fileName);

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Record deleted message
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get recordDeleted;

  /// No records error
  ///
  /// In en, this message translates to:
  /// **'No records to export'**
  String get noRecordsToExport;

  /// Clear all confirmation title
  ///
  /// In en, this message translates to:
  /// **'Clear all records?'**
  String get clearAllRecords;

  /// Clear all confirmation message
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All import records will be permanently deleted.'**
  String get clearAllConfirm;

  /// Clear all button
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// All records cleared message
  ///
  /// In en, this message translates to:
  /// **'All records cleared'**
  String get allRecordsCleared;

  /// Sheet names label
  ///
  /// In en, this message translates to:
  /// **'Sheet names'**
  String get sheetNames;

  /// Total rows label
  ///
  /// In en, this message translates to:
  /// **'Total rows'**
  String get totalRows;

  /// Sheets count label
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get sheetsCount;

  /// Import date time
  ///
  /// In en, this message translates to:
  /// **'Imported on {date} at {time}'**
  String importedOn(String date, String time);

  /// JSON preview label
  ///
  /// In en, this message translates to:
  /// **'JSON Preview'**
  String get jsonPreview;

  /// Select sheet dropdown label
  ///
  /// In en, this message translates to:
  /// **'SELECT SHEET:'**
  String get selectSheet;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Chinese language name
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// Settings menu
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
