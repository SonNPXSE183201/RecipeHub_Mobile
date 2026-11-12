import 'package:shared_preferences/shared_preferences.dart';

import 'interfaces/i_recipe_bookmark_store.dart';

class PrefsRecipeBookmarkStore implements IRecipeBookmarkStore {
  const PrefsRecipeBookmarkStore();

  String _key(String uid) => 'recipe_bookmarks_$uid';

  @override
  Future<Set<String>> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(uid)) ?? const <String>[]).toSet();
  }

  @override
  Future<void> save(String uid, Set<String> recipeCodes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(uid), recipeCodes.toList()..sort());
  }
}
