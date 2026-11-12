import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/ai_practice_models.dart';
import '../../../core/theme/nomad_kit.dart';
import '../../../core/viewmodels/ai_practice_viewmodel.dart';

/// Thẻ "AI cùng luyện" theo redesign: eyebrow + tiêu đề + nội dung theo từng
/// trạng thái (sẵn sàng, chuẩn bị, câu hỏi, phản hồi, lỗi, hoàn tất).
///
/// [standalone] = true (mặc định): thẻ tự chứa hàng timer và các nút hành
/// động; màn tự luyện truyền false vì đã có thanh hành động phía dưới.
class AiRecallCard extends StatelessWidget {
  const AiRecallCard({super.key, this.standalone = true});

  final bool standalone;

  static String clock(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiPracticeViewModel>();
    final state = vm.aiState;
    final q = vm.question;
    final failed = state == RecallState.error || state == RecallState.empty;

    final String eyebrow;
    final String title;
    String? body;
    if (!vm.aiEnabled) {
      eyebrow = 'SẴN SÀNG';
      title = 'Bật AI cùng luyện';
      body = 'Hỏi ngắn theo nhịp luyện để nhớ công thức. Không tính điểm.';
    } else if (vm.collapsed) {
      eyebrow = 'ĐÃ THU GỌN';
      title = 'Câu hỏi ôn tập đang ẩn';
    } else if (state == RecallState.loading) {
      eyebrow = 'ĐANG CHUẨN BỊ';
      title = 'Đang chuẩn bị câu hỏi…';
      body = 'Đọc công thức và SOP đã ban hành. Bạn có thể tiếp tục thao tác pha chế.';
    } else if (failed) {
      eyebrow = state == RecallState.error ? 'LỖI KẾT NỐI' : 'CHƯA ĐỦ NỘI DUNG';
      title = state == RecallState.error
          ? 'Chưa kết nối được AI'
          : 'Chưa có câu hỏi phù hợp';
      body =
          vm.error ?? 'Chưa đủ nội dung có căn cứ để tạo lựa chọn cho món này.';
    } else if (state == RecallState.exhausted) {
      eyebrow = 'HOÀN TẤT';
      title = 'Đã ôn hết câu hỏi';
      body = 'Bạn đã xem hết câu hỏi trong phiên. Tiếp tục thực hành và lưu ghi chú khi hoàn thành.';
    } else if (q != null) {
      eyebrow = vm.selectedIndex == null ? 'CÂU HỎI' : 'PHẢN HỒI';
      title = q.prompt;
      body = vm.selectedIndex == null
          ? 'Chọn một đáp án để ôn lại định lượng.'
          : null;
    } else {
      eyebrow = 'ĐANG LUYỆN';
      title = 'Câu hỏi sẽ xuất hiện sau';
      body = vm.running
          ? 'Câu hỏi sẽ xuất hiện theo nhịp luyện. Timer vẫn chạy.'
          : 'Bấm giờ để bắt đầu hoặc tiếp tục nhận câu hỏi.';
    }

    return Container(
      key: const ValueKey('ai_recall_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NomadKit.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.auto_awesome_outlined,
              size: 24,
              color: NomadKit.sandDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            eyebrow,
            style: NomadKit.caption.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
              color: NomadKit.sandDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: NomadKit.subtitle),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: NomadKit.label.copyWith(
                fontWeight: FontWeight.w400,
                color: NomadKit.secondary,
              ),
            ),
          ],
          if (vm.aiEnabled && !vm.collapsed && vm.sourceNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(vm.sourceNote, style: NomadKit.caption),
          ],
          if (state == RecallState.loading &&
              vm.aiEnabled &&
              !vm.collapsed) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              minHeight: 3,
              color: NomadKit.sandDark,
              backgroundColor: NomadKit.sandLight,
            ),
          ],
          if (standalone && vm.aiEnabled && !vm.collapsed && q != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(clock(vm.seconds), style: NomadKit.label)),
                _LinkButton(
                  label: vm.running ? 'Tạm dừng' : 'Tiếp tục bấm giờ',
                  onPressed: vm.toggleTimer,
                ),
              ],
            ),
          ],
          if (vm.aiEnabled && !vm.collapsed && q != null) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < q.choices.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Choice(vm: vm, index: i, question: q),
              ),
            if (vm.selectedIndex != null || vm.hint) ...[
              const SizedBox(height: 4),
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Icon(
                      vm.selectedIndex == null
                          ? Icons.info_outline_rounded
                          : vm.isCorrect!
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 20,
                      color: vm.isCorrect == true
                          ? NomadKit.forest
                          : NomadKit.sandDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(q.explanation, style: NomadKit.body),
              const SizedBox(height: 6),
              Text('Nguồn: ${q.source}', style: NomadKit.caption),
            ],
          ],
          ..._actions(vm, q, failed),
        ],
      ),
    );
  }

  List<Widget> _actions(
    AiPracticeViewModel vm,
    RecallQuestion? q,
    bool failed,
  ) {
    final links = <Widget>[];
    if (!vm.aiEnabled) {
      links.add(
        _LinkButton(
          label: 'Ôn bằng câu hỏi mẫu',
          onPressed: () => vm.enableAi(templates: true),
        ),
      );
    } else if (vm.collapsed) {
      links.add(
        _LinkButton(
          label: 'Mở câu hỏi ôn tập',
          onPressed: () => vm.setCollapsed(false),
        ),
      );
    } else {
      if (failed) {
        if (vm.canRetry) {
          links.add(
            _LinkButton(label: 'Thử lại AI', onPressed: () => vm.enableAi()),
          );
        }
        if (standalone) {
          links.add(
            _LinkButton(
              label: 'Ôn bằng câu hỏi mẫu',
              onPressed: () => vm.enableAi(templates: true),
            ),
          );
        }
      }
      if (q != null) {
        if (vm.selectedIndex == null) {
          links.add(
            _LinkButton(
              label: 'Gợi ý / Xem nguồn chuẩn',
              onPressed: vm.showHint,
            ),
          );
          links.add(
            _LinkButton(
              label: 'Bỏ qua câu hỏi',
              onPressed: vm.continuePractice,
            ),
          );
        } else if (standalone) {
          links.add(
            _LinkButton(
              label: 'Tiếp tục luyện',
              onPressed: vm.continuePractice,
            ),
          );
        }
      }
      links.add(
        _LinkButton(label: 'Thu gọn', onPressed: () => vm.setCollapsed(true)),
      );
    }
    return [const SizedBox(height: 8), Wrap(spacing: 16, children: links)];
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.vm,
    required this.index,
    required this.question,
  });

  final AiPracticeViewModel vm;
  final int index;
  final RecallQuestion question;

  @override
  Widget build(BuildContext context) {
    final answered = vm.selectedIndex != null;
    final correct = answered && index == question.correctIndex;
    final wrong = answered && vm.selectedIndex == index && !correct;
    return OutlinedButton(
      key: ValueKey('recall_choice_$index'),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        foregroundColor: NomadKit.ink,
        disabledForegroundColor: correct ? NomadKit.forest : NomadKit.ink,
        backgroundColor: correct
            ? NomadKit.forestLight
            : wrong
            ? NomadKit.warningLight
            : NomadKit.canvas,
        side: BorderSide(color: correct ? NomadKit.forest : NomadKit.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: answered ? null : () => vm.answer(index),
      child: Row(
        children: [
          Text('${String.fromCharCode(65 + index)}.', style: NomadKit.label),
          const SizedBox(width: 8),
          Expanded(child: Text(question.choices[index], style: NomadKit.label)),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: NomadKit.sandDark,
      padding: const EdgeInsets.symmetric(vertical: 8),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      label,
      style: NomadKit.label.copyWith(
        fontWeight: FontWeight.w600,
        color: NomadKit.sandDark,
      ),
    ),
  );
}
