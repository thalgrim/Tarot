import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';

import '../models/game.dart';
import 'database_factory_provider.dart';

class GameRepository {
  static final _store = stringMapStoreFactory.store('games');

  Database? _db;

  Future<Database> _database() async {
    final existing = _db;
    if (existing != null) return existing;

    final factory = getDatabaseFactory();
    late final String path;
    if (kIsWeb) {
      path = 'tarot.db';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = p.join(dir.path, 'tarot.db');
    }
    final db = await factory.openDatabase(path);
    _db = db;
    return db;
  }

  Future<void> saveGame(TarotGame game) async {
    final db = await _database();
    await _store.record(game.id).put(db, game.toMap());
  }

  Future<List<TarotGame>> listGames() async {
    final db = await _database();
    final records = await _store.find(
      db,
      finder: Finder(sortOrders: [SortOrder('updatedAt', false)]),
    );
    return records.map((r) => TarotGame.fromMap(r.value)).toList();
  }

  Future<TarotGame?> loadGame(String id) async {
    final db = await _database();
    final value = await _store.record(id).get(db);
    if (value == null) return null;
    return TarotGame.fromMap(value);
  }

  Future<void> deleteGame(String id) async {
    final db = await _database();
    await _store.record(id).delete(db);
  }
}
