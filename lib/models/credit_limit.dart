/// Credit Limit Model
class CreditLimit {
  final int? id;
  final String? walletAccount;
  final double? limit;
  final double? used;
  final double? available;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isFrozen;
  final String? freezeReason;

  CreditLimit({
    this.id,
    this.walletAccount,
    this.limit,
    this.used,
    this.available,
    this.createdAt,
    this.updatedAt,
    this.isFrozen,
    this.freezeReason,
  });

  // Computed getters for backward compatibility
  double? get availableCredit => available;
  double? get usedCredit => used;

  factory CreditLimit.fromJson(Map<String, dynamic> json) {
    return CreditLimit(
      id: json['id'] as int?,
      walletAccount: json['wallet_account'] as String?,
      limit: json['limit'] != null
          ? double.tryParse(json['limit'].toString())
          : null,
      used: json['used'] != null
          ? double.tryParse(json['used'].toString())
          : null,
      available: json['available'] != null
          ? double.tryParse(json['available'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      isFrozen: json['is_frozen'] as bool? ?? json['isFrozen'] as bool?,
      freezeReason:
          json['freeze_reason'] as String? ?? json['freezeReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_account': walletAccount,
      'limit': limit,
      'used': used,
      'available': available,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_frozen': isFrozen,
      'freeze_reason': freezeReason,
    };
  }
}
