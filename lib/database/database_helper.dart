import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hospice_meds.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create medications table
    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        official_name TEXT NOT NULL,
        form TEXT NOT NULL,
        max_dosage REAL NOT NULL,
        min_time_between_doses INTEGER NOT NULL,
        notifications_enabled INTEGER NOT NULL DEFAULT 0,
        notification_sound TEXT NOT NULL DEFAULT 'gentle',
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');

    // Create dose_logs table
    await db.execute('''
      CREATE TABLE dose_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        date_time INTEGER NOT NULL,
        dose_given REAL NOT NULL,
        given_by TEXT NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');
  }

  // Medication CRUD operations
  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    return await db.insert('medications', medication.toMap());
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medications');
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<Medication?> getMedication(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Dose log CRUD operations
  Future<int> insertDoseLog(DoseLog doseLog) async {
    final db = await database;
    return await db.insert('dose_logs', doseLog.toMap());
  }

  Future<List<DoseLog>> getDoseLogsForMedication(int medicationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'date_time DESC',
    );
    return List.generate(maps.length, (i) => DoseLog.fromMap(maps[i]));
  }

  Future<List<DoseLog>> getAllDoseLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      orderBy: 'date_time DESC',
    );
    return List.generate(maps.length, (i) => DoseLog.fromMap(maps[i]));
  }

  Future<DoseLog?> getLastDoseForMedication(int medicationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'date_time DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DoseLog.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteDoseLog(int id) async {
    final db = await database;
    return await db.delete(
      'dose_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get medications with their last dose information
  Future<List<Map<String, dynamic>>> getMedicationsWithLastDose() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        m.*,
        dl.date_time as last_dose_time,
        dl.dose_given as last_dose_amount,
        dl.given_by as last_dose_given_by
      FROM medications m
      LEFT JOIN (
        SELECT 
          medication_id,
          date_time,
          dose_given,
          given_by,
          ROW_NUMBER() OVER (PARTITION BY medication_id ORDER BY date_time DESC) as rn
        FROM dose_logs
      ) dl ON m.id = dl.medication_id AND dl.rn = 1
      ORDER BY m.name
    ''');
  }
}
