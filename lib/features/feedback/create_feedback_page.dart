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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung phản hồi chi tiết.'),
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
        ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi phản hồi thành công đến Quản lý Admin.'),
        backgroundColor: NomadKit.forest,
      ),
    );

    Navigator.pop(context);
  }

  Widget _attachmentSection() {
    final st = context.watch<StorageViewModel>();
    final media = st.attachment;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NomadKit.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NomadKit.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh đính kèm (tùy chọn, tối đa 5MB)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: NomadKit.ink,
            ),
          ),
          const SizedBox(height: 10),
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
              style: const TextStyle(fontSize: 11, color: NomadKit.secondary),
            ),
            if (st.attachmentStatus == UploadStatus.uploading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: st.attachmentProgress,
                color: NomadKit.sand,
              ),
            ],
            if (st.attachmentUrl != null)
              const Text(
                'Đã tải ảnh lên',
                key: AppKeys.attachmentUrl,
                style: TextStyle(fontSize: 11, color: NomadKit.forest),
              ),
            const SizedBox(height: 8),
          ],
          if (st.attachmentError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                st.attachmentError!,
                style: const TextStyle(fontSize: 12, color: NomadKit.error),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: AppKeys.pickFromGallery,
                  onPressed: st.isUploadingAttachment
                      ? null
                      : () => st.pickAttachment(fromCamera: false),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Thư viện'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: AppKeys.pickFromCamera,
                  onPressed: st.isUploadingAttachment
                      ? null
                      : () => st.pickAttachment(fromCamera: true),
                  icon: const Icon(Icons.photo_camera_outlined, size: 16),
                  label: const Text('Chụp ảnh'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: NomadKit.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo phản hồi tiêu chuẩn',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: NomadKit.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Context Card
                    InkWell(
                      key: const ValueKey('feedback_recipe_picker'),
                      onTap: widget.initialSopCode != null || _isSubmitting
                          ? null
                          : _chooseRecipe,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: NomadKit.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: NomadKit.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NGỮ CẢNH ĐANG XEM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: NomadKit.sandDark,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  _version.isEmpty
                                      ? 'Chọn món cần phản hồi'
                                      : 'Bản $_version',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: NomadKit.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _targetName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: NomadKit.ink,
                                    ),
                                  ),
                                ),
                                if (widget.initialSopCode == null)
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    color: NomadKit.sandDark,
                                  ),
                              ],
                            ),
                            if (_stepNote != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Vị trí: $_stepNote',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: NomadKit.ocean,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Feedback Type Choice (Uniform 3-button row)
                    const Text(
                      'LOẠI PHẢN HỒI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: NomadKit.sandDark,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 10),

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

                    // Quick Topic Selector
                    const Text(
                      'HẠNG MỤC LIÊN QUAN TẠI QUẦY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: NomadKit.sandDark,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickTopics.map((topic) {
                        final isSelected = _selectedTopic == topic;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTopic = topic),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? NomadKit.sandLight
                                  : NomadKit.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? NomadKit.sand
                                    : NomadKit.border,
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Text(
                              topic,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? NomadKit.sandDark
                                    : NomadKit.secondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Content Input
                    const Text(
                      'NỘI DUNG CHI TIẾT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: NomadKit.sandDark,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _contentCtrl,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 14, color: NomadKit.ink),
                      decoration: InputDecoration(
                        hintText: 'Mô tả rõ vấn đề bạn gặp phải tại quầy bar: định lượng bị lệch, hiện tượng tách tầng, thời gian làm không kịp...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: NomadKit.secondary,
                        ),
                        filled: true,
                        fillColor: NomadKit.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: NomadKit.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: NomadKit.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: NomadKit.sand,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _attachmentSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Pinned Bottom Action Bar with Balanced Submit Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(
                color: NomadKit.surface,
                border: Border(top: BorderSide(color: NomadKit.border)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 115,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NomadKit.secondary,
                        side: const BorderSide(
                          color: NomadKit.border,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Hủy bỏ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NomadKit.sand,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                            : const Icon(Icons.send_rounded, size: 17),
                        label: const Text(
                          'Gửi phản hồi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            color: isSelected ? color.withOpacity(0.10) : NomadKit.surface,
            borderRadius: BorderRadius.circular(14),
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
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
