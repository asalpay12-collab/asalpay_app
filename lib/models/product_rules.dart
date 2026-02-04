/// Product Rules Model
class ProductRules {
  final int? id;
  final int? productId;
  final String? ruleType;
  final Map<String, dynamic>? ruleData;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? calculatedDeposit;
  final double? depositPercentage;
  final double? loanAmount;
  final int? repaymentDurationMonths;
  final double? monthlyInstallment;

  ProductRules({
    this.id,
    this.productId,
    this.ruleType,
    this.ruleData,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.calculatedDeposit,
    this.depositPercentage,
    this.loanAmount,
    this.repaymentDurationMonths,
    this.monthlyInstallment,
  });

  factory ProductRules.fromJson(Map<String, dynamic> json) {
    final repMonths = json['repayment_duration_months'];
    final repaymentMonths = repMonths == null
        ? null
        : (repMonths is int
            ? repMonths
            : (repMonths is num
                ? repMonths.toInt()
                : int.tryParse(repMonths.toString())));
    return ProductRules(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      productId: json['product_id'] is int
          ? json['product_id'] as int
          : int.tryParse(json['product_id']?.toString() ?? ''),
      ruleType: json['rule_type']?.toString(),
      ruleData: json['rule_data'] is Map<String, dynamic>
          ? json['rule_data'] as Map<String, dynamic>
          : null,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      calculatedDeposit: json['calculated_deposit'] != null
          ? (json['calculated_deposit'] is num
              ? (json['calculated_deposit'] as num).toDouble()
              : double.tryParse(json['calculated_deposit'].toString()))
          : null,
      depositPercentage: json['deposit_percentage'] != null
          ? (json['deposit_percentage'] is num
              ? (json['deposit_percentage'] as num).toDouble()
              : double.tryParse(json['deposit_percentage'].toString()))
          : null,
      loanAmount: json['loan_amount'] != null
          ? (json['loan_amount'] is num
              ? (json['loan_amount'] as num).toDouble()
              : double.tryParse(json['loan_amount'].toString()))
          : null,
      repaymentDurationMonths: repaymentMonths,
      monthlyInstallment: json['monthly_installment'] != null
          ? (json['monthly_installment'] is num
              ? (json['monthly_installment'] as num).toDouble()
              : double.tryParse(json['monthly_installment'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'rule_type': ruleType,
      'rule_data': ruleData,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'calculated_deposit': calculatedDeposit,
      'deposit_percentage': depositPercentage,
      'loan_amount': loanAmount,
      'repayment_duration_months': repaymentDurationMonths,
      'monthly_installment': monthlyInstallment,
    };
  }
}
