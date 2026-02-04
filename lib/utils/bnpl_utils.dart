/// BNPL Business Logic Utility Class
/// Handles all BNPL calculations, eligibility checks, and business rules

class BnplUtils {
  /// Check if order total is eligible for BNPL (minimum $50)
  static bool isOrderEligible(double totalAmount) {
    return totalAmount >= 50.0;
  }

  /// Determine income category based on monthly income
  static String getIncomeCategory(double monthlyIncome) {
    if (monthlyIncome >= 1000 && monthlyIncome <= 2000) {
      return 'E';
    } else if (monthlyIncome >= 701 && monthlyIncome <= 1000) {
      return 'D';
    } else if (monthlyIncome >= 501 && monthlyIncome <= 700) {
      return 'C';
    } else if (monthlyIncome >= 400 && monthlyIncome <= 500) {
      return 'B';
    } else if (monthlyIncome >= 300 && monthlyIncome <= 399) {
      return 'A';
    }
    return 'A'; // Default to category A
  }

  /// Calculate deposit and repayment terms based on income category and product price
  /// Returns: {depositPercentage, durationMonths, averageMonthlyPayment}
  static Map<String, dynamic> calculateDepositAndDuration(
    String incomeCategory,
    double productPrice,
  ) {
    double depositPercentage = 0.0;
    int durationMonths = 0;
    double averageMonthlyPayment = 0.0;

    switch (incomeCategory) {
      case 'A': // $300-399
        if (productPrice >= 50 && productPrice <= 100) {
          depositPercentage = 15.0;
          durationMonths = 2;
          averageMonthlyPayment = 40.0;
        } else if (productPrice >= 101 && productPrice <= 150) {
          depositPercentage = 15.0;
          durationMonths = 3;
          averageMonthlyPayment = 40.0;
        } else if (productPrice >= 151 && productPrice <= 250) {
          depositPercentage = 20.0;
          durationMonths = 4;
          averageMonthlyPayment = 50.0;
        }
        break;

      case 'B': // $400-499
        if (productPrice >= 251 && productPrice <= 400) {
          depositPercentage = 20.0;
          durationMonths = 5;
          averageMonthlyPayment = 60.0;
        } else if (productPrice >= 401 && productPrice <= 500) {
          depositPercentage = 20.0;
          durationMonths = 6;
          averageMonthlyPayment = 60.0;
        }
        break;

      case 'C': // $501-700
        if (productPrice >= 501 && productPrice <= 600) {
          depositPercentage = 30.0;
          durationMonths = 6;
          averageMonthlyPayment = 70.0;
        } else if (productPrice >= 601 && productPrice <= 700) {
          depositPercentage = 30.0;
          durationMonths = 6;
          averageMonthlyPayment = 80.0;
        }
        break;

      case 'D': // $701-1,000
        if (productPrice >= 701 && productPrice <= 850) {
          depositPercentage = 40.0;
          durationMonths = 6;
          averageMonthlyPayment = 85.0;
        } else if (productPrice >= 851 && productPrice <= 1000) {
          depositPercentage = 40.0;
          durationMonths = 6;
          averageMonthlyPayment = 80.0;
        }
        break;

      case 'E': // $1,000-2,000
        if (productPrice >= 1000 && productPrice <= 1500) {
          depositPercentage = 40.0;
          durationMonths = 9;
          averageMonthlyPayment = 90.0;
        } else if (productPrice >= 1501 && productPrice <= 2000) {
          depositPercentage = 50.0;
          durationMonths = 9;
          averageMonthlyPayment = 80.0;
        }
        break;
    }

    // Calculate actual values
    final calculatedDeposit = (productPrice * depositPercentage) / 100;
    final loanAmount = productPrice - calculatedDeposit;
    final monthlyInstallment =
        durationMonths > 0 ? loanAmount / durationMonths : 0.0;

    return {
      'deposit_percentage': depositPercentage,
      'duration_months': durationMonths,
      'calculated_deposit': calculatedDeposit,
      'loan_amount': loanAmount,
      'monthly_installment': monthlyInstallment,
      'average_monthly_payment': averageMonthlyPayment,
    };
  }

  /// Check if outstanding balance would exceed $1,000 limit
  static bool wouldExceedLimit(
      double currentOutstanding, double newLoanAmount) {
    return (currentOutstanding + newLoanAmount) > 1000.0;
  }

  /// Get risk category description
  static String getRiskCategoryDescription(String riskCategory) {
    switch (riskCategory) {
      case '1':
        return 'Low Risk (Near City)';
      case '2':
        return 'Medium Risk (Suburban)';
      case '3':
        return 'High Risk (Remote Areas)';
      default:
        return 'Unknown Risk';
    }
  }

  /// Get approval status description
  static String getApprovalStatusDescription(String? status) {
    if (status == null) return 'Unknown';
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'branch_approved':
        return 'Branch Approved';
      case 'credit_approved':
        return 'Credit Approved';
      case 'operations_approved':
        return 'Operations Approved';
      case 'rejected':
        return 'Rejected';
      case 'approved':
        return 'Approved';
      default:
        return status;
    }
  }

  /// Get payment status color
  static int getPaymentStatusColor(String? status) {
    if (status == null) return 0xFF757575; // Grey
    switch (status.toLowerCase()) {
      case 'paid':
        return 0xFF4CAF50; // Green
      case 'pending':
        return 0xFFFF9800; // Orange
      case 'overdue':
        return 0xFFF44336; // Red
      default:
        return 0xFF757575; // Grey
    }
  }

  /// Format currency
  static String formatCurrency(double? amount) {
    if (amount == null) return '\$0.00';
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Format date - accepts both String and DateTime
  static String formatDate(dynamic dateInput) {
    if (dateInput == null) return 'N/A';

    DateTime date;
    if (dateInput is DateTime) {
      date = dateInput;
    } else if (dateInput is String) {
      if (dateInput.isEmpty) return 'N/A';
      try {
        date = DateTime.parse(dateInput);
      } catch (e) {
        return dateInput;
      }
    } else {
      return 'N/A';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  /// Check if application needs manual approval (Category C)
  static bool needsManualApproval(String? riskCategory) {
    return riskCategory == '3' || riskCategory == 'C';
  }

  /// Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Check if it's a valid Somali phone number (usually 9 digits after country code)
    return cleaned.length >= 9;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
