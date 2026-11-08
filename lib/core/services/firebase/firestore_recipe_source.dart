import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/recipe_models.dart';
import '../i_recipe_source.dart';

/// Công thức lưu trên Firestore `recipes/{code}` (Admin quản lý trên web).
/// Chuyển về đúng DTO của Gateway để `RecipeMapper`, ViewModel và View không phải đổi.
class FirestoreRecipeSource implements IRecipeSource, IBulkRecipeSource {
  FirestoreRecipeSource({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Bỏ dấu tiếng Việt, chữ thường – khớp `searchKeywords` do web ghi.
  static String normalize(String s) {
    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final lower = s.toLowerCase();
    final b = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString();
  }

  @override
  Future<PagedResponse<RecipeSummaryResponse>> searchApproved({String? query, int pageSize = 50}) async {
    Query<Map<String, dynamic>> q = _db.collection('recipes').where('status', isEqualTo: 'published');
    final words = normalize(query ?? '').split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty).toList();
    if (words.isNotEmpty) {
      q = q.where('searchKeywords', arrayContains: words.first);
    } else {
      q = q.orderBy('name');
    }
    final snap = await q.limit(pageSize).get();
    if (snap.docs.isEmpty && snap.metadata.isFromCache) throw const RecipeOfflineException();
    final items = snap.docs.map((d) => RecipeSummaryResponse.fromJson(_summaryJson(d.id, d.data()))).toList();
    return PagedResponse(items: items, page: 1, pageSize: pageSize, totalCount: items.length);
  }

  @override
  Future<List<RecipeDetailResponse>> loadPublishedDetails({int limit = 50}) async {
    final snap =
        await _db.collection('recipes').where('status', isEqualTo: 'published').orderBy('name').limit(limit).get();
    if (snap.docs.isEmpty && snap.metadata.isFromCache) throw const RecipeOfflineException();
    final out = <RecipeDetailResponse>[];
    for (final d in snap.docs) {
      try {
        out.add(RecipeDetailResponse.fromJson(detailJson(d.id, d.data())));
      } catch (_) {
        // Một món dữ liệu hỏng không làm hỏng cả danh sách.
      }
    }
    return out;
  }

  @override
  Future<RecipeDetailResponse> getRecipe(String id) async {
    final snap = await _db.doc('recipes/$id').get();
    final data = snap.data();
    if (!snap.exists || data == null || data['status'] != 'published') {
      throw StateError('Công thức $id không còn ban hành.');
    }
    return RecipeDetailResponse.fromJson(detailJson(snap.id, data));
  }

  static Map<String, dynamic> _summaryJson(String id, Map<String, dynamic> d) => {
        'id': id,
        'code': d['code'] ?? id,
        'state': 'active',
        'versionId': '$id-v${d['versionNumber'] ?? 1}',
        'versionNumber': (d['versionNumber'] as num?)?.toInt() ?? 1,
        'versionStatus': d['status'] ?? 'published',
        'name': d['name'] ?? id,
        'updatedAt': _iso(d['updatedAt']),
        'createdAt': _iso(d['updatedAt']),
      };

  /// Firestore → JSON dạng `RecipeDetailResponse` của Gateway.
  static Map<String, dynamic> detailJson(String id, Map<String, dynamic> d) {
    final ingredients = (d['ingredients'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>();
    final steps = (d['steps'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>();
    return {
      ..._summaryJson(id, d),
      'description': d['description'],
      'ingredients': [
        for (var i = 0; i < ingredients.length; i++)
          {
            'id': '$id-i$i',
            'ingredientId': '$id-i$i',
            'ingredientCode': '',
            'ingredientName': ingredients[i]['name'] ?? '',
            'quantity': (ingredients[i]['quantity'] as num?)?.toDouble() ?? 0,
            'unitId': ingredients[i]['unit'] ?? '',
            'unitCode': ingredients[i]['unit'] ?? '',
            'sortOrder': i + 1,
            'stageName': ingredients[i]['stage'],
            'note': ingredients[i]['note'],
            'warning': ingredients[i]['warning'],
          },
      ],
      'steps': [
        for (var i = 0; i < steps.length; i++)
          {
            'id': '$id-s$i',
            'publicId': '$id-s$i',
            'sortOrder': i + 1,
            'title': steps[i]['title'] ?? 'Bước ${i + 1}',
            'description': steps[i]['description'] ?? '',
            'durationSeconds': (steps[i]['durationSeconds'] as num?)?.toInt(),
            'temperatureCelsius': (steps[i]['temperatureCelsius'] as num?)?.toDouble(),
            'equipment': steps[i]['equipment'],
            'safetyNote': steps[i]['safetyNote'],
            'media': const [],
          },
      ],
    };
  }

  static String _iso(Object? v) =>
      v is Timestamp ? v.toDate().toUtc().toIso8601String() : DateTime.now().toUtc().toIso8601String();
}
