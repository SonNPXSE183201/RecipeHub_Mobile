
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';
import '../models/recipe_models.dart';
import '../services/i_recipe_source.dart';
import '../services/recipe_mapper.dart';
import '../services/interfaces/i_file_save_service.dart';
import '../services/report/report_font.dart';
import '../services/report/sop_book_pdf.dart';
import '../services/report/report_file_actions.dart';

typedef SopPdfBuilder = Future<Uint8List> Function(
  List<RecipeItem> recipes,
  List<SopItem> sops,
  DateTime at,
);

Future<Uint8List> _buildPdf(
  List<RecipeItem> recipes,
  List<SopItem> sops,
  DateTime at,
) async {
  final font = await ReportFont.load();
  return compute(_renderPdf, (font, recipes, sops, at));
}

Uint8List _renderPdf(
  (Uint8List, List<RecipeItem>, List<SopItem>, DateTime) input,
) => SopBookPdf.build(
  fontBytes: input.$1,
  recipes: input.$2,
  sops: input.$3,
  generatedAt: input.$4,
);

enum SopBookLoad { loading, ready, error }

/// Nạp ĐỦ công thức đã ban hành cho sổ tay (không bị giới hạn `max_lookup_results`) và nhớ trang đang đọc.
class SopBookViewModel extends ChangeNotifier {
  SopBookViewModel({
    required this._source,
    this.uid,
    this.limit = 500,
    this._fileSaver,
    SopPdfBuilder? pdfBuilder,
    ReportFileActions? fileActions,
  }) : _pdfBuilder = pdfBuilder ?? _buildPdf,
       _fileActions = fileActions ?? ReportFileActions();

  final IRecipeSource _source;
  final String? uid;
  final int limit;
  bool _disposed = false;
  final IFileSaveService? _fileSaver;
  final SopPdfBuilder _pdfBuilder;
  final ReportFileActions _fileActions;
  bool _exporting = false;
  String? _exportError;
  SavedFile? _exportedFile;
  bool get exporting => _exporting;
  String? get exportError => _exportError;
  SavedFile? get exportedFile => _exportedFile;

  Future<SavedFile?> exportPdf({
    required List<SopItem> sops,
    DateTime? generatedAt,
  }) async {
    if (_exporting || _disposed || _state != SopBookLoad.ready) return null;
    _exporting = true;
    _exportError = null;
    _exportedFile = null;
    _notify();
    try {
      final saver = _fileSaver;
      if (saver == null) {
        throw const FileSaveFailure(
          'Thiết bị này chưa hỗ trợ lưu file về máy.',
        );
      }
      final at = generatedAt ?? DateTime.now();
      final bytes = await _pdfBuilder(List.of(_recipes), List.of(sops), at);
      if (_disposed) return null;
      final file = await saver.savePdf(
        fileName: SopBookPdf.fileName(at),
        bytes: bytes,
      );
      if (_disposed) return null;
      _exportedFile = file;
      return file;
    } on FileSaveFailure catch (e) {
      _exportError = e.message;
      return null;
    } catch (_) {
      _exportError = 'Không tạo được PDF sổ tay. Vui lòng thử lại.';
      return null;
    } finally {
      _exporting = false;
      _notify();
    }
  }

  Future<bool> openPdf(SavedFile file) async {
    try {
      return await _fileSaver?.open(file) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sharePdf(SavedFile file) => _fileActions.share(file);

  SopBookLoad _state = SopBookLoad.loading;
  List<RecipeItem> _recipes = const [];
  String? _error;
  int _savedPage = 0;

  SopBookLoad get state => _state;
  List<RecipeItem> get recipes => _recipes;
  String? get error => _error;
  int get savedPage => _savedPage;

  String get _prefKey => 'sop_book_page_${uid ?? 'anon'}';

  Future<void> load() async {
    _state = SopBookLoad.loading;
    _error = null;
    _notify();
    try {
      final src = _source;
      List<RecipeDetailResponse> details;
      if (src is IBulkRecipeSource) {
        details = await (src as IBulkRecipeSource).loadPublishedDetails(
          limit: limit,
        );
      } else {
        final page = await src.searchApproved(pageSize: limit);
        // A partial book must not masquerade as the full published book.
        details = await Future.wait(page.items.map((s) => src.getRecipe(s.id)));
      }
      _recipes = details.map(RecipeMapper.fromDetail).toList();
      try {
        final prefs = await SharedPreferences.getInstance();
        _savedPage = prefs.getInt(_prefKey) ?? 0;
      } catch (_) {
        _savedPage = 0;
      }
      _state = SopBookLoad.ready;
    } catch (_) {
      _error =
          'Không tải được công thức cho sổ tay. Kiểm tra kết nối rồi thử lại.';
      _state = SopBookLoad.error;
    }
    _notify();
  }

  Future<void> savePage(int page) async {
    _savedPage = page;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, page);
    } catch (_) {}
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
