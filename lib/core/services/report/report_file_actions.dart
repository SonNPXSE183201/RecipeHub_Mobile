import 'package:flutter/services.dart';

import '../interfaces/i_file_save_service.dart';

/// Shares the saved content URI through Android's chooser, never a public URL.
class ReportFileActions {
  ReportFileActions({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.recipehub.mobile/files');
  final MethodChannel _channel;

  Future<bool> share(SavedFile file) async {
    try {
      return await _channel.invokeMethod<bool>('shareFile', {
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
}
