import 'package:flutter/material.dart';
import '../models/app_models.dart';

class MockDataService {
  static final MockDataService instance = MockDataService._internal();
  MockDataService._internal();

  // Thông tin người dùng hiện tại
  UserRole currentRole = UserRole.viewer;
  String currentUserName = 'Nguyễn Văn Tuấn';
  String currentUserEmail = 'tuan.barista@recipehub.vn';
  String currentStoreBranch = 'Landmark 81 · Bình Thạnh, TP.HCM';
  String adminStoreScope = 'Landmark 81, Bitexco Q1, Thảo Điền Q2 (3 Chi nhánh)';

  void switchRole(UserRole role) {
    currentRole = role;
    if (role == UserRole.admin) {
      currentUserName = 'Trần Minh Anh';
      currentUserEmail = 'minhanh.admin@recipehub.vn';
    } else {
      currentUserName = 'Nguyễn Văn Tuấn';
      currentUserEmail = 'tuan.barista@recipehub.vn';
    }
  }

    // Công thức lấy từ Gateway thật (RecipeViewModel nạp vào đây). Không còn seed giả lập.
  List<RecipeItem> recipes = [];

  // Danh mục SOP Kỹ thuật & Quy chuẩn
  List<SopItem> sops = [
    SopItem(
      id: 'sop-01',
      code: 'SOP-MAC-01',
      title: 'Kỹ thuật đánh kem bọt Macchiato muối biển sánh mịn',
      category: 'Kỹ thuật pha chế',
      version: 'v1.2',
      publishedDate: '12/10/2026',
      summary: 'Quy chuẩn đánh bông kem whipping và bột béo tạo lớp kem dày 2cm nổi trên bề mặt trà, không bị chìm hay tách nước.',
      linkedRecipeCodes: ['RC-OL-01', 'RC-MATCHA-01'],
      steps: [
        SopStepItem(
          stepNumber: 1,
          title: 'Chuẩn bị nguyên liệu lạnh sâu',
          content: 'Whipping cream và sữa tươi phải được bảo quản ở ngăn mát 3-5°C tối thiểu 4 tiếng trước khi đánh.',
          note: 'Nếu nguyên liệu ấm, kem sẽ bị tách bơ và vón cục.',
          icon: Icons.ac_unit_rounded,
        ),
        SopStepItem(
          stepNumber: 2,
          title: 'Cân định lượng muối biển và đường',
          content: 'Cân chính xác 3g muối hồng Himalaya mịn và 20g đường bột vào cối xay sinh tố công nghiệp.',
          icon: Icons.scale_rounded,
        ),
        SopStepItem(
          stepNumber: 3,
          title: 'Đánh ở tốc độ cấp 2 trong 25 giây',
          content: 'Bật máy đánh ở nấc 2 đúng 25 giây đến khi bề mặt xuất hiện vân gợn sóng mềm (Soft peak level 3).',
          note: 'Không đánh quá lâu khiến kem đông cứng.',
          icon: Icons.speed_rounded,
        ),
        SopStepItem(
          stepNumber: 4,
          title: 'Bảo quản ca kem trong xô đá',
          content: 'Sau khi đánh xong, chuyển kem vào bình inox giữ nhiệt và bảo quản trong xô đá quầy bar, dùng trong ca 4 tiếng.',
          icon: Icons.inventory_2_rounded,
        ),
      ],
    ),
    SopItem(
      id: 'sop-02',
      code: 'SOP-COLD-01',
      title: 'Quy trình ủ lạnh 16h và lọc cốt Cold Brew',
      category: 'Kỹ thuật pha chế',
      version: 'v2.0',
      publishedDate: '05/10/2026',
      summary: 'Tiêu chuẩn xay thô cà phê Arabica Cầu Đất, tỷ lệ nước 1:10 và kiểm soát nhiệt độ ủ 4-6°C.',
      linkedRecipeCodes: ['RC-CB-01'],
      steps: [
        SopStepItem(
          stepNumber: 1,
          title: 'Xay thô cà phê mức Coarse',
          content: 'Sử dụng máy xay Mahlkonig ở nấc 9 (hạt thô như muối biển hạt to) để tránh đục và nghẽn màng lọc.',
          icon: Icons.grain_rounded,
        ),
        SopStepItem(
          stepNumber: 2,
          title: 'Ngâm ủ với nước lọc tinh khiết',
          content: 'Tỷ lệ 100g bột cà phê ngâm cùng 1000ml nước lọc RO ở nhiệt độ phòng. Đậy kín nắp bình thủy tinh.',
          icon: Icons.water_drop_rounded,
        ),
        SopStepItem(
          stepNumber: 3,
          title: 'Bảo quản tủ mát 16 tiếng',
          content: 'Đặt bình vào tủ mát 4°C, cài đặt hẹn giờ đúng 16 tiếng. Không ngâm quá 20 tiếng gây chát khét.',
          icon: Icons.timer_rounded,
        ),
        SopStepItem(
          stepNumber: 4,
          title: 'Lọc 2 lần qua màng vải và giấy',
          content: 'Lần 1 qua túi lọc vải cotton, lần 2 qua phễu giấy V60 để nước cốt trong veo, không cặn mịn.',
          icon: Icons.filter_alt_rounded,
        ),
      ],
    ),
    SopItem(
      id: 'sop-03',
      code: 'SOP-CLEAN-01',
      title: 'Vệ sinh và bảo dưỡng máy Espresso cuối ca',
      category: 'Vệ sinh máy móc',
      version: 'v1.0',
      publishedDate: '01/09/2026',
      summary: 'Quy trình xả bột thuốc Cafiza, cọ rửa họng pha Grouphead và ngâm vòi steam sữa chống bám cặn sữa khô.',
      linkedRecipeCodes: ['RC-CB-01'],
      steps: [
        SopStepItem(
          stepNumber: 1,
          title: 'Xả sạch bã cà phê trong Grouphead',
          content: 'Dùng cọ chuyên dụng chà sạch viền gioăng cao su quanh họng pha trong khi xả nước nóng.',
          icon: Icons.cleaning_services_rounded,
        ),
        SopStepItem(
          stepNumber: 2,
          title: 'Backflush với phin mù và bột Cafiza',
          content: 'Cho 3g bột Cafiza vào phin mù, lắp vào họng và bật bơm 5 lần (mỗi lần 10 giây xả, 10 giây nghỉ).',
          icon: Icons.sync_rounded,
        ),
        SopStepItem(
          stepNumber: 3,
          title: 'Ngâm và vệ sinh vòi steam sữa',
          content: 'Ngâm vòi steam vào ca nước ấm pha dung dịch Rinza trong 15 phút, lau sạch và xả steam 3 giây.',
          icon: Icons.coffee_maker_rounded,
        ),
      ],
    ),
  ];

