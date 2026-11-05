import '../models/app_models.dart';
import '../models/recipe_models.dart';

/// Chuyển DTO của backend (RecipeDetailResponse) sang model UI (RecipeItem).
///
/// Backend hiện chỉ có MỘT bộ định lượng cho mỗi công thức (chưa có biến thể S/M/L,
/// xem docs/mobile-backend-api-gaps.md) nên UI nhận đúng 1 size chuẩn 'M'.
class RecipeMapper {
  RecipeMapper._();

  static RecipeItem fromDetail(RecipeDetailResponse d) {
    final ingredients = [...d.ingredients]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final steps = [...d.steps]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final portions = ingredients
        .map((i) => IngredientPortion(
              name: i.ingredientName,
              amount: i.quantity,
              unit: i.unitCode,
              note: i.note ?? i.stageName,
              warning: i.warning,
            ))
        .toList();

    var cursor = 0;
    var stepNo = 0;
    final stepItems = <RecipeStepItem>[];
    for (final st in steps) {
      stepNo++;
      final dur = st.durationSeconds ?? 0;
      final start = cursor;
      cursor += dur > 0 ? dur : 10;
      final extra = <String>[
        if (st.equipment != null && st.equipment!.isNotEmpty) 'Dụng cụ: ${st.equipment}',
        if (st.safetyNote != null && st.safetyNote!.isNotEmpty) 'Lưu ý: ${st.safetyNote}',
      ];
      stepItems.add(RecipeStepItem(
        stepNumber: stepNo,
        title: st.title,
        instruction: [st.description, ...extra].where((e) => e.isNotEmpty).join('\n'),
        videoStartSeconds: start,
        videoEndSeconds: cursor,
        temperature: st.temperatureCelsius == null ? null : '${_trim(st.temperatureCelsius!)}°C',
        durationText: dur > 0 ? '$dur giây' : null,
      ));
    }

    final totalSeconds = steps.fold<int>(0, (a, s) => a + (s.durationSeconds ?? 0));
    final temps = steps.map((s) => s.temperatureCelsius).whereType<double>().toList();
    final u = d.updatedAt.toLocal();

    return RecipeItem(
      id: d.id,
      code: d.code,
      name: d.name,
      category: categoryOf(d.name),
      version: 'v${d.versionNumber}.0',
      status: d.versionStatus.toLowerCase() == 'published' ? 'Ban hành' : d.versionStatus,
      publishedDate:
          '${u.day.toString().padLeft(2, '0')}/${u.month.toString().padLeft(2, '0')}/${u.year}',
      publisher: 'R&D RecipeHub',
      description: d.description ?? '',
      standardTime: totalSeconds > 0 ? '$totalSeconds giây' : '—',
      standardTemp: temps.isEmpty ? '—' : '${_trim(temps.reduce((a, b) => a > b ? a : b))}°C',
      hasNewerVersion: false,
      sizes: [
        RecipeSizeOption(
          sizeCode: 'M',
          label: 'Định lượng chuẩn',
          servingNotes: '',
          ingredients: portions,
        ),
      ],
      steps: stepItems,
      videoUrl: '',
    );
  }

  /// Backend chưa có danh mục đồ uống → suy ra nhóm từ tên để khớp bộ lọc UI.
  static String categoryOf(String name) {
    final n = name.toLowerCase();
    if (n.contains('cà phê') || n.contains('cafe') || n.contains('coffee') || n.contains('cold brew') || n.contains('espresso')) {
      return 'Cà phê & Cold Brew';
    }
    if (n.contains('sữa') || n.contains('kem') || n.contains('milk') || n.contains('latte') || n.contains('matcha')) return 'Trà Sữa & Kem Mây';
    return 'Trà Trái Cây';
  }

  static String _trim(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
