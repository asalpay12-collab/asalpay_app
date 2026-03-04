/// QOWS KAAB Application Model
class QowsKaabApplication {
  final int? id;
  final String? walletAccount;
  final String? status;
  final String? applicationNumber;
  final double? creditLimit;
  final double? usedAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final String? serviceModel;
  final double? packTotalAmount;
  final double? dailyCreditLimit;
  final double? paymentDueNextMonth;
  final double? monthlyPaymentDue;
  final int? familySize;
  /// 0 = pending approval, 1 = approved (only pending can be cancelled by customer)
  final int? eligibilityApproved;

  QowsKaabApplication({
    this.id,
    this.walletAccount,
    this.status,
    this.applicationNumber,
    this.creditLimit,
    this.usedAmount,
    this.createdAt,
    this.updatedAt,
    this.metadata,
    this.serviceModel,
    this.packTotalAmount,
    this.dailyCreditLimit,
    this.paymentDueNextMonth,
    this.monthlyPaymentDue,
    this.familySize,
    this.eligibilityApproved,
  });

  /// True when application is pending approval and can be cancelled by the customer.
  bool get canCancel =>
      (eligibilityApproved ?? 0) == 0 &&
      (status?.toLowerCase() != 'closed' && status?.toLowerCase() != 'cancelled');

  // Computed getters
  bool get isMonthlyPack => serviceModel?.toLowerCase() == 'monthly_pack';
  bool get isDailyCredit => serviceModel?.toLowerCase() == 'daily_credit';
  int? get qowsKaabId => id;

  factory QowsKaabApplication.fromJson(Map<String, dynamic> json) {
    return QowsKaabApplication(
      id: (json['qows_kaab_id'] ?? json['id']) != null
          ? int.tryParse((json['qows_kaab_id'] ?? json['id']).toString())
          : null,
      walletAccount: _stringFromJson(json['wallet_account']),
      status: _stringFromJson(json['status']),
      applicationNumber: _stringFromJson(json['application_number']),
      creditLimit: json['credit_limit'] != null
          ? double.tryParse(json['credit_limit'].toString())
          : null,
      usedAmount: json['used_amount'] != null
          ? double.tryParse(json['used_amount'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
      serviceModel: _stringFromJson(json['service_model']),
      packTotalAmount: json['pack_total_amount'] != null
          ? double.tryParse(json['pack_total_amount'].toString())
          : null,
      dailyCreditLimit: json['daily_credit_limit'] != null
          ? double.tryParse(json['daily_credit_limit'].toString())
          : null,
      paymentDueNextMonth: json['payment_due_next_month'] != null
          ? double.tryParse(json['payment_due_next_month'].toString())
          : null,
      monthlyPaymentDue: json['monthly_payment_due'] != null
          ? double.tryParse(json['monthly_payment_due'].toString())
          : null,
      familySize: json['family_size'] != null ? int.tryParse(json['family_size'].toString()) : null,
      eligibilityApproved: json['eligibility_approved'] != null ? int.tryParse(json['eligibility_approved'].toString()) : null,
    );
  }

  static String? _stringFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_account': walletAccount,
      'status': status,
      'application_number': applicationNumber,
      'credit_limit': creditLimit,
      'used_amount': usedAmount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'service_model': serviceModel,
      'pack_total_amount': packTotalAmount,
      'daily_credit_limit': dailyCreditLimit,
      'payment_due_next_month': paymentDueNextMonth,
      'monthly_payment_due': monthlyPaymentDue,
      'family_size': familySize,
      'eligibility_approved': eligibilityApproved,
    };
  }
}
