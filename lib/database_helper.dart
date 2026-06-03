import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rise_and_brew.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE soil_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farm_name TEXT NOT NULL,
        prediction TEXT NOT NULL,
        confidence TEXT NOT NULL,
        ph_level TEXT NOT NULL,
        ph_status TEXT NOT NULL,
        ph_confidence TEXT NOT NULL DEFAULT '0.0',
        date TEXT NOT NULL,
        image_path TEXT NOT NULL,
        is_suitable INTEGER NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE soil_results ADD COLUMN ph_confidence TEXT NOT NULL DEFAULT '0.0'",
      );
    }
  }

  // ── INSERT ──
  Future<int> insertResult(SoilResult result) async {
    final db = await instance.database;
    return await db.insert('soil_results', result.toMap());
  }

  // ── GET ALL ──
  Future<List<SoilResult>> getAllResults() async {
    final db = await instance.database;
    final maps = await db.query('soil_results', orderBy: 'id DESC');
    return maps.map((map) => SoilResult.fromMap(map)).toList();
  }

  // ── UPDATE ── (FIX: was missing, caused compile error in _showEditDialog)
  Future<int> updateResult(SoilResult result) async {
    final db = await instance.database;
    return await db.update(
      'soil_results',
      result.toMap(),
      where: 'id = ?',
      whereArgs: [result.id],
    );
  }

  // ── DELETE ──
  Future<void> deleteResult(int id) async {
    final db = await instance.database;
    await db.delete('soil_results', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

// ── Model ──
class SoilResult {
  final int? id;
  String farmName; // FIX: was `final` — must be mutable for in-place edit
  final String prediction;
  final String confidence;
  final String phLevel;
  final String phStatus;
  final String phConfidence;
  final String date;
  final String imagePath;
  final bool isSuitable;

  SoilResult({
    this.id,
    required this.farmName,
    required this.prediction,
    required this.confidence,
    required this.phLevel,
    required this.phStatus,
    this.phConfidence = '0.0',
    required this.date,
    required this.imagePath,
    required this.isSuitable,
  });

  Map<String, dynamic> toMap() {
    return {
      // Omit 'id' when null so SQLite auto-increments on insert;
      // include it on update so the correct row is targeted.
      if (id != null) 'id': id,
      'farm_name': farmName,
      'prediction': prediction,
      'confidence': confidence,
      'ph_level': phLevel,
      'ph_status': phStatus,
      'ph_confidence': phConfidence,
      'date': date,
      'image_path': imagePath,
      'is_suitable': isSuitable ? 1 : 0,
    };
  }

  factory SoilResult.fromMap(Map<String, dynamic> map) {
    return SoilResult(
      id: map['id'] as int?,
      farmName: map['farm_name'] as String,
      prediction: map['prediction'] as String,
      confidence: map['confidence'] as String,
      phLevel: map['ph_level'] as String,
      phStatus: map['ph_status'] as String,
      phConfidence: map['ph_confidence'] as String? ?? '0.0',
      date: map['date'] as String,
      imagePath: map['image_path'] as String,
      isSuitable: map['is_suitable'] == 1,
    );
  }
}
