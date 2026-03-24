import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mock_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_app_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Create Categories Table
    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  iconCode $integerType,
  colorValue $integerType,
  budgetLimit REAL DEFAULT 0
)
''');

    // Create Transactions Table
    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  title $textType,
  notes TEXT,
  date $textType,
  amount $realType,
  categoryId $textType,
  isIncome $integerType,
  FOREIGN KEY (categoryId) REFERENCES categories (id)
)
''');

    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    for (final category in MockData.categories) {
      final mockBudget = MockData.budgets.any((b) => b.category.id == category.id)
          ? MockData.budgets.firstWhere((b) => b.category.id == category.id)
          : null;

      final categoryMap = category.toMap();
      categoryMap['budgetLimit'] = mockBudget?.limit ?? 0.0;
      await db.insert('categories', categoryMap);
    }
  }

  // --- Category Methods ---

  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('categories', row);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await instance.database;
    return await db.query('categories');
  }

  Future<Map<String, dynamic>?> getCategoryById(String id) async {
    final db = await instance.database;
    final results = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateCategoryBudget(String id, double limit) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      {'budgetLimit': limit},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Transaction Methods ---

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    // Join with categories to get full details
    return await db.rawQuery('''
      SELECT t.*, c.name as categoryName, c.iconCode, c.colorValue
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
      ORDER BY t.date DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTransactionsByCategoryId(
    String categoryId,
  ) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT t.*, c.name as categoryName, c.iconCode, c.colorValue
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
      WHERE t.categoryId = ?
      ORDER BY t.date DESC
      ''',
      [categoryId],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> clearDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finance_app_v3.db');

    // Close existing connection if open
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete the database file
    await deleteDatabase(path);

    // Re-initialize to populate with default data again
    await database;
  }
}
