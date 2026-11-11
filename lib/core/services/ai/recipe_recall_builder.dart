import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../models/ai_practice_models.dart';
import '../../models/app_models.dart';
import '../../models/recipe_models.dart';

/// Builds auditable choices from source. The model cannot invent an answer key.
class RecipeRecallBuilder {
  static String number(num n) => n == n.roundToDouble() ? '${n.toInt()}' : '$n';

  static RecallContext build(RecipeDetailResponse d, List<SopItem> sops) {
    final relevant =
        sops
            .where(
              (s) =>
                  d.sopCodes.contains(s.code) ||
                  d.sopCodes.contains(s.id) ||
                  s.linkedRecipeCodes.contains(d.code),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final questions = <RecallQuestion>[];
    final fingerprint = <Object?>[
      d.id,
      d.versionId,
      d.versionNumber,
      d.updatedAt.toIso8601String(),
      d.versionStatus,
      d.servingNotes,
      d.specialRequests,
    ];
    void add(
      String id,
      String prompt,
      String correct,
      Iterable<String> wrong,
      String excerpt,
      String source,
    ) {
      final choices = <String>{
        correct.trim(),
        ...wrong.map((s) => s.trim()).where((s) => s.isNotEmpty),
      }.take(4).toList();
      if (correct.trim().isEmpty || choices.length < 2) return;
      // Stable per-source shuffle, not on rebuild.
      choices.shuffle(Random(id.codeUnits.fold<int>(0, (a, b) => a + b)));
      questions.add(
        RecallQuestion(
          id: id,
          prompt: prompt,
          choices: choices,
          correctIndex: choices.indexOf(correct.trim()),
          explanation: excerpt,
          source: source,
        ),
      );
    }

    List<RecipeIngredientResponse> ingredients = d.ingredients;
    var note = '';
    if (d.sizes.length == 1) ingredients = d.sizes.single.ingredients;
    if (d.sizes.length > 1) {
      // No silent first-size default: only facts common across every portion.
      ingredients = d.sizes.first.ingredients
          .where(
            (i) => d.sizes.every(
              (s) => s.ingredients.any(
                (x) =>
                    x.ingredientName == i.ingredientName &&
                    x.quantity == i.quantity &&
                    x.unitCode == i.unitCode,
              ),
            ),
          )
          .toList();
      note = 'Món có nhiều định lượng. Chỉ ôn phần chung đã được xác định trong công thức.';
    }
    fingerprint.addAll([
      for (final s in d.sizes)
        [
          s.code,
          for (final i in s.ingredients)
            [i.ingredientName, i.quantity, i.unitCode],
        ],
    ]);
    fingerprint.addAll([
      for (final i in d.ingredients)
        [i.ingredientName, i.quantity, i.unitCode, i.note, i.warning],
    ]);
    for (var n = 0; n < ingredients.length; n++) {
      final i = ingredients[n];
      if (i.quantity <= 0 ||
          !i.quantity.isFinite ||
          i.unitCode.trim().isEmpty ||
          i.ingredientName.trim().isEmpty) {
        continue;
      }
      final correct = '${number(i.quantity)} ${i.unitCode}';
      add(
        'ingredient:$n',
        'Theo công thức ${d.name}, cần bao nhiêu ${i.ingredientName}?',
        correct,
        [
          for (final multiplier in [0.5, 1.5, 2.0])
            '${number(i.quantity * multiplier)} ${i.unitCode}',
        ],
        '${i.ingredientName}: $correct.${i.warning == null ? '' : ' ${i.warning}'}',
        '${d.name} · Định lượng · v${d.versionNumber}',
      );
    }
    final steps = [...d.steps]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    fingerprint.addAll([
      for (final st in steps)
        [
          st.title,
          st.description,
          st.durationSeconds,
          st.temperatureCelsius,
          st.equipment,
          st.safetyNote,
        ],
    ]);
    for (var n = 0; n + 1 < steps.length; n++) {
      final st = steps[n], next = steps[n + 1];
      if (st.title.trim().isEmpty ||
          next.title.trim().isEmpty ||
          steps.map((s) => s.title.trim()).toSet().length != steps.length) {
        continue;
      }
      add(
        'step:$n',
        'Theo công thức ${d.name}, sau “${st.title}” là bước nào?',
        next.title,
        steps.where((s) => s != next).map((s) => s.title),
        '${next.title}: ${next.description}',
        '${d.name} · Bước ${n + 2} · v${d.versionNumber}',
      );
    }
    for (final sop in relevant) {
      fingerprint.add([
        sop.id,
        sop.version,
        sop.summary,
        for (final s in sop.steps) [s.title, s.content, s.note],
      ]);
      for (var n = 0; n < sop.steps.length; n++) {
        final st = sop.steps[n];
        if (st.content.trim().isEmpty ||
            st.content.length > 260 ||
            st.title.trim().isEmpty) {
          continue;
        }
        // Exact source excerpts only. No made-up safety advice or numerical claims.
        add(
          'sop:${sop.id}:$n',
          'Trong SOP “${sop.title}”, bước “${st.title}” hướng dẫn gì?',
          st.content,
          sop.steps
              .where((s) => s != st && s.content.length <= 260)
              .map((s) => s.content),
          '${st.content}${st.note == null ? '' : '\n${st.note}'}',
          '${sop.title} · Bước ${st.stepNumber} · ${sop.version}',
        );
      }
    }
    return RecallContext(
      recipeId: d.id,
      recipeName: d.name,
      revision: sha256.convert(utf8.encode(jsonEncode(fingerprint))).toString(),
      questions: d.versionStatus.toLowerCase() == 'published'
          ? questions.take(40).toList()
          : [],
      note: note,
    );
  }

  static List<RecallQuestion> validate(
    RecallContext context,
    List<String> refs,
  ) {
    if (refs.isEmpty || refs.length > 5 || refs.toSet().length != refs.length) {
      throw const FormatException('Invalid question selection');
    }
    final byId = {for (final q in context.questions) q.id: q};
    return refs.map((id) {
      final q = byId[id];
      if (q == null ||
          q.choices.length < 2 ||
          q.choices.length > 4 ||
          q.choices.map((s) => s.trim().toLowerCase()).toSet().length !=
              q.choices.length ||
          q.correctIndex < 0 ||
          q.correctIndex >= q.choices.length) {
        throw const FormatException('Invalid source reference');
      }
      return q;
    }).toList();
  }
}
