/// MBTI 소개팅 프로필 모델
class DatingProfile {
  final String id;
  final String userId;
  final int birthYear;
  final String gender;
  final String mbti;
  final String? job;
  final int? height;
  final List<String> keywords;
  final String? bio;
  final String? photoPath;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DatingProfile({
    required this.id,
    required this.userId,
    required this.birthYear,
    required this.gender,
    required this.mbti,
    this.job,
    this.height,
    this.keywords = const [],
    this.bio,
    this.photoPath,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory DatingProfile.fromJson(Map<String, dynamic> json) {
    return DatingProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      birthYear: json['birth_year'] as int,
      gender: json['gender'] as String,
      mbti: json['mbti'] as String,
      job: json['job'] as String?,
      height: json['height'] as int?,
      keywords:
          (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bio: json['bio'] as String?,
      photoPath: json['photo_path'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'birth_year': birthYear,
      'gender': gender,
      'mbti': mbti,
      'job': job,
      'height': height,
      'keywords': keywords,
      'bio': bio,
      'photo_path': photoPath,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get age => DateTime.now().year - birthYear;

  String get genderDisplay => gender == 'male' ? '남성' : '여성';

  DatingProfile copyWith({
    String? id,
    String? userId,
    int? birthYear,
    String? gender,
    String? mbti,
    String? job,
    int? height,
    List<String>? keywords,
    String? bio,
    String? photoPath,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DatingProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      mbti: mbti ?? this.mbti,
      job: job ?? this.job,
      height: height ?? this.height,
      keywords: keywords ?? this.keywords,
      bio: bio ?? this.bio,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 소개팅 선호도 모델
class DatingPreferences {
  final String id;
  final String userId;
  final List<String> targetMbti;
  final int ageMin;
  final int ageMax;
  final String? targetGender;
  final int? heightMin;
  final int? heightMax;
  final List<String>? jobPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  DatingPreferences({
    required this.id,
    required this.userId,
    this.targetMbti = const [],
    this.ageMin = 20,
    this.ageMax = 40,
    this.targetGender,
    this.heightMin,
    this.heightMax,
    this.jobPreferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DatingPreferences.fromJson(Map<String, dynamic> json) {
    return DatingPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      targetMbti:
          (json['target_mbti'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      ageMin: json['age_min'] as int? ?? 20,
      ageMax: json['age_max'] as int? ?? 40,
      targetGender: json['target_gender'] as String?,
      heightMin: json['height_min'] as int?,
      heightMax: json['height_max'] as int?,
      jobPreferences: (json['job_preferences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'target_mbti': targetMbti,
      'age_min': ageMin,
      'age_max': ageMax,
      'target_gender': targetGender,
      'height_min': heightMin,
      'height_max': heightMax,
      'job_preferences': jobPreferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DatingPreferences copyWith({
    String? id,
    String? userId,
    List<String>? targetMbti,
    int? ageMin,
    int? ageMax,
    String? targetGender,
    int? heightMin,
    int? heightMax,
    List<String>? jobPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DatingPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetMbti: targetMbti ?? this.targetMbti,
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      targetGender: targetGender ?? this.targetGender,
      heightMin: heightMin ?? this.heightMin,
      heightMax: heightMax ?? this.heightMax,
      jobPreferences: jobPreferences ?? this.jobPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 추천된 프로필 (오늘의 추천용)
class RecommendedProfile {
  final String recommendedUserId;
  final String mbti;
  final int birthYear;
  final String? job;
  final List<String> keywords;
  final String? bio;
  final String? photoPath;

  RecommendedProfile({
    required this.recommendedUserId,
    required this.mbti,
    required this.birthYear,
    this.job,
    this.keywords = const [],
    this.bio,
    this.photoPath,
  });

  factory RecommendedProfile.fromJson(Map<String, dynamic> json) {
    return RecommendedProfile(
      recommendedUserId: json['recommended_user_id'] as String,
      mbti: json['mbti'] as String,
      birthYear: json['birth_year'] as int,
      job: json['job'] as String?,
      keywords:
          (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bio: json['bio'] as String?,
      photoPath: json['photo_path'] as String?,
    );
  }

  int get age => DateTime.now().year - birthYear;
}

/// 매치 모델
class DatingMatch {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;

  DatingMatch({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
  });

  factory DatingMatch.fromJson(Map<String, dynamic> json) {
    return DatingMatch(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