  // Danh sách việc học của tôi
  List<LearningTaskItem> tasks = [
    LearningTaskItem(
      id: 'tsk-01',
      title: 'Học lại phiên bản v2.1: Ô Long Sen Vàng Macchiato',
      type: 'Công thức',
      targetCode: 'RC-OL-01',
      version: 'v2.1',
      assignedBy: 'Trần Minh Anh (Admin R&D)',
      assignedDate: '26/10/2026',
      dueDate: '02/11/2026',
      isOverdue: false,
      isRelearnRequired: true,
      status: TaskStatus.inProgress,
      progress: 0.65,
      sections: [
        'Xem video chuẩn mốc đánh bọt kem Macchiato',
        'Đọc bảng định lượng nguyên liệu tiêu chuẩn mới',
        'Ôn tập SOP-MAC-01: Quy chuẩn đánh kem sánh mịn',
      ],
    ),
    LearningTaskItem(
      id: 'tsk-02',
      title: 'Đào tạo chuẩn pha chế: Cold Brew Cam Quế v2.0',
      type: 'Công thức',
      targetCode: 'RC-CB-01',
      version: 'v2.0',
      assignedBy: 'Trần Minh Anh (Admin R&D)',
      assignedDate: '16/10/2026',
      dueDate: '25/10/2026',
      isOverdue: false,
      isRelearnRequired: false,
      status: TaskStatus.completed,
      progress: 1.0,
      sections: [
        'Xem video mốc từng bước (45 giây)',
        'Đọc bảng định lượng nguyên liệu tiêu chuẩn',
        'Xác nhận đã tiếp nhận quy trình ủ lạnh',
      ],
    ),
    LearningTaskItem(
      id: 'tsk-03',
      title: 'Quy trình an toàn vệ sinh máy Espresso cuối ca',
      type: 'SOP',
      targetCode: 'SOP-CLEAN-01',
      version: 'v1.0',
      assignedBy: 'Nguyễn Hoàng (Quản lý cửa hàng)',
      assignedDate: '20/10/2026',
      dueDate: '28/10/2026',
      isOverdue: true,
      isRelearnRequired: false,
      status: TaskStatus.notStarted,
      progress: 0.0,
      sections: [
        'Đọc các bước xả phin mù Cafiza',
        'Vệ sinh và ngâm vòi đánh sữa Rinza',
        'Xác nhận hoàn tất vệ sinh bàn bar',
      ],
    ),
    LearningTaskItem(
      id: 'tsk-04',
      title: 'Công thức mùa thu: Trà Đào Cam Sả Tươi v2.0',
      type: 'Công thức',
      targetCode: 'RC-PEACH-02',
      version: 'v2.0',
      assignedBy: 'Trần Minh Anh (Admin R&D)',
      assignedDate: '12/10/2026',
      dueDate: '05/11/2026',
      isOverdue: false,
      isRelearnRequired: false,
      status: TaskStatus.inProgress,
      progress: 0.35,
      sections: [
        'Xem video mốc kỹ thuật lắc Boston Shaker',
        'Kiểm tra bảng định lượng nguyên liệu tiêu chuẩn',
      ],
    ),
  ];


