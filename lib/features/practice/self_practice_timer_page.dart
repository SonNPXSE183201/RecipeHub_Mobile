import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_services.dart';
import '../../core/models/app_models.dart';
import '../../core/models/session_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/services/ai/recipe_practice_context_service.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/models/ai_practice_models.dart';
import '../../core/viewmodels/ai_practice_viewmodel.dart';
import '../../core/viewmodels/app_config_viewmodel.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/practice_history_viewmodel.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/widgets/load_state_view.dart';
import '../../core/widgets/personal_learning_blocked.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../core/utils/navigation.dart';
import 'practice_history_page.dart';
import 'widgets/ai_recall_card.dart';

class SelfPracticeTimerPage extends StatelessWidget {
  const SelfPracticeTimerPage({
    super.key,
    this.initialRecipe,
    this.initialSizeCode,
    this.clock,
  });
  final RecipeItem? initialRecipe;
  // Retained route compatibility; AI never asks the user to select a size.
  final String? initialSizeCode;

  /// Tests inject their clock; device builds use monotonic elapsed time.
  final PracticeClock? clock;
  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthViewModel>().hasPersonalLearning) {
      return const PersonalLearningBlocked();
    }
    final recipes = context.watch<RecipeViewModel>();
    final recipe = initialRecipe ?? recipes.items.firstOrNull;
    if (recipe != null && recipe.sizes.isNotEmpty) {
      return ChangeNotifierProvider(
        create: (context) {
          final services = context.read<AppServices>();
          return AiPracticeViewModel(
            recipe: recipe,
            source: RecipePracticeContextService(
              services.recipes,
              services.training,
            ),
            ai: services.aiPractice,
            analytics: services.analytics,
            clock: clock,
          );
        },
        child: const _PracticeBody(),
      );
    }
    return RhFlowScaffold(
      title: 'Tự luyện',
      body: recipes.state == ViewState.error
          ? LoadStateView.error(
              message: recipes.error ?? 'Không tải được món.',
              onRetry: recipes.load,
            )
          : recipes.state == ViewState.empty
          ? const LoadStateView.empty(
              message: 'Chưa có công thức nào để luyện tập.',
            )
          : const LoadStateView.loading(),
    );
  }
}

class _PracticeBody extends StatefulWidget {
  const _PracticeBody();
  @override
  State<_PracticeBody> createState() => _PracticeBodyState();
}

