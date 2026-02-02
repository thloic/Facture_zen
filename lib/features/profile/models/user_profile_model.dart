  import 'package:flutter/foundation.dart';

  /// Modèle de profil utilisateur contenant les informations de l'entreprise
  class UserProfile {
    final String userId;
    
    // Identification de l'entreprise
    final String? companyName;
    final String? companyAddress;
    final String? companyPhone;
    final String? companyEmail;
    final String? companySiret;
    final String? companySiren;
    final String? companyLegalForm; // EURL, SAS, SARL, etc.
    final String? companyCapital; // Capital social
    final String? companyTvaNumber; // Numéro de TVA intracommunautaire
    final String? companyLogo; // URL Firebase Storage
    
    // Facturation
    final String? invoicePrefix; // Préfixe de numérotation (ex: FACT-)
    
    // Paiement
    final String? iban;
    final String? bic;
    final String? paymentDelay; // Délai de paiement (ex: "30 jours")
    final String? penaltyRate; // Taux de pénalité de retard (ex: "10%")
    
    // Mentions légales spécifiques
    final String? insuranceCompany; // Compagnie d'assurance (artisans)
    final String? insurancePolicy; // Numéro de police d'assurance
    final String? approvedAssociation; // Association agréée
    
    // Statuts
    final bool? isAutoEntrepreneur; // Auto-entrepreneur (TVA non applicable)
    final bool? isArtisan; // Artisan (assurance décennale)
    final bool? hasTVA; // Soumis à la TVA
    
    final DateTime createdAt;
    final DateTime updatedAt;

    UserProfile({
      required this.userId,
      this.companyName,
      this.companyAddress,
      this.companyPhone,
      this.companyEmail,
      this.companySiret,
      this.companySiren,
      this.companyLegalForm,
      this.companyCapital,
      this.companyTvaNumber,
      this.companyLogo,
      this.invoicePrefix,
      this.iban,
      this.bic,
      this.paymentDelay,
      this.penaltyRate,
      this.insuranceCompany,
      this.insurancePolicy,
      this.approvedAssociation,
      this.isAutoEntrepreneur,
      this.isArtisan,
      this.hasTVA,
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
        companySiren: map['companySiren'] as String?,
        companyLegalForm: map['companyLegalForm'] as String?,
        companyCapital: map['companyCapital'] as String?,
        companyTvaNumber: map['companyTvaNumber'] as String?,
        companyLogo: map['companyLogo'] as String?,
        invoicePrefix: map['invoicePrefix'] as String?,
        iban: map['iban'] as String?,
        bic: map['bic'] as String?,
        paymentDelay: map['paymentDelay'] as String?,
        penaltyRate: map['penaltyRate'] as String?,
        insuranceCompany: map['insuranceCompany'] as String?,
        insurancePolicy: map['insurancePolicy'] as String?,
        approvedAssociation: map['approvedAssociation'] as String?,
        isAutoEntrepreneur: map['isAutoEntrepreneur'] as bool?,
        isArtisan: map['isArtisan'] as bool?,
        hasTVA: map['hasTVA'] as bool?,
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
        'companySiren': companySiren,
        'companyLegalForm': companyLegalForm,
        'companyCapital': companyCapital,
        'companyTvaNumber': companyTvaNumber,
        'companyLogo': companyLogo,
        'invoicePrefix': invoicePrefix,
        'iban': iban,
        'bic': bic,
        'paymentDelay': paymentDelay,
        'penaltyRate': penaltyRate,
        'insuranceCompany': insuranceCompany,
        'insurancePolicy': insurancePolicy,
        'approvedAssociation': approvedAssociation,
        'isAutoEntrepreneur': isAutoEntrepreneur,
        'isArtisan': isArtisan,
        'hasTVA': hasTVA,
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
            (companySiret?.isNotEmpty ?? false) ||
            (companySiren?.isNotEmpty ?? false) ||
            (companyLegalForm?.isNotEmpty ?? false) ||
            (companyCapital?.isNotEmpty ?? false) ||
            (companyTvaNumber?.isNotEmpty ?? false) ||
            (invoicePrefix?.isNotEmpty ?? false) ||
            (iban?.isNotEmpty ?? false) ||
            (bic?.isNotEmpty ?? false);
    }

    /// Vérifie si le profil est complet pour générer une facture légale
    bool get isCompleteForInvoice {
      // Vérifications minimales pour une facture conforme
      bool hasBasicInfo = (companyName?.isNotEmpty ?? false) &&
                          (companyAddress?.isNotEmpty ?? false);
      
      bool hasIdentification = (companySiret?.isNotEmpty ?? false) ||
                              (companySiren?.isNotEmpty ?? false);
      
      return hasBasicInfo && hasIdentification;
    }

    /// Récupère les mentions légales à afficher sur la facture
    String get legalMentions {
      List<String> mentions = [];
      
      // Auto-entrepreneur
      if (isAutoEntrepreneur == true) {
        mentions.add('TVA non applicable, art. 293 B du CGI');
      }
      
      // Artisan - Assurance décennale
      if (isArtisan == true && insuranceCompany?.isNotEmpty == true) {
        String insurance = 'Assurance décennale : $insuranceCompany';
        if (insurancePolicy?.isNotEmpty == true) {
          insurance += ' - $insurancePolicy';
        }
        mentions.add(insurance);
      }
      
      // Association agréée
      if (approvedAssociation?.isNotEmpty == true) {
        mentions.add('Membre de l\'association agréée : $approvedAssociation');
        mentions.add('Acceptant le règlement des sommes dues par chèques libellés à son nom ou par carte bancaire');
      }
      
      // Pénalités de retard (obligatoire entre professionnels)
      if (penaltyRate?.isNotEmpty == true) {
        mentions.add('Pénalités de retard : $penaltyRate');
      }
      
      // Indemnité forfaitaire (40€ obligatoire entre professionnels)
      mentions.add('Indemnité forfaitaire pour frais de recouvrement : 40 €');
      
      return mentions.join('\n');
    }

    /// Crée une copie du profil avec des modifications
    UserProfile copyWith({
      String? companyName,
      String? companyAddress,
      String? companyPhone,
      String? companyEmail,
      String? companySiret,
      String? companySiren,
      String? companyLegalForm,
      String? companyCapital,
      String? companyTvaNumber,
      String? companyLogo,
      String? invoicePrefix,
      String? iban,
      String? bic,
      String? paymentDelay,
      String? penaltyRate,
      String? insuranceCompany,
      String? insurancePolicy,
      String? approvedAssociation,
      bool? isAutoEntrepreneur,
      bool? isArtisan,
      bool? hasTVA,
      DateTime? updatedAt,
    }) {
      return UserProfile(
        userId: userId,
        companyName: companyName ?? this.companyName,
        companyAddress: companyAddress ?? this.companyAddress,
        companyPhone: companyPhone ?? this.companyPhone,
        companyEmail: companyEmail ?? this.companyEmail,
        companySiret: companySiret ?? this.companySiret,
        companySiren: companySiren ?? this.companySiren,
        companyLegalForm: companyLegalForm ?? this.companyLegalForm,
        companyCapital: companyCapital ?? this.companyCapital,
        companyTvaNumber: companyTvaNumber ?? this.companyTvaNumber,
        companyLogo: companyLogo ?? this.companyLogo,
        invoicePrefix: invoicePrefix ?? this.invoicePrefix,
        iban: iban ?? this.iban,
        bic: bic ?? this.bic,
        paymentDelay: paymentDelay ?? this.paymentDelay,
        penaltyRate: penaltyRate ?? this.penaltyRate,
        insuranceCompany: insuranceCompany ?? this.insuranceCompany,
        insurancePolicy: insurancePolicy ?? this.insurancePolicy,
        approvedAssociation: approvedAssociation ?? this.approvedAssociation,
        isAutoEntrepreneur: isAutoEntrepreneur ?? this.isAutoEntrepreneur,
        isArtisan: isArtisan ?? this.isArtisan,
        hasTVA: hasTVA ?? this.hasTVA,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
    }

    @override
    String toString() {
      return 'UserProfile(userId: $userId, companyName: $companyName, siret: $companySiret)';
    }
  }