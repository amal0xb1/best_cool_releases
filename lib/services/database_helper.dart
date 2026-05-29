import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/complaint.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('best_cool.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE complaints (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deviceType TEXT NOT NULL,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  customerName TEXT NOT NULL,
  customerNumber TEXT NOT NULL,
  issueDescription TEXT NOT NULL,
  extraNotes TEXT,
  spareIssue TEXT,
  photoPath TEXT,
  address TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  priority INTEGER NOT NULL,
  status TEXT NOT NULL,
  createdAt TEXT NOT NULL
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE complaints ADD COLUMN deviceType TEXT NOT NULL DEFAULT "Unknown"');
      await db.execute('ALTER TABLE complaints ADD COLUMN extraNotes TEXT');
      await db.execute('ALTER TABLE complaints ADD COLUMN spareIssue TEXT');
    }
  }

  Future<Complaint> create(Complaint complaint) async {
    final db = await instance.database;
    final id = await db.insert('complaints', complaint.toMap());
    return complaint.copyWith(id: id);
  }

  Future<List<Complaint>> readAllComplaints() async {
    final db = await instance.database;
    final orderBy = 'createdAt DESC';
    final result = await db.query('complaints', orderBy: orderBy);
    return result.map((json) => Complaint.fromMap(json)).toList();
  }

  Future<List<Complaint>> readComplaintsByStatus(String status) async {
    final db = await instance.database;
    final result = await db.query(
      'complaints',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'priority DESC, createdAt DESC',
    );
    return result.map((json) => Complaint.fromMap(json)).toList();
  }

  Future<int> update(Complaint complaint) async {
    final db = await instance.database;
    return db.update(
      'complaints',
      complaint.toMap(),
      where: 'id = ?',
      whereArgs: [complaint.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'complaints',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> backupDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'best_cool.db');
    
    final dbFile = File(path);
    if (!await dbFile.exists()) {
      throw 'Local database file is not initialized yet.';
    }
    
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw 'External storage directory is not accessible.';
    }
    
    await directory.create(recursive: true);
    final backupPath = join(directory.path, 'best_cool_backup.db');
    await dbFile.copy(backupPath);
    return backupPath;
  }

  Future<bool> restoreDatabase() async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw 'External storage directory is not accessible.';
    }
    
    await directory.create(recursive: true);
    final backupPath = join(directory.path, 'best_cool_backup.db');
    final backupFile = File(backupPath);
    
    if (!await backupFile.exists()) {
      throw 'Backup file "best_cool_backup.db" not found in folder: Android/data/com.bestcool.best_cool/files/';
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'best_cool.db');
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    await backupFile.copy(path);
    await database; // re-initialize database connection
    return true;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
