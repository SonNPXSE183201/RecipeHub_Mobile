import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../models/recipe_models.dart';
import '../models/session_models.dart';
import '../services/i_recipe_source.dart';
import '../services/interfaces/i_crash_reporter.dart';
import '../services/recipe_mapper.dart';
import '../services/mock_data_service.dart';

/// Nạp công thức đã ban hành từ Gateway thật; hiển thị loading / ready / empty / error.
class RecipeViewModel extends ChangeNotifier {
  RecipeViewModel({required this._source, required this._crash});

  final IRecipeSource _source;
  final ICrashReporter _crash;
  bool _disposed = false;

  ViewState _state = ViewState.idle;
  List<RecipeItem> _items = const [];
  String? _error;

  ViewState get state => _state;
  List<RecipeItem> get items => _items;
  String? get error => _error;

  int _loadedLimit = 0;

  /// [silent]: tải lại phía sau, giữ nguyên danh sách đang hiển thị (không chuyển sang loading).
  Future<void> load({int limit = 50, bool silent = false}) async {
    if (!silent) {
      _state = ViewState.loading;
      _error = null;
      _notify();
    }
    try {
      final details = await _loadDetails(limit);
      _loadedLimit = limit;
      _items = details.map(RecipeMapper.fromDetail).toList();
      MockDataService.instance.recipes = List.of(_items);
      _state = _items.isEmpty ? ViewState.empty : ViewState.ready;
    } catch (e, s) {
      // Tải ngầm lỗi: giữ danh sách đang có, chỉ ghi non-fatal.
      if (!silent) {
        _error = _message(e);
        _state = ViewState.error;
      }
      await _crash.recordError(e, s, reason: silent ? 'recipe_reload_limit' : 'recipe_load');
    }
    _notify();
  }

  /// Firestore: một truy vấn ra đủ chi tiết. Gateway: danh sách + chi tiết từng món; món lỗi (vừa bị ẩn,
  /// 404…) bị bỏ qua thay vì làm hỏng cả lần tải – chỉ báo lỗi khi KHÔNG món nào tải được.
  Future<List<RecipeDetailResponse>> _loadDetails(int limit) async {
    final src = _source;
    if (src is IBulkRecipeSource) return (src as IBulkRecipeSource).loadPublishedDetails(limit: limit);
    final page = await src.searchApproved(pageSize: limit);
    Object? firstError;
    final details = await Future.wait(page.items.map((s) async {
      try {
        return await src.getRecipe(s.id);
      } catch (e) {
        firstError ??= e;
        return null;
      }
    }));
    final ok = details.whereType<RecipeDetailResponse>().toList();
    if (ok.isEmpty && firstError != null) throw firstError!;
    return ok;
  }

  /// Remote Config đổi `max_lookup_results`. Giảm: View tự cắt bằng `take`.
  /// Tăng vượt số đã tải trong khi danh sách đang bị cắt đúng bằng giới hạn cũ → tải lại ngầm.
  Future<void> applyLimit(int limit) async {
    if (kDebugMode) {
      debugPrint('[Recipe] applyLimit $limit state=$_state loaded=$_loadedLimit items=${_items.length}');
    }
    if (_state != ViewState.ready) return;
    if (limit > _loadedLimit && _items.length >= _loadedLimit) {
      await load(limit: limit, silent: true);
    }
  }

  /// Tìm công thức cho deep link FCM theo `id` hoặc `code`.
  /// Danh sách đã tải có thể bị giới hạn bởi Remote Config `max_lookup_results`,
  /// nên nếu không có sẵn thì hỏi Gateway theo mã (vẫn chỉ lấy bản đã ban hành).
  Future<RecipeItem?> findForDeepLink(String? idOrCode) async {
    if (idOrCode == null || idOrCode.isEmpty) return null;
    for (final r in _items) {
      if (r.id == idOrCode || r.code == idOrCode) return r;
    }
    // Firestore: id document = mã món → đọc thẳng (tìm theo từ khóa có thể trượt khi nhiều món cùng tiền tố).
    if (_source is IBulkRecipeSource) {
      try {
        return RecipeMapper.fromDetail(await _source.getRecipe(idOrCode));
      } catch (e, s) {
        await _crash.recordError(e, s, reason: 'deeplink_recipe_lookup');
        return null;
      }
    }
    try {
      final page = await _source.searchApproved(query: idOrCode, pageSize: 5);
      for (final s in page.items) {
        if (s.id == idOrCode || s.code == idOrCode) {
          return RecipeMapper.fromDetail(await _source.getRecipe(s.id));
        }
      }
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'deeplink_recipe_lookup');
    }
    return null;
  }

  static String _message(Object e) {
    if (e is RecipeOfflineException) {
      return 'Không có kết nối mạng và chưa có dữ liệu công thức lưu sẵn. Bật Wi-Fi rồi thử lại.';
    }
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Không kết nối được máy chủ công thức. Kiểm tra mạng / Gateway rồi thử lại.';
        default:
          final code = e.response?.statusCode;
          return code == null ? 'Lỗi mạng khi tải công thức.' : 'Máy chủ trả lỗi $code khi tải công thức.';
      }
    }
    return 'Không tải được công thức. Vui lòng thử lại.';
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
