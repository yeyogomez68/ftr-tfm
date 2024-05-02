import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tfm_admin/model/TreeDataModel.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await openDatabase(
      join(await getDatabasesPath(), 'data.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE data(speciesName TEXT, totalHeight REAL, x REAL, y REAL, fileName TEXT)',
        );
      },
      version: 1,
    );

    return _database!;
  }

  static Future<void> insertData(TreeDataModel data) async {
    final Database db = await database;
    await db.insert(
      'data',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<TreeDataModel>> getData() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('data');

    return List.generate(maps.length, (i) {
      return TreeDataModel(
        speciesName: maps[i]['speciesName'],
        totalHeight: maps[i]['totalHeight'],
        x: maps[i]['x'],
        y: maps[i]['y'],
        fileName: maps[i]['fileName'],
      );
    });
  }
}
