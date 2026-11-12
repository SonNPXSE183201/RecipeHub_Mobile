import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/services/firebase/firestore_recipe_source.dart';
import '../../core/models/app_models.dart';
import '../../core/di/app_services.dart';
import '../../core/models/session_models.dart';
import '../../core/navigation/app_keys.dart';
import '../../core/viewmodels/recipe_viewmodel.dart';
import '../../core/services/interfaces/i_feedback_repository.dart';
import '../../core/viewmodels/auth_viewmodel.dart';
import '../../core/viewmodels/storage_viewmodel.dart';
import '../../core/widgets/app_toast.dart';

class CreateFeedbackPage extends StatefulWidget {
  const CreateFeedbackPage({
    super.key,
    this.initialRecipeCode,
    this.initialRecipeName,
    this.initialVersion,
    this.initialStepNumber,
    this.initialStepTitle,
    this.initialSopCode,
    this.initialSopTitle,
  });

  final String? initialRecipeCode;
  final String? initialRecipeName;
  final String? initialVersion;
  final int? initialStepNumber;
  final String? initialStepTitle;
  final String? initialSopCode;
  final String? initialSopTitle;

  @override
  State<CreateFeedbackPage> createState() => _CreateFeedbackPageState();
}

class _RecipePickerSheet extends StatefulWidget {
  const _RecipePickerSheet();

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecipeViewModel>();
    final query = FirestoreRecipeSource.normalize(_query.trim());
    final items = vm.items
        .where((r) => FirestoreRecipeSource.normalize(r.name).contains(query))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .6,
          child: Column(
            children: [
              const Text(
                'Chọn món cần phản hồi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Tìm tên món',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: vm.state == ViewState.loading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.state == ViewState.error
                    ? Center(
                        child: TextButton(
                          onPressed: () => vm.load(),
                          child: const Text('Thử tải lại danh sách món'),
                        ),
                      )
                    : items.isEmpty
                    ? const Center(child: Text('Không tìm thấy món'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(
                            items[index].name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(context, items[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateFeedbackPageState extends State<CreateFeedbackPage> {
  // Giữ đồng bộ với validNewFeedback trong firebase/firestore.rules.
  static const int _maxContentLength = 2000;

  FeedbackType _selectedType = FeedbackType.issue;
  String _selectedTopic = 'Định lượng nguyên liệu';
  late TextEditingController _contentCtrl;
  bool _isSubmitting = false;

  static const List<String> _quickTopics = [
    'Định lượng nguyên liệu',
    'Nhiệt độ / Thời gian',
    'Thao tác dụng cụ',
    'Chất lượng kem / Bọt',
  ];

  String _targetName = 'Chạm để chọn món';
  String _targetCode = '';
  String _version = '';
  String? _stepNote;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StorageViewModel>().clearAttachment();
    });

    if (widget.initialRecipeCode != null) {
      _targetCode = widget.initialRecipeCode!;
      _targetName = widget.initialRecipeName ?? 'Công thức';
      _version = widget.initialVersion ?? 'v2.0';
      if (widget.initialStepNumber != null) {
        _stepNote =
            'Bước ${widget.initialStepNumber}: ${widget.initialStepTitle ?? ''}';
      }
    } else if (widget.initialSopCode != null) {
      _targetCode = widget.initialSopCode!;
      _targetName = widget.initialSopTitle ?? 'SOP Kỹ thuật';
      _version = widget.initialVersion ?? 'v1.0';
      _stepNote = 'Quy chuẩn SOP';
    }
  }

  Future<void> _chooseRecipe() async {
    final vm = context.read<RecipeViewModel>();
    final recipe = await showModalBottomSheet<RecipeItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NomadKit.surface,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: const _RecipePickerSheet(),
      ),
    );
    if (!mounted || recipe == null) return;
    setState(() {
      if (_targetCode != recipe.code) _stepNote = null;
      _targetCode = recipe.code;
      _targetName = recipe.name;
      _version = recipe.version;
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_targetCode.isEmpty || _isSubmitting) return;
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) {
      ToastMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung phản hồi chi tiết.'),
          backgroundColor: NomadKit.error,
        ),
      );
      return;
    }

    if (text.length > _maxContentLength) {
      ToastMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nội dung phản hồi không được vượt quá $_maxContentLength ký tự.',
          ),
          backgroundColor: NomadKit.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final storage = context.read<StorageViewModel>();
    final services = context.read<AppServices>();
    String? imageUrl;
    if (storage.attachment != null) {
      imageUrl = await storage.uploadAttachment();
      if (!mounted) return;
      if (imageUrl == null) {
        // Upload lỗi: giữ nguyên form để người dùng thử lại / bỏ ảnh.
        setState(() => _isSubmitting = false);
        ToastMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(storage.attachmentError ?? 'Tải ảnh thất bại.'),
            backgroundColor: NomadKit.error,
          ),
        );
        return;
      }
    }

    final auth = context.read<AuthViewModel>();
    final uid = auth.user?.uid;
    if (uid == null) {
      setState(() => _isSubmitting = false);
      ToastMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.'),
          backgroundColor: NomadKit.error,
        ),
      );
      return;
    }
    try {
      await services.feedback.create(
        NewFeedback(
          ownerUid: uid,
          ownerName: auth.displayName,
          ownerRole: auth.roleLabel,
          storeBranch: auth.storeBranch,
          type: _selectedType,
          content: text,
          targetCode: _targetCode,
          targetName: _targetName,
          version: _version,
          stepNote: _stepNote,
          attachmentUrl: imageUrl,
          attachmentPath: imageUrl == null ? null : storage.attachmentPath,
        ),
      );
    } on FeedbackFailure catch (f) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ToastMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: NomadKit.error),
      );
      return;
    }
    if (!mounted) return;
    await services.analytics.logSubmitFeedback(
      feedbackType: _selectedType.name,
      targetType: widget.initialSopCode != null ? 'sop' : 'recipe',
      targetCode: _targetCode,
      hasAttachment: imageUrl != null,
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);

    // Quay về màn trước rồi hiện snackbar thành công (Figma 112:324).
    final messenger = ToastMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: NomadKit.sandDark,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'Đã gửi phản hồi thành công đến Quản lý Admin.',
            style: NomadKit.label.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  bool get _hasDraft =>
      _contentCtrl.text.trim().isNotEmpty ||
      context.read<StorageViewModel>().attachment != null;

  Future<void> _requestClose() async {
    if (_isSubmitting) return;
    if (!_hasDraft) {
      Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bản nháp chưa lưu'),
        content: const Text(
          'Nội dung phản hồi chưa được gửi. Bạn có muốn bỏ bản nháp này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tiếp tục chỉnh sửa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bỏ bản nháp'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  TextStyle get _fieldLabel =>
      NomadKit.label.copyWith(fontSize: 14, fontWeight: FontWeight.w500);

  Widget _fieldLabelRow(String text, {bool required = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          style: _fieldLabel,
          children: [
            TextSpan(text: '$text '),
            if (required)
              const TextSpan(
                text: '*',
                style: TextStyle(color: NomadKit.error),
              ),
            if (hint != null)
              TextSpan(
                text: hint,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  color: NomadKit.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dashedButton({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      key: key,
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        painter: const _DashedBorderPainter(),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NomadKit.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: NomadKit.ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _fieldLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentSection() {
    final st = context.watch<StorageViewModel>();
    final media = st.attachment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabelRow('Ảnh minh họa', hint: '(tùy chọn, tối đa 5MB)'),
        if (media != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              media.bytes,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${media.fileName} · ${media.sizeMb.toStringAsFixed(2)} MB',
            style: NomadKit.caption,
          ),
          if (st.attachmentStatus == UploadStatus.uploading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: st.attachmentProgress,
              color: NomadKit.sand,
            ),
          ],
          if (st.attachmentUrl != null)
            Text(
              'Đã tải ảnh lên',
              key: AppKeys.attachmentUrl,
              style: NomadKit.caption.copyWith(color: NomadKit.forest),
            ),
          const SizedBox(height: 8),
        ],
        if (st.attachmentError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              st.attachmentError!,
              style: NomadKit.caption.copyWith(color: NomadKit.error),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _dashedButton(
                key: AppKeys.pickFromGallery,
                icon: Icons.photo_library_outlined,
                label: 'Chọn ảnh',
                onPressed: st.isUploadingAttachment
                    ? null
                    : () => st.pickAttachment(fromCamera: false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dashedButton(
                key: AppKeys.pickFromCamera,
                icon: Icons.photo_camera_outlined,
                label: 'Chụp ảnh',
                onPressed: st.isUploadingAttachment
                    ? null
                    : () => st.pickAttachment(fromCamera: true),
              ),
            ),
          ],
        ),
        if (media != null)
          TextButton(
            onPressed: st.isUploadingAttachment
                ? st.cancelUpload
                : st.clearAttachment,
            child: Text(st.isUploadingAttachment ? 'Hủy tải' : 'Bỏ ảnh'),
          ),
      ],
    );
  }

  Widget _section({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 20),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: NomadKit.border)),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(color: NomadKit.border);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: Scaffold(
        backgroundColor: NomadKit.canvas,
        appBar: AppBar(
          backgroundColor: NomadKit.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 64,
          shape: const Border(bottom: BorderSide(color: NomadKit.border)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            onPressed: _requestClose,
          ),
          title: Text(
            'Gửi phản hồi',
            style: NomadKit.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NomadKit.secondary,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stepNote != null
                            ? 'Về ${_stepNote!.split(':').first.trim().toLowerCase()}'
                            : 'Góp ý tài liệu',
                        style: NomadKit.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: NomadKit.sandDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Điều gì cần cải thiện?',
                        style: NomadKit.title.copyWith(
                          fontSize: 24,
                          height: 34 / 24,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _fieldLabelRow('Về công thức / SOP', required: true),
                      InkWell(
                        key: const ValueKey('feedback_recipe_picker'),
                        onTap: widget.initialSopCode != null || _isSubmitting
                            ? null
                            : _chooseRecipe,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: NomadKit.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: NomadKit.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _targetCode.isEmpty
                                      ? 'Chọn món cần phản hồi'
                                      : _targetName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NomadKit.body.copyWith(
                                    fontSize: 16,
                                    height: 24 / 16,
                                    color: _targetCode.isEmpty
                                        ? NomadKit.secondary
                                        : NomadKit.ink,
                                  ),
                                ),
                              ),
                              if (widget.initialSopCode == null)
                                const Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                  color: NomadKit.secondary,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_version.isNotEmpty || _stepNote != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (_version.isNotEmpty) 'Bản $_version',
                            if (_stepNote != null) 'Vị trí: $_stepNote',
                          ].join(' · '),
                          style: NomadKit.caption.copyWith(fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 26),
                      _section(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabelRow('Loại phản hồi'),
                            Row(
                              children: [
                                _typeChip(
                                  FeedbackType.issue,
                                  'Báo cáo vấn đề',
                                  Icons.report_problem_outlined,
                                  NomadKit.error,
                                ),
                                const SizedBox(width: 10),
                                _typeChip(
                                  FeedbackType.inquiry,
                                  'Hỏi cách làm',
                                  Icons.help_outline_rounded,
                                  NomadKit.ocean,
                                ),
                                const SizedBox(width: 10),
                                _typeChip(
                                  FeedbackType.suggestion,
                                  'Đề xuất đổi',
                                  Icons.lightbulb_outline_rounded,
                                  NomadKit.sandDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _fieldLabelRow('Hạng mục liên quan tại quầy'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _quickTopics.map((topic) {
                                final isSelected = _selectedTopic == topic;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedTopic = topic),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? NomadKit.sandLight
                                          : NomadKit.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? NomadKit.sand
                                            : NomadKit.border,
                                      ),
                                    ),
                                    child: Text(
                                      topic,
                                      style: NomadKit.caption.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? NomadKit.sandDark
                                            : NomadKit.secondary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _section(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabelRow('Vấn đề bạn gặp', required: true),
                            TextField(
                              controller: _contentCtrl,
                              maxLength: _maxContentLength,
                              minLines: 6,
                              maxLines: 6,
                              style: NomadKit.body.copyWith(
                                fontSize: 16,
                                height: 28 / 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Mô tả rõ vấn đề bạn gặp phải tại quầy bar: định lượng bị lệch, hiện tượng tách tầng, thời gian làm không kịp...',
                                hintStyle: NomadKit.caption.copyWith(
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: NomadKit.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: borderSide,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: borderSide,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: NomadKit.sand,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _section(child: _attachmentSection()),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: const BoxDecoration(
                  color: NomadKit.surface,
                  border: Border(top: BorderSide(color: NomadKit.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NomadKit.sandDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    key: AppKeys.feedbackSubmit,
                    onPressed: _isSubmitting || _targetCode.isEmpty
                        ? null
                        : _submitFeedback,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'Gửi phản hồi',
                      style: NomadKit.label.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
    FeedbackType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.10)
                : NomadKit.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : NomadKit.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : NomadKit.secondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: NomadKit.caption.copyWith(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : NomadKit.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NomadKit.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
