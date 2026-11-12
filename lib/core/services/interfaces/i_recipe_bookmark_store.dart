/// Lưu danh sách món đã đánh dấu theo từng người dùng (không mất khi tắt app).
abstract class IRecipeBookmarkStore {
  Future<Set<String>> load(String uid);

  Future<void> save(String uid, Set<String> recipeCodes);
}