  // Danh sách Feedback
  List<FeedbackItemModel> feedbacks = [
    FeedbackItemModel(
      id: 'fb-01',
      senderName: 'Nguyễn Văn Tuấn',
      senderRole: 'Barista Landmark 81',
      storeBranch: 'Landmark 81',
      type: FeedbackType.issue,
      content: 'Lớp kem bọt Macchiato khi rót lên trà Ô Long nóng 85°C dễ bị chìm và tan nhanh vào nước trà, không giữ được 2 tầng đẹp mắt.',
      targetName: 'Ô Long Sen Vàng Macchiato',
      targetCode: 'RC-OL-01',
      version: 'v2.1',
      stepNote: 'Bước 4: Phủ lớp kem bọt Macchiato',
      status: FeedbackStatus.resolved,
      createdAt: '29/10/2026 14:30',
      replies: [
        const FeedbackReplyModel(
          senderName: 'Trần Minh Anh (Admin R&D)',
          isAdmin: true,
          message: 'Chào Tuấn, lưu ý khi rót trà nóng thì bắt buộc phải thả đá viên bi phủ kín bề mặt trước rồi mới rót kem lên bề mặt đá. Khi đó kem sẽ nổi vững chắc 100%. R&D đã cập nhật bổ sung lưu ý này vào video mốc Bước 4!',
          time: '29/10/2026 15:45',
        ),
      ],
    ),
    FeedbackItemModel(
      id: 'fb-02',
      senderName: 'Nguyễn Văn Tuấn',
      senderRole: 'Barista Landmark 81',
      storeBranch: 'Landmark 81',
      type: FeedbackType.suggestion,
      content: 'Đề xuất tăng lượng syrup quế từ 15ml lên 18ml cho khẩu phần chuẩn của Cold Brew Cam Quế vì đá tan nhiều làm nhạt hương quế.',
      targetName: 'Cold Brew Cam Quế',
      targetCode: 'RC-CB-01',
      version: 'v2.0',
      stepNote: 'Định lượng tiêu chuẩn',
      status: FeedbackStatus.inProgress,
      createdAt: '27/10/2026 09:15',
      replies: [
        const FeedbackReplyModel(
          senderName: 'Trần Minh Anh (Admin R&D)',
          isAdmin: true,
          message: 'Cảm ơn góp ý rất thực tế của Tuấn tại quầy bar. Đội ngũ R&D đang thử nghiệm pha mẫu và sẽ đưa vào phiên bản v2.1 trong đợt phát hành tới.',
          time: '27/10/2026 11:20',
        ),
      ],
    ),
  ];

  // Lịch sử tự luyện
  List<SelfPracticeRecord> practiceRecords = [
    const SelfPracticeRecord(
      id: 'pr-01',
      recipeName: 'Cold Brew Cam Quế',
      recipeCode: 'RC-CB-01',
      size: 'Khẩu phần chuẩn (500ml)',
      durationSeconds: 42,
      notes: 'Thao tác nhanh, cam cắt mỏng đều tay, lớp đá vừa chạm miệng ly.',
      practicedAt: '30/10/2026 16:20',
    ),
    const SelfPracticeRecord(
      id: 'pr-02',
      recipeName: 'Trà Đào Cam Sả Tươi',
      recipeCode: 'RC-PEACH-02',
      size: 'Khẩu phần chuẩn (500ml)',
      durationSeconds: 53,
      notes: 'Lắc shaker lực tốt tạo bọt mịn, cần chú ý đong sả dứt khoát hơn.',
      practicedAt: '28/10/2026 10:15',
    ),
  ];

