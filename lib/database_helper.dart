import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/laporan.dart';

class StatLaporan {
  final int total;
  final int aktif;
  final int selesai;
  const StatLaporan(this.total, this.aktif, this.selesai);
}

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async => _db ??= await _init();

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'smart_city.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE laporan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            judul TEXT NOT NULL,
            kategori TEXT NOT NULL,
            lokasi TEXT NOT NULL,
            urgensi INTEGER NOT NULL,
            tanggal TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'Baru'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE laporan ADD COLUMN urgensi INTEGER NOT NULL DEFAULT 1',
          );
          await db.execute(
            "ALTER TABLE laporan ADD COLUMN status TEXT NOT NULL DEFAULT 'Baru'",
          );
        }
      },
    );
  }

  Future<int> tambah(Laporan l) async {
    final db = await database;
    return db.insert('laporan', l.toMap());
  }

  Future<List<Laporan>> getLaporan({
    String search = '',
    String status = 'Semua',
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object>[];
    if (search.isNotEmpty) {
      where.add('(judul LIKE ? OR lokasi LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    if (status != 'Semua') {
      where.add('status = ?');
      args.add(status);
    }
    final rows = await db.query(
      'laporan',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy:
          "CASE WHEN status = 'Selesai' THEN 1 ELSE 0 END ASC, urgensi DESC, tanggal ASC",
    );
    return rows.map(Laporan.fromMap).toList();
  }

  Future<StatLaporan> getStatistik() async {
    final db = await database;
    final total =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM laporan'),
        ) ??
        0;
    final aktif =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM laporan WHERE status IN (?, ?)',
            ['Baru', 'Diproses'],
          ),
        ) ??
        0;
    final selesai =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM laporan WHERE status = ?', [
            'Selesai',
          ]),
        ) ??
        0;
    return StatLaporan(total, aktif, selesai);
  }

  Future<int> updateStatus(int id, String status) async {
    final db = await database;
    return db.update(
      'laporan',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> update(Laporan l) async {
    final db = await database;
    return db.update('laporan', l.toMap(), where: 'id = ?', whereArgs: [l.id]);
  }

  Future<int> hapus(int id) async {
    final db = await database;
    return db.delete('laporan', where: 'id = ?', whereArgs: [id]);
  }
}
