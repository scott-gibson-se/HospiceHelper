# Hospice Helper

A comprehensive Flutter application designed to help hospice patients and their caregivers manage medications, track questions, and keep notes. The app provides a user-friendly interface with tab-based navigation and local data storage.

All data is kept locally on the device.

## Features

### Medication Management
- **Add Medications**: Create medication profiles with:
  - Medication name and official name
  - Form (tablet, capsule, liquid, injection, patch, etc.)
  - Maximum dosage
  - Minimum time between doses
  - Notification settings (enable/disable reminders)
- **Edit and Delete**: Full management of medication entries
- **Visual Status**: Color-coded indicators showing which medications are due vs. when the next dose is scheduled
- **Calculation of total onboard doses**: Each medication has a running total of all does within the minimum time between doses.  This helps keep track of partial dosing.  e.g. if give 0.25ml at 1PM and another 0.25ml at 2PM the associated medication would show 0.5ml given until the minimum time between doses passes for the first dose.

### Dose Logging
- **Log Doses**: Record when medications are administered with:
  - Date and time
  - Dose amount given
  - Who administered the dose
  - Optional notes
- **Log from Multiple Places**: Log doses from the medication list or the Dose History screen
- **Edit and Delete**: Modify or remove dose entries from the Dose History screen
- **Dose History**: Dedicated screen to view, add, edit, and delete all dose logs

### Questions (for Healthcare Providers or Others)
- **Track Questions**: Record questions to ask nurses, doctors, or other caregivers
- **Add Questions**: Title, question text, and date/time entered
- **Answer Questions**: Add answers when you receive them; mark as Pending or Answered
- **Filter Views**: Browse All questions, or filter by Pending or Answered
- **Full Editing**: Edit question details, add or update answers, delete questions

### Notes
- **Quick Notes**: Create notes with a title and body for observations, instructions, or reminders
- **Edit Anytime**: Modify notes with full edit support
- **Timestamps**: View creation and last-updated timestamps
- **Status Indicator**: Visual indicator for new vs. modified notes

### Notifications
- **Medication Reminders**: Get notified when it's time for the next dose based on each medication's interval
- **Per-Medication Control**: Enable or disable notifications for each medication

### Data Management
- **Local Storage**: All Medicine, Notes and Questions data is stored locally using SQLite.
- **PDF Reports**: PDF reports are available for Doses, Notes and Questions; saved to the device's Downloads folder for manual sharing
- **Patient Name**: Set patient name in Settings; included in generated reports
- **Clear Medication Data**: Option to clear all medications and dose logs (questions and notes are preserved)
- **Database Export/Import**: The database file can be exported/imported.  This is intended to be used by the users to protect data in the event of device updates/changes.  This could be used as a manual backup capability also.

### User Interface
- **Tab-Based Navigation**: Switch between Medications, Questions, and Notes
- **Intuitive Design**: Clean, easy-to-use interface
- **Refresh**: Pull-to-refresh and refresh button to reload data
- **Direct Access**: Quick access to Dose History and Settings from the app bar
- **Reporting**: Reports are accessed via a floating action button from the main list screens for each primary tab.

## Usage

### Adding Medications
1. Open the Medications tab and tap the "+" button
2. Fill in medication details (name, official name, form, max dosage, interval)
3. Enable notifications if desired
4. Save

### Logging Doses
1. From the Medications tab, tap the green "+" button next to due medications, or
2. Open Dose History (clock icon) and tap the "+" button
3. Enter dose amount, who gave it, and optionally date/time and notes
4. Confirm

### Managing Questions
1. Open the Questions tab
2. Tap "+" to add a question (title, text, date entered)
3. Tap a question to view details and add or edit answers
4. Use sub-tabs to filter by All, Pending, or Answered

### Managing Notes
1. Open the Notes tab
2. Tap "+" to add a note
3. Tap a note to view or edit it

### Settings and Reports
1. Tap the settings icon in the app bar
2. Set patient name (required for PDF reports)
3. Generate PDF report (saved to Downloads)
4. Clear medication and dose data if needed (does not affect questions or notes)

## Data Privacy

- **Local Storage**: All data is stored locally on the device
- **No Cloud Sync**: Data is not transmitted to external servers
- **User Control**: Users have complete control over their data
- **Export**: Medication reports can be generated as PDF and shared manually

## Platform Support

As a flutter app multiple platforms are supported.  **HOWEVER: Only the Android version has been built and tested.**

- **Android**: Full support with native notifications
- **iOS**: Full support with native notifications
- **Windows**: Basic support (notifications may be limited)
- **Linux**: Basic support (notifications may be limited)
- **Web**: Limited support (no local notifications)## Technical Features

### Database
- **SQLite Integration**: Local database using `sqflite` package
- **Relational Data**: Foreign key relationships between medications and dose logs
- **Data Integrity**: Automatic cascade delete of dose logs when medications are removed

### Notifications
- **Local Notifications**: Uses `flutter_local_notifications` package
- **Timezone Support**: Proper timezone handling for scheduling
- **Exact Alarms**: Supports exact alarm scheduling on Android when permission is granted

### PDF Generation
- **Medication Reports**: Create PDF reports with medication profiles and dose history
- **Notes Report**: All notes are produced in a PDF
- **Patient Identification**: Reports include patient name from settings
- **File Output**: Date stamped PDF files are saved to Downloads directory

### Dependencies

- `sqflite`: Local database storage
- `flutter_local_notifications`: Local notifications
- `timezone`: Timezone handling
- `pdf`: PDF report generation
- `url_launcher`: Platform integration (e.g., mailto support)
- `provider`: State management
- `intl`: Date/time formatting
- `path_provider`: File system access
- `shared_preferences`: Settings storage
- `permission_handler`: Notification and storage permissions

## Installation

1. **Prerequisites**:
   - Flutter SDK (3.8.1 or higher)
   - Dart SDK
   - Android Studio / VS Code with Flutter extensions

2. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd HospiceHelper
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support or questions about this application, please create an issue in the repository.

## Version History

- **v1.0.0**: Initial release
  - Medication management and dose logging
  - Questions for healthcare providers
  - Notes
  - Local notifications
  - PDF report generation
  - Settings and data management

---

**Note**: This application is designed for hospice care scenarios and should be used in consultation with healthcare professionals.