  // Bộ câu hỏi Quiz mẫu
  List<QuizQuestionModel> quizQuestions = [
    const QuizQuestionModel(
      id: 1,
      question: 'Thời gian tiêu chuẩn để ngâm ủ lạnh Cold Brew trong tủ mát 4°C là bao lâu?',
      options: ['8 đến 10 tiếng', '12 tiếng chính xác', '16 tiếng tiêu chuẩn', '24 tiếng trở lên'],
      correctOptionIndex: 2,
      explanation: 'Theo SOP-COLD-01 v2.0, thời gian ủ lạnh chuẩn là 16 tiếng. Ủ quá 20 tiếng sẽ trích xuất nhiều vị đắng gắt và chát khét từ hạt.',
      reviewSection: 'SOP-COLD-01: Quy trình ủ lạnh 16h',
    ),
    const QuizQuestionModel(
      id: 2,
      question: 'Nhiệt độ nước tối ưu khi đánh bột Matcha Shizuoka để không làm mất hương và bị đắng chát là?',
      options: ['100°C (Nước sôi trực tiếp)', '75°C (Nước ấm vừa)', '50°C (Nước nguội)', 'Nước đá lạnh'],
      correctOptionIndex: 1,
      explanation: 'Nước 75°C giúp giải phóng hương thơm thanh khiết của Matcha và không làm cháy trà.',
      reviewSection: 'Công thức Matcha Latte Mây v3.0 - Bước 1',
    ),
    const QuizQuestionModel(
      id: 3,
      question: 'Định lượng nước cốt cam vàng tươi cho món Cold Brew Cam Quế tiêu chuẩn là bao nhiêu?',
      options: ['25 ml', '30 ml', '40 ml', '50 ml'],
      correctOptionIndex: 2,
      explanation: 'Định lượng chuẩn cho mỗi ly Cold Brew Cam Quế là 40ml nước cam vắt tươi.',
      reviewSection: 'Công thức RC-CB-01 v2.0 - Bảng định lượng tiêu chuẩn',
    ),
  ];

  // Đánh giá thực hành của nhân viên (Admin chấm tại quầy)
  List<PracticalEvaluationRecord> evaluations = [
    PracticalEvaluationRecord(
      id: 'eval-01',
      traineeName: 'Nguyễn Văn Tuấn',
      storeBranch: 'Landmark 81',
      evaluatorName: 'Trần Minh Anh (Admin R&D)',
      recipeCode: 'RC-CB-01',
      recipeName: 'Cold Brew Cam Quế',
      version: 'v2.0',
      evaluatedDate: '28/10/2026',
      isPassed: true,
      overallComment: 'Thao tác chuẩn xác, định lượng đúng từng ml, vệ sinh quầy sạch sẽ. Phục vụ khách tự tin.',
      relearnPlan: 'Tiếp tục duy trì phong độ cho ca phục vụ cao điểm.',
      criteria: [
        EvaluationCriterion(
          id: 'c1',
          name: 'Đúng định lượng nguyên liệu theo Size',
          standardRequirement: 'Sai số không quá ±1g hoặc ±1ml',
          isPassed: true,
          isCrucial: true,
        ),
        EvaluationCriterion(
          id: 'c2',
          name: 'Kiểm soát nhiệt độ nước và đá',
          standardRequirement: 'Cold Brew giữ lạnh ở 4°C, đá viên bi sạch',
          isPassed: true,
          isCrucial: true,
        ),
        EvaluationCriterion(
          id: 'c3',
          name: 'Thao tác khuấy và tạo hình',
          standardRequirement: 'Gác lát cam 45 độ, không rớt hạt vào ly',
          isPassed: true,
          isCrucial: false,
        ),
        EvaluationCriterion(
          id: 'c4',
          name: 'Vệ sinh và bảo quản ca đong sau khi pha',
          standardRequirement: 'Rửa ngay ca đong dưới vòi sục nước áp lực',
          isPassed: true,
          isCrucial: true,
        ),
      ],
    ),
  ];

  // Thêm feedback mới
  void addFeedback(FeedbackItemModel fb) {
    feedbacks.insert(0, fb);
  }

  // Thêm bản ghi tự luyện
  void addPracticeRecord(SelfPracticeRecord record) {
    practiceRecords.insert(0, record);
  }

  // Admin lưu đánh giá thực hành mới
  void saveEvaluation(PracticalEvaluationRecord eval) {
    evaluations.insert(0, eval);
  }
}

