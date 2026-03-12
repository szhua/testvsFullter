# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Excel Importer is a Flutter application for importing Excel (.xlsx) and CSV files, converting them to JSON format. Supports Chinese/English internationalization.

## Commands

```bash
# Run the app
flutter run

# Install dependencies
flutter pub get

# Run tests
flutter test

# Build for production
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web

# Analyze code
flutter analyze
```

## Architecture

### Layer Structure
- **main.dart**: App entry point, theme configuration, i18n setup, and shared UI widgets
- **screens/**: UI screens (ImportScreen, RecordsScreen)
- **services/**: Business logic layer
  - `ExcelService`: File parsing and export logic
  - `StorageService`: Data persistence using SharedPreferences
- **providers/**: State management (LocaleProvider for language switching)
- **models/**: Data models (ImportRecord)

### Excel Parsing Strategy
Two different libraries are used for different purposes:
- **Reading**: `archive` + `xml` packages parse xlsx internal XML directly (bypasses numFmtId validation issues with WPS-generated files)
- **Exporting**: `syncfusion_flutter_xlsio` for creating new Excel files

Note: `syncfusion_flutter_xlsio` only supports creating Excel files, not reading them.

### CSV Parsing
Auto-detects delimiter (Tab vs comma) by counting occurrences in the first line.

### Internationalization
Manual implementation in `AppLocalizations` class within main.dart - no code generation required. Supports 'en' and 'zh' locales. LocaleProvider persists user preference via SharedPreferences.

### UI Theme
GitHub-inspired design system with custom color palette:
- Primary green: #1F883D
- Dark text: #24292F
- Borders: #D0D7DE
- Background: #F6F8FA

## Key Dependencies
- `syncfusion_flutter_xlsio`: Excel creation/export
- `archive` + `xml`: xlsx parsing (reading)
- `csv`: CSV parsing
- `file_picker`: File selection
- `shared_preferences`: Local storage
- `provider`: State management
- `intl`: Date formatting

## Data Flow
1. User selects file via FilePicker
2. ExcelService parses file (xlsx uses XML parsing, CSV uses csv package)
3. Data converted to JSON structure with headers array and data rows
4. ImportRecord saved via StorageService to SharedPreferences
5. Records displayed in RecordsScreen with expandable cards