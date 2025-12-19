class UserProfileModel {
  final String fullName;
  final String? avatarUrl;

  UserProfileModel({
    required this.fullName,
    this.avatarUrl,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      fullName: json['fullName'] ?? '',
      avatarUrl: json['avatarUrl'],
    );
  }
}