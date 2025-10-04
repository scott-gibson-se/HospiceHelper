import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import '../models/dose_log.dart';
import '../models/question.dart';
import '../models/note.dart';

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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // Create questions table
    await db.execute('''
      CREATE TABLE questions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        question_text TEXT NOT NULL,
        date_entered INTEGER NOT NULL,
        answer TEXT,
        answered_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add questions table for version 2
      await db.execute('''
        CREATE TABLE questions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          question_text TEXT NOT NULL,
          date_entered INTEGER NOT NULL,
          answer TEXT,
          answered_at INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add notes table for version 3
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      // Remove notification_sound column for version 4
      // Create new medications table without notification_sound
      await db.execute('''
        CREATE TABLE medications_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          official_name TEXT NOT NULL,
          form TEXT NOT NULL,
          max_dosage REAL NOT NULL,
          min_time_between_doses INTEGER NOT NULL,
          notifications_enabled INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');

      // Copy data from old table to new table
      await db.execute('''
        INSERT INTO medications_new (id, name, official_name, form, max_dosage, min_time_between_doses, notifications_enabled, created_at, updated_at)
        SELECT id, name, official_name, form, max_dosage, min_time_between_doses, notifications_enabled, created_at, updated_at
        FROM medications
      ''');

      // Drop old table and rename new table
      await db.execute('DROP TABLE medications');
      await db.execute('ALTER TABLE medications_new RENAME TO medications');
    }
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

  Future<int> updateDoseLog(DoseLog doseLog) async {
    final db = await database;
    return await db.update(
      'dose_logs',
      doseLog.toMap(),
      where: 'id = ?',
      whereArgs: [doseLog.id],
    );
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

  // Question CRUD operations
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    return await db.insert('questions', question.toMap());
  }

  Future<List<Question>> getAllQuestions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      orderBy: 'date_entered DESC',
    );
    return List.generate(maps.length, (i) => Question.fromMap(maps[i]));
  }

  Future<Question?> getQuestion(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Question.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQuestion(Question question) async {
    final db = await database;
    return await db.update(
      'questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<int> deleteQuestion(int id) async {
    final db = await database;
    return await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Question>> getUnansweredQuestions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'answer IS NULL OR answer = ?',
      whereArgs: [''],
      orderBy: 'date_entered DESC',
    );
    return List.generate(maps.length, (i) => Question.fromMap(maps[i]));
  }

  Future<List<Question>> getAnsweredQuestions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'answer IS NOT NULL AND answer != ?',
      whereArgs: [''],
      orderBy: 'answered_at DESC',
    );
    return List.generate(maps.length, (i) => Question.fromMap(maps[i]));
  }

  // Note CRUD operations
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<Note?> getNote(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
