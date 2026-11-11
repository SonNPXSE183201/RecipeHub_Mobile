import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_services.dart';
import '../../core/models/app_models.dart';
import '../../core/models/session_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/services/ai/recipe_practice_context_service.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/viewmodels/ai_practice_viewmodel.dart';
import '../../core/viewmodels/app_config_viewmodel.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/practice_history_viewmodel.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/load_state_view.dart';
import '../../core/widgets/personal_learning_blocked.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tự luyện', style: NomadKit.title)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu phiên tự luyện vào lịch sử cá nhân.'),
      ),
    );
    go(context, const PracticeHistoryPage());
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: NomadKit.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: NomadKit.border),
    ),
    child: child,
  );
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
    // Show only quantities common to every variant, never silently choose the first size.
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
    final time =
        '${(vm.seconds ~/ 60).toString().padLeft(2, '0')}:${(vm.seconds % 60).toString().padLeft(2, '0')}';
    final aiAvailable =
        config.enableAiAssist || const bool.fromEnvironment('AI_DEMO_ENABLED');
    return PopScope(
      canPop: _allowPop || !vm.hasSession,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: NomadKit.canvas,
        appBar: AppBar(
          backgroundColor: NomadKit.canvas,
          title: const Text(
            'Tự luyện & Bấm giờ quầy bar',
            style: NomadKit.title,
          ),
          leading: IconButton(
            onPressed: _leave,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          actions: [
            IconButton(
              tooltip: 'Lịch sử tự luyện',
              onPressed: _history,
              icon: const Icon(Icons.history_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('CHỌN MÓN LUYỆN TẬP', style: NomadKit.section),
                      const SizedBox(height: 8),
                      AppDropdown<RecipeItem>(
                        value: selected,
                        items: items
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                  '${r.name} · ${r.version}',
                                  style: NomadKit.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _changeRecipe,
                      ),
                      const SizedBox(height: 12),
                      _card(
                        Column(
                          children: [
                            const Text(
                              'ĐỒNG HỒ BẤM GIỜ THAO TÁC',
                              style: NomadKit.section,
                            ),
                            Text(
                              time,
                              key: const ValueKey('practice_elapsed'),
                              style: vm.aiEnabled
                                  ? NomadKit.timerCompact
                                  : NomadKit.timer,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: vm.running
                                          ? NomadKit.error
                                          : NomadKit.sand,
                                      foregroundColor: NomadKit.surface,
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    key: AppKeys.timerStart,
                                    onPressed: vm.toggleTimer,
                                    icon: Icon(
                                      vm.running
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                    label: Text(
                                      vm.running ? 'Tạm dừng' : 'Bấm giờ',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: NomadKit.ink,
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: vm.reset,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Đặt lại'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (aiAvailable)
                        KeyedSubtree(key: _aiKey, child: const AiRecallCard())
                      else
                        _card(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/icons/icon_sparkle_ai.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Ôn công thức khi luyện',
                                      style: NomadKit.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'AI chưa được bật. Bạn có thể ôn bằng câu hỏi mẫu lấy từ công thức.',
                                style: NomadKit.caption,
                              ),
                              if (!vm.aiEnabled)
                                TextButton(
                                  onPressed: () => vm.enableAi(templates: true),
                                  child: const Text('Ôn bằng câu hỏi mẫu'),
                                ),
                              if (vm.aiEnabled)
                                KeyedSubtree(
                                  key: _aiKey,
                                  child: const AiRecallCard(),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'ĐỊNH LƯỢNG NGUYÊN LIỆU THAM KHẢO',
                        style: NomadKit.section,
                      ),
                      const SizedBox(height: 8),
                      if (vm.recipe.sizes.length > 1)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Món có nhiều định lượng. Phần dưới chỉ hiển thị nguyên liệu có cùng lượng ở mọi khẩu phần; xem công thức để đối chiếu đầy đủ.',
                            style: NomadKit.caption,
                          ),
                        ),
                      _card(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (ingredients.isEmpty)
                              const Text(
                                'Chưa có định lượng chung được xác định.',
                                style: NomadKit.body,
                              ),
                            for (final ingredient in ingredients)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ingredient.name,
                                        style: NomadKit.body,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        '${ingredient.amount.toString().replaceFirst(RegExp(r'\.0$'), '')} ${ingredient.unit}',
                                        style: NomadKit.subtitle,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (vm.recipe.steps.isNotEmpty) ...[
                        const Text('CÁC BƯỚC PHA CHẾ', style: NomadKit.section),
                        const SizedBox(height: 8),
                        for (final step in vm.recipe.steps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _card(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bước ${step.stepNumber}: ${step.title}',
                                    style: NomadKit.subtitle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(step.instruction, style: NomadKit.body),
                                  if (step.durationText != null)
                                    Text(
                                      'Thời lượng của bước: ${step.durationText}',
                                      style: NomadKit.caption,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'GHI CHÚ RÚT KINH NGHIỆM CÁ NHÂN',
                        style: NomadKit.section,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notes,
                        maxLines: 3,
                        style: NomadKit.body,
                        decoration: const InputDecoration(
                          hintText:
                              'Ghi lại điều bạn muốn nhớ trong lần luyện sau…',
                          hintStyle: NomadKit.caption,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _history,
                      child: const Text('Lịch sử'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: NomadKit.forest,
                          foregroundColor: NomadKit.surface,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        key: AppKeys.timerSave,
                        child: Text(
                          _saving ? 'Đang lưu…' : 'Lưu lần luyện tập',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
