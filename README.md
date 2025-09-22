# Hospice Medication Tracker

A comprehensive Flutter application designed to help hospice patients and their caregivers efficiently track medications, dosages, and timing. The app provides a user-friendly interface for managing medication schedules, logging doses, and receiving notifications.

## Features

### Medication Management
- **Add Medications**: Create detailed medication profiles with:
  - Medication name and official name
  - Form (tablet, capsule, liquid, injection, etc.)
  - Maximum dosage
  - Minimum time between doses
  - Notification settings

### Dose Logging
- **Log Doses**: Record when medications are administered with:
  - Date and time
  - Dose amount given
  - Who administered the dose
  - Optional notes

### Notifications
- **Smart Reminders**: Get notified when it's time for the next dose
- **Configurable Sounds**: Choose from a range of notification sounds from gentle to attention-getting
- **Customizable Settings**: Enable/disable notifications per medication

### Data Management
- **Local Storage**: All data is stored locally using SQLite
- **Export Reports**: Generate PDF reports of medication history
- **Email Integration**: Send reports via email to caregivers or healthcare providers
- **Data Backup**: Export and backup medication data

### User Interface
- **Intuitive Design**: Clean, easy-to-use interface suitable for all ages
- **Visual Indicators**: Color-coded status indicators for medication due times
- **Responsive Layout**: Works on phones and tablets
- **Accessibility**: Designed with accessibility in mind

## Technical Features

### Database
- **SQLite Integration**: Local database using `sqflite` package
- **Relational Data**: Proper foreign key relationships between medications and dose logs
- **Data Integrity**: Automatic cleanup when medications are deleted

### Notifications
- **Local Notifications**: Uses `flutter_local_notifications` package
- **Timezone Support**: Proper timezone handling for accurate scheduling
- **Sound Customization**: Multiple notification sound options

### PDF Generation
- **Report Generation**: Create comprehensive medication reports
- **Professional Formatting**: Clean, readable PDF layouts
- **Complete History**: Include all medication and dose information

### Email Integration
- **Email Reports**: Send medication reports via email
- **Attachment Support**: Attach PDF reports to emails
- **Multiple Recipients**: Send to caregivers and healthcare providers

## Dependencies

The app uses the following key packages:

- `sqflite`: Local database storage
- `flutter_local_notifications`: Local notifications
- `pdf`: PDF report generation
- `url_launcher`: Email functionality
- `provider`: State management
- `intl`: Date/time formatting
- `timezone`: Timezone handling
- `path_provider`: File system access

## Installation

1. **Prerequisites**:
   - Flutter SDK (3.8.1 or higher)
   - Dart SDK
   - Android Studio / VS Code with Flutter extensions

2. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd hospice_meds
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Usage

### Adding Medications
1. Tap the "+" button on the home screen
2. Fill in medication details:
   - Name (e.g., "Pain Relief")
   - Official name (e.g., "Morphine Sulfate")
   - Form (tablet, liquid, etc.)
   - Maximum dosage
   - Minimum time between doses
3. Configure notification settings
4. Save the medication

### Logging Doses
1. From the home screen, tap the green "+" button next to due medications
2. Enter the dose amount given
3. Specify who administered the dose
4. Add any optional notes
5. Confirm the dose

### Viewing History
1. Tap the history icon in the app bar
2. View all logged doses with timestamps
3. See medication details and caregiver information
4. Delete incorrect entries if needed

### Managing Medications
1. Tap on any medication to view details
2. Edit medication information
3. Enable/disable notifications
4. View dose history for that medication
5. Delete medications when no longer needed

### Settings and Reports
1. Tap the settings icon in the app bar
2. Generate PDF reports
3. Email reports to caregivers
4. Clear all data if needed

## Data Privacy

- **Local Storage**: All data is stored locally on the device
- **No Cloud Sync**: Data is not transmitted to external servers
- **User Control**: Users have complete control over their data
- **Export Options**: Data can be exported and backed up

## Platform Support

- **Android**: Full support with native notifications
- **iOS**: Full support with native notifications
- **Windows**: Basic support (notifications may be limited)
- **Linux**: Basic support (notifications may be limited)
- **Web**: Limited support (no local notifications)

## Contributing

This is a specialized application for hospice care. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support or questions about this application, please contact the development team or create an issue in the repository.

## Version History

- **v1.0.0**: Initial release with core medication tracking features
  - Medication management
  - Dose logging
  - Local notifications
  - PDF report generation
  - Email integration
  - Settings and data management

---

**Note**: This application is designed specifically for hospice care scenarios and should be used in consultation with healthcare professionals.