class PagedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;

  PagedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawList = json['items'] as List<dynamic>? ?? [];
    return PagedResponse<T>(
      items: rawList
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }
}

class RecipeSummaryResponse {
  final String id;
  final String code;
  final String state;
  final String versionId;
  final int versionNumber;
  final String versionStatus;
  final String name;
  final DateTime updatedAt;

  RecipeSummaryResponse({
    required this.id,
    required this.code,
    required this.state,
    required this.versionId,
    required this.versionNumber,
    required this.versionStatus,
    required this.name,
    required this.updatedAt,
  });

  factory RecipeSummaryResponse.fromJson(Map<String, dynamic> json) {
    return RecipeSummaryResponse(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      state: json['state'] as String? ?? 'Draft',
      versionId: json['versionId'] as String? ?? '',
      versionNumber: json['versionNumber'] as int? ?? 1,
      versionStatus: json['versionStatus'] as String? ?? 'Draft',
      name: json['name'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class RecipeIngredientResponse {
  final int id;
  final String ingredientId;
  final String ingredientCode;
  final String ingredientName;
  final double quantity;
  final String unitId;
  final String unitCode;
  final int sortOrder;
  final String? stageName;
  final String? note;
  final String? warning;

  RecipeIngredientResponse({
    required this.id,
    required this.ingredientId,
    required this.ingredientCode,
    required this.ingredientName,
    required this.quantity,
    required this.unitId,
    required this.unitCode,
    required this.sortOrder,
    this.stageName,
    this.note,
    this.warning,
  });

  factory RecipeIngredientResponse.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientResponse(
      id: json['id'] as int? ?? 0,
      ingredientId: json['ingredientId'] as String? ?? '',
      ingredientCode: json['ingredientCode'] as String? ?? '',
      ingredientName: json['ingredientName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitId: json['unitId'] as String? ?? '',
      unitCode: json['unitCode'] as String? ?? 'g',
      sortOrder: json['sortOrder'] as int? ?? 0,
      stageName: json['stageName'] as String?,
      note: json['note'] as String?,
      warning: json['warning'] as String?,
    );
  }
}

class RecipeStepMediaResponse {
  final String linkId;
  final String mediaAssetRef;
  final int sortOrder;
  final bool isPrimary;
  final String? caption;

  RecipeStepMediaResponse({
    required this.linkId,
    required this.mediaAssetRef,
    required this.sortOrder,
    required this.isPrimary,
    this.caption,
  });

  factory RecipeStepMediaResponse.fromJson(Map<String, dynamic> json) {
    return RecipeStepMediaResponse(
      linkId: json['linkId'] as String? ?? '',
      mediaAssetRef: json['mediaAssetRef'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isPrimary: json['isPrimary'] as bool? ?? false,
      caption: json['caption'] as String?,
    );
  }
}

class RecipeStepResponse {
  final int id;
  final String publicId;
  final int sortOrder;
  final String title;
  final String description;
  final int? durationSeconds;
  final double? temperatureCelsius;
  final String? equipment;
  final String? safetyNote;
  final List<RecipeStepMediaResponse> media;

  RecipeStepResponse({
    required this.id,
    required this.publicId,
    required this.sortOrder,
    required this.title,
    required this.description,
    this.durationSeconds,
    this.temperatureCelsius,
    this.equipment,
    this.safetyNote,
    required this.media,
  });

  factory RecipeStepResponse.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'] as List<dynamic>? ?? [];
    return RecipeStepResponse(
      id: json['id'] as int? ?? 0,
      publicId: json['publicId'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationSeconds: json['durationSeconds'] as int?,
      temperatureCelsius:
          (json['temperatureCelsius'] as num?)?.toDouble(),
      equipment: json['equipment'] as String?,
      safetyNote: json['safetyNote'] as String?,
      media: rawMedia
          .map((m) => RecipeStepMediaResponse.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecipeDetailResponse {
  final String id;
  final String code;
  final String state;
  final String versionId;
  final int versionNumber;
  final String versionStatus;
  final String name;
  final String? description;
  final int rowVersion;
  final String? primaryMediaAssetRef;
  final List<RecipeIngredientResponse> ingredients;
  final List<RecipeStepResponse> steps;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeDetailResponse({
    required this.id,
    required this.code,
    required this.state,
    required this.versionId,
    required this.versionNumber,
    required this.versionStatus,
    required this.name,
    this.description,
    required this.rowVersion,
    this.primaryMediaAssetRef,
    required this.ingredients,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecipeDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawIngr = json['ingredients'] as List<dynamic>? ?? [];
    final rawSteps = json['steps'] as List<dynamic>? ?? [];

    return RecipeDetailResponse(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      state: json['state'] as String? ?? 'Draft',
      versionId: json['versionId'] as String? ?? '',
      versionNumber: json['versionNumber'] as int? ?? 1,
      versionStatus: json['versionStatus'] as String? ?? 'Draft',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      rowVersion: json['rowVersion'] as int? ?? 0,
      primaryMediaAssetRef: json['primaryMediaAssetRef'] as String?,
      ingredients: rawIngr
          .map((i) => RecipeIngredientResponse.fromJson(i as Map<String, dynamic>))
          .toList(),
      steps: rawSteps
          .map((s) => RecipeStepResponse.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
