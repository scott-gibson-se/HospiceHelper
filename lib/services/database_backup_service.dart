import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

class DatabaseBackupService {
  static Future<String> _getAccessibleDownloadsPath() async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('External storage not available');
    }

    final externalStoragePath = directory.path.split('/Android')[0];
    final downloadsPath = '$externalStoragePath/Download';
    final downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    return downloadsPath;
  }

  static Future<String> exportDatabaseFile() async {
    final downloadsPath = await _getAccessibleDownloadsPath();
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final fileName = 'HospiceHelper_backup_$timestamp.db';
    final destinationPath = '$downloadsPath/$fileName';

    await DatabaseHelper().exportDatabaseTo(destinationPath);
    return destinationPath;
  }

  static Future<void> importDatabaseFile(String sourcePath) async {
    await DatabaseHelper().importDatabaseFrom(sourcePath);
  }
}
