/// BNPL Application Model
class BnplApplication {
  final int? id;
  final String? walletAccount;
  final String? status;
  final double? creditLimit;
  final double? usedAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final String? approvalStatus;
  final String? applicationNumber;
  final String? productName;
  final DateTime? applicationDate;
  final double? productPrice;
  final double? calculatedDeposit;
  final double? loanAmount;
  final double? monthlyInstallment;
  final int? repaymentDurationMonths;
  final int? orderId;

  BnplApplication({
    this.id,
    this.walletAccount,
    this.status,
    this.creditLimit,
    this.usedAmount,
    this.createdAt,
    this.updatedAt,
    this.metadata,
    this.approvalStatus,
    this.applicationNumber,
    this.productName,
    this.applicationDate,
    this.productPrice,
    this.calculatedDeposit,
    this.loanAmount,
    this.monthlyInstallment,
    this.repaymentDurationMonths,
    this.orderId,
  });

  // Computed getter for backward compatibility
  int? get applicationId => id;

  factory BnplApplication.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    // Helper function to safely parse string
    String? _parseString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    // Helper function to safely parse map
    Map<String, dynamic>? _parseMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    }

    return BnplApplication(
      id: _parseInt(json['id'] ?? json['application_id']),
      walletAccount: _parseString(json['wallet_account']),
      status: _parseString(json['status']),
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
      metadata: _parseMap(json['metadata']),
      approvalStatus: _parseString(json['approval_status'] ?? json['status']),
      applicationNumber: _parseString(json['application_number']),
      productName: _parseString(json['product_name']),
      applicationDate: json['application_date'] != null
          ? DateTime.tryParse(json['application_date'].toString())
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null),
      productPrice: json['product_price'] != null
          ? double.tryParse(json['product_price'].toString())
          : null,
      calculatedDeposit: json['calculated_deposit'] != null
          ? double.tryParse(json['calculated_deposit'].toString())
          : null,
      loanAmount: json['loan_amount'] != null
          ? double.tryParse(json['loan_amount'].toString())
          : null,
      monthlyInstallment: json['monthly_installment'] != null
          ? double.tryParse(json['monthly_installment'].toString())
          : null,
      repaymentDurationMonths: _parseInt(json['repayment_duration_months']),
      orderId: _parseInt(json['order_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_account': walletAccount,
      'status': status,
      'credit_limit': creditLimit,
      'used_amount': usedAmount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'approval_status': approvalStatus ?? status,
      'application_number': applicationNumber,
      'product_name': productName,
      'application_date':
          applicationDate?.toIso8601String() ?? createdAt?.toIso8601String(),
      'product_price': productPrice,
      'calculated_deposit': calculatedDeposit,
      'loan_amount': loanAmount,
      'monthly_installment': monthlyInstallment,
      'repayment_duration_months': repaymentDurationMonths,
      'order_id': orderId,
    };
  }
}
