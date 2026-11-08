class DraftDetailResponse {
  final String draftId;
  final String recipeVersionId;
  final String? recipeStepId;
  final String targetKind;
  final String state; // queued | processing | generated | failed | accepting | accepted | discarded | expired
  final String? userBrief;
  final String? previewUrl;
  final String? mediaAssetId;
  final DateTime? createdAt;
  final DateTime? generatedAt;
  final DateTime? expiresAt;
  final String? errorCode;
  final String? errorMessage;

  DraftDetailResponse({
    required this.draftId,
    required this.recipeVersionId,
    this.recipeStepId,
    required this.targetKind,
    required this.state,
    this.userBrief,
    this.previewUrl,
    this.mediaAssetId,
    this.createdAt,
    this.generatedAt,
    this.expiresAt,
    this.errorCode,
    this.errorMessage,
  });

  bool get isProcessing => state == 'queued' || state == 'processing';
  bool get isGenerated => state == 'generated' || state == 'accepted';
  bool get isFailed => state == 'failed' || state == 'expired';

  factory DraftDetailResponse.fromJson(Map<String, dynamic> json) {
    return DraftDetailResponse(
      draftId: json['draftId'] as String? ?? '',
      recipeVersionId: json['recipeVersionId'] as String? ?? '',
      recipeStepId: json['recipeStepId'] as String?,
      targetKind: json['targetKind'] as String? ?? 'step_instruction',
      state: json['state'] as String? ?? 'queued',
      userBrief: json['userBrief'] as String?,
      previewUrl: json['previewUrl'] as String?,
      mediaAssetId: json['mediaAssetId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
