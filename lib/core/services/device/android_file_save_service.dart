
import 'package:flutter/services.dart';

import '../interfaces/i_file_save_service.dart';

/// Lưu file qua MethodChannel Kotlin (MediaStore.Downloads, `Download/RecipeHub/`, Android 10+).
class AndroidFileSaveService implements IFileSaveService {
  AndroidFileSaveService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.recipehub.mobile/files';
  static const folder = 'Download/RecipeHub';

  final MethodChannel _channel;

  @override
  Future<SavedFile> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final uri = await _channel.invokeMethod<String>('savePdf', {
        'name': fileName,
        'bytes': bytes,
        'folder': 'RecipeHub',
      });
      if (uri == null || uri.isEmpty) {
        throw const FileSaveFailure(
          'Không lưu được file về máy. Vui lòng thử lại.',
        );
      }
      return SavedFile(
        name: fileName,
        displayPath: '$folder/$fileName',
        uri: uri,
      );
    } on PlatformException catch (e) {
      throw FileSaveFailure(_message(e.code));
    } on MissingPluginException {
      throw const FileSaveFailure('Thiết bị này chưa hỗ trợ lưu file về máy.');
    }
  }

  @override
  Future<bool> open(SavedFile file) async {
    try {
      return await _channel.invokeMethod<bool>('openFile', {
            'uri': file.uri,
            'mime': 'application/pdf',
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static String _message(String code) => switch (code) {
    'no_space' => 'Bộ nhớ máy đã đầy. Hãy giải phóng dung lượng rồi thử lại.',
    'unsupported' =>
      'Android dưới 10 chưa hỗ trợ lưu thẳng vào thư mục Tải xuống.',
    _ => 'Không lưu được file về máy. Vui lòng thử lại.',
  };
}
