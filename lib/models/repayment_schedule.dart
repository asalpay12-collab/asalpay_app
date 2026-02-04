/// Repayment Schedule Model
class RepaymentSchedule {
  final int? id;
  final int? applicationId;
  final double? amount;
  final DateTime? dueDate;
  final String? status;
  final DateTime? paidAt;
  final Map<String, dynamic>? metadata;
  final String? paymentStatus;
  final int? installmentNumber;
  final String? paymentMethod;

  RepaymentSchedule({
    this.id,
    this.applicationId,
    this.amount,
    this.dueDate,
    this.status,
    this.paidAt,
    this.metadata,
    this.paymentStatus,
    this.installmentNumber,
    this.paymentMethod,
  });

  // Computed getters for backward compatibility
  int? get scheduleId => id;
  double? get installmentAmount => amount;
  DateTime? get paymentDate => paidAt;

  // Computed getter for overdue status
  bool get isOverdue {
    if (dueDate == null) return false;
    final statusToCheck = paymentStatus ?? status;
    if (statusToCheck?.toLowerCase() == 'paid') return false;
    return dueDate!.isBefore(DateTime.now());
  }

  factory RepaymentSchedule.fromJson(Map<String, dynamic> json) {
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

    // Helper function to safely parse double
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Remove any currency symbols or spaces, but keep decimal point
        final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
        final parsed = double.tryParse(cleaned);
        if (parsed == null && cleaned.isNotEmpty) {
          // Try parsing as integer if decimal parsing fails
          final intParsed = int.tryParse(cleaned);
          if (intParsed != null) return intParsed.toDouble();
        }
        return parsed;
      }
      return null;
    }

    // Parse amount - backend returns 'installment_amount' as primary field
    // Try multiple possible field names in order of priority
    final amountValue = json['installment_amount'] ??
        json['amount'] ??
        json['monthly_installment'] ??
        json['installmentAmount'];

    return RepaymentSchedule(
      id: _parseInt(json['id'] ?? json['schedule_id']),
      applicationId: _parseInt(json['application_id']),
      amount: _parseDouble(amountValue),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      status: _parseString(json['status']),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
      metadata: _parseMap(json['metadata']),
      paymentStatus: _parseString(json['payment_status'] ?? json['status']),
      installmentNumber: _parseInt(json['installment_number']),
      paymentMethod: _parseString(json['payment_method']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_id': applicationId,
      'amount': amount,
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'paid_at': paidAt?.toIso8601String(),
      'metadata': metadata,
      'payment_status': paymentStatus ?? status,
      'installment_number': installmentNumber,
      'payment_method': paymentMethod,
    };
  }
}
