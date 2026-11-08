import 'dart:typed_data';

import '../interfaces/i_file_save_service.dart';

class MockFileSaveService implements IFileSaveService {
  MockFileSaveService({this.failNext, this.canOpen = true});

  FileSaveFailure? failNext;
  bool canOpen;
  final List<String> savedNames = [];
  final List<SavedFile> opened = [];

  @override
  Future<SavedFile> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
    savedNames.add(fileName);
    return SavedFile(
      name: fileName,
      displayPath: 'Download/RecipeHub/$fileName',
      uri: 'content://mock/$fileName',
    );
  }

  @override
  Future<bool> open(SavedFile file) async {
    opened.add(file);
    return canOpen;
  }
}