class _PracticeBodyState extends State<_PracticeBody>
    with WidgetsBindingObserver {
  final _notes = TextEditingController();
  final _scroll = ScrollController();
  final _aiKey = GlobalKey();
  bool _saving = false, _leaving = false, _allowPop = false;
  bool _aiMode = false, _showRecipe = false, _showLock = false;
  AiPracticeViewModel? _vm;
  bool _hadQuestion = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<AiPracticeViewModel>();
    if (_vm != vm) {
      _vm?.removeListener(_onTick);
      _vm = vm;
      vm.addListener(_onTick);
    }
  }

  void _onTick() {
    final hasQuestion = _vm?.question != null;
    if (hasQuestion && !_hadQuestion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _aiKey.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 250),
            alignment: .1,
          );
        }
      });
    }
    _hadQuestion = hasQuestion;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _vm?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vm?.removeListener(_onTick);
    _notes.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tiếp tục món hiện tại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final vm = context.read<AiPracticeViewModel>();
    final leave =
        !vm.hasSession ||
        await _confirm(
          'Kết thúc phiên luyện?',
          'Thời gian và phần ôn chưa lưu sẽ được đóng.',
          'Kết thúc',
        );
    _leaving = false;
    if (!mounted || !leave) return;
    vm.pause();
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _changeRecipe(RecipeItem? recipe) async {
    final vm = context.read<AiPracticeViewModel>();
    if (recipe == null || recipe.id == vm.recipe.id || recipe.sizes.isEmpty) {
      return;
    }
    if (vm.hasSession &&
        !await _confirm(
          'Bắt đầu món mới?',
          'Timer và câu hỏi sẽ bắt đầu lại cho món mới.',
          'Bắt đầu món mới',
        )) {
      return;
    }
    if (!mounted) return;
    vm.changeRecipe(recipe);
    _notes.clear();
    setState(() => _aiMode = false);
  }

  void _history() {
    context.read<AiPracticeViewModel>().pause();
    go(context, const PracticeHistoryPage());
  }

  Future<void> _save() async {
    final vm = context.read<AiPracticeViewModel>();
    if (_saving) return;
    if (vm.seconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng bấm giờ thực hành trước khi lưu.'),
        ),
      );
      return;
    }
    vm.pause();
    setState(() => _saving = true);
    await context.read<PracticeHistoryViewModel>().add(
      SelfPracticeRecord(
        id: 'pr-${DateTime.now().microsecondsSinceEpoch}',
        recipeName: vm.recipe.name,
        recipeCode: vm.recipe.code,
        size: 'Theo công thức ${vm.recipe.version}',
        durationSeconds: vm.seconds,
        notes: _notes.text.trim().isEmpty
            ? 'Tự luyện hoàn thành.'
            : _notes.text.trim(),
        practicedAt: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        targetSeconds: 0,
      ),
    );
    if (!mounted) return;
    vm.recordSaved();
    setState(() => _saving = false);
    vm.reset();
    setState(() => _aiMode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu phiên tự luyện vào lịch sử cá nhân.'),
      ),
    );
    go(context, const PracticeHistoryPage());
  }

  Future<void> _pickRecipe(List<RecipeItem> items, RecipeItem selected) async {
    final picked = await showModalBottomSheet<RecipeItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NomadKit.surface,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _RecipePickerSheet(items: items, selected: selected),
    );
    if (picked != null) await _changeRecipe(picked);
  }

  /// Nút chính ở thanh dưới khi đang ở chế độ AI cùng luyện.
  ({String label, VoidCallback onPressed}) _aiAction(
    AiPracticeViewModel vm,
    bool aiAvailable,
  ) {
    if (!vm.aiEnabled) {
      return (
        label: 'Bắt đầu tự luyện',
        onPressed: () {
          vm.enableAi(templates: !aiAvailable);
          if (!vm.running) vm.toggleTimer();
        },
      );
    }
    return switch (vm.aiState) {
      RecallState.feedback => (
        label: 'Tiếp tục luyện',
        onPressed: vm.continuePractice,
      ),
      RecallState.error || RecallState.empty => (
        label: 'Ôn bằng câu hỏi mẫu',
        onPressed: () => vm.enableAi(templates: true),
      ),
      RecallState.exhausted => (
        label: 'Tiếp tục thực hành',
        onPressed: () => setState(() => _aiMode = false),
      ),
      _ => (
        label: vm.running ? 'Tạm dừng luyện' : 'Tiếp tục bấm giờ',
        onPressed: vm.toggleTimer,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiPracticeViewModel>();
    final config = context.watch<AppConfigViewModel>();
    if (!config.enableAiAssist &&
        vm.aiEnabled &&
        !vm.templateMode &&
        const bool.fromEnvironment('AI_DEMO_ENABLED') == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) vm.disableAi();
      });
    }
    final live = context
        .watch<RecipeViewModel>()
        .items
        .where((r) => r.sizes.isNotEmpty)
        .toList();
    final items = live.any((r) => r.id == vm.recipe.id)
        ? live
        : [vm.recipe, ...live];
    final selected = items.firstWhere((r) => r.id == vm.recipe.id);
    final aiAvailable =
        config.enableAiAssist || const bool.fromEnvironment('AI_DEMO_ENABLED');
    final time = AiRecallCard.clock(vm.seconds);
    final status = vm.running
        ? 'Đang thực hiện'
        : vm.seconds > 0
        ? 'Tạm dừng'
        : 'Chưa bắt đầu';

    final Widget bottom;
    if (_aiMode) {
      final action = _aiAction(vm, aiAvailable);
      bottom = RhPrimaryButton(
        key: AppKeys.timerStart,
        label: action.label,
        icon: null,
        onPressed: action.onPressed,
      );
    } else if (!vm.running && vm.seconds == 0) {
      bottom = RhPrimaryButton(
        key: AppKeys.timerStart,
        label: 'Bắt đầu tự luyện',
        icon: Icons.play_arrow_outlined,
        onPressed: vm.toggleTimer,
      );
    } else {
      bottom = Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                key: AppKeys.timerStart,
                onPressed: vm.toggleTimer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: NomadKit.sandDark,
                  backgroundColor: NomadKit.surface,
                  side: const BorderSide(color: NomadKit.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  vm.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 20,
                ),
                label: Text(
                  vm.running ? 'Tạm dừng' : 'Tiếp tục',
                  style: NomadKit.label.copyWith(color: NomadKit.ink),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                key: AppKeys.timerSave,
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: NomadKit.sandDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: NomadKit.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  _saving ? 'Đang lưu…' : 'Lưu lần luyện tập',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NomadKit.label.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Chỉ hiện nguyên liệu có cùng lượng ở mọi khẩu phần, không tự chọn size đầu.
    final ingredients = vm.recipe.sizes.first.ingredients
        .where(
          (i) => vm.recipe.sizes.every(
            (s) => s.ingredients.any(
              (x) =>
                  x.name == i.name && x.amount == i.amount && x.unit == i.unit,
            ),
          ),
        )
        .toList();

    return PopScope(
      canPop: _allowPop || !vm.hasSession,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: RhFlowScaffold(
        title: 'Tự luyện',
        trailing: IconButton(
          tooltip: 'Lịch sử tự luyện',
          onPressed: _history,
          icon: const RhSvgIcon(
            'assets/redesign/clock.svg',
            size: 22,
            color: NomadKit.sandDark,
          ),
        ),
        bottomAction: bottom,
        body: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: _aiMode
              ? _aiBody(vm, time, status, aiAvailable)
              : _manualBody(vm, items, selected, time, status, ingredients),
        ),
      ),
    );
  }

  Widget _aiBody(
    AiPracticeViewModel vm,
    String time,
    String status,
    bool aiAvailable,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'TỰ LUYỆN · ${vm.recipe.name.toUpperCase()}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: NomadKit.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: .4,
          color: NomadKit.sandDark,
        ),
      ),
      const SizedBox(height: 6),
      Text('AI cùng luyện', style: NomadKit.title.copyWith(fontSize: 24)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NomadKit.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NomadKit.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 22,
                  color: NomadKit.sandDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$time · $status',
                    key: const ValueKey('practice_elapsed'),
                    style: NomadKit.subtitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Một món · Luyện theo công thức đã ban hành',
              style: NomadKit.caption,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      KeyedSubtree(key: _aiKey, child: const AiRecallCard(standalone: false)),
      const SizedBox(height: 12),
      Text(
        vm.templateMode
            ? 'Câu hỏi mẫu lấy từ công thức · Không tính điểm'
            : 'Câu hỏi bám công thức & SOP · Không tính điểm',
        style: NomadKit.caption,
      ),
      const SizedBox(height: 8),
      _InfoRow(
        icon: const Icon(
          Icons.timer_outlined,
          size: 20,
          color: NomadKit.sandDark,
        ),
        label: 'Quay lại bấm giờ thủ công',
        trailing: const RhChevron(),
        onTap: () => setState(() => _aiMode = false),
      ),
      if (vm.aiEnabled)
        _InfoRow(
          icon: const Icon(
            Icons.close_rounded,
            size: 20,
            color: NomadKit.sandDark,
          ),
          label: 'Tắt AI cùng luyện',
          onTap: vm.disableAi,
        ),
    ],
  );

  Widget _manualBody(
    AiPracticeViewModel vm,
    List<RecipeItem> items,
    RecipeItem selected,
    String time,
    String status,
    List<IngredientPortion> ingredients,
  ) {
    final caption = vm.running
        ? 'Đo thời gian, không giới hạn tốc độ của bạn.'
        : vm.seconds > 0
        ? 'Đã tạm dừng · Tiếp tục khi sẵn sàng.'
        : 'Bấm bắt đầu khi sẵn sàng. Không giới hạn tốc độ.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tập trung vào từng thao tác',
          style: NomadKit.label.copyWith(color: NomadKit.sandDark),
        ),
        const SizedBox(height: 6),
        Text('Phiên tự luyện', style: NomadKit.title.copyWith(fontSize: 24)),
        const SizedBox(height: 22),
        Text('Món thực hành', style: NomadKit.label.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Material(
          color: NomadKit.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: NomadKit.border),
          ),
          child: InkWell(
            key: const ValueKey('practice_recipe_picker'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => _pickRecipe(items, selected),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${selected.name} · ${selected.version}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NomadKit.body,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: NomadKit.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Luyện theo công thức đang được ban hành.',
          style: NomadKit.caption,
        ),
        const SizedBox(height: 18),
        const Divider(height: 1, color: NomadKit.border),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const RhSvgIcon(
              'assets/redesign/timer.svg',
              size: 16,
              color: NomadKit.sandDark,
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: NomadKit.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: NomadKit.sandDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          time,
          key: const ValueKey('practice_elapsed'),
          textAlign: TextAlign.center,
          style: NomadKit.timer.copyWith(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.w500,
            color: NomadKit.sandDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(caption, textAlign: TextAlign.center, style: NomadKit.caption),
        const SizedBox(height: 22),
        const Divider(height: 1, color: NomadKit.border),
        _InfoRow(
          icon: const RhSvgIcon(
            'assets/redesign/book.svg',
            size: 20,
            color: NomadKit.sandDark,
          ),
          label: 'Xem lại công thức',
          trailing: AnimatedRotation(
            turns: _showRecipe ? .25 : 0,
            duration: const Duration(milliseconds: 150),
            child: const RhChevron(),
          ),
          onTap: () => setState(() => _showRecipe = !_showRecipe),
        ),
        if (_showRecipe) _recipeReview(vm, ingredients),
        const Divider(height: 1, color: NomadKit.border),
        _InfoRow(
          label: 'Khi chuyển màn hoặc khóa máy',
          trailing: Icon(
            _showLock ? Icons.remove_rounded : Icons.add_rounded,
            size: 18,
            color: NomadKit.secondary,
          ),
          onTap: () => setState(() => _showLock = !_showLock),
        ),
        if (_showLock)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Timer tự tạm dừng khi bạn rời ứng dụng hoặc khóa máy. Bấm Tiếp tục để chạy lại.',
              style: NomadKit.caption,
            ),
          ),
        const Divider(height: 1, color: NomadKit.border),
        _InfoRow(
          icon: const Icon(
            Icons.auto_awesome_outlined,
            size: 20,
            color: NomadKit.sandDark,
          ),
          label: 'AI cùng luyện',
          trailing: const RhChevron(),
          onTap: () => setState(() => _aiMode = true),
        ),
        const Divider(height: 1, color: NomadKit.border),
        _InfoRow(
          key: const ValueKey('practice_reset'),
          icon: const Icon(
            Icons.refresh_rounded,
            size: 20,
            color: NomadKit.sandDark,
          ),
          label: 'Đặt lại',
          onTap: vm.reset,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          decoration: BoxDecoration(
            color: NomadKit.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NomadKit.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ghi chú (tùy chọn)', style: NomadKit.subtitle),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                style: NomadKit.label.copyWith(fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  hintText: 'Điều đã làm tốt hoặc cần luyện thêm…',
                  hintStyle: NomadKit.label.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recipeReview(
    AiPracticeViewModel vm,
    List<IngredientPortion> ingredients,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Định lượng nguyên liệu tham khảo', style: NomadKit.label),
        const SizedBox(height: 6),
        if (vm.recipe.sizes.length > 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Món có nhiều định lượng. Phần dưới chỉ hiển thị nguyên liệu có cùng lượng ở mọi khẩu phần; xem công thức để đối chiếu đầy đủ.',
              style: NomadKit.caption,
            ),
          ),
        if (ingredients.isEmpty)
          const Text(
            'Chưa có định lượng chung được xác định.',
            style: NomadKit.body,
          ),
        for (final ingredient in ingredients)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(ingredient.name, style: NomadKit.body)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '${ingredient.amount.toString().replaceFirst(RegExp(r'\.0$'), '')} ${ingredient.unit}',
                    style: NomadKit.subtitle.copyWith(fontSize: 15),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        if (vm.recipe.steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Các bước pha chế', style: NomadKit.label),
          const SizedBox(height: 6),
          for (final step in vm.recipe.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước ${step.stepNumber}: ${step.title}',
                    style: NomadKit.subtitle.copyWith(fontSize: 15),
                  ),
                  Text(step.instruction, style: NomadKit.body),
                  if (step.durationText != null)
                    Text(
                      'Thời lượng của bước: ${step.durationText}',
                      style: NomadKit.caption,
                    ),
                ],
              ),
            ),
        ],
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 12)],
          Expanded(child: Text(label, style: NomadKit.label)),
          ?trailing,
        ],
      ),
    ),
  );
}

class _RecipePickerSheet extends StatelessWidget {
  const _RecipePickerSheet({required this.items, required this.selected});

  final List<RecipeItem> items;
  final RecipeItem selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NomadKit.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Chọn món thực hành', style: NomadKit.section),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  style: IconButton.styleFrom(
                    backgroundColor: NomadKit.sandLight,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: NomadKit.sandDark,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final item = items[i];
                final active = item.id == selected.id;
                return Material(
                  color: active ? NomadKit.sandLight : NomadKit.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: active ? NomadKit.sandLight : NomadKit.border,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(context, item),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} · ${item.version}',
                                style: NomadKit.label.copyWith(
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: active
                                      ? NomadKit.sandDark
                                      : NomadKit.ink,
                                ),
                              ),
                            ),
                            if (active)
                              const RhSvgIcon(
                                'assets/redesign/circle_check.svg',
                                size: 20,
                                color: NomadKit.sandDark,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
