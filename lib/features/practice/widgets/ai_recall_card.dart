import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/ai_practice_models.dart';
import '../../../core/theme/nomad_kit.dart';
import '../../../core/viewmodels/ai_practice_viewmodel.dart';

class AiRecallCard extends StatelessWidget {
  const AiRecallCard({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiPracticeViewModel>();
    return Container(
      key: const ValueKey('ai_recall_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NomadKit.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/icon_sparkle_ai.png',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vm.templateMode ? 'Ôn bằng câu hỏi mẫu' : 'AI cùng luyện',
                  style: NomadKit.subtitle,
                ),
              ),
              Switch.adaptive(
                activeTrackColor: NomadKit.sand,
                value: vm.aiEnabled,
                onChanged: (value) => value ? vm.enableAi() : vm.disableAi(),
              ),
            ],
          ),
          if (!vm.aiEnabled) ...[
            const Text(
              'Hỏi ngắn theo nhịp luyện để nhớ công thức. Không tính điểm.',
              style: NomadKit.caption,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => vm.enableAi(templates: true),
                child: const Text('Ôn bằng câu hỏi mẫu'),
              ),
            ),
          ] else if (vm.collapsed) ...[
            TextButton(
              onPressed: () => vm.setCollapsed(false),
              child: const Text('Mở câu hỏi ôn tập'),
            ),
          ] else ...[
            if (vm.question != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${(vm.seconds ~/ 60).toString().padLeft(2, '0')}:${(vm.seconds % 60).toString().padLeft(2, '0')}',
                      style: NomadKit.subtitle,
                    ),
                  ),
                  TextButton(
                    onPressed: vm.toggleTimer,
                    child: Text(vm.running ? 'Tạm dừng' : 'Tiếp tục bấm giờ'),
                  ),
                ],
              ),
            if (vm.sourceNote.isNotEmpty)
              Text(vm.sourceNote, style: NomadKit.caption),
            if (vm.aiState == RecallState.loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Đang chuẩn bị câu hỏi từ công thức và SOP… Bạn cứ tiếp tục luyện.',
                style: NomadKit.caption,
              ),
            ],
            if (vm.aiState == RecallState.error ||
                vm.aiState == RecallState.empty) ...[
              Text(
                vm.error ??
                    'Chưa đủ nội dung có căn cứ để tạo lựa chọn cho món này.',
                style: NomadKit.body,
              ),
              Wrap(
                spacing: 8,
                children: [
                  if (vm.canRetry)
                    TextButton(
                      onPressed: () => vm.enableAi(),
                      child: const Text('Thử lại AI'),
                    ),
                  TextButton(
                    onPressed: () => vm.enableAi(templates: true),
                    child: const Text('Ôn bằng câu hỏi mẫu'),
                  ),
                ],
              ),
            ],
            if (vm.aiState == RecallState.waiting)
              Text(
                vm.running
                    ? 'Câu hỏi sẽ xuất hiện theo nhịp luyện. Timer vẫn chạy.'
                    : 'Bấm giờ để bắt đầu hoặc tiếp tục nhận câu hỏi.',
                style: NomadKit.caption,
              ),
            if (vm.aiState == RecallState.exhausted)
              const Text(
                'Đã xem hết câu hỏi của phiên này. Bạn cứ tiếp tục luyện nhé.',
                style: NomadKit.body,
              ),
            if (vm.question case final q?) ...[
              const SizedBox(height: 8),
              Text(q.prompt, style: NomadKit.subtitle),
              const SizedBox(height: 12),
              for (var i = 0; i < q.choices.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    key: ValueKey('recall_choice_$i'),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.all(12),
                      foregroundColor:
                          vm.selectedIndex != null && i == q.correctIndex
                          ? NomadKit.forest
                          : NomadKit.ink,
                      disabledForegroundColor: i == q.correctIndex
                          ? NomadKit.forest
                          : NomadKit.secondary,
                      backgroundColor:
                          vm.selectedIndex != null && i == q.correctIndex
                          ? NomadKit.forestLight
                          : vm.selectedIndex == i
                          ? NomadKit.warningLight
                          : NomadKit.surface,
                      side: const BorderSide(color: NomadKit.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: vm.selectedIndex == null
                        ? () => vm.answer(i)
                        : null,
                    child: Row(
                      children: [
                        Text(
                          '${String.fromCharCode(65 + i)}.',
                          style: NomadKit.label,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(q.choices[i], style: NomadKit.body),
                        ),
                      ],
                    ),
                  ),
                ),
              if (vm.selectedIndex != null || vm.hint) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    vm.selectedIndex == null
                        ? 'Gợi ý từ công thức'
                        : vm.isCorrect!
                        ? 'Đúng rồi!'
                        : 'Cùng nhớ lại công thức nhé',
                    style: NomadKit.subtitle.copyWith(
                      color: vm.isCorrect == true
                          ? NomadKit.forest
                          : NomadKit.sandDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(q.explanation, style: NomadKit.body),
                const SizedBox(height: 6),
                Text('Nguồn: ${q.source}', style: NomadKit.caption),
              ],
              Wrap(
                spacing: 8,
                children: [
                  if (vm.selectedIndex == null)
                    TextButton(
                      onPressed: vm.showHint,
                      child: const Text('Gợi ý / Xem nguồn chuẩn'),
                    ),
                  TextButton(
                    onPressed: vm.continuePractice,
                    child: Text(
                      vm.selectedIndex == null
                          ? 'Bỏ qua câu hỏi'
                          : 'Tiếp tục luyện',
                    ),
                  ),
                ],
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => vm.setCollapsed(true),
                child: const Text('Thu gọn'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
