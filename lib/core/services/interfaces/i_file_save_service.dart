import 'dart:typed_data';

/// File đã lưu về máy (Download/RecipeHub/...).
class SavedFile {
  const SavedFile({
    required this.name,
    required this.displayPath,
    required this.uri,
  });

  final String name;

  /// Đường dẫn hiển thị cho người dùng, ví dụ `Download/RecipeHub/luyen-tap_20261107-0930.pdf`.
  final String displayPath;

  /// Content Uri (MediaStore) để mở bằng ứng dụng khác.
  final String uri;
}

/// Lỗi lưu file, [message] đã là tiếng Việt cho người đọc.
class FileSaveFailure implements Exception {
  const FileSaveFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class IFileSaveService {
  /// Lưu PDF vào thư mục tải xuống của máy. Ném [FileSaveFailure] khi lỗi.
  Future<SavedFile> savePdf({
    required String fileName,
    required Uint8List bytes,
  });

  /// Mở file đã lưu bằng ứng dụng đọc PDF. Trả `false` nếu không có ứng dụng phù hợp.
  Future<bool> open(SavedFile file);
}
