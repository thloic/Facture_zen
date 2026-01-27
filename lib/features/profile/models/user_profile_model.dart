import 'package:flutter/foundation.dart';

/// Modèle de profil utilisateur contenant les informations de l'entreprise
class UserProfile {
  final String userId;
  final String? companyName;
  final String? companyAddress;
  final String? companyPhone;
  final String? companyEmail;
  final String? companySiret;
  final String? companyLogo; // URL Firebase Storage
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.companySiret,
    this.companyLogo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un UserProfile depuis une Map (données Firebase)
  factory UserProfile.fromMap(Map<dynamic, dynamic> map, String userId) {
    return UserProfile(
      userId: userId,
      companyName: map['companyName'] as String?,
      companyAddress: map['companyAddress'] as String?,
      companyPhone: map['companyPhone'] as String?,
      companyEmail: map['companyEmail'] as String?,
      companySiret: map['companySiret'] as String?,
      companyLogo: map['companyLogo'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  /// Convertit le UserProfile en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'companySiret': companySiret,
      'companyLogo': companyLogo,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Vérifie si le profil contient au moins une information
  bool get hasData {
    return (companyName?.isNotEmpty ?? false) ||
           (companyAddress?.isNotEmpty ?? false) ||
           (companyPhone?.isNotEmpty ?? false) ||
           (companyEmail?.isNotEmpty ?? false) ||
           (companySiret?.isNotEmpty ?? false);
  }

  /// Crée une copie du profil avec des modifications
  UserProfile copyWith({
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? companySiret,
    String? companyLogo,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companySiret: companySiret ?? this.companySiret,
      companyLogo: companyLogo ?? this.companyLogo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, companyName: $companyName)';
  }
}
