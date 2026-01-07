class UserModel {
  final String uid;
  final String email;
  final String companyName;
  final String companyAddress;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? avatarUrl;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.email,
    required this.companyName,
    required this.companyAddress,
    required this.createdAt,
    this.lastLoginAt,
    this.avatarUrl,
    this.phoneNumber,
  });

  /// Crée un UserModel depuis les données Firebase Realtime Database
  /// @param uid L'identifiant unique Firebase de l'utilisateur
  /// @param json Les données JSON récupérées de la base
  factory UserModel.fromJson(String uid, Map<String, dynamic> json) {
    return UserModel(
      uid: uid,
      email: json['email'] ?? '',
      companyName: json['companyName'] ?? '',
      companyAddress: json['companyAddress'] ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      lastLoginAt: _parseTimestamp(json['lastLoginAt']),
      avatarUrl: json['avatarUrl'],
      phoneNumber: json['phoneNumber'],
    );
  }

  /// Parse un timestamp Firebase en DateTime
  /// Firebase peut retourner soit un int (milliseconds) soit un Map (ServerValue.timestamp)
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    if (timestamp is Map && timestamp.containsKey('.sv')) {
      // C'est un ServerValue.timestamp qui n'a pas encore été résolu
      return DateTime.now();
    }

    return DateTime.now();
  }

  /// Convertit le UserModel en JSON pour Firebase
  /// Utilisé lors de la création ou mise à jour dans Realtime Database
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }

  /// Crée une copie du UserModel avec certains champs modifiés
  /// Utile pour mettre à jour les données sans créer un nouvel objet complet
  UserModel copyWith({
    String? email,
    String? companyName,
    String? companyAddress,
    DateTime? lastLoginAt,
    String? avatarUrl,
    String? phoneNumber,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  /// Retourne le nom d'affichage de l'utilisateur
  /// Utilise le nom de l'entreprise par défaut
  String get displayName => companyName.isNotEmpty ? companyName : email;

  /// Vérifie si l'utilisateur a une photo de profil
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Vérifie si l'utilisateur a un numéro de téléphone
  bool get hasPhoneNumber => phoneNumber != null && phoneNumber!.isNotEmpty;

  /// Retourne les initiales du nom de l'entreprise
  /// Utilisé pour afficher un avatar par défaut avec les initiales
  String get initials {
    if (companyName.isEmpty) return email.substring(0, 1).toUpperCase();

    final words = companyName.split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
  }

  /// Formate la date de création
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a ${weeks} semaine${weeks > 1 ? 's' : ''}';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Formate la dernière connexion
  String get formattedLastLogin {
    if (lastLoginAt == null) return 'Jamais connecté';

    final now = DateTime.now();
    final difference = now.difference(lastLoginAt!);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${lastLoginAt!.day}/${lastLoginAt!.month}/${lastLoginAt!.year}';
    }
  }

  /// Conversion en String pour debug
  @override
  String toString() {
    return 'UserModel('
        'uid: $uid, '
        'email: $email, '
        'companyName: $companyName, '
        'companyAddress: $companyAddress, '
        'createdAt: $createdAt, '
        'lastLoginAt: $lastLoginAt'
        ')';
  }

  /// Comparaison entre deux UserModel
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.companyName == companyName &&
        other.companyAddress == companyAddress;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
    email.hashCode ^
    companyName.hashCode ^
    companyAddress.hashCode;
  }
}