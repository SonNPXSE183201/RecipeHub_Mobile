import 'package:flutter/foundation.dart';

import '../services/interfaces/i_recipe_bookmark_store.dart';

/// Trạng thái đánh dấu món yêu thích của một người dùng.
class RecipeBookmarkViewModel extends ChangeNotifier {
  RecipeBookmarkViewModel({required this._store, String? uid})
    : _uid = uid ?? 'anon';

  final IRecipeBookmarkStore _store;
  final String _uid;
  Set<String> _codes = <String>{};
  bool _loaded = false;
  bool _disposed = false;

  bool get loaded => _loaded;
  Set<String> get codes => Set.unmodifiable(_codes);
  bool isBookmarked(String recipeCode) => _codes.contains(recipeCode);

  Future<void> load() async {
    try {
      _codes = await _store.load(_uid);
    } catch (_) {
      _codes = <String>{};
    }
    _loaded = true;
    _notify();
  }

  /// Trả về trạng thái mới (true = đã lưu); `null` nếu lưu thất bại và đã hoàn tác.
  Future<bool?> toggle(String recipeCode) async {
    final before = Set<String>.of(_codes);
    final next = Set<String>.of(_codes);
    final nowSaved = next.add(recipeCode);
    if (!nowSaved) next.remove(recipeCode);
    _codes = next;
    _notify();
    try {
      await _store.save(_uid, next);
      return nowSaved;
    } catch (_) {
      _codes = before;
      _notify();
      return null;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
